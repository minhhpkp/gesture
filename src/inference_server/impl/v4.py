# Version 4: one worker per model, multi-stream for overlaping copy/compute in CSLR
# Configurable params: NUM_SLOTS, det_batch_size

import time
from collections import deque
import queue
import torch
import numpy as np
from typing import Optional, List, Callable
from enum import Enum
from utils.misc import get_logger
from worker import Worker
from buffers import DropOldBuffer, DropOldBatchBuffer
from pose import get_part_keypoints, PoseInferencer
from onlinecslr import OnlineCSLRInferencer

class VotingStrategy(Enum):
    MAJORITY = 0
    MAX_AVG_PROB = 1

def get_frame_num_in_win_batch(window_batch_size, window_size, stride):
    return window_size + stride * (window_batch_size - 1)

class Slot:
    def __init__(self, keypoint_num: int, height: int, width: int, window_size: int, stride: int,
                 max_batch_size: int, vocab_size: int, device):
        self.video_cpu = torch.empty((max_batch_size, window_size, 3, height, width), dtype=torch.float32, pin_memory=True)
        self.video_gpu = torch.empty((max_batch_size, window_size, 3, height, width), dtype=torch.float32, device=device)
        self.keypoint_cpu = torch.empty((max_batch_size, window_size, keypoint_num, 3), dtype=torch.float32, pin_memory=True)
        self.keypoint_gpu = torch.empty((max_batch_size, window_size, keypoint_num, 3), dtype=torch.float32, device=device)        
        self.logit_gpu = torch.empty((max_batch_size, vocab_size), dtype=torch.float32, device=device)
        self.logit_cpu = torch.zeros((max_batch_size, vocab_size), dtype=torch.float32, pin_memory=True)        

        self.batch_size = max_batch_size
        self.window_size = window_size        
        self.h2d_done = torch.cuda.Event()
        self.compute_done = torch.cuda.Event()
        self.d2h_done = torch.cuda.Event()

        self.start = None

   
class PoseInferenceWorker(Worker):
    def __init__(self, det_buf: DropOldBuffer, pose_buf: DropOldBatchBuffer, used_parts: List[str], height: int, width: int, inferencer: PoseInferencer, vis_buf: Optional[DropOldBuffer] = None, daemon = True):
        super().__init__(daemon=daemon)
        self.logger = get_logger()
        self.inferencer = inferencer
        self.inferencer.warm_up(height=height, width=width, steps=10)
        self.used_parts = used_parts
        self.det_buf = det_buf
        self.pose_buf = pose_buf
        self.vis_buf = vis_buf

    def work(self):
        frame, person_boxes, start = self.det_buf.get()
        
        all_kp = self.inferencer.infer(frame, person_boxes)
        necessary_kp = get_part_keypoints(all_keypoints=all_kp, used_parts=self.used_parts)

        frame_tensor = torch.from_numpy(frame).permute(2, 0, 1).float().div(255.0).contiguous() # C,H,W float32
        keypoint_tensor = torch.from_numpy(necessary_kp)
        self.pose_buf.put((frame_tensor, keypoint_tensor, start))

        if self.vis_buf is not None:
            self.vis_buf.put((frame[..., ::-1], all_kp))

class WindowBatcher(Worker):
    def __init__(self, pose_buf: DropOldBatchBuffer, window_size: int, stride: int, max_batch_size: int, batching_timeout: float,
                 slots: List[Slot], free_ids: queue.Queue, loaded_ids: queue.Queue, daemon = True):
        super().__init__(daemon = daemon)
        self.pose_buf = pose_buf
        self.window_size = window_size
        self.stride = stride
        self.slots = slots
        self.free_ids = free_ids
        self.loaded_ids = loaded_ids
        self.frame_batch_size = get_frame_num_in_win_batch(max_batch_size, window_size, stride)
        self.batching_timeout = batching_timeout
        self.prev_video = []
        self.prev_keypoints = []
        self.reserved = window_size - stride
        
    def work(self):
        avail = len(self.prev_video)
        needed = self.frame_batch_size - avail
        batch = self.pose_buf.get_batch(N=needed, timeout=self.batching_timeout)
        id = self.free_ids.get()
        slot = self.slots[id]

        # when this batch is obtained
        slot.start = batch[-1][2]

        frame_tensors = self.prev_video + [item[0] for item in batch]
        keypoint_tensors = self.prev_keypoints + [item[1] for item in batch]
        self.prev_video = frame_tensors[-self.reserved:]
        self.prev_keypoints = keypoint_tensors[-self.reserved:]
        
        N_total = len(frame_tensors)

        if N_total < self.window_size:     
            self.logger.warning(f'batcher: small window')       
            for w_idx in range(N_total):
                slot.video_cpu[0, w_idx].copy_(frame_tensors[w_idx])
                slot.keypoint_cpu[0, w_idx].copy_(keypoint_tensors[w_idx])
            slot.batch_size = 1
            slot.window_size = N_total
        else:
            # compute max windows possible from available frames
            B_actual = 1 + (N_total - self.window_size) // self.stride
            # if last window doesn't have enough frame
            # reduce stride to add frames from second-to-last window
            reduce_last_stride = (N_total - self.window_size) % self.stride != 0
            if reduce_last_stride:
                B_actual += 1
            # print(f'inf: B_actual={B_actual}')

            for b in range(B_actual - 1): 
                base = b * self.stride
                # print(base)
                for w_idx in range(self.window_size):
                    slot.video_cpu[b, w_idx].copy_(frame_tensors[base + w_idx])
                    slot.keypoint_cpu[b, w_idx].copy_(keypoint_tensors[base + w_idx])
                
            # get the last chunk of frames
            last_base = N_total - self.window_size
            for w_idx in range(self.window_size):                  
                slot.video_cpu[B_actual - 1, w_idx].copy_(frame_tensors[last_base + w_idx])
                slot.keypoint_cpu[B_actual - 1, w_idx].copy_(keypoint_tensors[last_base + w_idx])
            slot.batch_size = B_actual
            slot.window_size = self.window_size            
        self.loaded_ids.put(id)

class CSLRInferenceWorker(Worker):
    def __init__(self, inferencer: OnlineCSLRInferencer, slots: List[Slot], loaded_ids: queue.Queue, scheduled_ids: queue.Queue, max_batch_size: int, daemon = True):
        super().__init__(daemon=daemon)
        self.inferencer = inferencer
        self.inferencer.warm_up(steps=10, batch_size=max_batch_size)                
        self.slots = slots
        self.scheduled_ids = scheduled_ids
        self.loaded_ids = loaded_ids
        self.h2d_stream = torch.cuda.Stream(device=inferencer.device)
        self.compute_stream = torch.cuda.Stream(device=inferencer.device)
        self.d2h_stream = torch.cuda.Stream(device=inferencer.device)        
        self.logger = get_logger()    
        self.compute_done = torch.cuda.Event()

    def work(self):
        id = self.loaded_ids.get()
        slot = self.slots[id]            

        with torch.cuda.stream(self.h2d_stream):            
            try:
                slot.video_gpu[:slot.batch_size, :slot.window_size].copy_(slot.video_cpu[:slot.batch_size, :slot.window_size], non_blocking=True)
            except RuntimeError:
                self.logger.warning(f'inf: video async copy failed, falling back to blocking')
                slot.video_gpu[:slot.batch_size, :slot.window_size] = slot.video_cpu[:slot.batch_size, :slot.window_size].to(device=self.inferencer.device)
            
            try:                    
                slot.keypoint_gpu[:slot.batch_size, :slot.window_size].copy_(slot.keypoint_cpu[:slot.batch_size, :slot.window_size], non_blocking=True)
            except RuntimeError:
                self.logger.warning(f'inf: keypoints async copy failed, falling back to blocking')
                slot.keypoint_gpu[:slot.batch_size, :slot.window_size] = slot.keypoint_cpu[:slot.batch_size, :slot.window_size].to(device=self.inferencer.device)
        slot.h2d_done.record(self.h2d_stream)
        
        slot.h2d_done.wait(self.compute_stream)
        with torch.cuda.stream(self.compute_stream):            
            gls_logits = self.inferencer.infer(slot.video_gpu[:slot.batch_size, :slot.window_size], slot.keypoint_gpu[:slot.batch_size, :slot.window_size])
            slot.logit_gpu.copy_(gls_logits)
        slot.compute_done.record(self.compute_stream)

        slot.compute_done.wait(self.d2h_stream)
        with torch.cuda.stream(self.d2h_stream):
            slot.logit_cpu.copy_(slot.logit_gpu, non_blocking=True)
        slot.d2h_done.record(self.d2h_stream)
        
        self.scheduled_ids.put(id)

class PostProcessingWorker(Worker):
    def __init__(self, slots: List[Slot], scheduled_ids: queue.Queue, free_ids: queue.Queue,  out_buf: DropOldBuffer, logits2glosses: Callable[[torch.Tensor], List],
                 voting_bag_size: int,  blank_id: int, voting_bag_stride: int = 1, voting_strategy: VotingStrategy = VotingStrategy.MAJORITY, daemon=True):
        super().__init__(daemon=daemon)
        self.slots = slots
        self.scheduled_ids = scheduled_ids
        self.free_ids = free_ids
        self.B = voting_bag_size
        self.S = voting_bag_stride    
        self.blank_id = blank_id
        self.voting_strategy = voting_strategy
        self.logits2glosses = logits2glosses
        
        self.last_output_id = blank_id
        self.last_voting_result = blank_id
        self.out_buf = out_buf        
        self.start_idx = 0

        self.reserved = self.B - self.S
        if self.voting_strategy == VotingStrategy.MAJORITY:
            self.prev_res = []
        else:            
            self.prev_res = torch.empty((0, slots[0].logit_cpu.shape[1]), dtype=torch.float32)

        self.logger = get_logger()

    def work(self):
        id = self.scheduled_ids.get()
        slot = self.slots[id]
        slot.d2h_done.synchronize()   
        N = slot.logit_cpu.shape[0] + self.reserved
        if self.voting_strategy == VotingStrategy.MAJORITY:          
            glosses = self.prev_res + self.logits2glosses(slot.logit_cpu)
            self.logger.info(f'post: glosses={glosses} delay={time.monotonic()-slot.start}')
            for start in range(0, N - self.B + 1, self.S):
                if self.B == 1: # Naive greedy
                    gloss_id = glosses[start]
                else:
                    gloss_id = self._majority_vote(glosses[start:start+self.B])
                self._save_result(gloss_id)
            if self.reserved:
                self.prev_res = glosses[-self.reserved:]
        else:            
            logits = torch.vstack([self.prev_res, slot.logit_cpu])            
            for start in range(0, N - self.B + 1, self.S):
                gloss_id = self._max_avg_prob_vote(logits[start:start+self.B])
                self._save_result(gloss_id)
            self.prev_res = logits[-self.reserved:]
        self.free_ids.put(id)

    def _majority_vote(self, bag: List[int]) -> int:
        uniq, count = np.unique(bag, return_counts=True)
        keep = uniq[count > self.B//2]
        if keep.shape[0] == 1:
            return keep.item()
        return self.blank_id
    
    def _max_avg_prob_vote(self, logits: torch.Tensor) -> int:        
        prob = logits.softmax(dim=-1).mean(dim=0)
        gloss_id = torch.argmax(prob).item()
        return gloss_id
    
    def _save_result(self, gloss_id: int):
        if gloss_id != self.blank_id and (gloss_id != self.last_output_id or self.last_voting_result == self.blank_id):
            self.out_buf.put(gloss_id)
            self.last_output_id = gloss_id
        self.last_voting_result = gloss_id
    
class Renderer(Worker):
    def __init__(self, out_buf: DropOldBuffer, index2gloss: Callable[[int], str], daemon = True):
        super().__init__(daemon = daemon)
        self.out_buf = out_buf
        self.index2gloss = index2gloss
        self.output = deque(maxlen=100)
        self.logger = get_logger()

    def work(self):
        gloss_id = self.out_buf.get()
        gloss = self.index2gloss(gloss_id)
        self.output.append(gloss)
        self.logger.info(' '.join(self.output))

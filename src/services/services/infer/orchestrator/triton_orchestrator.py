import asyncio
import numpy as np
from ..buffer import BatchBuffer
from collections.abc import AsyncIterator
from ..preprocessing import (
    preprocess_for_detection,
    preprocess_for_pose,
    preprocess_for_cslr,
    get_used_kp_indices
)
from ..postprocessing import filter_bboxes, majority_vote, max_avg_prob_vote
from ..keypoints_from_heatmaps import TopdownHeatmapBaseHeadDecode
import tritonclient.grpc.aio as grpcclient
from collections import deque
import time
from livekit import rtc
from services.settings import InferSettings, VotingStrategy
from services.utils.logging import get_logger
from .orchestrator import InferenceOrchestrator, ResultIterator

logger = get_logger(__name__)


class TritonInferenceOrchestrator(InferenceOrchestrator):
    def __init__(
        self,
        client: grpcclient.InferenceServerClient,
        infer_settings: InferSettings
    ):
        self._det_cfg = infer_settings.det
        self._pose_cfg = infer_settings.pose
        self._cslr_cfg = infer_settings.cslr
        self._client = client

        self._used_kp_indices = get_used_kp_indices(self._cslr_cfg.used_parts)


    def stream_infer(self, video_stream: AsyncIterator[rtc.VideoFrameEvent]):
        det_input_buffer = BatchBuffer()
        det_output_buffer = BatchBuffer()
        pose_input_buffer = BatchBuffer()
        pose_output_buffer = BatchBuffer()
        cslr_input_buffer = BatchBuffer()
        cslr_output_buffer = BatchBuffer()
        result_buffer = BatchBuffer()

        postprocess_task = asyncio.create_task(
            self._postprocess(
                cslr_output_buffer=cslr_output_buffer,
                result_buffer=result_buffer
            )
        )
        stream_cslr_infer_task = asyncio.create_task(
            self._stream_cslr_infer(
                input_buffer=cslr_input_buffer,
                output_buffer=cslr_output_buffer
            )
        )
        preprocess_for_cslr_task = asyncio.create_task(
            self._preprocess_for_cslr(
                pose_output_buffer=pose_output_buffer, 
                cslr_input_buffer=cslr_input_buffer
            )
        )
        stream_pose_infer_task = asyncio.create_task(
            self._stream_pose_infer(
                input_buffer=pose_input_buffer,
                output_buffer=pose_output_buffer
            )
        )
        preprocess_for_pose_task = asyncio.create_task(
            self._preprocess_for_pose(
                det_output_buffer=det_output_buffer,
                pose_input_buffer=pose_input_buffer
            )
        )
        stream_det_infer_task = asyncio.create_task(
            self._stream_det_infer(
                input_buffer=det_input_buffer,
                output_buffer=det_output_buffer
            )
        )
        preprocess_for_det_task = asyncio.create_task(
            self._preprocess_for_det(
                video_stream=video_stream,
                det_input_buffer=det_input_buffer
            )
        )

        class _ResultIterator(ResultIterator):
            def __aiter__(self):
                return self
            
            async def __anext__(self) -> int:
                result = await result_buffer.get()
                return result
            
            async def stop(self):
                preprocess_for_det_task.cancel()
                stream_det_infer_task.cancel()
                preprocess_for_pose_task.cancel()
                stream_pose_infer_task.cancel()
                preprocess_for_cslr_task.cancel()
                stream_cslr_infer_task.cancel()
                postprocess_task.cancel()

                try:
                    await asyncio.wait_for(
                        asyncio.gather(
                            preprocess_for_det_task,
                            stream_det_infer_task,
                            preprocess_for_pose_task,
                            stream_pose_infer_task,
                            preprocess_for_cslr_task,
                            stream_cslr_infer_task,
                            postprocess_task,
                        ),
                        timeout=5
                    )
                except asyncio.CancelledError:
                    logger.info("orchestrator stream stopped via cancellation")
                except asyncio.TimeoutError:
                    logger.info("Timed out waiting for orchestrator stream to stop")
        return _ResultIterator()


    async def close(self):
        await self._client.close()


    async def _preprocess_for_det(self, video_stream: AsyncIterator[rtc.VideoFrameEvent], det_input_buffer: BatchBuffer):
        async for frame_event in video_stream:
            # logger.info("frame event received")
            frame = frame_event.frame
            if frame.height < 20 or frame.width < 20:
                # at the end of the video stream there are usually 
                # some small garbage frames e.g. of size 16x16
                continue
            frame_np = np.frombuffer(frame.data, dtype=np.uint8)
            frame_np = frame_np.reshape((frame.height, frame.width, 3)) # H,W,3 RGB
            frame_np = frame_np[..., ::-1] # RGB -> BGR
            det_frame = preprocess_for_detection(frame_np, self._det_cfg.input_size)
            # logger.info("frame shape: %s det frame shape: %s", frame_np.shape, det_frame.shape)
            await det_input_buffer.put((det_frame, frame_np))


    async def _stream_det_infer(self, input_buffer: BatchBuffer, output_buffer: BatchBuffer):
        async def stream_det_request():
            while True:
                det_batch = await input_buffer.get_batch(
                    self._det_cfg.batch_size,
                    self._det_cfg.batching_timeout
                )
                if len(det_batch) == 0: continue
                # logger.info("det input received")
                det_frames = []
                orig_frames = []
                for inp in det_batch:
                    det_frames.append(inp[0])
                    orig_frames.append(inp[1])
                frame_batch = np.stack(det_frames, axis=0)
                inp_imgs = grpcclient.InferInput('IMAGES', frame_batch.shape, 'UINT8')
                inp_imgs.set_data_from_numpy(frame_batch)

                out_bboxes = grpcclient.InferRequestedOutput('BBOXES')
                out_bbox_counts = grpcclient.InferRequestedOutput('BBOX_COUNTS')

                yield {
                    "request": {
                        "model_name": "det",
                        "inputs": [inp_imgs],
                        "outputs": [out_bboxes, out_bbox_counts],
                    },

                    "prev_output": orig_frames
                }

        # logger.info("det infer started")      
        result_iterator = _stream_infer(
            self._client,
            inputs_iterator=stream_det_request(),
            model_tag="Detection"
        )
        # logger.info("def infer stream started")

        async for res, orig_frames in result_iterator:
            if res is None:
                logger.error("[Detection] None result received")
                continue
            idx, result = res
            bboxes = result.as_numpy('BBOXES')
            bbox_counts = result.as_numpy('BBOX_COUNTS')
            # logger.info("det result %d received bboxes=%s bbox_counts=%s", idx, bboxes, bbox_counts)

            if bbox_counts.shape[0] != len(orig_frames):
                logger.error("[Detection] result size mismatch: %d results for %d frames", bbox_counts.shape, len(orig_frames))
                continue

            await output_buffer.put((orig_frames, bboxes, bbox_counts))
    

    async def _preprocess_for_pose(self, det_output_buffer: BatchBuffer, pose_input_buffer: BatchBuffer):
        # logger.info("preprocess for pose started")
        while True:
            orig_frames, bboxes, bbox_counts = await det_output_buffer.get()
            # logger.info("det output received")
            offset = 0
            for idx, count in enumerate(bbox_counts):
                frame_bboxes = bboxes[offset:offset+count]
                # det postprocessing
                good_box = filter_bboxes(frame_bboxes, self._det_cfg.score_thr, self._det_cfg.area_thr)
                good_box = good_box[:4]
                # logger.info("det postprocess: box=%s", good_box)
                if good_box.shape[0] == 0:
                    await pose_input_buffer.put((False, orig_frames[idx]))
                else:
                    # pose preprocessing
                    # start_time = time.monotonic()
                    resized_img, center, scale = preprocess_for_pose(
                        img=orig_frames[idx],
                        mean=self._pose_cfg.mean,
                        std=self._pose_cfg.std,
                        input_size=self._pose_cfg.input_size,
                        bbox=good_box
                    )
                    # end_time = time.monotonic()
                    # logger.info("Pose preprocessing time: %.4fs result=%s %s", end_time - start_time, resized_img.shape, resized_img.dtype)
                    await pose_input_buffer.put(
                        (True, resized_img, center, scale, good_box, orig_frames[idx])
                    )
                offset += count


    async def _stream_pose_infer(self, input_buffer: BatchBuffer, output_buffer: BatchBuffer):
        async def stream_pose_request():
            while True:
                pose_batch = await input_buffer.get_batch(
                    self._pose_cfg.max_batch_size,
                    self._pose_cfg.batching_timeout
                )
                if len(pose_batch) == 0: continue
                # logger.info("pose input received")
                good_frames = []
                centers = []
                scales = []
                bboxes = []
                orig_frames = []
                bad_frame_ids = []
                for idx, inp in enumerate(pose_batch):
                    if inp[0]:
                        good_frames.append(inp[1])
                        centers.append(inp[2])
                        scales.append(inp[3])
                        bboxes.append(inp[4])
                    else:
                        bad_frame_ids.append(idx)
                    orig_frames.append(inp[-1])
                if len(good_frames) > 0:
                    frame_batch = np.stack(good_frames, axis=0, dtype=np.float32) # B, H, W, 3
                    frame_batch = frame_batch.transpose(0, 3, 1, 2) # B, 3, H, W
                    inp = grpcclient.InferInput('input', frame_batch.shape, 'FP32')
                    inp.set_data_from_numpy(frame_batch)
                    out = grpcclient.InferRequestedOutput('output')
                    request = {
                        "model_name": "res50",
                        "inputs": [inp],
                        "outputs": [out],
                    }
                else:
                    request = None
                
                yield {
                    "request": request,
                    "prev_output": (centers, scales, bboxes, orig_frames, bad_frame_ids)
                }
        
        # logger.info("pose infer started")
        result_iterator = _stream_infer(
            self._client,
            inputs_iterator=stream_pose_request(),
            model_tag="Pose"
        )
        # logger.info("pose infer stream started")

        async for res, prev_output in result_iterator:
            if res is not None:
                idx, result = res
                heatmaps = result.as_numpy('output')
                # logger.info("pose result %d received shape=%s", idx, heatmaps.shape)

                centers = prev_output[0]
                if heatmaps.shape[0] != len(centers):
                    logger.error("[Pose] result size mismatch: %d results for %d frames", heatmaps.shape, len(centers))
                    continue
            else:
                heatmaps = None

            await output_buffer.put((prev_output, heatmaps))

        
    async def _preprocess_for_cslr(self, pose_output_buffer: BatchBuffer, cslr_input_buffer: BatchBuffer):
        decoder = TopdownHeatmapBaseHeadDecode(
            flip_test=self._pose_cfg.flip_test,
            use_udp=self._pose_cfg.use_udp,
            post_process=self._pose_cfg.post_process,
            shift_heatmap=self._pose_cfg.shift_heatmap
        )
        current_frames = []
        current_keypoints = []
        reserved = self._cslr_cfg.window_size - self._cslr_cfg.stride
        # logger.info("preprocess for cslr started")
        while True:
            (centers, scales, bboxes, orig_frames, bad_frame_ids), heatmaps = await pose_output_buffer.get()
            # logger.info("pose output received")
            # pose postprocessing
            if heatmaps is not None:
                centers = np.asarray(centers, dtype=np.float32)
                scales = np.asarray(scales, dtype=np.float32)
                # start_time = time.monotonic()
                all_keypoints = decoder(heatmaps, centers, scales)
                # end_time = time.monotonic()
                # elapsed_time = end_time - start_time
                # logger.info(
                #     "Pose postprocessing time for %d frames: total=%.4f avg=%.4f",
                #     heatmaps.shape[0], elapsed_time, elapsed_time / heatmaps.shape[0]
                # )
                used_keypoints = all_keypoints[:, self._used_kp_indices, :]
            else:
                if len(bad_frame_ids) != len(orig_frames):
                    logger.error("[Pose postprocessing] got no heatmaps but not all frames were bad")
                    continue

            # cslr preprocessing
            bad_idx = 0
            good_idx = 0
            for frame_idx, frame in enumerate(orig_frames):
                if bad_idx < len(bad_frame_ids) and frame_idx == bad_frame_ids[bad_idx]:
                    bbox = np.array([0, 0, frame.shape[1], frame.shape[0]], dtype=np.float32)
                    keypoints = np.zeros((len(self._used_kp_indices), 3), dtype=np.float32)
                    bad_idx += 1
                else:
                    bbox = bboxes[good_idx]
                    keypoints = used_keypoints[good_idx]
                    good_idx += 1
                cslr_frame = preprocess_for_cslr(
                    frame,
                    bbox,
                    target_ratio=self._cslr_cfg.target_ratio,
                    input_size=self._cslr_cfg.input_size,
                    margin=self._cslr_cfg.bbox_margin,
                    border_width=self._cslr_cfg.crop_border
                )
                current_frames.append(cslr_frame)
                current_keypoints.append(keypoints)
                if len(current_frames) == self._cslr_cfg.window_size:
                    await cslr_input_buffer.put((current_frames, current_keypoints))
                    current_frames = current_frames[-reserved:]
                    current_keypoints = current_keypoints[-reserved:]
            

    async def _stream_cslr_infer(self, input_buffer: BatchBuffer, output_buffer: BatchBuffer):
        async def stream_cslr_request():
            while True:
                cslr_batch = await input_buffer.get_batch(
                    self._cslr_cfg.batch_size,
                    self._cslr_cfg.batching_timeout
                )
                if len(cslr_batch) == 0: continue
                # logger.info("cslr input received")
                win_frames = []
                win_keypoints = []
                for inp in cslr_batch:
                    win_frames.append(inp[0])
                    win_keypoints.append(inp[1])
                batched_win_frames = np.stack(win_frames, axis=0)                      # B, T, H, W, C
                batched_win_frames = np.transpose(batched_win_frames, (0, 4, 1, 2, 3)) # B, C, T, H, W
                inp_clips = grpcclient.InferInput('CLIP', batched_win_frames.shape, 'UINT8')
                inp_clips.set_data_from_numpy(batched_win_frames)

                batched_win_keypoints = np.stack(win_keypoints, axis=0)
                inp_keypoints = grpcclient.InferInput('KEYPOINTS', batched_win_keypoints.shape, 'FP32')
                inp_keypoints.set_data_from_numpy(batched_win_keypoints)

                out_gloss = grpcclient.InferRequestedOutput('GLOSS')

                yield {
                    "request": {
                        "model_name": "online_cslr",
                        "inputs": [inp_clips, inp_keypoints],
                        "outputs": [out_gloss],
                    },

                    "prev_output": len(win_frames)
                }

        # logger.info("cslr infer started")
        result_iterator = _stream_infer(
            self._client,
            inputs_iterator=stream_cslr_request(),
            model_tag="CSLR"
        )
        # logger.info("cslr infer stream started")

        async for res, batch_size in result_iterator:
            if res is None:
                logger.error("[CSLR] None result received")
                continue
            idx, result = res
            gls_logits = result.as_numpy('GLOSS')
            # logger.info("cslr result %d received gls=%s", idx, gls_logits.shape)
            if gls_logits.shape[0] != batch_size:
                logger.warning("[CSLR] result size mismatch: %d results for %d windows", gls_logits.shape, batch_size)
            await output_buffer.put(gls_logits)

    
    async def _postprocess(self, cslr_output_buffer: BatchBuffer, result_buffer: BatchBuffer):
        # logger.info("postprocess started")
        reserved = self._cslr_cfg.voting_bag_size - self._cslr_cfg.voting_bag_stride
        if self._cslr_cfg.voting_strategy == VotingStrategy.MAJORITY:
            prev_res = []
        else:
            prev_res = np.empty((0, self._cslr_cfg.num_classes), dtype=np.float32)

        last_output_id = self._cslr_cfg.blank_id
        last_voting_result = self._cslr_cfg.blank_id
        async def handle_voting_result(gloss_id: int):
            nonlocal last_output_id
            nonlocal last_voting_result
            if gloss_id != self._cslr_cfg.blank_id and (gloss_id != last_output_id or last_voting_result == self._cslr_cfg.blank_id):
                await result_buffer.put(gloss_id)
                last_output_id = gloss_id
            last_voting_result = gloss_id
        
        while True:
            gls_logits = await cslr_output_buffer.get()
            # logger.info("cslr output received")
            N = gls_logits.shape[0] + reserved
            if self._cslr_cfg.voting_strategy == VotingStrategy.MAJORITY:
                gls_indices = prev_res + np.argmax(gls_logits, axis=-1).tolist()
                for start in range(0, N - self._cslr_cfg.voting_bag_size + 1, self._cslr_cfg.stride):
                    if self._cslr_cfg.voting_bag_size == 1: # Naive greedy
                        gloss_id = gls_indices[start]
                    else:
                        gloss_id = majority_vote(
                            gls_indices[start:start+self._cslr_cfg.voting_bag_size],
                            self._cslr_cfg.blank_id
                        )
                    await handle_voting_result(gloss_id)
                if reserved > 0:
                    prev_res = gls_indices[-reserved:]
            else:
                logits = np.concatenate([prev_res, gls_logits], axis=0)
                for start in range(0, N - self._cslr_cfg.voting_bag_size + 1, self._cslr_cfg.voting_bag_stride):
                    gloss_id = max_avg_prob_vote(logits[start:start+self._cslr_cfg.voting_bag_size])
                    await handle_voting_result(gloss_id)
                if reserved > 0:
                    prev_res = logits[-reserved:]


async def _stream_infer(
    client: grpcclient.InferenceServerClient,
    inputs_iterator: AsyncIterator[dict],
    model_tag: str = "" # for logging
):
    batches = deque()
    async def stream_request():
        count = 0
        async for input in inputs_iterator:
            request = input.get("request", None)
            prev_output = input.get("prev_output", None)
            request_id = str(count)
            batches.append((count, prev_output, request is not None))
            if request is not None:
                request["request_id"] = request_id
                # logger.info("sending request %s for %s", request_id, request['model_name'])
                yield request
            else:
                logger.info("[%s] empty request %d", model_tag, count)
            count += 1
    response_iterator = None
    try:
        response_iterator = client.stream_infer(
            inputs_iterator=stream_request()
        )
        # logger.info("[%s] infer stream started", model_tag)
        
        batch_req_id = -1
        async for response in response_iterator:
            result, error = response
            if error is not None:
                logger.warning('[%s] error response: %s', model_tag, error)
            else:
                request_id = int(result.get_response().id)
                # logger.info("[%s] received response for request %d", model_tag, request_id)
                while len(batches) > 0:
                    batch_req_id, prev_output, has_request = batches.popleft()
                    if batch_req_id >= request_id:
                        break
                    if has_request:
                        logger.error("[%s] an inference request got lost")
                    else:
                        # this is a simple previous output forward without an inference request
                        yield (None, prev_output)
                if batch_req_id < request_id:
                    logger.error("[%s] Missing batch %d in local cache", model_tag, request_id)
                    continue
                if batch_req_id > request_id:
                    logger.warning("[%s] The result of a batch %d is missing", model_tag, request_id)
                    continue

                yield ((request_id, result), prev_output)
    except grpcclient.InferenceServerException:
        logger.warning('[%s] Inference Server exception', model_tag, exc_info=True)
    finally:
        if response_iterator is not None:
            # cancel ongoing requests
            response_iterator.cancel()
       
        
            
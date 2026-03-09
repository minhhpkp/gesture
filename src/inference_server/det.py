import os.path as osp
import numpy as np
from typing import List
import torch

try:
    import mmdet
    from mmdet.apis import inference_detector, init_detector
except (ImportError, ModuleNotFoundError):
    raise ImportError('Failed to import `inference_detector` and '
                      '`init_detector` form `mmdet.apis`. These apis are '
                      'required in this script! ')

class DetectionInferencer:
    def __init__(self, det_config, det_ckpt, det_score_thr=0.5, det_area_thr=1600, device: str = 'cuda:0'):
        default_mmdet_root = osp.dirname(mmdet.__path__[0])
        config = f'{default_mmdet_root}/{det_config}'
        self.det_model = init_detector(config, det_ckpt, device)
        assert self.det_model.CLASSES[0] == 'person', 'A detector trained on COCO is required'
        self.det_score_thr = det_score_thr
        self.det_area_thr = det_area_thr
        if device.startswith('cuda'):            
            self.stream = torch.cuda.Stream(device=torch.device(device))
        else:
            self.stream = None

    def infer(self, frames: List[np.ndarray]):
        """
        Detect persons in a batch of frames.

        Arguments:
            frames (List[np.ndarray]): each of shape (H, W, 3), dtype uint8, value in range [0, 255]       
        """
        if self.stream is None:
            det_results = inference_detector(self.det_model, frames)
        else:
            with torch.cuda.stream(self.stream):
                # det_results: list of frame results for each frame, each frame results is a list of person results, each person results is an ndarray of shape (N, 5), N = number of boxes
                det_results = inference_detector(self.det_model, frames)
            self.stream.synchronize()
        filtered_results = self.filter_results(det_results)
        return filtered_results

    def filter_results(self, det_results: List[List[np.ndarray]]):
        """
        Filter out boxes with small scores and small areas.
        
        Note: currently only process the boxes of first detected person in each frame.

        TODO: handle multiple people in frame.                 
        """
        filtered = []
        for res in det_results:    
            # if len(res) == 0: continue # no person detected
            res = res[0] # get only the first detected person among possibly many            
            # filter boxes with small scores
            res = res[res[:, 4] >= self.det_score_thr]
            # filter boxes with small areas
            box_areas = (res[:, 3] - res[:, 1]) * (res[:, 2] - res[:, 0])
            res = res[box_areas >= self.det_area_thr]
            # if res.shape[0] > 0:
            filtered.append(res)
        return filtered

    def warm_up(self, batch_size, height=260, width=210, steps=1):
        frames = [np.random.randint(0, 256, (height, width, 3), dtype=np.uint8) for _ in range(batch_size)]        
        for _ in range(steps):
            self.infer(frames)


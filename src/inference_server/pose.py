import os.path as osp
import numpy as np
from typing import List
import torch

Hrnet_Part2index = {
    'pose': list(range(11)),
    'hand': list(range(91, 133)),
    'mouth': list(range(71,91)),
    'face_others': list(range(23, 71))
}
for k_ in ['mouth','face_others', 'hand']:
    Hrnet_Part2index[k_+'_half'] = Hrnet_Part2index[k_][::2]
    Hrnet_Part2index[k_+'_1_3'] = Hrnet_Part2index[k_][::3]

try:
    import mmpose
    from mmpose.apis import inference_top_down_pose_model, init_pose_model
except (ImportError, ModuleNotFoundError):
    raise ImportError('Failed to import `inference_top_down_pose_model` and '
                      '`init_pose_model` form `mmpose.apis`. These apis are '
                      'required in this script! ')

class PoseInferencer:
    def __init__(self, pose_config, pose_ckpt, device: str = 'cuda:0'):
        default_mmpose_root = osp.dirname(mmpose.__path__[0])
        config = f'{default_mmpose_root}/{pose_config}'
        self.pose_model = init_pose_model(config, pose_ckpt, device=device)
        if device.startswith('cuda'):
            self.stream = torch.cuda.Stream(device=torch.device(device))
        else:
            self.stream = None

    def infer(self, frame: np.ndarray, person_boxes: np.ndarray):
        """
        Generate keypoints for a detection result.

        Arguments:
            frame (ndarray): input frame
            person_boxes (ndarray): shape (N, 5) containing N bounding boxes of the detected person.
        
        Returns:
            best keypoints
        """
        # convert to pose input format
        person_results = [dict(bbox=box) for box in list(person_boxes)]
        if len(person_results) == 0:
            return np.zeros((133, 3), dtype=np.float32) # returns zero np array for empty result
        if self.stream is None:
            pose, _ = inference_top_down_pose_model(self.pose_model, frame, person_results, format='xyxy')
        else:
            with torch.cuda.stream(self.stream):
                pose, _ = inference_top_down_pose_model(self.pose_model, frame, person_results, format='xyxy')
            self.stream.synchronize()
        if len(pose) == 0:
            return np.zeros((133, 3), dtype=np.float32) # returns zero np array for empty result
        # vis_pose_result(self.pose_model, frame, pose, show=True)
        best_pose = max(pose, key=lambda x:x['bbox'][-1])            
        return best_pose['keypoints']
    
    def warm_up(self, height=260, width=210, steps=1):
        for _ in range(steps):
            frame = np.random.randint(0, 256, (height, width, 3), dtype=np.uint8)            
            xmin = np.random.uniform(0, width)
            ymin = np.random.uniform(0, height)
            xmax = np.random.uniform(xmin, width)
            ymax = np.random.uniform(ymin, height)
            confidence = np.random.random()
            det = np.float32(np.array([[xmin, ymin, xmax, ymax, confidence]]))
            self.infer(frame, det)

def get_part_keypoints(all_keypoints: np.ndarray, used_parts: List[str]) -> np.ndarray:
    necessary_kp = []
    for k in sorted(used_parts):
        selected_index = Hrnet_Part2index[k]
        necessary_kp.append(all_keypoints[selected_index]) # N, 3
    necessary_kp = np.concatenate(necessary_kp, axis=0) # N, 3
    return necessary_kp

def get_part_keypoints_count(used_parts: List[str]) -> int:
    count = 0
    for k in used_parts:
        count += len(Hrnet_Part2index[k])
    return count

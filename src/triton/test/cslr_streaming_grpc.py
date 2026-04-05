import argparse
import cv2
import numpy as np
import tritonclient.grpc as grpcclient
from pathlib import Path
import json
from typing import List
from queue import Queue

BLANK_ID = 0

COCOWholebody_Part2Indices = {
    'pose': list(range(11)),
    'hand': list(range(91, 133)),
    'mouth': list(range(71,91)),
    'face_others': list(range(23, 71))
}
for k_ in ['mouth','face_others', 'hand']:
    COCOWholebody_Part2Indices[k_+'_half'] = COCOWholebody_Part2Indices[k_][::2]
    COCOWholebody_Part2Indices[k_+'_1_3'] = COCOWholebody_Part2Indices[k_][::3]

def get_part_keypoints(all_keypoints: np.ndarray, used_parts: List[str]) -> np.ndarray:
    """
    all_keypoints, shape = (K, 3): the key points of a single person detection (not a batch of detections)

    This is how the author extract key points of interest during training, which rearrages the order of key points.
    This is why we can't simply use numpy fancy indexing on the whole all_keypoints.
    """
    necessary_kp = []
    for k in sorted(used_parts):
        selected_index = COCOWholebody_Part2Indices[k]
        necessary_kp.append(all_keypoints[selected_index]) # N, 3
    necessary_kp = np.concatenate(necessary_kp, axis=0) # N, 3
    return necessary_kp

def parse_args():
    parser = argparse.ArgumentParser(
        description='test online CSLR model'
    )
    parser.add_argument('--server-url', help='inference server url', default='localhost:8001')
    parser.add_argument('--frames-path', help='path to video frames, file names need to be in this format: images*.png', required=True)
    parser.add_argument('--pose-file', default='pose.npy')
    parser.add_argument('--cslr-batch-size', type=int, default=16)
    parser.add_argument('--window-size', type=int, default=16)
    parser.add_argument('--stride', type=int, default=1)
    parser.add_argument('--vocab-file', help='path to vocab file', required=True)
    return parser.parse_args()

def main():
    args = parse_args()

    all_imgs = []
    folder = Path(args.frames_path).resolve()
    for file_path in sorted(folder.glob("images*.png")):
        if Path.is_file(file_path):
            img = cv2.imread(file_path)
            img = cv2.cvtColor(img, cv2.COLOR_BGR2RGB)
            all_imgs.append(img)
    
    imgs = np.stack(all_imgs, axis=0)
    imgs = imgs.transpose(0, 3, 1, 2)  # N, H, W, 3 -> N, 3, H, W
    print(f'imgs dtype={imgs.dtype} shape={imgs.shape}')
    
    with open(args.vocab_file, 'rb') as f:
        vocab = json.load(f)

    print(f'vocab size = {len(vocab)}')

    all_keypoints = np.load(args.pose_file)
    print(f'kp type = {all_keypoints.dtype}, kp shape = {all_keypoints.shape}')
    used_parts = ['pose', 'mouth_half', 'hand']
    all_used_kp = []
    for kp in all_keypoints:
        used_kp = get_part_keypoints(kp, used_parts)
        all_used_kp.append(used_kp)
    all_used_kp_np = np.stack(all_used_kp, axis=0)
    print(f'keypoints shape = {all_used_kp_np.shape}')

    current_window_frames = []
    current_window_keypoints = []

    def make_inputs_outputs():
        batched_window_frames = np.stack(current_window_frames, axis=0)
        # print(f'batch frames shape = {batched_window_frames.shape}')
        inp_clips = grpcclient.InferInput('CLIP', batched_window_frames.shape, 'UINT8')
        inp_clips.set_data_from_numpy(batched_window_frames)

        batched_window_keypoints = np.stack(current_window_keypoints, axis=0)
        # print(f'batch keypoints shape = {batched_window_keypoints.shape}, dtype={batched_window_keypoints.dtype}')
        inp_keypoints = grpcclient.InferInput('KEYPOINTS', batched_window_keypoints.shape, 'FP32')
        inp_keypoints.set_data_from_numpy(batched_window_keypoints)

        out_gloss = grpcclient.InferRequestedOutput('GLOSS')
        return ([inp_clips, inp_keypoints], [out_gloss])

    def batch_generator():
        nonlocal current_window_frames
        nonlocal current_window_keypoints
        request_id = 0
        for begin in range(0, imgs.shape[0] - args.window_size + 1, args.stride):
            end = begin + args.window_size
            # print(f'\nwin begin={begin}, end={end}', end='', flush=True)
            window_frames = imgs[begin:end]
            current_window_frames.append(window_frames)
            window_keypoints = all_used_kp_np[begin:end]
            current_window_keypoints.append(window_keypoints)

            if len(current_window_frames) == args.cslr_batch_size:
                inputs, outputs = make_inputs_outputs()
                
                yield {
                    "model_name": 'online_cslr', 
                    "inputs": inputs,
                    "outputs": outputs,
                    "request_id": str(request_id)
                }

                request_id += 1

                current_window_frames.clear()
                current_window_keypoints.clear()

        if len(current_window_frames) > 0:
            inputs, outputs = make_inputs_outputs()

            yield {
                "model_name": 'online_cslr', 
                "inputs": inputs,
                "outputs": outputs,
                "request_id": str(request_id)
            }

    last_accepted_id = BLANK_ID
    last_output_id = BLANK_ID
    all_accepted = Queue()
    def handle_output(gloss_id: int):
        nonlocal last_accepted_id
        nonlocal last_output_id
        if gloss_id != BLANK_ID and (last_output_id != gloss_id or last_accepted_id == BLANK_ID):
            all_accepted.put(vocab[gloss_id])
            last_accepted_id = gloss_id
        last_output_id = gloss_id

    def handle_inference_result(result: grpcclient.InferResult, error: grpcclient.InferenceServerException | None):
        if error is not None:
            print(f"[Callback] Inference error: {error}")
            return
        
        request_id = result.get_response().id
        gls_logits = result.as_numpy('GLOSS')

        # naive greedy decoding
        gls_indices = np.argmax(gls_logits, axis=-1).tolist()

        glosses = [vocab[idx] for idx in gls_indices]
        print(f'request #{request_id}: {' '.join(glosses)}')

        for idx in gls_indices:
            handle_output(idx)

    client = grpcclient.InferenceServerClient(url=args.server_url)
    try:
        client.start_stream(callback=handle_inference_result)

        gen = batch_generator()

        for request_kwargs in gen:
            print(f'sending request #{request_kwargs['request_id']}')
            client.async_stream_infer(**request_kwargs)
    except grpcclient.InferenceServerException as e:
        print('[Client] Server exception:', e)
    except KeyboardInterrupt:
        print("[Client] Interrupted by user.")
    finally:
        client.stop_stream()
        client.close()

        print(f'final = {' '.join(all_accepted.queue)}')
        
if __name__ == '__main__':
    main()


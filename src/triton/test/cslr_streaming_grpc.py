import argparse
import cv2
import numpy as np
import numpy.typing as npt
import tritonclient.grpc.aio as grpcclient
from pathlib import Path
import json
from typing import List
from asyncio import Queue
import asyncio
import time


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


def get_kp_indices(used_parts: list[str]) -> list[int]:
    indices = []
    for part in sorted(used_parts):
        selected_indices = COCOWholebody_Part2Indices[part]
        indices.extend(selected_indices)
    return indices

def parse_args():
    parser = argparse.ArgumentParser(
        description='test online CSLR model'
    )
    parser.add_argument('--server-url', help='inference server url', default='localhost:8001')
    parser.add_argument('--frames-path', help='path to video frames, file names need to be in this format: images*.png', required=True)
    parser.add_argument('--bboxes', default='bboxes.npy')
    parser.add_argument('--filter-results', default='filter_results.json')
    parser.add_argument('--pose-file', default='pose.npy')
    parser.add_argument('--cslr-batch-size', type=int, default=16)
    parser.add_argument('--window-size', type=int, default=16)
    parser.add_argument('--stride', type=int, default=1)
    parser.add_argument('--vocab-file', help='path to vocab file', required=True)
    parser.add_argument('--count', help='number of inference iterations', type=int, default=1)
    return parser.parse_args()

def preprocess_for_cslr(
        frame: npt.NDArray[np.uint8],
        bbox: npt.NDArray[np.float32],
        target_ratio: float,
        input_size: tuple[int, int],
        margin: float = 0.1,
        border_width: int = 10,
    ):
    """
    The following operations are applied:

    1. Crop to the person's bounding box,
    2. Padd to the target aspect ratio,
    3. Resize to the model's input size.

    The padding colour is obtained by sampling the average pixel value from the
    border region of the cropped frame.

    The detector's bounding box is tight around the person.
    We expand it by some margin (e.g. 10-20%) to include some surrounding context.


    Arguments:
        frame:
            shape (H, W, 3).
        bbox:
            shape (4,); left, top, right, bottom coordinates.
        target_ratio:
            target aspect ratio.
        input_size:
            model's input size.
        margin:
            the box's margin to expand into. Default 10%.
        border_width:
            the number of pixels from the edge of the cropped frame to sample. Default: 10.
    Returns:
        preprocessed frame.
    """
    frame_w, frame_h = frame.shape[:2]
    left, top, right, bottom = bbox[:4]
    box_left = max(0, left - margin * (right - left))
    box_right = min(frame_w, right + margin * (right - left))
    box_top = max(0, top - margin * (bottom - top))
    box_bottom = min(frame_h, bottom + margin * (bottom - top))

    crop = frame[int(box_top):int(box_bottom), int(box_left):int(box_right)]

    top = crop[:border_width, :]
    bottom = crop[-border_width:, :]
    left = crop[:, :border_width]
    right = crop[:, -border_width:]

    border_pixels = np.concatenate([
        top.reshape(-1, 3),
        bottom.reshape(-1, 3),
        left.reshape(-1, 3),
        right.reshape(-1, 3)
    ], axis=0)

    avg_color = border_pixels.mean(axis=0)  # shape (3,), float
    avg_color = tuple(avg_color.astype(int).tolist())  # e.g. (118, 121, 115)

    crop_h, crop_w = crop.shape[:2]
    current_ratio = crop_h / crop_w

    if current_ratio < target_ratio:
        # crop is too wide relative to height, pad top and bottom
        target_h = int(crop_w * target_ratio)
        pad_total = target_h - crop_h
        pad_top = pad_total // 2
        pad_bottom = pad_total - pad_top
        crop = cv2.copyMakeBorder(crop, pad_top, pad_bottom, 0, 0, cv2.BORDER_CONSTANT, value=avg_color)
    else:
        # crop is too tall relative to width, pad left and right
        target_w = int(crop_h / target_ratio)
        pad_total = target_w - crop_w
        pad_left = pad_total // 2
        pad_right = pad_total - pad_left
        crop = cv2.copyMakeBorder(crop, 0, 0, pad_left, pad_right, cv2.BORDER_CONSTANT, value=avg_color)
    
    return cv2.resize(crop, input_size)

async def main():
    args = parse_args()

    bboxes = np.load(args.bboxes)
    with open(args.filter_results, 'r') as f:
        filter_results = json.load(f)
    unusable_ids = filter_results['unusable_indices']

    all_imgs = []
    folder = Path(args.frames_path).resolve()
    idx = 0
    box_idx = 0
    for file_path in sorted(folder.glob("images*.png")):
        if Path.is_file(file_path):
            img = cv2.imread(file_path)
            # if idx in unusable_ids:
            #     box = np.array([0, 0, img.shape[1], img.shape[0]], dtype=np.float32)
            # else:
            #     box = bboxes[box_idx]
            #     box_idx += 1
            # img = preprocess_for_cslr(
            #     img,
            #     box,
            #     target_ratio=260/210,
            #     input_size=(224,224)
            # )
            # idx += 1
            img = cv2.resize(img, (224,224))
            all_imgs.append(img)

    imgs = np.stack(all_imgs, axis=0) # # N, H, W, C
    print(f'imgs dtype={imgs.dtype} shape={imgs.shape}')
    
    with open(args.vocab_file, 'rb') as f:
        vocab = json.load(f)

    print(f'vocab size = {len(vocab)}')

    all_keypoints = np.load(args.pose_file)
    print(f'kp type = {all_keypoints.dtype}, kp shape = {all_keypoints.shape}')
    used_parts = ['pose', 'mouth_half', 'hand']
    used_indices = get_kp_indices(used_parts)
    all_used_kp_np = all_keypoints[:, used_indices, :]
    print(f'keypoints shape = {all_used_kp_np.shape}')

    current_window_frames = []
    current_window_keypoints = []

    def make_inputs_outputs():
        batched_window_frames = np.stack(current_window_frames, axis=0) # B, T, H, W, C
        batched_window_frames = np.transpose(batched_window_frames, (0, 4, 1, 2, 3)) # B, C, T, H, W
        # print(f'batch frames shape = {batched_window_frames.shape}')
        inp_clips = grpcclient.InferInput('CLIP', batched_window_frames.shape, 'UINT8')
        inp_clips.set_data_from_numpy(batched_window_frames)

        batched_window_keypoints = np.stack(current_window_keypoints, axis=0)
        # print(f'batch keypoints shape = {batched_window_keypoints.shape}, dtype={batched_window_keypoints.dtype}')
        inp_keypoints = grpcclient.InferInput('KEYPOINTS', batched_window_keypoints.shape, 'FP32')
        inp_keypoints.set_data_from_numpy(batched_window_keypoints)

        out_gloss = grpcclient.InferRequestedOutput('GLOSS')
        return ([inp_clips, inp_keypoints], [out_gloss])

    async def batch_generator():
        nonlocal current_window_frames
        nonlocal current_window_keypoints
        request_id = 0
        # await asyncio.sleep(args.window_size * 0.04)
        for begin in range(0, imgs.shape[0] - args.window_size + 1, args.stride):
            # await asyncio.sleep(args.stride * 0.04)
            end = begin + args.window_size
            # print(f'\nwin begin={begin}, end={end}', end='', flush=True)
            window_frames = imgs[begin:end]
            current_window_frames.append(window_frames)
            window_keypoints = all_used_kp_np[begin:end]
            current_window_keypoints.append(window_keypoints)

            if len(current_window_frames) == args.cslr_batch_size:
                inputs, outputs = make_inputs_outputs()
                
                print(f'sending request #{request_id}')
                start_time = time.monotonic()
                yield {
                    "model_name": 'online_cslr', 
                    "inputs": inputs,
                    "outputs": outputs,
                    "request_id": str(request_id)
                }
                end_time = time.monotonic()
                print(f"network latency for request #{request_id}: {end_time-start_time}")

                request_id += 1

                current_window_frames.clear()
                current_window_keypoints.clear()

        if len(current_window_frames) > 0:
            inputs, outputs = make_inputs_outputs()
            print(f'sending request #{request_id}')
            yield {
                "model_name": 'online_cslr', 
                "inputs": inputs,
                "outputs": outputs,
                "request_id": str(request_id)
            }

    last_accepted_id = BLANK_ID
    last_output_id = BLANK_ID
    all_accepted = Queue()
    async def handle_output(gloss_id: int):
        nonlocal last_accepted_id
        nonlocal last_output_id
        if gloss_id != BLANK_ID and (last_output_id != gloss_id or last_accepted_id == BLANK_ID):
            await all_accepted.put(vocab[gloss_id])
            last_accepted_id = gloss_id
        last_output_id = gloss_id

    async def handle_inference_result(result: grpcclient.InferResult, error: grpcclient.InferenceServerException | None):
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
            await handle_output(idx)

    client = grpcclient.InferenceServerClient(url=args.server_url)
    response_iterator = None
    async def vid():
        await asyncio.sleep(len(all_imgs) * 0.04)
        print("END OF VIDEO")

    v = asyncio.create_task(vid())
    try:
        for _ in range(args.count):
            response_iterator = client.stream_infer(
                inputs_iterator=batch_generator()
            )

            async for result, error in response_iterator:
                await handle_inference_result(result, error)
    except grpcclient.InferenceServerException as e:
        print('[Client] Server exception:', e)
    except KeyboardInterrupt:
        print("[Client] Interrupted by user.")
    finally:
        final = []
        while all_accepted.qsize() > 0:
            item = all_accepted.get_nowait()
            final.append(item)
        print(f'final = {' '.join(final)}')
        if response_iterator is not None:
            response_iterator.cancel()
        await client.close()
        await v

        
if __name__ == '__main__':
    asyncio.run(main())


import argparse
import cv2
import numpy as np
import tritonclient.grpc.aio as grpcclient
from pathlib import Path
import json
import asyncio


def parse_args():
    parser = argparse.ArgumentParser(
        description='test online CSLR model'
    )
    parser.add_argument('--server-url', help='inference server url', default='localhost:8001')
    parser.add_argument('--frames-path', help='path to video frames', required=True)
    parser.add_argument('--bboxes', default='bboxes.npy')
    parser.add_argument('--filter-results', default='filter_results.json')
    parser.add_argument('--batch-size', type=int, default=16)
    parser.add_argument('--output-file', help='output file path', default='pose.npy')
    return parser.parse_args()

async def main():
    args = parse_args()

    bboxes = np.load(args.bboxes)
    with open(args.filter_results, 'r') as f:
        filter_results = json.load(f)
    usable_ids = filter_results['usable_indices']

    all_imgs = []
    folder = Path(args.frames_path).resolve()
    for file_path in sorted(folder.glob("images*.png")):
        # print(file_path)
        if Path.is_file(file_path):
            img = cv2.imread(file_path)
            all_imgs.append(img)
    
    imgs_np = np.stack(all_imgs, axis=0)  
    imgs_np = imgs_np[usable_ids]
    print(f'usable imgs shape = {imgs_np.shape}')

    async def batch_generator():
        for begin in range(0, imgs_np.shape[0], args.batch_size):
            end = min(begin + args.batch_size, imgs_np.shape[0])

            img_batch = imgs_np[begin:end]
            inp_imgs = grpcclient.InferInput('IMAGES', img_batch.shape, 'UINT8')
            inp_imgs.set_data_from_numpy(img_batch)

            bboxes_batch = bboxes[begin:end]
            inp_bboxes = grpcclient.InferInput('BBOXES', bboxes_batch.shape, 'FP32')
            inp_bboxes.set_data_from_numpy(bboxes_batch)

            bbox_counts = np.array([1] * (end - begin), dtype=np.int32)
            inp_bbox_counts = grpcclient.InferInput('BBOX_COUNTS', bbox_counts.shape, 'INT32')
            inp_bbox_counts.set_data_from_numpy(bbox_counts)

            out_pose = grpcclient.InferRequestedOutput('KEYPOINTS')

            yield {
                "model_name": "pose", 
                "inputs": [inp_imgs, inp_bboxes, inp_bbox_counts],
                "outputs": [out_pose],
                "request_id": str(begin)
            }

    client = grpcclient.InferenceServerClient(url=args.server_url)
    response_iterator = None
    try:
        response_iterator = client.stream_infer(
            inputs_iterator=batch_generator()
        )

        all_pose_outputs = []
        async for result, error in response_iterator:
            if error is not None:
                print("Inference error")
                continue

            pose_result = result.as_numpy('KEYPOINTS')
            all_pose_outputs.append(pose_result)

        all_pose_outputs_np = np.concatenate(all_pose_outputs, axis=0)

        pose_out_idx = 0
        all_kp = []
        num_imgs = len(all_imgs)
        for idx in range(num_imgs):
            if idx in usable_ids:
                all_kp.append(all_pose_outputs_np[pose_out_idx])
                pose_out_idx += 1
            else:
                all_kp.append(np.zeros((133, 3), dtype=np.float32))
        all_kp_np = np.stack(all_kp, axis=0)
        np.save(args.output_file, all_kp_np)

        for idx, (img, kp) in enumerate(zip(all_imgs, all_kp_np)):
            if idx in usable_ids:
                point_num = kp.shape[0]
                points = kp[:, :2].reshape(point_num, 2)

                for [x, y] in points.astype(int):
                    cv2.circle(img, (x, y), 1, (0, 255, 0), 2)
            cv2.imwrite(f'output_pose_{idx}.png', img)


        print('POSE DONE')
    except grpcclient.InferenceServerException as e:
        print('[Client] Server exception:', e)
    except KeyboardInterrupt:
        print("[Client] Interrupted by user.")
    finally:
        if response_iterator is not None:
            response_iterator.cancel()
        await client.close()

if __name__ == '__main__':
    asyncio.run(main())

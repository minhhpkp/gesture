import argparse
import cv2
import numpy as np
import tritonclient.grpc.aio as grpcclient
from pathlib import Path
import json
from services.infer.preprocessing import preprocess_for_pose
from services.infer.keypoints_from_heatmaps import TopdownHeatmapBaseHeadDecode
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
    parser.add_argument('--count', help='number of inference iterations', type=int, default=1)
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

    resized_imgs = []
    centers = []
    scales = []
    for idx, img in enumerate(imgs_np):
        resized_img, center, scale = preprocess_for_pose(
            img,
            mean=[123.675, 116.28, 103.53],
            std=[58.395, 57.12, 57.375],
            input_size=[192, 256],
            bbox=bboxes[idx]
        )
        resized_imgs.append(resized_img)
        centers.append(center)
        scales.append(scale)

    centers = np.asarray(centers, dtype=np.float32)
    scales = np.asarray(scales, dtype=np.float32)

    decoder = TopdownHeatmapBaseHeadDecode(
        flip_test=False,
        use_udp=False,
        post_process="default",
        shift_heatmap=True
    )

    async def batch_generator():
        for begin in range(0, imgs_np.shape[0], args.batch_size):
            end = min(begin + args.batch_size, imgs_np.shape[0])

            img_batch = np.stack(resized_imgs[begin:end], axis=0, dtype=np.float32)
            img_batch = img_batch.transpose(0, 3, 1, 2)
            inp_imgs = grpcclient.InferInput('input', img_batch.shape, 'FP32')
            inp_imgs.set_data_from_numpy(img_batch)
            out_pose = grpcclient.InferRequestedOutput('output')

            yield {
                "model_name": "res50",
                "inputs": [inp_imgs],
                "outputs": [out_pose],
                "request_id": f"{begin}:{end}"
            }

    client = grpcclient.InferenceServerClient(url=args.server_url)
    response_iterator = None
    try:
        for _ in range(args.count):
            response_iterator = client.stream_infer(
                inputs_iterator=batch_generator()
            )

            all_pose_outputs = []
            async for result, error in response_iterator:
                if error is not None:
                    print("Inference error")
                    continue

                heatmaps = result.as_numpy('output')
                begin, end = map(int, result.get_response().id.split(":"))

                keypoints = decoder(heatmap=heatmaps, center=centers[begin:end], scale=scales[begin:end])
                all_pose_outputs.append(keypoints)

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


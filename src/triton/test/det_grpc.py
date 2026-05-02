import argparse
import cv2
import numpy as np
import tritonclient.grpc.aio as grpcclient
from pathlib import Path
import json
import asyncio


def filter_best(bboxes: np.ndarray, score_thr=0.5, area_thr=1600):
    """
    Arguments:
        bboxes: shape = (N, 5) one for each detection in the image
    Returns:
        a single highest-score high-quality box shape (5,), or no boxes at all if every box is low quality
    """

    # filter boxes with small scores
    filtered = bboxes[bboxes[:, 4] >= score_thr]
    # filter boxes with small areas
    box_areas = (filtered[:, 3] - filtered[:, 1]) * (filtered[:, 2] - filtered[:, 0])
    filtered = filtered[box_areas >= area_thr]
    if filtered.shape[0] > 0:
        # return highest scored box
        return filtered[np.argmax(filtered[:, 4])]
    return filtered

def parse_args():
    parser = argparse.ArgumentParser(
        description='test human detection model'
    )
    parser.add_argument('--server-url', help='inference server url', default='localhost:8001')
    parser.add_argument('--frames-path', help='path to video frames')
    parser.add_argument('--batch-size', type=int, default=16)
    parser.add_argument('--output-bboxes', help='output file path', default='bboxes.npy')
    parser.add_argument('--output-filter', default='filter_results.json')
    parser.add_argument('--count', help='number of inference iterations', type=int, default=1)
    return parser.parse_args()

async def main():
    args = parse_args()

    all_imgs = []
    folder = Path(args.frames_path).resolve()
    for file_path in sorted(folder.glob("images*.png")):
        # print(file_path)
        if Path.is_file(file_path):
            img = cv2.imread(file_path)
            cv2.resize(img, (320, 320))
            all_imgs.append(img)
    
    imgs_np = np.stack(all_imgs, axis=0)
    all_bboxes = []
    usable_ids = []
    unusable_ids = []

    async def batch_generator():
        for begin in range(0, imgs_np.shape[0], args.batch_size):
            end = min(begin + args.batch_size, imgs_np.shape[0])

            img_batch = imgs_np[begin:end]
            inp_imgs = grpcclient.InferInput('IMAGES', img_batch.shape, 'UINT8')
            inp_imgs.set_data_from_numpy(img_batch)

            out_bboxes = grpcclient.InferRequestedOutput('BBOXES')
            out_bbox_counts = grpcclient.InferRequestedOutput('BBOX_COUNTS')

            yield {
                "model_name": "det", 
                "inputs": [inp_imgs],
                "outputs": [out_bboxes, out_bbox_counts],
                "request_id": str(begin)
            }
    
    client = grpcclient.InferenceServerClient(url=args.server_url)
    response_iterator = None
    try:
        for _ in range(args.count):
            response_iterator = client.stream_infer(
                inputs_iterator=batch_generator()
            )
            async for result, error in response_iterator:
                if error is not None:
                    print("Inference error")
                    continue
                
                begin = int(result.get_response().id)
                bboxes = result.as_numpy('BBOXES')
                bbox_counts = result.as_numpy('BBOX_COUNTS').tolist()

                offset = 0
                for (batch_idx, count) in enumerate(bbox_counts):
                    filtered = filter_best(bboxes[offset:offset+count])
                    img_idx = begin + batch_idx
                    if filtered.shape == (5,):
                        all_bboxes.append(filtered[:4])
                        usable_ids.append(img_idx)
                    else:
                        unusable_ids.append(img_idx)
                    offset += count

            print('DET DONE')

            print(f'unusable={unusable_ids}')

            filter_res = {
                'unusable_indices': unusable_ids,
                'usable_indices': usable_ids,
            }
            with open(args.output_filter, 'w') as f:
                json.dump(filter_res, f)

            bboxes = np.stack(all_bboxes, axis=0)
            np.save(args.output_bboxes, bboxes)

            box_idx = 0
            for idx, img in enumerate(all_imgs):
                if idx in usable_ids:
                    bbox = all_bboxes[box_idx]
                    box_idx += 1
                    [left, top, right, bottom] = bbox.astype(int)
                    cv2.rectangle(img, (left, top), (right, bottom), (0, 255, 0))
                cv2.imwrite(f'output_detection_{idx}.png', img)
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


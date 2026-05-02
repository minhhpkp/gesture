from services.infer.preprocessing import preprocess_for_cslr
import argparse
import cv2
import numpy as np

def parse_args():
    parser = argparse.ArgumentParser(description="test preprocessing")
    parser.add_argument("--frame-path", help='help to a frame image file', required=True)
    parser.add_argument("--bbox", help="left top right bottom coordinates of the box", nargs=4, required=True)
    parser.add_argument("--output-file", default="output_preprocessed.png")
    return parser.parse_args()

def main():
    args = parse_args()
    frame = cv2.imread(args.frame_path)
    bbox = np.array(args.bbox, dtype=np.float32)
    result = preprocess_for_cslr(frame, bbox, target_ratio=260/210)
    cv2.imwrite(args.output_file, result)

if __name__ == "__main__":
    main()
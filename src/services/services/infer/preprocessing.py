import numpy as np
import numpy.typing as npt
import cv2
from typing import Tuple, Optional, List

COCOWholebody_Part2Indices = {
    'pose': list(range(11)),
    'hand': list(range(91, 133)),
    'mouth': list(range(71,91)),
    'face_others': list(range(23, 71))
}
for k_ in ['mouth','face_others', 'hand']:
    COCOWholebody_Part2Indices[k_+'_half'] = COCOWholebody_Part2Indices[k_][::2]
    COCOWholebody_Part2Indices[k_+'_1_3'] = COCOWholebody_Part2Indices[k_][::3]

def get_used_kp_indices(used_parts: list[str]) -> list[int]:
    """
    Get the indices of the keypoints of interest, in the order that
    the author used during model training.
    """
    used_indices = []
    for part in sorted(used_parts):
        selected_indices = COCOWholebody_Part2Indices[part]
        used_indices.extend(selected_indices)
    return used_indices


def preprocess_for_detection(
        frame: npt.NDArray[np.uint8],
        input_size: tuple[int, int]
    ):
    return cv2.resize(frame, input_size)


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
    return cv2.resize(frame, input_size)
    frame_w, frame_h = frame.shape[:2]
    left, top, right, bottom = bbox
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


def preprocess_for_pose(
    img: np.ndarray, 
    mean: List[float],
    std: List[float],
    input_size: Tuple[int, int] = (192, 256),
    bbox: Optional[np.ndarray] = None
) -> Tuple[np.ndarray, np.ndarray, np.ndarray]:
    """Do preprocessing for RTMPose model inference.

    Args:
        img (np.ndarray): Input image in shape.
        input_size (tuple): Input image size in shape (w, h).

    Returns:
        tuple:
        - resized_img (np.ndarray): Preprocessed image.
        - center (np.ndarray): Center of image.
        - scale (np.ndarray): Scale of image.
    """
    # get shape of image
    img_shape = img.shape[:2]
    if bbox is None:
        bbox = np.array([0, 0, img_shape[1], img_shape[0]])

    # get center and scale
    center, scale = bbox_xyxy2cs(bbox, padding=1.25)

    # do affine transformation
    resized_img, scale = top_down_affine(input_size, scale, center, img)

    # normalize image
    mean = np.array(mean)
    std = np.array(std)
    resized_img = (resized_img - mean) / std

    return resized_img, center, scale


def bbox_xyxy2cs(bbox: np.ndarray,
                 padding: float = 1.) -> Tuple[np.ndarray, np.ndarray]:
    """Transform the bbox format from (x,y,w,h) into (center, scale)

    Args:
        bbox (ndarray): Bounding box(es) in shape (4,) or (n, 4), formatted
            as (left, top, right, bottom)
        padding (float): BBox padding factor that will be multilied to scale.
            Default: 1.0

    Returns:
        tuple: A tuple containing center and scale.
        - np.ndarray[float32]: Center (x, y) of the bbox in shape (2,) or
            (n, 2)
        - np.ndarray[float32]: Scale (w, h) of the bbox in shape (2,) or
            (n, 2)
    """
    # convert single bbox from (4, ) to (1, 4)
    dim = bbox.ndim
    if dim == 1:
        bbox = bbox[None, :]

    # get bbox center and scale
    x1, y1, x2, y2 = np.hsplit(bbox, [1, 2, 3])
    center = np.hstack([x1 + x2, y1 + y2]) * 0.5
    scale = np.hstack([x2 - x1, y2 - y1]) * padding

    if dim == 1:
        center = center[0]
        scale = scale[0]

    return center, scale


def _fix_aspect_ratio(bbox_scale: np.ndarray,
                      aspect_ratio: float) -> np.ndarray:
    """Extend the scale to match the given aspect ratio.

    Args:
        scale (np.ndarray): The image scale (w, h) in shape (2, )
        aspect_ratio (float): The ratio of ``w/h``

    Returns:
        np.ndarray: The reshaped image scale in (2, )
    """
    w, h = np.hsplit(bbox_scale, [1])
    bbox_scale = np.where(w > h * aspect_ratio,
                          np.hstack([w, w / aspect_ratio]),
                          np.hstack([h * aspect_ratio, h]))
    return bbox_scale


def _rotate_point(pt: np.ndarray, angle_rad: float) -> np.ndarray:
    """Rotate a point by an angle.

    Args:
        pt (np.ndarray): 2D point coordinates (x, y) in shape (2, )
        angle_rad (float): rotation angle in radian

    Returns:
        np.ndarray: Rotated point in shape (2, )
    """
    sn, cs = np.sin(angle_rad), np.cos(angle_rad)
    rot_mat = np.array([[cs, -sn], [sn, cs]])
    return rot_mat @ pt


def _get_3rd_point(a: np.ndarray, b: np.ndarray) -> np.ndarray:
    """To calculate the affine matrix, three pairs of points are required. This
    function is used to get the 3rd point, given 2D points a & b.

    The 3rd point is defined by rotating vector `a - b` by 90 degrees
    anticlockwise, using b as the rotation center.

    Args:
        a (np.ndarray): The 1st point (x,y) in shape (2, )
        b (np.ndarray): The 2nd point (x,y) in shape (2, )

    Returns:
        np.ndarray: The 3rd point.
    """
    direction = a - b
    c = b + np.r_[-direction[1], direction[0]]
    return c


def get_warp_matrix(center: np.ndarray,
                    scale: np.ndarray,
                    rot: float,
                    output_size: Tuple[int, int],
                    shift: Tuple[float, float] = (0., 0.),
                    inv: bool = False) -> np.ndarray:
    """Calculate the affine transformation matrix that can warp the bbox area
    in the input image to the output size.

    Args:
        center (np.ndarray[2, ]): Center of the bounding box (x, y).
        scale (np.ndarray[2, ]): Scale of the bounding box
            wrt [width, height].
        rot (float): Rotation angle (degree).
        output_size (np.ndarray[2, ] | list(2,)): Size of the
            destination heatmaps.
        shift (0-100%): Shift translation ratio wrt the width/height.
            Default (0., 0.).
        inv (bool): Option to inverse the affine transform direction.
            (inv=False: src->dst or inv=True: dst->src)

    Returns:
        np.ndarray: A 2x3 transformation matrix
    """
    shift = np.array(shift)
    src_w = scale[0]
    dst_w = output_size[0]
    dst_h = output_size[1]

    # compute transformation matrix
    rot_rad = np.deg2rad(rot)
    src_dir = _rotate_point(np.array([0., src_w * -0.5]), rot_rad)
    dst_dir = np.array([0., dst_w * -0.5])

    # get four corners of the src rectangle in the original image
    src = np.zeros((3, 2), dtype=np.float32)
    src[0, :] = center + scale * shift
    src[1, :] = center + src_dir + scale * shift
    src[2, :] = _get_3rd_point(src[0, :], src[1, :])

    # get four corners of the dst rectangle in the input image
    dst = np.zeros((3, 2), dtype=np.float32)
    dst[0, :] = [dst_w * 0.5, dst_h * 0.5]
    dst[1, :] = np.array([dst_w * 0.5, dst_h * 0.5]) + dst_dir
    dst[2, :] = _get_3rd_point(dst[0, :], dst[1, :])

    if inv:
        warp_mat = cv2.getAffineTransform(np.float32(dst), np.float32(src))
    else:
        warp_mat = cv2.getAffineTransform(np.float32(src), np.float32(dst))

    return warp_mat


def top_down_affine(input_size: dict, bbox_scale: dict, bbox_center: dict,
                    img: np.ndarray) -> Tuple[np.ndarray, np.ndarray]:
    """Get the bbox image as the model input by affine transform.

    Args:
        input_size (dict): The input size of the model.
        bbox_scale (dict): The bbox scale of the img.
        bbox_center (dict): The bbox center of the img.
        img (np.ndarray): The original image.

    Returns:
        tuple: A tuple containing center and scale.
        - np.ndarray[float32]: img after affine transform.
        - np.ndarray[float32]: bbox scale after affine transform.
    """
    w, h = input_size
    warp_size = (int(w), int(h))

    # reshape bbox to fixed aspect ratio
    bbox_scale = _fix_aspect_ratio(bbox_scale, aspect_ratio=w / h)

    # get the affine matrix
    center = bbox_center
    scale = bbox_scale
    rot = 0
    warp_mat = get_warp_matrix(center, scale, rot, output_size=(w, h))

    # do affine transform
    img = cv2.warpAffine(img, warp_mat, warp_size, flags=cv2.INTER_LINEAR)

    return img, bbox_scale
import numpy as np

def filter_bboxes(bboxes: np.ndarray, score_thr: float, area_thr: int):
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


def majority_vote(bag: list[int], blank_id: int) -> int:
    """
    Returns:
        the gloss ID taking up more than 50% of the bag, or blank ID if no majority exists.
    """
    uniq, count = np.unique(bag, return_counts=True)
    keep = uniq[count > len(bag) // 2]
    if keep.shape[0] == 1:
        return keep.item()
    return blank_id


def max_avg_prob_vote(logits: np.ndarray) -> int:
    """
    Returns:
        the gloss ID with the highest average probability in the bag.
    """
    # apply softmax
    prob = np.exp(logits - logits.max(axis=-1, keepdims=True))
    prob = (prob / prob.sum(axis=-1, keepdims=True))

    prob = prob.mean(axis=0)
    gloss_id = np.argmax(prob).item()
    return gloss_id

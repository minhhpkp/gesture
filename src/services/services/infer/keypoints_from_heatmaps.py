# Adapted from OpenMMLab's keypoints_from_heatmap.cpp
# Original: Copyright (c) OpenMMLab. All rights reserved.
#
# Batched version: all operations run over (N, K, H, W) inputs.
# Per-keypoint loops are replaced with vectorised numpy operations;
# the only remaining Python loops are over K (or N×K) for cv2.GaussianBlur,
# which requires a 2-D input and cannot be trivially batched in pure numpy.
#
# Heatmap convention : [N, K, H, W]  float32
# Pred convention    : [N, K, 3]     columns = (x, y, score)

from __future__ import annotations

import numpy as np
import cv2


# ---------------------------------------------------------------------------
# Decoder class
# ---------------------------------------------------------------------------

class TopdownHeatmapBaseHeadDecode:
    """Batched Python port of TopdownHeatmapBaseHeadDecode from MMDeploy/MMPose.

    All public methods accept and return tensors with a leading batch dimension N.

    Parameters
    ----------
    flip_test          : Whether the model was run with flip augmentation.
    use_udp            : Use UDP (Unbiased Data Processing) coordinate mapping.
    target_type        : 'GaussianHeatMap' or 'CombinedTarget'.
    valid_radius_factor: Scale factor for the offset radius in CombinedTarget mode.
    unbiased_decoding  : Use unbiased (log-space Taylor) decoding.
    post_process       : One of 'default', 'unbiased', 'megvii', 'null'.
    shift_heatmap      : Stored for API compatibility; not used in decode.
    modulate_kernel    : Kernel size used for Gaussian smoothing steps (must be odd).
    """

    def __init__(
        self,
        flip_test: bool = True,
        use_udp: bool = False,
        target_type: str = "GaussianHeatmap",
        valid_radius_factor: float = 0.0546875,
        unbiased_decoding: bool = False,
        post_process: str = "default",
        shift_heatmap: bool = True,
        modulate_kernel: int = 11,
    ) -> None:
        self.flip_test = flip_test
        self.use_udp = use_udp
        self.target_type = target_type
        self.valid_radius_factor = valid_radius_factor
        self.unbiased_decoding = unbiased_decoding
        self.post_process = post_process
        self.shift_heatmap = shift_heatmap
        self.modulate_kernel = modulate_kernel

    # ------------------------------------------------------------------
    # Public entry point
    # ------------------------------------------------------------------

    def __call__(
        self,
        heatmap: np.ndarray,
        center: np.ndarray,
        scale: np.ndarray,
    ) -> np.ndarray:
        """Decode a batch of raw heatmaps into keypoint coordinates.

        Parameters
        ----------
        heatmap : np.ndarray, shape [N, K, H, W], dtype float32
        center  : np.ndarray, shape [N, 2]  —  (cx, cy) per image
        scale   : np.ndarray, shape [N, 2]  —  (sx, sy) per image

        Returns
        -------
        List of N PoseDetectorOutput objects, each with K Keypoint(x, y, score).
        """
        assert heatmap.ndim == 4 and heatmap.dtype == np.float32, (
            f"Expected float32 [N,K,H,W], got shape={heatmap.shape} dtype={heatmap.dtype}"
        )
        center = np.asarray(center, dtype=np.float32)   # [N, 2]
        scale  = np.asarray(scale,  dtype=np.float32)   # [N, 2]
        assert center.shape == (heatmap.shape[0], 2), \
            f"center must be [N=={heatmap.shape[0]}, 2], got {center.shape}"
        assert scale.shape  == (heatmap.shape[0], 2), \
            f"scale must be [N=={heatmap.shape[0]}, 2], got {scale.shape}"

        pred = self._keypoints_from_heatmap(heatmap, center, scale)  # [N, K, 3]
        return pred

    # ------------------------------------------------------------------
    # Internal helpers
    # ------------------------------------------------------------------

    def _keypoints_from_heatmap(
        self,
        heatmap: np.ndarray,    # [N, K, H, W]
        center: np.ndarray,     # [N, 2]
        scale: np.ndarray,      # [N, 2]
    ) -> np.ndarray:            # [N, K, 3]
        N, K, H, W = heatmap.shape

        if self.post_process == "megvii":
            heatmap = self._gaussian_blur(heatmap, self.modulate_kernel)

        if self.use_udp:
            if self.target_type.lower() == "gaussianheatmap":
                pred = self._get_max_pred(heatmap)
                pred = self._post_dark_udp(pred, heatmap, self.modulate_kernel)

            elif self.target_type.lower() == "combinedtarget":
                assert K % 3 == 0, "K must be divisible by 3 for CombinedTarget"

                # Per-channel blur: heatmap channels and offset channels use
                # different kernel sizes
                for n in range(N):
                    for i in range(K):
                        kt = 2 * self.modulate_kernel + 1 if (i % 3 == 0) \
                             else self.modulate_kernel
                        heatmap[n, i] = cv2.GaussianBlur(heatmap[n, i], (kt, kt), 0)

                valid_radius = self.valid_radius_factor * H

                # Split into (K/3) triplets: [heatmap, offset_x, offset_y]
                heatmap_ = np.ascontiguousarray(heatmap[:, 0::3])   # [N, K/3, H, W]
                offset_x = heatmap[:, 1::3] * valid_radius           # [N, K/3, H, W]
                offset_y = heatmap[:, 2::3] * valid_radius           # [N, K/3, H, W]

                pred = self._get_max_pred(heatmap_)  # [N, K/3, 3]
                num_kp = K // 3

                # Gather offset values at each predicted peak location
                n_idx = np.arange(N)[:, np.newaxis]            # [N, 1]
                k_idx = np.arange(num_kp)[np.newaxis, :]       # [1, K/3]
                px = np.clip(pred[:, :, 0].astype(int), 0, W - 1)  # [N, K/3]
                py = np.clip(pred[:, :, 1].astype(int), 0, H - 1)  # [N, K/3]

                pred[:, :, 0] += offset_x[n_idx, k_idx, py, px]
                pred[:, :, 1] += offset_y[n_idx, k_idx, py, px]

            else:
                raise ValueError(f"Unknown target_type: {self.target_type}")

        else:
            pred = self._get_max_pred(heatmap)  # [N, K, 3]

            if self.post_process == "unbiased":
                heatmap = self._gaussian_blur(heatmap, self.modulate_kernel)
                heatmap = np.log(np.maximum(heatmap, 1e-10))
                pred = self._taylor_batch(heatmap, pred)

            elif self.post_process != "null":
                pred = self._default_shift(heatmap, pred)

        # K may have shrunk (CombinedTarget)
        K_out = pred.shape[1]

        # Map all keypoints of all images back to image space in one call
        pred = self._transform_pred_batch(pred, center, scale, [W, H], self.use_udp)

        if self.post_process == "megvii":
            pred[:, :, 2] = pred[:, :, 2] / 255.0 + 0.5

        return pred

    # ------------------------------------------------------------------
    # Vectorised sub-operations
    # ------------------------------------------------------------------

    def _get_max_pred(self, heatmap: np.ndarray) -> np.ndarray:
        """Find peak (x, y, score) for every (batch, keypoint). Returns [N, K, 3]."""
        N, K, H, W = heatmap.shape
        flat     = heatmap.reshape(N, K, -1)       # [N, K, H*W]
        max_vals = flat.max(axis=2)                # [N, K]
        max_idx  = flat.argmax(axis=2)             # [N, K]

        pred = np.zeros((N, K, 3), dtype=np.float32)
        pred[:, :, 2] = max_vals
        positive = max_vals > 0.0
        pred[:, :, 0] = np.where(positive, max_idx % W,  -1.0).astype(np.float32)
        pred[:, :, 1] = np.where(positive, max_idx // W, -1.0).astype(np.float32)
        return pred

    def _default_shift(
        self, heatmap: np.ndarray, pred: np.ndarray
    ) -> np.ndarray:
        """Sign-based quarter-pixel shift (default and megvii post-process)."""
        N, K, H, W = heatmap.shape

        px = pred[:, :, 0].astype(int)  # [N, K]
        py = pred[:, :, 1].astype(int)  # [N, K]

        in_bounds = (px > 1) & (px < W - 1) & (py > 1) & (py < H - 1)

        # Broadcast indices for advanced gathering: [N,1] op [1,K]
        n_idx = np.arange(N)[:, np.newaxis]
        k_idx = np.arange(K)[np.newaxis, :]

        # Clamp so out-of-bounds indices don't crash (masked out below anyway)
        pxc = np.clip(px, 1, W - 2)
        pyc = np.clip(py, 1, H - 2)

        v1 = (heatmap[n_idx, k_idx, pyc,     pxc + 1] -
              heatmap[n_idx, k_idx, pyc,     pxc - 1])   # [N, K]
        v2 = (heatmap[n_idx, k_idx, pyc + 1, pxc    ] -
              heatmap[n_idx, k_idx, pyc - 1, pxc    ])   # [N, K]

        # np.sign gives -1, 0, +1 → multiply by 0.25
        shift_x = np.sign(v1) * 0.25
        shift_y = np.sign(v2) * 0.25

        pred[:, :, 0] += np.where(in_bounds, shift_x, 0.0)
        pred[:, :, 1] += np.where(in_bounds, shift_y, 0.0)

        if self.post_process == "megvii":
            pred[:, :, 0] += np.where(in_bounds, 0.5, 0.0)
            pred[:, :, 1] += np.where(in_bounds, 0.5, 0.0)

        return pred

    def _transform_pred_batch(
        self,
        pred: np.ndarray,           # [N, K, 3]
        center: np.ndarray,         # [N, 2]
        scale: np.ndarray,          # [N, 2]
        output_size: list[int],     # [W, H]
        use_udp: bool = False,
    ) -> np.ndarray:
        """Map all predictions from heatmap space to original image coordinates."""
        sx = scale[:, 0]            # [N]
        sy = scale[:, 1]            # [N]

        if use_udp:
            scale_x = sx / (output_size[0] - 1.0)
            scale_y = sy / (output_size[1] - 1.0)
        else:
            scale_x = sx / output_size[0]
            scale_y = sy / output_size[1]

        # Broadcast [N] → [N, 1] to multiply against [N, K]
        pred[:, :, 0] = (pred[:, :, 0] * scale_x[:, None]
                         + center[:, 0:1] - sx[:, None] * 0.5)
        pred[:, :, 1] = (pred[:, :, 1] * scale_y[:, None]
                         + center[:, 1:2] - sy[:, None] * 0.5)
        return pred

    def _post_dark_udp(
        self, pred: np.ndarray, heatmap: np.ndarray, kernel: int
    ) -> np.ndarray:
        """Batched DARK sub-pixel refinement for UDP mode.

        Computes a 2×2 Hessian at each peak and solves for the true maximum.
        All N×K Hessians are inverted in a single batched np.linalg.inv call.
        """
        N, K, H, W = heatmap.shape

        for n in range(N):
            for k in range(K):
                heatmap[n, k] = cv2.GaussianBlur(heatmap[n, k], (kernel, kernel), 0)

        heatmap = np.clip(heatmap, 0.001, 50.0)
        heatmap = np.log(heatmap)

        px = pred[:, :, 0].astype(int)   # [N, K]
        py = pred[:, :, 1].astype(int)   # [N, K]

        n_idx = np.arange(N)[:, np.newaxis]
        k_idx = np.arange(K)[np.newaxis, :]

        def lookup(dy: int, dx: int) -> np.ndarray:
            y = np.clip(py + dy, 0, H - 1)
            x = np.clip(px + dx, 0, W - 1)
            return heatmap[n_idx, k_idx, y, x]

        i_      = lookup( 0,  0)
        ix1     = lookup( 0, +1)
        ix1_    = lookup( 0, -1)
        iy1     = lookup(+1,  0)
        iy1_    = lookup(-1,  0)
        ix1y1   = lookup(+1, +1)
        ix1_y1_ = lookup(-1, -1)

        dx  = 0.5 * (ix1  - ix1_)
        dy  = 0.5 * (iy1  - iy1_)
        dxx = ix1  - 2.0 * i_ + ix1_
        dyy = iy1  - 2.0 * i_ + iy1_
        dxy = 0.5  * (ix1y1 - ix1 - iy1 + i_ + i_ - ix1_ - iy1_ + ix1_y1_)

        # Build [N, K, 2, 2] batch of Hessians
        hessians = np.stack([
            np.stack([dxx, dxy], axis=-1),
            np.stack([dxy, dyy], axis=-1),
        ], axis=-2)                                      # [N, K, 2, 2]

        derivatives = np.stack([dx, dy], axis=-1)[..., np.newaxis]  # [N, K, 2, 1]

        dets  = dxx * dyy - dxy * dxy                   # [N, K]
        valid = np.abs(dets) > 1e-6                     # [N, K]

        # Replace singular Hessians with identity to keep inv() stable
        hessians_safe = hessians.copy()
        hessians_safe[~valid] = np.eye(2, dtype=np.float32)

        offsets = -(np.linalg.inv(hessians_safe) @ derivatives)[..., 0]  # [N, K, 2]

        pred[:, :, 0] += np.where(valid, offsets[:, :, 0], 0.0)
        pred[:, :, 1] += np.where(valid, offsets[:, :, 1], 0.0)
        return pred

    def _taylor_batch(
        self, heatmap: np.ndarray, pred: np.ndarray
    ) -> np.ndarray:
        """Batched second-order Taylor sub-pixel refinement (unbiased mode)."""
        N, K, H, W = heatmap.shape

        px = pred[:, :, 0].astype(int)   # [N, K]
        py = pred[:, :, 1].astype(int)   # [N, K]

        in_bounds = (px > 1) & (px < W - 2) & (py > 1) & (py < H - 2)

        n_idx = np.arange(N)[:, np.newaxis]
        k_idx = np.arange(K)[np.newaxis, :]

        # Safe clamped coords so out-of-bounds items don't index-error
        pxs = np.clip(px, 2, W - 3)
        pys = np.clip(py, 2, H - 3)

        def hm(dy: int, dx: int) -> np.ndarray:
            return heatmap[n_idx, k_idx, pys + dy, pxs + dx]

        center = hm( 0,  0)
        dx  = 0.5  * (hm( 0, +1) - hm( 0, -1))
        dy  = 0.5  * (hm(+1,  0) - hm(-1,  0))
        dxx = 0.25 * (hm( 0, +2) - 2.0 * center + hm( 0, -2))
        dyy = 0.25 * (hm(+2,  0) - 2.0 * center + hm(-2,  0))
        dxy = 0.25 * (hm(+1, +1) - hm(-1, +1) - hm(+1, -1) + hm(-1, -1))

        hessians = np.stack([
            np.stack([dxx, dxy], axis=-1),
            np.stack([dxy, dyy], axis=-1),
        ], axis=-2)                                      # [N, K, 2, 2]

        derivatives = np.stack([dx, dy], axis=-1)[..., np.newaxis]  # [N, K, 2, 1]

        dets  = dxx * dyy - dxy * dxy
        valid = in_bounds & (np.abs(dets) > 1e-6)

        hessians_safe = hessians.copy()
        hessians_safe[~valid] = np.eye(2, dtype=np.float32)

        offsets = -(np.linalg.inv(hessians_safe) @ derivatives)[..., 0]  # [N, K, 2]

        pred[:, :, 0] += np.where(valid, offsets[:, :, 0], 0.0)
        pred[:, :, 1] += np.where(valid, offsets[:, :, 1], 0.0)
        return pred

    def _gaussian_blur(self, heatmap: np.ndarray, kernel: int) -> np.ndarray:
        """Per-channel Gaussian blur with zero-padding and magnitude preservation."""
        assert kernel % 2 == 1, "kernel must be odd"
        N, K, H, W = heatmap.shape
        border = (kernel - 1) // 2
        out = np.empty_like(heatmap)

        for n in range(N):
            for k in range(K):
                ch = heatmap[n, k]
                origin_max = ch.max()

                padded = np.zeros((H + 2 * border, W + 2 * border), dtype=np.float32)
                padded[border:border + H, border:border + W] = ch
                padded = cv2.GaussianBlur(padded, (kernel, kernel), 0)
                cropped = padded[border:border + H, border:border + W]

                cur_max = cropped.max()
                out[n, k] = cropped * (origin_max / cur_max) if cur_max > 0 else cropped

        return out
# video_file_publisher.py
import argparse
import asyncio
import logging
import os
from dotenv import load_dotenv
from signal import SIGINT, SIGTERM
from time import perf_counter

import cv2
from livekit import api, rtc

# ensure LIVEKIT_URL, LIVEKIT_API_KEY, and LIVEKIT_API_SECRET are set
load_dotenv()


def build_token(*, room_name: str, identity: str, name: str) -> str:
    return (
        api.AccessToken()
        .with_identity(identity)
        .with_name(name)
        .with_grants(api.VideoGrants(room_join=True, room=room_name))
        .to_jwt()
    )


def probe_video(path: str) -> tuple[int, int, float]:
    cap = cv2.VideoCapture(path)
    if not cap.isOpened():
        raise RuntimeError(f"Could not open video file: {path}")

    width = int(cap.get(cv2.CAP_PROP_FRAME_WIDTH)) or 0
    height = int(cap.get(cv2.CAP_PROP_FRAME_HEIGHT)) or 0
    fps = float(cap.get(cv2.CAP_PROP_FPS)) or 0.0

    # Some containers report 0; fallback later if needed.
    cap.release()
    if width <= 0 or height <= 0:
        raise RuntimeError("Could not determine video width/height from the file.")
    return width, height, fps


async def stream_video_file(
    *,
    source: rtc.VideoSource,
    path: str,
    out_width: int,
    out_height: int,
    fps: float,
    loop_video: bool,
):
    cap = cv2.VideoCapture(path)
    if not cap.isOpened():
        raise RuntimeError(f"Could not open video file: {path}")

    if fps <= 0:
        fps = float(cap.get(cv2.CAP_PROP_FPS)) or 30.0
    if fps <= 0:
        fps = 30.0

    logging.info(f'Publishing video with width={out_width} height={out_height} FPS={fps}')

    frame_interval = 1.0 / fps
    next_frame_time = perf_counter()
    frame_index = 0

    while True:
        ok, bgr = cap.read()
        if not ok:
            if loop_video:
                cap.set(cv2.CAP_PROP_POS_FRAMES, 0)
                frame_index = 0
                continue
            break

        # Resize to match the VideoSource resolution (must be consistent)
        if bgr.shape[1] != out_width or bgr.shape[0] != out_height:
            bgr = cv2.resize(bgr, (out_width, out_height), interpolation=cv2.INTER_AREA)

        rgba = cv2.cvtColor(bgr, cv2.COLOR_BGR2RGB)
        buf = rgba.tobytes()  # width * height * 4 bytes

        frame = rtc.VideoFrame(out_width, out_height, rtc.VideoBufferType.RGB24, buf)

        # VideoSource.capture_frame supports an optional timestamp_us
        timestamp_us = int(frame_index * 1_000_000 / fps)
        source.capture_frame(frame, timestamp_us=timestamp_us)

        frame_index += 1
        next_frame_time += frame_interval
        await asyncio.sleep(max(0.0, next_frame_time - perf_counter()))

    cap.release()


async def main(loop: asyncio.AbstractEventLoop, args: argparse.Namespace):
    url = args.url or os.getenv("LIVEKIT_URL")
    if not url:
        raise RuntimeError("Missing LIVEKIT_URL (or pass --url).")

    token = build_token(room_name=args.room, identity=args.identity, name=args.name)

    room = rtc.Room(loop=loop)

    logging.info("Connecting to %s ...", url)
    await room.connect(url, token)
    logging.info("Connected to room: %s", room.name)

    width, height, file_fps = probe_video(args.file)
    fps = args.fps if args.fps > 0 else (file_fps if file_fps > 0 else 30.0)

    # Create a source + local track, then publish it
    source = rtc.VideoSource(width, height)
    track = rtc.LocalVideoTrack.create_video_track("file-video", source)

    options = rtc.TrackPublishOptions(
        source=rtc.TrackSource.SOURCE_CAMERA,
        simulcast=args.simulcast,
        # When setting encoding, set both max_framerate and max_bitrate
        video_encoding=rtc.VideoEncoding(
            max_framerate=int(fps),
            max_bitrate=args.bitrate,
        ),
        video_codec=rtc.VideoCodec.H264,
    )

    publication = await room.local_participant.publish_track(track, options)
    logging.info("Published track sid=%s name=%s", publication.sid, track.name)

    # Keep pushing frames continuously (important even for “static” content)
    asyncio.create_task(
        stream_video_file(
            source=source,
            path=args.file,
            out_width=width,
            out_height=height,
            fps=fps,
            loop_video=args.loop,
        )
    )

    # Block forever; Ctrl+C triggers cleanup in the signal handler.
    await asyncio.Event().wait()


def parse_args() -> argparse.Namespace:
    p = argparse.ArgumentParser()
    p.add_argument("--file", required=True, help="Path to a local video file (mp4, mov, ...)")
    p.add_argument("--room", default="my-room")
    p.add_argument("--identity", default="python-video-bot")
    p.add_argument("--name", default="Python Video Bot")
    p.add_argument("--url", default=None, help="Overrides LIVEKIT_URL")
    p.add_argument("--fps", type=float, default=0.0, help="Override FPS (0 = use file FPS)")
    p.add_argument("--bitrate", type=int, default=3_000_000)
    p.add_argument("--simulcast", action="store_true")
    p.add_argument("--loop", action="store_true", help="Loop the video when it ends")
    return p.parse_args()


if __name__ == "__main__":
    logging.basicConfig(level=logging.INFO)

    args = parse_args()
    loop = asyncio.new_event_loop()
    asyncio.set_event_loop(loop)

    task = loop.create_task(main(loop, args))

    async def cleanup():
        task.cancel()
        loop.stop()

    # Note: signal handlers are not supported the same way on Windows.
    for sig in (SIGINT, SIGTERM):
        try:
            loop.add_signal_handler(sig, lambda: asyncio.create_task(cleanup()))
        except NotImplementedError:
            pass

    try:
        loop.run_forever()
    finally:
        loop.close()

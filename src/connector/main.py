import asyncio
import logging
import os
from dotenv import load_dotenv
from signal import SIGINT, SIGTERM
import json

from livekit import api, rtc

import websockets
from websockets.exceptions import ConnectionClosed


# ensure LIVEKIT_URL, LIVEKIT_API_KEY, and LIVEKIT_API_SECRET are set
load_dotenv()

tasks = set()


def map_phoenix_gls(g_lower):#lower->upper
    if 'neg-' in g_lower[:4]:
        g_upper = 'neg-'+g_lower[4:].upper()
    elif 'poss-' in g_lower:
        g_upper = 'poss-'+g_lower[5:].upper()
    elif 'negalp-' in g_lower:
        g_upper = 'negalp-'+g_lower[7:].upper()
    elif 'loc-' in g_lower:
        g_upper = 'loc-'+g_lower[7:].upper()
    elif 'cl-' in g_lower:
        g_upper = 'cl-'+g_lower[7:].upper()
    else:
        g_upper = g_lower.upper()
    return g_upper


async def main(room: rtc.Room) -> None:
    current = None

    @room.on("track_subscribed")
    def on_track_subscribed(track: rtc.Track, *_):
        if track.kind == rtc.TrackKind.KIND_VIDEO:
            nonlocal current
            if current is not None:
                # only process the first stream received
                return

            current = track
            print("subscribed to track: " + track.name)            
            task = asyncio.create_task(frame_loop(track, room))
            tasks.add(task)
            task.add_done_callback(tasks.remove)    

    token = (
        api.AccessToken()
        .with_identity("moderator")
        .with_name("Python Infer Bot")
        .with_grants(
            api.VideoGrants(
                room_join=True,
                room="my-room",
            )
        )
    )    
    await room.connect(os.getenv("LIVEKIT_URL"), token.to_jwt())
    print("connected to room: " + room.name)


async def send_frames(video_stream: rtc.VideoStream, conn: websockets.ClientConnection):
    try:
        async for frame_event in video_stream:
            frame = frame_event.frame
            meta = {
                'width': frame.width,
                'height': frame.height,                
            }            
            await conn.send(json.dumps(meta))
            await conn.send(frame.data)
    except asyncio.CancelledError:
        pass  # clean exit

async def receive_results(conn: websockets.ClientConnection, room: rtc.Room, track_sid: str):    
    with open('phoenix_iso_with_blank.vocab', 'rb') as f:
        vocab = json.load(f)    
    try:
        while True:
            msg = await conn.recv()
            id = json.loads(msg)['gloss_id']
            gloss = map_phoenix_gls(vocab[id])
            print(gloss, end=' ', flush=True)
            task = asyncio.create_task(room.local_participant.publish_data(payload=gloss, reliable=True, topic='caption'))
            tasks.add(task)
            task.add_done_callback(tasks.remove)
    except ConnectionClosed:
        print("Connection closed by server")

async def frame_loop(track: rtc.Track, room: rtc.Room) -> None:
    video_stream = rtc.VideoStream(track, format=rtc.VideoBufferType.RGB24)    
    uri = os.getenv('INFERENCE_URL')
    async with websockets.connect(uri) as conn:
        send_task = asyncio.create_task(send_frames(video_stream, conn))
        recv_task = asyncio.create_task(receive_results(conn, room, track.sid))

        try:
            await asyncio.gather(send_task, recv_task)
        except ConnectionClosed:
            pass
        finally:
            send_task.cancel()
            recv_task.cancel()
     
    
if __name__ == "__main__":
    logging.basicConfig(level=logging.INFO)

    loop = asyncio.get_event_loop()
    room = rtc.Room(loop=loop)

    async def cleanup():
        for task in tasks:
            task.cancel()
        await asyncio.gather(*tasks, return_exceptions=True)
        await room.disconnect()
        loop.stop()

    asyncio.ensure_future(main(room))
    for signal in [SIGINT, SIGTERM]:
        loop.add_signal_handler(signal, lambda: asyncio.ensure_future(cleanup()))

    try:
        loop.run_forever()
    finally:
        loop.close()
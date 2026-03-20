import asyncio
import logging
import os
from dotenv import load_dotenv
from signal import SIGINT, SIGTERM
import json
from typing import Set
from livekit import api, rtc
from session import SignRecognitionSession
import argparse

# ensure LIVEKIT_URL, LIVEKIT_API_KEY, and LIVEKIT_API_SECRET are set
load_dotenv()

tasks: Set[asyncio.Task] = set()
current_session: SignRecognitionSession | None = None

def add_task(coro):
    task = asyncio.create_task(coro)
    tasks.add(task)
    task.add_done_callback(tasks.remove)
    return task

async def main(room: rtc.Room, room_name: str) -> None:
    with open('phoenix_iso_with_blank.vocab', 'rb') as f:
        vocab = json.load(f)
    inference_url = os.getenv('INFERENCE_URL')
    
    stream_task: asyncio.Task | None = None
    stop_task: asyncio.Task | None = None

    async def stream_inference_results(track: rtc.RemoteVideoTrack):
        writer = await room.local_participant.stream_text(topic='glosses')

        try:
            async for gloss in current_session.start(track):
                print(gloss, end=' ', flush=True)
                await writer.write(gloss)
            logging.info("result stream finished")
        finally:
            await writer.aclose()
            logging.info("result stream closed")

    @room.on("track_subscribed")
    def on_track_subscribed(
        track: rtc.Track,
        publication: rtc.RemoteTrackPublication,
        participant: rtc.RemoteParticipant,
    ):
        logging.info("track subscribed: %s", publication.sid)
        if current_session is not None and publication.sid == current_session.publication.sid:
            if track.kind == rtc.TrackKind.KIND_VIDEO:
                nonlocal stream_task
                stream_task = add_task(stream_inference_results(track))

    @room.on("track_unsubscribed")
    def on_track_unsubscribed(
        track: rtc.Track,
        publication: rtc.RemoteTrackPublication,
        participant: rtc.RemoteParticipant,
    ):
        logging.info("track unsubscribed: %s", publication.sid)
        if current_session is not None and current_session.publication.sid == publication.sid:
            nonlocal stop_task
            stop_task = add_task(current_session.stop_video_subscriber())

    async def stop_sign_recognition_session():
        global current_session
        if current_session is not None:
            await current_session.stop()
            try:
                # stream_task should be done by now, cancel here just for good measures
                async with asyncio.timeout(5):
                    await stream_task
            except asyncio.exceptions.CancelledError:
                logging.info("Result stream cancelled")        
            logging.info(f"Current sign recognition session of {current_session.signer_identity} stopped")
            current_session = None

    @room.on("participant_disconnected")
    def on_participant_disconnected(participant: rtc.RemoteParticipant):
        logging.info("participant disconnected: %s %s", participant.sid, participant.identity)
        if current_session is not None and participant.identity == current_session.signer_identity:
            nonlocal stop_task
            stop_task = add_task(stop_sign_recognition_session())

    token = (
        api.AccessToken()
        .with_identity("connector")
        .with_grants(
            api.VideoGrants(
                room_join=True,
                room=room_name,
            )
        )
    )    
    await room.connect(
        os.getenv("LIVEKIT_URL"), 
        token.to_jwt(),
        rtc.RoomOptions(auto_subscribe=False)
    )
    logging.info("Connected to room: " + room.name)
    
    @room.local_participant.register_rpc_method("start_sign_recognition")
    async def start_sign_recognition(data: rtc.RpcInvocationData):
        logging.info(f'start sign recognition requested by {data.caller_identity}')
        global current_session
        # wait for the previous session to finish cleaning up
        if stop_task is not None and not stop_task.done():
            await stop_task
        if current_session is not None:
            raise rtc.RpcError(code=2001, message="A session is already in progress")
        req = json.loads(data.payload)
        publication = None
        pub_sid = req["pub_sid"]
        caller = room.remote_participants[data.caller_identity]
        if pub_sid is not None:
            publication = caller.track_publications[pub_sid]
        else:
            for pub in caller.track_publications.values():
                if pub.kind == rtc.TrackKind.KIND_VIDEO:
                    publication = pub
                    break
        if publication is None:
            raise rtc.RpcError(code=2002, message="Caller has not published any video tracks")
        current_session = SignRecognitionSession(data.caller_identity, publication, inference_url, vocab)
        logging.info(f"New sign recognition session started by {data.caller_identity}")
        return "OK"
    
    @room.local_participant.register_rpc_method("stop_sign_recognition")
    def stop_sign_recognition(data: rtc.RpcInvocationData):
        logging.info(f'stop sign recognition requested by {data.caller_identity}')
        if current_session is None:
            raise rtc.RpcError(code=3001, message="No active session")
        if current_session.signer_identity != data.caller_identity:
            raise rtc.RpcError(code=3002, message="Caller is not the current participant using the sign recognition service")
        nonlocal stop_task 
        stop_task = add_task(stop_sign_recognition_session())
        return "OK"


def parse_args() -> argparse.Namespace:
    p = argparse.ArgumentParser()
    p.add_argument("--room", default="my-room")
    return p.parse_args()

if __name__ == "__main__":   
    logging.basicConfig(level=logging.INFO)

    args = parse_args()

    loop = asyncio.new_event_loop()
    asyncio.set_event_loop(loop)
    room = rtc.Room(loop=loop)
    tasks.add(loop.create_task(main(room, room_name=args.room)))

    async def cleanup():
        logging.info('Cleanup started') 
        if current_session is not None:
            await current_session.stop()
            logging.info('Session stopped')
        for task in tasks:
            task.cancel()                
        await asyncio.gather(*tasks, return_exceptions=True)
        await room.disconnect()
        logging.info('Cleanup done')
        loop.stop()

    for signal in (SIGINT, SIGTERM):
        loop.add_signal_handler(signal, lambda: asyncio.create_task(cleanup()))

    try:
        loop.run_forever()
    finally:
        loop.close()
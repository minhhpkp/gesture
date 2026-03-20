from livekit import rtc
import websockets
import json
import asyncio
from typing import List
import logging

logger = logging.getLogger(__name__)

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

class SignRecognitionSession:
    def __init__(self, signer_identity: str, publication: rtc.RemoteTrackPublication, uri: str, vocab: List[str]):
        self.signer_identity = signer_identity
        publication.set_subscribed(True)
        self.publication = publication
        self.uri = uri
        self.vocab = vocab
        self.video_stream: rtc.VideoStream | None = None
        self._stopping = False
    
    def is_running(self) -> bool:
        return self.video_stream is not None
    
    async def start(self, track: rtc.RemoteVideoTrack):
        """
        Start sending the signer's video stream to inference server and receiving inference results.

        Cancelling this only stops the session from receiving new recognition results,
        the session continues sending the video stream.
        To stop both sending and receiving tasks, call :method:`stop`.
        """
        async with websockets.connect(self.uri) as self._conn:
            self.video_stream = rtc.VideoStream(track, format=rtc.VideoBufferType.RGB24)
            self._send_task = asyncio.create_task(self._send_frames())
            async for gloss in self._receive_results():
                yield gloss

    async def stop(self):
        """
        Stop sending frames to and receiving results from the inference server.
        """
        if not self.is_running() or self._stopping: return
        self._stopping = True
        try:
            await asyncio.gather(
                self.stop_video_subscriber(),
                self._conn.close()
            )
            self.publication.set_subscribed(False)
            logger.info('stop: done')
        finally:
            self._stopping = False
    
    async def stop_video_subscriber(self):
        if not self._stopping and self.video_stream is not None:
            logger.info('stopping sender')
            await self.video_stream.aclose()
            logger.info('video stream closed')
            self.video_stream = None
            # for some reason, even after the video stream is closed, its async iterator keeps on running
            # therefore it's necessary to cancel the async iteration too
            self._send_task.cancel()
            await self._send_task
            logger.info('sender stopped')

    async def _send_frames(self):
        try:
            async for frame_event in self.video_stream:
                frame = frame_event.frame
                meta = {
                    'width': frame.width,
                    'height': frame.height,                
                }
                # logger.info('frame %dx%d received', frame.width, frame.height)
                await self._conn.send(json.dumps(meta))
                await self._conn.send(frame.data)
                # logger.info('frame %dx%d sent', frame.width, frame.height)
        except websockets.exceptions.ConnectionClosed:
            logger.info('send: connection closed')
        except asyncio.CancelledError:
            logger.info('send: cancelled')
            # don't reraise because video_stream doesn't seem to respond to cancellation
        logger.info('send: finished')

    async def _receive_results(self):
        try:
            while True:
                msg = await self._conn.recv()
                id = json.loads(msg)['gloss_id']
                gloss = map_phoenix_gls(self.vocab[id])
                yield gloss
        except websockets.exceptions.ConnectionClosed:
            logger.info('recv: connection closed')


from .orchestrator import InferenceOrchestrator
from enum import Enum, auto
import asyncio
from livekit import rtc
from services.utils.logging import get_logger

logger = get_logger(__name__)

class SessionState(Enum):
    RUNNING = auto()
    PAUSED = auto()
    STOPPED = auto()

class InferenceSession:
    def __init__(self, orchestrator: InferenceOrchestrator):
        self._orchestrator = orchestrator

        self.state = SessionState.RUNNING
        self.cond = asyncio.Condition()

        self._video_stream = None
        self._result_iterator = None

    async def stream_infer(self, video_stream: rtc.VideoStream):
        self._video_stream = video_stream
        self._result_iterator = self._orchestrator.stream_infer(self._stream_frame())
        async for result in self._result_iterator:
            yield result

    async def _stream_frame(self):
        idx = -1
        async for event in self._video_stream:
            idx += 1
            logger.info("event %d received", idx)
            async with self.cond:
                await self.cond.wait_for(lambda: self.state != SessionState.PAUSED)
                if self.state == SessionState.STOPPED:
                    break
                # state must now be "RUNNING"
                logger.info("sending event %d", idx)
                yield event
    
    async def pause(self):
        async with self.cond:
            if self.state == SessionState.RUNNING:
                self.state = SessionState.PAUSED
                self.cond.notify_all()
    
    async def resume(self):
        async with self.cond:
            if self.state == SessionState.PAUSED:
                self.state = SessionState.RUNNING
                self.cond.notify_all()

    async def stop(self, timeout: float | None = None):
        async with self.cond:
            # do nothing if already stopped
            if self.state != SessionState.STOPPED:
                self.state = SessionState.STOPPED
                self.cond.notify_all()
                if self._video_stream is not None:
                    try:
                        await asyncio.wait_for(
                            self._video_stream.aclose(),
                            timeout=timeout
                        )
                    except asyncio.TimeoutError:
                        logger.info("Timed out waiting for video stream to close")
                if self._result_iterator is not None:
                    await self._result_iterator.stop()
                logger.info("orchestrator infer stream stopped")

    
    
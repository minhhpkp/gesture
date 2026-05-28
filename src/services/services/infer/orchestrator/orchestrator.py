from abc import ABC, abstractmethod
from collections.abc import AsyncIterator
from livekit import rtc


class ResultIterator(ABC):
    def __aiter__(self):
        return self
    
    @abstractmethod
    async def __anext__(self) -> int:
        ...

    @abstractmethod
    async def stop(self):
        ...


class InferenceOrchestrator(ABC):
    @abstractmethod
    def stream_infer(self, video_stream: AsyncIterator[rtc.VideoFrameEvent]) -> ResultIterator:
        ...

    @abstractmethod
    async def close(self):
        ...
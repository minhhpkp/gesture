from services.infer.orchestrator import InferenceOrchestrator, ResultIterator
from services.settings import InferSettings
from services.di import get_infer_settings
from collections.abc import AsyncIterator
from livekit import rtc
import random
from fastapi import Depends
import asyncio


class FakeInferenceOrchestrator(InferenceOrchestrator):
    def __init__(self, num_classes):
        self.num_classes = num_classes

    def stream_infer(self, video_stream: AsyncIterator[rtc.VideoFrameEvent]):
        class _ResultIterator(ResultIterator):
            def __init__(self, num_classes):
                self.num_classes = num_classes

            def __aiter__(self):
                return self
            
            async def __anext__(self) -> int:
                await asyncio.sleep(1)
                return random.randint(0, self.num_classes)
            
            async def stop(self):
                pass
        return _ResultIterator(self.num_classes)

    async def close(self):
        pass


def get_fake_infer_orchestrator(
    infer_settings: InferSettings = Depends(get_infer_settings)
) -> InferenceOrchestrator:
    return FakeInferenceOrchestrator(num_classes=infer_settings.cslr.num_classes)
    
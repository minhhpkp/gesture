from .settings import LiveKitSettings, InferSettings, BotSettings
from functools import lru_cache
from livekit import api as lkapi
from fastapi import Depends, Request
from .infer.orchestrator import InferenceOrchestrator
from .infer import SignRecognitionBot
from tritonclient.grpc.aio import InferenceServerClient


@lru_cache
def get_livekit_settings() -> LiveKitSettings:
    return LiveKitSettings()


@lru_cache
def get_infer_settings() -> InferSettings:
    return InferSettings()


@lru_cache
def get_bot_settings() -> BotSettings:
    return BotSettings()


def get_lk_webhook_receiver(
    lk_settings: LiveKitSettings = Depends(get_livekit_settings)
) -> lkapi.WebhookReceiver:
    return lkapi.WebhookReceiver(
        lkapi.TokenVerifier(
            lk_settings.api_key,
            lk_settings.api_secret
        )
    )


def get_vocab(request: Request) -> list[str]:
    return request.app.state.vocab


def get_bots(request: Request) -> dict[str, SignRecognitionBot]:
    return request.app.state.bots


def get_infer_orchestrator(request: Request) -> InferenceOrchestrator:
    return request.app.state.infer_orchestrator


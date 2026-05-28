from fastapi import FastAPI, Request, Depends
from pydantic import BaseModel
from livekit import api as lkapi
from livekit import rtc as lkrtc
from contextlib import asynccontextmanager
from .utils.logging import setup_logging, get_logger
from .infer.orchestrator import TritonInferenceOrchestrator, InferenceOrchestrator
from .infer import SignRecognitionBot
from tritonclient.grpc.aio import InferenceServerClient
import asyncio
from .settings import BotSettings, LiveKitSettings
import services.di as di
import json
from fastapi.middleware.cors import CORSMiddleware


@asynccontextmanager
async def lifespan(app: FastAPI):
    setup_logging(log_level="INFO")
    bots: dict[str, SignRecognitionBot] = {}
    app.state.bots = bots

    bot_settings = di.get_bot_settings()
    with open(bot_settings.vocab_file, "rb") as f:
        vocab = json.load(f)
    app.state.vocab = vocab
    
    infer_settings = di.get_infer_settings()
    app.state.infer_orchestrator = TritonInferenceOrchestrator(
        client=InferenceServerClient(infer_settings.server_url),
        infer_settings=infer_settings
    )

    yield
    await asyncio.gather(*[
        bot.stop(timeout=bot_settings.stop_timeout) 
        for bot in app.state.bots.values()
    ])
    await app.state.infer_orchestrator.close()

app = FastAPI(lifespan=lifespan)
logger = get_logger(__name__)

origins = [
    "http://localhost:8080"
]

app.add_middleware(
    CORSMiddleware,
    allow_origins=origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

class CreateJoinTokenRequest(BaseModel):
    username: str
    roomId: str

@app.post("/join-tokens")
def create_join_token(
    req: CreateJoinTokenRequest,
    livekit_settings: LiveKitSettings = Depends(di.get_livekit_settings)
):
    token = (
        lkapi.AccessToken(
            api_key=livekit_settings.api_key,
            api_secret=livekit_settings.api_secret
        )
        .with_identity(req.username.strip())
        .with_grants(
            lkapi.VideoGrants(
                room_join=True,
                room=req.roomId.strip(),
            )
        )
    )
    return {
        "token": token.to_jwt(), 
        "ttl": token.ttl.total_seconds()
    }


@app.post("/webhooks/livekit")
async def handle_livekit_event(
    request: Request,
    webhook_receiver: lkapi.WebhookReceiver = Depends(di.get_lk_webhook_receiver),
    bots: dict[str, SignRecognitionBot] = Depends(di.get_bots),
    bot_settings: BotSettings = Depends(di.get_bot_settings),
    vocab: list[str] = Depends(di.get_vocab),
    livekit_settings: LiveKitSettings = Depends(di.get_livekit_settings),
    infer_orchestrator: InferenceOrchestrator = Depends(di.get_infer_orchestrator)
):
    body = await request.body()
    body = body.decode("utf-8")
    auth = request.headers.get("Authorization")
    event = webhook_receiver.receive(body, auth)
    logger.info("livekit event received: %s room sid=%s", event.event, event.room.sid)
    if (event.event == "room_started" or event.event == "participant_joined") and event.room.sid not in bots:
        bot = SignRecognitionBot(
            vocab=vocab,
            livekit_settings=livekit_settings,
            infer_orchestrator=infer_orchestrator  
        )
        bots[event.room.sid] = bot
        await bot.start(
            room_name=event.room.name,
            room=lkrtc.Room(loop=asyncio.get_event_loop()),
        )
    elif event.event == "room_finished":
        bot = bots.pop(event.room.sid, None)
        if bot is not None:
            await bot.stop(timeout=bot_settings.stop_timeout)


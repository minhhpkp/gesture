import asyncio
from livekit import api as lkapi
from livekit import rtc as lkrtc
from .session import InferenceSession
from .orchestrator import InferenceOrchestrator
from services.settings import LiveKitSettings
from services.utils.logging import get_logger
import json
from dataclasses import dataclass


logger = get_logger(__name__)


@dataclass
class Signer:
    signer_identity: str
    publication_sid: str


class SignRecognitionBot:
    def __init__(
        self,
        vocab: list[str],
        livekit_settings: LiveKitSettings,
        infer_orchestrator: InferenceOrchestrator
    ):
        self.vocab = vocab
        self._livekit_settings = livekit_settings
        self._infer_orchestrator = infer_orchestrator

        self._room: lkrtc.Room | None = None
        self._signer: Signer | None = None
        self._infer_sess: InferenceSession | None = None
        self._stream_results_task: asyncio.Task | None = None
        self._stop_session_task: asyncio.Task | None = None
        logger.info("bot created")
    
    
    async def start(self, room_name: str, room: lkrtc.Room):
        self._room = room

        async def stream_inference_results(track: lkrtc.RemoteVideoTrack):
            writer = await room.local_participant.stream_text(topic='glosses')

            self._infer_sess = InferenceSession(self._infer_orchestrator)
            video_stream = lkrtc.VideoStream(track, format=lkrtc.VideoBufferType.RGB24)
            try:
                result_iterator = self._infer_sess.stream_infer(video_stream)
                async for gloss_id in result_iterator:
                    await writer.write(self.vocab[gloss_id])
            finally:
                await writer.aclose()

        @self._room.on("track_subscribed")
        def on_track_subscribed(
            track: lkrtc.Track,
            publication: lkrtc.RemoteTrackPublication,
            participant: lkrtc.RemoteParticipant,
        ):
            logger.info("subscribed to track %s by %s", track.sid, participant.name)
            if self._signer is not None and self._signer.publication_sid == publication.sid:
                if track.kind == lkrtc.TrackKind.KIND_VIDEO:
                    self._stream_results_task = asyncio.create_task(stream_inference_results(track))
        
        @self._room.on("track_unsubscribed")
        def on_track_unsubscribed(
            track: lkrtc.Track,
            publication: lkrtc.RemoteTrackPublication,
            participant: lkrtc.RemoteParticipant,
        ):
            logger.info("unsubscribed to track %s by %s", track.sid, participant.name)
            if self._has_session_started() and self._signer.publication_sid == publication.sid:
                if self._stop_session_task is None:
                    self._stop_session_task = asyncio.create_task(self._stop_session(5))
            
        @self._room.on("participant_disconnected")
        def on_participant_disconnected(participant: lkrtc.RemoteParticipant):
            logger.info("participant %s disconnected", participant.name)
            if self._has_session_started() and self._signer.signer_identity == participant.identity:
                if self._stop_session_task is None:
                    self._stop_session_task = asyncio.create_task(self._stop_session(5))
        
        token = (
            lkapi.AccessToken(
                self._livekit_settings.api_key,
                self._livekit_settings.api_secret
            )
            .with_identity("sign-recognition-bot")
            .with_grants(
                lkapi.VideoGrants(
                    room_join=True,
                    room=room_name,
                )
            )
        )
        await self._room.connect(
            self._livekit_settings.server_url, 
            token.to_jwt(),
            lkrtc.RoomOptions(auto_subscribe=False)
        )
        logger.info("Connected to room: %s", self._room.name)

        @self._room.local_participant.register_rpc_method("start_sign_recognition")
        async def start_sign_recognition(data: lkrtc.RpcInvocationData):
            # wait for the previous session to finish cleaning up
            if self._stop_session_task is not None:
                await self._stop_session_task
            if self._has_session_started():
                raise lkrtc.RpcError(code=2001, message="A session is already in progress")
            req = json.loads(data.payload)
            publication = None
            pub_sid = req.get("pub_sid")
            caller = room.remote_participants[data.caller_identity]
            if pub_sid is not None:
                publication = caller.track_publications[pub_sid]
                if publication.kind != lkrtc.TrackKind.KIND_VIDEO:
                    raise lkrtc.RpcError(code=2003, message="Input publication is not of a video track")
            else:
                for pub in caller.track_publications.values():
                    if pub.kind == lkrtc.TrackKind.KIND_VIDEO:
                        publication = pub
                        break
            if publication is None:
                raise lkrtc.RpcError(code=2002, message="Caller has not published any video tracks")
            self._signer = Signer(
                signer_identity=data.caller_identity,
                publication_sid=publication.sid
            )
            if publication.subscribed:
                self._stream_results_task = asyncio.create_task(stream_inference_results(publication.track))
            else:
                publication.set_subscribed(True)
            logger.info("New sign recognition session started by %s", data.caller_identity)
            return "OK"
        
        @self._room.local_participant.register_rpc_method("pause_sign_recognition")
        async def pause_sign_recognition(data: lkrtc.RpcInvocationData):
            self._validate_active_session(data.caller_identity)
            await self._infer_sess.pause()
            return "OK"
        
        @self._room.local_participant.register_rpc_method("resume_sign_recognition")
        async def resume_sign_recognition(data: lkrtc.RpcInvocationData):
            self._validate_active_session(data.caller_identity)
            await self._infer_sess.resume()
            return "OK"

        @self._room.local_participant.register_rpc_method("stop_sign_recognition")
        async def stop_sign_recognition(data: lkrtc.RpcInvocationData):
            self._validate_active_session(data.caller_identity)
            if self._stop_session_task is None:
                self._stop_session_task = asyncio.create_task(self._stop_session())
            return "OK"

    def _validate_active_session(self, caller_identity: str):
        if self._infer_sess is None:
                raise lkrtc.RpcError(code=3001, message="No active session")
        if self._signer.signer_identity != caller_identity:
            raise lkrtc.RpcError(code=3002, message="Caller is not the current participant using the sign recognition service")
    
    def _has_session_started(self):
        return self._signer is not None and self._stream_results_task is not None

    async def _stop_session(self, timeout: float | None = None):
        logger.info("stopping session...")
        if not self._has_session_started():
            self._stop_session_task = None
            return
        self._stream_results_task.cancel()
        try:
            await self._stream_results_task
        except asyncio.CancelledError:
            logger.info("stream results task cancelled succesfully")
        try:
            await self._infer_sess.stop(timeout)
        except asyncio.TimeoutError:
            logger.info("Timed out while wating for session to stop")
        finally:
            self._infer_sess = None
            self._stop_session_task = None
            self._stream_results_task = None
            self._signer = None

    async def stop(self, timeout: float | None = None):
        logger.info("bot stopping...")
        if self._has_session_started():
            if self._stop_session_task is not None:
                await self._stop_session_task
            else:
                await self._stop_session(timeout)
        await self._room.disconnect()

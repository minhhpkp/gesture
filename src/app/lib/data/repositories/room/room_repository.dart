import 'dart:async';
import 'dart:convert';

import 'package:gesture/data/repositories/bot_identity.dart';
import 'package:gesture/data/repositories/join_token/join_token_repository.dart';
import 'package:gesture/data/repositories/room/signer_state.dart';
import 'package:gesture/ui/room/control/sign_recognition/sign_recognition_state.dart';
import 'package:gesture/utils/logging.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:rxdart/subjects.dart';

class RoomRepository {
  RoomRepository({
    required JoinTokenRepository joinTokenRepository,
    required String url,
  }) : _joinTokenRepository = joinTokenRepository,
       _url = url;
  final JoinTokenRepository _joinTokenRepository;
  final String _url;

  Room? _room;
  Room? get room => _room;
  var _roomSubject = BehaviorSubject<Room>();
  Stream<Room> get roomStream => _roomSubject.stream;
  var _localParticipantSubject = BehaviorSubject<LocalParticipant>();
  Stream<LocalParticipant> get localParticipantStream => _localParticipantSubject.stream;
  var _signerSubject = BehaviorSubject<Participant?>.seeded(null);
  Stream<Participant?> get signerStream => _signerSubject.stream;

  EventsListener<RoomEvent>? _listener;
  EventsListener<RoomEvent>? get listener => _listener;

  Future<void> createRoomAndListener({
    bool e2ee = false,
    String? e2eeKey,
    bool simulcast = true,
    bool adaptiveStream = true,
    bool dynacast = true,
    String preferredCodec = 'VP8',
    bool enableBackupVideoCodec = false,
  }) async {
    const cameraEncoding = VideoEncoding(
      maxBitrate: 5 * 1000 * 1000,
      maxFramerate: 30,
    );

    const screenEncoding = VideoEncoding(
      maxBitrate: 3 * 1000 * 1000,
      maxFramerate: 15,
    );

    E2EEOptions? e2eeOptions;
    if (e2ee && e2eeKey != null) {
      final keyProvider = await BaseKeyProvider.create();
      e2eeOptions = E2EEOptions(keyProvider: keyProvider);
      await keyProvider.setKey(e2eeKey);
    }

    final r = Room(
      roomOptions: RoomOptions(
        adaptiveStream: adaptiveStream,
        dynacast: dynacast,
        defaultAudioPublishOptions: const AudioPublishOptions(
          name: 'custom_audio_track_name',
        ),
        defaultCameraCaptureOptions: const CameraCaptureOptions(
          maxFrameRate: 30,
          params: VideoParameters(
            dimensions: VideoDimensions(1280, 720),
          ),
        ),
        defaultScreenShareCaptureOptions: const ScreenShareCaptureOptions(
          useiOSBroadcastExtension: true,
          params: VideoParameters(
            dimensions: VideoDimensionsPresets.h1080_169,
          ),
        ),
        defaultVideoPublishOptions: VideoPublishOptions(
          simulcast: simulcast,
          videoCodec: preferredCodec,
          backupVideoCodec: BackupVideoCodec(
            enabled: enableBackupVideoCodec,
          ),
          videoEncoding: cameraEncoding,
          screenShareEncoding: screenEncoding,
        ),
        encryption: e2eeOptions,
      ),
    );

    _room = r;
    _listener = r.createListener();
  }

  Future<void> connect(LocalAudioTrack? audioTrack, LocalVideoTrack? videoTrack) async {
    final r = _room;
    if (r == null) throw Exception('room has not been created');

    final token = _joinTokenRepository.joinToken;
    if (token == null) throw Exception('join token has not been created');

    await r.prepareConnection(_url, token);

    // Try to connect to the room
    // This will throw an Exception if it fails for any reason.
    await r.connect(
      _url,
      token,
      fastConnectOptions: FastConnectOptions(
        microphone: TrackOption(track: audioTrack),
        camera: TrackOption(track: videoTrack),
      ),
    );

    r.addListener(_broadcastRoomChange);
    r.localParticipant!.addListener(_broadcastLocalParticipantChange);

    _listenToSignerChanges();
    // final signerState = await getSignerState();
    // final signerIdentity = signerState?.signer;
    // _updateSigner(signerIdentity);
  }

  void _broadcastRoomChange() {
    final r = _room;
    if (!_roomSubject.isClosed && r != null) _roomSubject.add(r);
  }

  void _broadcastLocalParticipantChange() {
    final localParticipant = _room?.localParticipant;
    if (!_localParticipantSubject.isClosed && localParticipant != null) {
      _localParticipantSubject.add(localParticipant);
    }
  }

  void _listenToSignerChanges() {
    final r = _room;
    if (r == null) return;
    r.registerRpcMethod('update_signer', (data) async {
      final signerIdentity = data.payload;
      print('update_signer request received, signer: $signerIdentity');
      if (data.callerIdentity == botIdentity) {
        _updateSigner(signerIdentity);
      }
      return 'OK';
    });
  }

  void _updateSigner(String? signerIdentity) {
    final r = _room;
    if (r == null) return;
    final Participant? signerParticipant;
    if (r.localParticipant?.identity == signerIdentity) {
      signerParticipant = r.localParticipant;
    } else {
      signerParticipant = r.remoteParticipants[signerIdentity];
    }
    _signerSubject.add(signerParticipant);
  }

  bool hasBotJoined() {
    final room = _room;
    if (room == null) return false;
    return room.remoteParticipants.containsKey(botIdentity);
  }

  Future<void> waitForBotToJoin() async {
    if (hasBotJoined()) return;
    await _listener!.waitFor<ParticipantConnectedEvent>(
      duration: const Duration(seconds: 10),
      filter: (event) => event.participant.identity == botIdentity,
      onTimeout: () => throw TimeoutException('Timed out while waiting for bot to join'),
    );
  }

  Future<SignerState?> getSignerState() async {
    await waitForBotToJoin();
    final localParticipant = _room?.localParticipant;
    if (localParticipant == null) return null;
    try {
      final response = await localParticipant.performRpc(
        PerformRpcParams(
          destinationIdentity: botIdentity,
          method: 'get_signer_state',
          payload: '',
          responseTimeoutMs: const Duration(seconds: 10),
        ),
      );
      Log.d('Get signer state: $response');
      final Map<String, dynamic> res = jsonDecode(response);
      if (res['signer'] != null) {
        return SignerState(
          signer: res['signer'],
          sessionState: SessionState.values.byName(res['session_state']),
        );
      }
      return null;
    } on Exception {
      return null;
    }
  }

  Future<void> dispose() async {
    _room?.localParticipant?.removeListener(_broadcastLocalParticipantChange);
    _room?.removeListener(_broadcastRoomChange);
    await _signerSubject.close();
    await _localParticipantSubject.close();
    await _roomSubject.close();
    await _listener?.dispose();
    await _room?.dispose();
    _listener = null;
    _room = null;
    _signerSubject = BehaviorSubject.seeded(null);
    _localParticipantSubject = BehaviorSubject();
    _roomSubject = BehaviorSubject();
  }
}

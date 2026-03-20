import 'dart:async';

import 'package:gesture/data/repositories/join_token/join_token_repository.dart';
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

  Future<void> dispose() async {
    _room?.localParticipant?.removeListener(_broadcastLocalParticipantChange);
    _room?.removeListener(_broadcastRoomChange);
    await _localParticipantSubject.close();
    await _roomSubject.close();
    await _listener?.dispose();
    await _room?.dispose();
    _listener = null;
    _room = null;
    _localParticipantSubject = BehaviorSubject();
    _roomSubject = BehaviorSubject();
  }
}

import 'dart:convert';

import 'package:gesture/data/repositories/room/room_repository.dart';
import 'package:gesture/data/repositories/sign_recognition_session/sign_recognition_session_exception.dart';
import 'package:gesture/utils/logging.dart';
import 'package:livekit_client/livekit_client.dart';

class SignRecognitionSessionRepository {
  SignRecognitionSessionRepository({
    required RoomRepository roomRepository,
  }) : _roomRepository = roomRepository;
  final RoomRepository _roomRepository;

  bool hasBotJoined() {
    final room = _roomRepository.room;
    if (room == null) return false;
    return room.remoteParticipants.containsKey(botIdentity);
  }

  Future<void> _waitForBotToJoin() async {
    await _roomRepository.listener!.waitFor<ParticipantConnectedEvent>(
      duration: const Duration(seconds: 10), 
      filter: (event) => event.participant.identity == botIdentity,
      onTimeout: () => throw ServerError()
    );
  }

  Future<void> startNewSession(LocalTrackPublication<LocalVideoTrack> publication) async {
    if (!hasBotJoined()) {
      await _waitForBotToJoin();
    }
    final localParticipant = _getlocalParticipantOrThrow();
    final payload = jsonEncode({'pub_sid': publication.sid});
    try {
      final response = await localParticipant.performRpc(
        PerformRpcParams(
          destinationIdentity: botIdentity,
          method: 'start_sign_recognition',
          payload: payload,
          responseTimeoutMs: const Duration(minutes: 1),
        ),
      );
      Log.d('Start sign recognition response: $response');
    } on RpcError catch (error) {
      throw SignRecognitionSessionException.fromRpcError(error);
    }
  }

  Future<void> pauseCurrentSession() async {
    final localParticipant = _getlocalParticipantOrThrow();
    try {
      final response = await localParticipant.performRpc(
        PerformRpcParams(
          destinationIdentity: botIdentity,
          method: 'pause_sign_recognition',
          payload: '',
          responseTimeoutMs: const Duration(minutes: 1),
        ),
      );
      Log.d('Pause sign recognition response: $response');
    } on RpcError catch (error) {
      throw SignRecognitionSessionException.fromRpcError(error);
    }
  }

  Future<void> resumeCurrentSession() async {
    final localParticipant = _getlocalParticipantOrThrow();
    try {
      final response = await localParticipant.performRpc(
        PerformRpcParams(
          destinationIdentity: botIdentity,
          method: 'resume_sign_recognition',
          payload: '',
          responseTimeoutMs: const Duration(minutes: 1),
        ),
      );
      Log.d('Resume sign recognition response: $response');
    } on RpcError catch (error) {
      throw SignRecognitionSessionException.fromRpcError(error);
    }
  }

  Future<void> stopCurrentSession() async {
    final localParticipant = _getlocalParticipantOrThrow();
    try {
      final response = await localParticipant.performRpc(
        PerformRpcParams(
          destinationIdentity: botIdentity,
          method: 'stop_sign_recognition',
          payload: '',
          responseTimeoutMs: const Duration(minutes: 1),
        ),
      );
      Log.d('Stop sign recognition response: $response');
    } on RpcError catch (error) {
      throw SignRecognitionSessionException.fromRpcError(error);
    }
  }

  LocalParticipant _getlocalParticipantOrThrow() {
    final localParticipant = _roomRepository.room?.localParticipant;
    if (localParticipant == null) throw LocalParticipantNotPresentException();
    return localParticipant;
  }

  static const botIdentity = 'sign-recognition-bot';
}

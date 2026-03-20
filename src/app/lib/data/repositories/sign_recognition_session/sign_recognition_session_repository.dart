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

  Future<void> startNewSession(LocalTrackPublication<LocalVideoTrack> publication) async {
    final localParticipant = _roomRepository.room?.localParticipant;
    if (localParticipant == null) throw LocalParticipantNotPresentException();
    final payload = jsonEncode({'pub_sid': publication.sid});
    try {
      final response = await localParticipant.performRpc(
        PerformRpcParams(
          destinationIdentity: connectorIdentity,
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

  Future<void> stopCurrentSession() async {
    final localParticipant = _roomRepository.room?.localParticipant;
    if (localParticipant == null) throw LocalParticipantNotPresentException();
    try {
      final response = await localParticipant.performRpc(
        PerformRpcParams(
          destinationIdentity: connectorIdentity,
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

  static const connectorIdentity = 'connector';
}

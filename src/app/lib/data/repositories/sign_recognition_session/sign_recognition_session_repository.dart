import 'dart:convert';

import 'package:gesture/data/repositories/bot_identity.dart';
import 'package:gesture/data/repositories/room/room_repository.dart';
import 'package:gesture/data/repositories/sign_recognition_session/sign_recognition_session_exception.dart';
import 'package:gesture/utils/logging.dart';
import 'package:gesture/utils/retry.dart';
import 'package:livekit_client/livekit_client.dart';

class SignRecognitionSessionRepository {
  SignRecognitionSessionRepository({
    required RoomRepository roomRepository,
  }) : _roomRepository = roomRepository;
  final RoomRepository _roomRepository;

  Future<void> startNewSession(LocalTrackPublication<LocalVideoTrack> publication) async {
    await _roomRepository.waitForBotToJoin();
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
      // relying on server's signer update signal
      final success = await retryUntilTrue(
        action: () async {
          final signer = await _roomRepository.signerStream.first;
          return (signer != null && signer.identity == localParticipant.identity);
        },
      );
      if (success) {
        Log.d('Start sign recognition successfully, even though an RPC error occurred');
      } else {
        throw SignRecognitionSessionException.fromRpcError(error);
      }
    }
  }

  Future<void> pauseCurrentSession() async {
    await _roomRepository.waitForBotToJoin();
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
      final success = await retryUntilTrue(
        action: () async {
          final signerState = await _roomRepository.getSignerState();
          return (signerState?.sessionState == .PAUSED);
        },
      );

      if (success) {
        Log.d('Pause sign recognition successfully, even though an RPC error occurred');
      } else {
        throw SignRecognitionSessionException.fromRpcError(error);
      }
    }
  }

  Future<void> resumeCurrentSession() async {
    await _roomRepository.waitForBotToJoin();
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
      final success = await retryUntilTrue(
        action: () async {
          final signerState = await _roomRepository.getSignerState();
          return (signerState?.sessionState == .RUNNING);
        },
      );

      if (success) {
        Log.d('Resume sign recognition successfully, even though an RPC error occurred');
      } else {
        throw SignRecognitionSessionException.fromRpcError(error);
      }
    }
  }

  Future<void> stopCurrentSession() async {
    await _roomRepository.waitForBotToJoin();
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
      final success = await retryUntilTrue(
        action: () async {
          final signerState = await _roomRepository.getSignerState();
          return (signerState == null || signerState.sessionState == .STOPPED);
        },
      );

      if (success) {
        Log.d('Stop sign recognition successfully, even though an RPC error occurred');
      } else {
        throw SignRecognitionSessionException.fromRpcError(error);
      }
    }
  }

  LocalParticipant _getlocalParticipantOrThrow() {
    final localParticipant = _roomRepository.room?.localParticipant;
    if (localParticipant == null) throw LocalParticipantNotPresentException();
    return localParticipant;
  }
}

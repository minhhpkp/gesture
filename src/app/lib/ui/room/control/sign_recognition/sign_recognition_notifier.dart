import 'package:gesture/data/repositories/sign_recognition_session/sign_recognition_session_exception.dart';
import 'package:gesture/data/repositories/sign_recognition_session/sign_recognition_session_repository.dart';
import 'package:gesture/di/providers.dart';
import 'package:gesture/ui/room/control/sign_recognition/sign_recognition_state.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:gesture/utils/logging.dart';

class SignRecognitionNotifier extends Notifier<SignRecognitionState> {
  late SignRecognitionSessionRepository _signRecognitionSessionRepository;

  @override
  SignRecognitionState build() {
    _signRecognitionSessionRepository = ref.read(signRecognitionSessionRepository);
    return SignRecognitionState();
  }

  void setSelectedVideoPublication(LocalTrackPublication<LocalVideoTrack> pub) {
    state = state.copyWith(selectedVideoPublication: pub);
  }

  Future<void> startSignRecognition() async {
    final selectedVideoPublication = state.selectedVideoPublication;
    if (state.inProgress || state.isLoading || selectedVideoPublication == null) return;
    try {
      state = state.copyWith(isLoading: true);
      await _signRecognitionSessionRepository.startNewSession(selectedVideoPublication);
      state = state.copyWith(inProgress: true, isLoading: false);
    } on SignRecognitionSessionException catch (e, st) {
      Log.d('Start sign recognition failed', error: e, stackTrace: st);
      state = state.copyWith(errorMessage: e.message, inProgress: false, isLoading: false);
    } on Exception catch (e, st) {
      Log.d('Start sign recognition failed', error: e, stackTrace: st);
      state = state.copyWith(errorMessage: 'Unknown error occurred', inProgress: false, isLoading: false);
    }
  }

  Future<void> stopSignRecognition() async {
    if (!state.inProgress || state.isLoading) return;
    try {
      state = state.copyWith(isLoading: true);
      await _signRecognitionSessionRepository.stopCurrentSession();
      state = state.copyWith(inProgress: false, isLoading: false);
    } on SignRecognitionSessionException catch (e, st) {
      Log.d('Stop sign recognition failed', error: e, stackTrace: st);
      state = state.copyWith(errorMessage: e.message, inProgress: false, isLoading: false);
    } on Exception catch (e, st) {
      Log.d('Stop sign recognition failed', error: e, stackTrace: st);
      state = state.copyWith(errorMessage: 'Unknown error occurred', inProgress: false, isLoading: false);
    }
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}

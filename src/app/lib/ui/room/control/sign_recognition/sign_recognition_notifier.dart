import 'package:gesture/data/repositories/sign_recognition_session/sign_recognition_session_exception.dart';
import 'package:gesture/data/repositories/sign_recognition_session/sign_recognition_session_repository.dart';
import 'package:gesture/di/providers.dart';
import 'package:gesture/ui/room/control/sign_recognition/sign_recognition_state.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:gesture/utils/logging.dart';

class SignRecognitionNotifier extends Notifier<SignRecognitionState> {
  late SignRecognitionSessionRepository _signRecognitionSessionRepository;
  var _isBuilding = true;

  @override
  SignRecognitionState build() {
    _isBuilding = true;
    _signRecognitionSessionRepository = ref.read(signRecognitionSessionRepository);
    final roomRepository = ref.read(roomRepositoryProvider);
    final listener = roomRepository.listener!;
    final cancelListener = listener.on<LocalTrackUnpublishedEvent>((event) {
      if (_isBuilding) return;
      state = state.copyWith(sessionState: .STOPPED);
    });
    ref.onDispose(cancelListener);
    _isBuilding = false;
    return SignRecognitionState();
  }

  void setSelectedVideoPublication(LocalTrackPublication<LocalVideoTrack> pub) {
    state = state.copyWith(selectedVideoPublication: pub);
  }

  Future<void> startSignRecognition() async {
    final selectedVideoPublication = state.selectedVideoPublication;
    if (state.sessionState != .STOPPED || state.isLoading || selectedVideoPublication == null) return;
    try {
      state = state.copyWith(isLoading: true);
      await _signRecognitionSessionRepository.startNewSession(selectedVideoPublication);
      state = state.copyWith(sessionState: .RUNNING, isLoading: false);
    } on SignRecognitionSessionException catch (e, st) {
      Log.w('Start sign recognition failed', error: e, stackTrace: st);
      state = state.copyWith(errorMessage: e.message, isLoading: false);
    } on Exception catch (e, st) {
      Log.w('Start sign recognition failed', error: e, stackTrace: st);
      state = state.copyWith(errorMessage: 'Unknown error occurred', isLoading: false);
    }
  }

  Future<void> pauseSignRecognition() async {
    if (state.sessionState != .RUNNING || state.isLoading) return;
    try {
      state = state.copyWith(isLoading: true);
      await _signRecognitionSessionRepository.pauseCurrentSession();
      state = state.copyWith(sessionState: .PAUSED, isLoading: false);
    } on SignRecognitionSessionException catch (e, st) {
      Log.w('Pause sign recognition failed', error: e, stackTrace: st);
      state = state.copyWith(errorMessage: e.message, isLoading: false);
    } on Exception catch (e, st) {
      Log.w('Pause sign recognition failed', error: e, stackTrace: st);
      state = state.copyWith(errorMessage: 'Unknown error occurred', isLoading: false);
    }
  }

  Future<void> resumeSignRecognition() async {
    if (state.sessionState != .PAUSED || state.isLoading) return;
    try {
      state = state.copyWith(isLoading: true);
      await _signRecognitionSessionRepository.resumeCurrentSession();
      state = state.copyWith(sessionState: .RUNNING, isLoading: false);
    } on SignRecognitionSessionException catch (e, st) {
      Log.w('Resume sign recognition failed', error: e, stackTrace: st);
      state = state.copyWith(errorMessage: e.message, isLoading: false);
    } on Exception catch (e, st) {
      Log.w('Resume sign recognition failed', error: e, stackTrace: st);
      state = state.copyWith(errorMessage: 'Unknown error occurred', isLoading: false);
    }
  }

  Future<void> stopSignRecognition() async {
    if (state.sessionState == .STOPPED || state.isLoading) return;
    try {
      state = state.copyWith(isLoading: true);
      await _signRecognitionSessionRepository.stopCurrentSession();
      state = state.copyWith(sessionState: .STOPPED, isLoading: false);
    } on NoActiveSessionException {
      Log.w('Stop sign recognition: session already stopped');
    } on SignRecognitionSessionException catch (e, st) {
      Log.w('Stop sign recognition failed', error: e, stackTrace: st);
      state = state.copyWith(errorMessage: e.message, isLoading: false);
    } on Exception catch (e, st) {
      Log.w('Stop sign recognition failed', error: e, stackTrace: st);
      state = state.copyWith(errorMessage: 'Unknown error occurred', isLoading: false);
    }
  }

  void errorShown() {
    state = state.copyWith(errorMessage: null);
  }
}

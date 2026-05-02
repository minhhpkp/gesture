import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:livekit_client/livekit_client.dart';

part 'sign_recognition_state.freezed.dart';

enum SessionState {
  STOPPED,
  RUNNING,
  PAUSED,
}

@freezed
abstract class SignRecognitionState with _$SignRecognitionState {
  const factory SignRecognitionState({
    LocalTrackPublication<LocalVideoTrack>? selectedVideoPublication,
    @Default(false) bool shouldNotifyNoVideoTrack,
    @Default(SessionState.STOPPED) SessionState sessionState,
    @Default(false) bool isLoading,
    String? errorMessage,
  }) = _SignRecognitionState;
}
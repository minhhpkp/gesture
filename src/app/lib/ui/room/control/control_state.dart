import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:livekit_client/livekit_client.dart';

part 'control_state.freezed.dart';

@freezed
abstract class ControlState with _$ControlState {
  const factory ControlState({
    required List<MediaDevice> audioInputs,
    required List<MediaDevice> audioOutputs,
    required List<MediaDevice> videoInputs,
    String? selectedAudioInputDeviceId,
    String? selectedAudioOutputDeviceId,
    String? selectedVideoInputDeviceId,
    required CameraPosition cameraPosition,
    required bool isSpeakerphoneOn,
    required bool isMicrophoneEnabled,
    required bool isCameraEnabled,
    required bool isScreenShareEnabled,
    required bool isMuted,
    required bool shouldNotifyScreenShare,
    required bool shouldNotifyScreenShareUnavailable,
  }) = _ControlState;
}

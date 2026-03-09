import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:livekit_client/livekit_client.dart';

part 'prejoin_state.freezed.dart';

@freezed
abstract class PrejoinState with _$PrejoinState {
  const factory PrejoinState({
    required List<MediaDevice> audioInputs,
    required List<MediaDevice> videoInputs,
    @Default(true) bool isAudioEnabled,
    @Default(true) bool isVideoEnabled,
    MediaDevice? selectedAudioDevice,
    MediaDevice? selectedVideoDevice,
    LocalVideoTrack? videoTrack,
    required VideoParameters selectedVideoParameters,
    @Default(false) bool isLoading,
    bool? isJoinSuccess,
  }) = _PrejoinState;
}
import 'dart:collection';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:gesture/ui/room/participant/participant_track.dart';

part 'room_state.freezed.dart';

@freezed
abstract class RoomState with _$RoomState {
  const factory RoomState({
    required List<ParticipantTrack> participantTracks,
    required Queue<String> glosses,
    @Default(false) bool unableToPlaybackAudio,
    @Default(false) bool roomDisconnected,
    bool? activeRecording,
    @Default(false) bool hasLocalParticipant,
    @Default(false) bool isLoading,
  }) = _RoomState;
}
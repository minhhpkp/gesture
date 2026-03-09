import 'package:livekit_client/livekit_client.dart';

enum ParticipantTrackType {
  userMedia,
  screenShare
  ;

  TrackSource get lkVideoSourceType => {
    ParticipantTrackType.userMedia: TrackSource.camera,
    ParticipantTrackType.screenShare: TrackSource.screenShareVideo,
  }[this]!;

  TrackSource get lkAudioSourceType => {
    ParticipantTrackType.userMedia: TrackSource.microphone,
    ParticipantTrackType.screenShare: TrackSource.screenShareAudio,
  }[this]!;
}

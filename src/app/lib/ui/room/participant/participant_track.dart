import 'package:gesture/ui/room/participant/participant_track_type.dart';
import 'package:livekit_client/livekit_client.dart';

class ParticipantTrack {
  ParticipantTrack({required this.participant, this.type = ParticipantTrackType.userMedia});
  Participant participant;
  final ParticipantTrackType type;
}

import 'dart:async';
import 'dart:collection';
import 'dart:convert';

import 'package:gesture/di/providers.dart';
import 'package:gesture/ui/room/participant/participant_track.dart';
import 'package:gesture/ui/room/participant/participant_track_type.dart';
import 'package:gesture/ui/room/room_state.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:livekit_client/livekit_client.dart';

class RoomViewModel extends Notifier<RoomState> {
  late final Room _room;
  var isBuilding = true;

  @override
  RoomState build() {
    final roomRepository = ref.read(roomRepositoryProvider);
    _room = roomRepository.room!;
    final listener = roomRepository.listener!;

    var initialState = RoomState(participantTracks: [], glosses: Queue());

    void onRoomDidUpdate() {
      final participants = _sortParticipants();
      if (isBuilding) {
        initialState = initialState.copyWith(
          participantTracks: participants,
          hasLocalParticipant: _room.localParticipant != null,
        );
      } else {
        state = state.copyWith(
          participantTracks: participants,
          hasLocalParticipant: _room.localParticipant != null,
        );
      }
    }

    _room.addListener(onRoomDidUpdate);
    ref.onDispose(() => _room.removeListener(onRoomDidUpdate));

    void sortAndSetParticipants() {
      final participants = _sortParticipants();
      if (isBuilding) {
        initialState = initialState.copyWith(participantTracks: participants);
      } else {
        state = state.copyWith(participantTracks: participants);
      }
    }

    listener
      ..on<RoomDisconnectedEvent>((event) async {
        if (event.reason != null) {
          print('Room disconnected: reason => ${event.reason}');
        }
        if (isBuilding) {
          initialState = initialState.copyWith(roomDisconnected: true);
        } else {
          state = state.copyWith(roomDisconnected: true);
        }
      })
      ..on<ParticipantEvent>((event) {
        // sort participants on many track events as noted in documentation
        sortAndSetParticipants();
      })
      ..on<RoomRecordingStatusChanged>((event) {
        if (isBuilding) {
          initialState = initialState.copyWith(activeRecording: event.activeRecording);
        } else {
          state = state.copyWith(activeRecording: event.activeRecording);
        }
      })
      ..on<RoomAttemptReconnectEvent>((event) {
        print(
          'Attempting to reconnect ${event.attempt}/${event.maxAttemptsRetry}, '
          '(${event.nextRetryDelaysInMs}ms delay until next attempt)',
        );
      })
      ..on<LocalTrackSubscribedEvent>((event) {
        print('Local track subscribed: ${event.trackSid}');
      })
      ..on<LocalTrackPublishedEvent>((_) => sortAndSetParticipants())
      ..on<LocalTrackUnpublishedEvent>((_) => sortAndSetParticipants())
      ..on<TrackSubscribedEvent>((_) => sortAndSetParticipants())
      ..on<TrackUnsubscribedEvent>((_) => sortAndSetParticipants())
      ..on<ParticipantNameUpdatedEvent>((event) {
        print('Participant name updated: ${event.participant.identity}, name => ${event.name}');
        sortAndSetParticipants();
      })
      ..on<ParticipantMetadataUpdatedEvent>((event) {
        print('Participant metadata updated: ${event.participant.identity}, metadata => ${event.metadata}');
      })
      ..on<RoomMetadataChangedEvent>((event) {
        print('Room metadata changed: ${event.metadata}');
      })
      ..on<DataReceivedEvent>((event) {
        String decoded = 'Failed to decode';
        try {
          if (event.topic == 'caption') {
            decoded = utf8.decode(event.data);
            final newGlosses = isBuilding ? Queue<String>() : Queue.of(state.glosses);
            newGlosses.add(decoded);
            while (newGlosses.length > 10) {
              newGlosses.removeFirst();
            }
            if (isBuilding) {
              initialState = initialState.copyWith(glosses: newGlosses);
            } else {
              state = state.copyWith(glosses: newGlosses);
            }
          }
        } catch (err) {
          print('Failed to decode: $err');
        }
        // unawaited(context.showDataReceivedDialog(decoded));
      })
      ..on<AudioPlaybackStatusChanged>((event) {
        if (!_room.canPlaybackAudio) {
          print('Audio playback failed for iOS Safari ..........');
          if (isBuilding) {
            initialState = initialState.copyWith(unableToPlaybackAudio: true);
          } else {
            state = state.copyWith(unableToPlaybackAudio: true);
          }
        }
      });

    ref.onDispose(() => roomRepository.dispose());
    sortAndSetParticipants();

    if (lkPlatformIs(PlatformType.android)) {
      unawaited(Hardware.instance.setSpeakerphoneOn(true));
    }

    isBuilding = false;

    return initialState;
  }

  List<ParticipantTrack> _sortParticipants() {
    final userMediaTracks = <ParticipantTrack>[];
    final screenTracks = <ParticipantTrack>[];
    for (var participant in _room.remoteParticipants.values) {
      for (var t in participant.videoTrackPublications) {
        if (t.isScreenShare) {
          screenTracks.add(
            ParticipantTrack(
              participant: participant,
              type: ParticipantTrackType.screenShare,
            ),
          );
        } else {
          userMediaTracks.add(ParticipantTrack(participant: participant));
        }
      }
    }
    // sort speakers for the grid
    userMediaTracks.sort((a, b) {
      // loudest speaker first
      if (a.participant.isSpeaking && b.participant.isSpeaking) {
        if (a.participant.audioLevel > b.participant.audioLevel) {
          return -1;
        } else {
          return 1;
        }
      }

      // last spoken at
      final aSpokeAt = a.participant.lastSpokeAt?.millisecondsSinceEpoch ?? 0;
      final bSpokeAt = b.participant.lastSpokeAt?.millisecondsSinceEpoch ?? 0;

      if (aSpokeAt != bSpokeAt) {
        return aSpokeAt > bSpokeAt ? -1 : 1;
      }

      // video on
      if (a.participant.hasVideo != b.participant.hasVideo) {
        return a.participant.hasVideo ? -1 : 1;
      }

      // joinedAt
      return a.participant.joinedAt.millisecondsSinceEpoch - b.participant.joinedAt.millisecondsSinceEpoch;
    });

    final localParticipantTracks = _room.localParticipant?.videoTrackPublications;
    if (localParticipantTracks != null) {
      for (var t in localParticipantTracks) {
        if (t.isScreenShare) {
          screenTracks.add(
            ParticipantTrack(
              participant: _room.localParticipant!,
              type: ParticipantTrackType.screenShare,
            ),
          );
        } else {
          userMediaTracks.add(ParticipantTrack(participant: _room.localParticipant!));
        }
      }
    }

    return [...screenTracks, ...userMediaTracks];
  }

  Future<void> manuallyPlayAudio() async {
    await _room.startAudio();
  }

  void waitForNextAudioPlaybackStatus() {
    state = state.copyWith(unableToPlaybackAudio: false);
  }

  void waitForNextRecordingStatus() {
    state = state.copyWith(activeRecording: null);
  }
}

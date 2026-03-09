import 'package:flutter/material.dart';
import 'package:gesture/ui/room/participant/no_video_indicator.dart';
import 'package:gesture/ui/room/participant/participant_status_bar.dart';
import 'package:gesture/ui/room/participant/participant_track.dart';
import 'package:gesture/ui/room/participant/participant_track_type.dart';
import 'package:gesture/ui/room/participant/sound_waveform.dart';
import 'package:livekit_client/livekit_client.dart';

abstract class ParticipantTile extends StatefulWidget {
  static ParticipantTile widgetFor(ParticipantTrack participantTrack) {
    if (participantTrack.participant is LocalParticipant) {
      return LocalParticipantTile(
          participantTrack.participant as LocalParticipant, participantTrack.type);
    } else if (participantTrack.participant is RemoteParticipant) {
      return RemoteParticipantTile(
          participantTrack.participant as RemoteParticipant, participantTrack.type);
    }
    throw UnimplementedError('Unknown participant type');
  }

  abstract final Participant participant;
  abstract final ParticipantTrackType type;

  const ParticipantTile({super.key});
}

class LocalParticipantTile extends ParticipantTile {
  @override
  final LocalParticipant participant;
  @override
  final ParticipantTrackType type;

  const LocalParticipantTile(
    this.participant,
    this.type, {
    super.key,
  });

  @override
  State<LocalParticipantTile> createState() => _LocalParticipantTileState();
}

class RemoteParticipantTile extends ParticipantTile {
  @override
  final RemoteParticipant participant;
  @override
  final ParticipantTrackType type;

  const RemoteParticipantTile(
    this.participant,
    this.type, {
    super.key,
  });

  @override
  State<RemoteParticipantTile> createState() => _RemoteParticipantTileState();
}

abstract class _ParticipantTileState<T extends ParticipantTile> extends State<T> {
  bool _visible = true;
  VideoTrack? get activeVideoTrack;
  AudioTrack? get activeAudioTrack;
  TrackPublication? get videoPublication;
  TrackPublication? get audioPublication;
  bool get isScreenShare => widget.type == ParticipantTrackType.screenShare;

  @override
  void initState() {
    super.initState();

    widget.participant.addListener(_onParticipantChanged);
    _onParticipantChanged();
  }

  @override
  void dispose() {
    widget.participant.removeListener(_onParticipantChanged);
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant T oldWidget) {
    oldWidget.participant.removeListener(_onParticipantChanged);
    widget.participant.addListener(_onParticipantChanged);
    _onParticipantChanged();
    super.didUpdateWidget(oldWidget);
  }

  // Notify Flutter that UI re-build is required, but we don't set anything here
  // since the updated values are computed properties.
  void _onParticipantChanged() => setState(() {});

  // Widgets to show above the info bar
  List<Widget> extraWidgets(bool isScreenShare) => [];

  @override
  Widget build(BuildContext ctx) => Container(
    foregroundDecoration: BoxDecoration(
      border: widget.participant.isSpeaking && !isScreenShare
          ? Border.all(
              width: 5,
              color: Colors.blue,
            )
          : null,
    ),
    decoration: BoxDecoration(
      color: Theme.of(ctx).cardColor,
    ),
    child: Stack(
      children: [
        // Video
        InkWell(
          onTap: () => setState(() => _visible = !_visible),
          child: activeVideoTrack != null && !activeVideoTrack!.muted
              ? VideoTrackRenderer(
                  renderMode: VideoRenderMode.auto,
                  activeVideoTrack!,
                )
              : const NoVideoIndicator(),
        ),
        // Bottom bar
        Align(
          alignment: Alignment.bottomCenter,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              ...extraWidgets(isScreenShare),
              ParticipantStatusBar(
                title: widget.participant.name.isNotEmpty
                    ? '${widget.participant.name} (${widget.participant.identity})'
                    : widget.participant.identity,
                audioAvailable: audioPublication?.muted == false && audioPublication?.subscribed == true,
                connectionQuality: widget.participant.connectionQuality,
                isScreenShare: isScreenShare,
                enabledE2EE: widget.participant.isEncrypted,
              ),
            ],
          ),
        ),
        if (activeAudioTrack != null && !activeAudioTrack!.muted)
          Positioned(
            top: 10,
            right: 10,
            left: 10,
            bottom: 10,
            child: SoundWaveform(
              key: ValueKey(activeAudioTrack!.hashCode),
              audioTrack: activeAudioTrack!,
              width: 8,
            ),
          ),
      ],
    ),
  );
}

class _LocalParticipantTileState extends _ParticipantTileState<LocalParticipantTile> {
  @override
  LocalTrackPublication<LocalVideoTrack>? get videoPublication => widget.participant.videoTrackPublications
      .where((element) => element.source == widget.type.lkVideoSourceType)
      .firstOrNull;

  @override
  LocalTrackPublication<LocalAudioTrack>? get audioPublication => widget.participant.audioTrackPublications
      .where((element) => element.source == widget.type.lkAudioSourceType)
      .firstOrNull;

  @override
  VideoTrack? get activeVideoTrack => videoPublication?.track;

  @override
  AudioTrack? get activeAudioTrack => audioPublication?.track;
}

class _RemoteParticipantTileState extends _ParticipantTileState<RemoteParticipantTile> {
  @override
  RemoteTrackPublication<RemoteVideoTrack>? get videoPublication => widget.participant.videoTrackPublications
      .where((element) => element.source == widget.type.lkVideoSourceType)
      .firstOrNull;

  @override
  RemoteTrackPublication<RemoteAudioTrack>? get audioPublication => widget.participant.audioTrackPublications
      .where((element) => element.source == widget.type.lkAudioSourceType)
      .firstOrNull;

  @override
  VideoTrack? get activeVideoTrack => videoPublication?.track;

  @override
  AudioTrack? get activeAudioTrack => audioPublication?.track;

  @override
  List<Widget> extraWidgets(bool isScreenShare) => [
    Row(
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // Menu for RemoteTrackPublication<RemoteAudioTrack>
        if (audioPublication != null)
          RemoteTrackPublicationMenu(
            pub: audioPublication!,
            icon: Icons.volume_up,
          ),
        // Menu for RemoteTrackPublication<RemoteVideoTrack>
        if (videoPublication != null)
          RemoteTrackPublicationMenu(
            pub: videoPublication!,
            icon: isScreenShare ? Icons.monitor : Icons.videocam,
          ),
        if (videoPublication != null)
          RemoteTrackFPSMenu(
            pub: videoPublication!,
            icon: Icons.menu,
          ),
        if (videoPublication != null)
          RemoteTrackQualityMenu(
            pub: videoPublication!,
            icon: Icons.monitor_outlined,
          ),
      ],
    ),
  ];
}

class RemoteTrackPublicationMenu extends StatelessWidget {
  final IconData icon;
  final RemoteTrackPublication pub;
  const RemoteTrackPublicationMenu({
    required this.pub,
    required this.icon,
    super.key,
  });

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.black.withValues(alpha: 0.3),
    child: PopupMenuButton<Function>(
      tooltip: 'Subscribe menu',
      icon: Icon(
        icon,
        color: {
          TrackSubscriptionState.notAllowed: Colors.red,
          TrackSubscriptionState.unsubscribed: Colors.grey,
          TrackSubscriptionState.subscribed: Colors.green,
        }[pub.subscriptionState],
      ),
      onSelected: (value) => value(),
      itemBuilder: (BuildContext context) => <PopupMenuEntry<Function>>[
        // Subscribe/Unsubscribe
        if (pub.subscribed == false)
          PopupMenuItem(
            child: const Text('Subscribe'),
            value: () => pub.subscribe(),
          )
        else if (pub.subscribed == true)
          PopupMenuItem(
            child: const Text('Un-subscribe'),
            value: () => pub.unsubscribe(),
          ),
      ],
    ),
  );
}

class RemoteTrackFPSMenu extends StatelessWidget {
  final IconData icon;
  final RemoteTrackPublication pub;
  const RemoteTrackFPSMenu({
    required this.pub,
    required this.icon,
    super.key,
  });

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.black.withValues(alpha: 0.3),
    child: PopupMenuButton<Function>(
      tooltip: 'Preferred FPS',
      icon: Icon(icon, color: Colors.white),
      onSelected: (value) => value(),
      itemBuilder: (BuildContext context) => <PopupMenuEntry<Function>>[
        PopupMenuItem(
          child: const Text('30'),
          value: () => pub.setVideoFPS(30),
        ),
        PopupMenuItem(
          child: const Text('15'),
          value: () => pub.setVideoFPS(15),
        ),
        PopupMenuItem(
          child: const Text('8'),
          value: () => pub.setVideoFPS(8),
        ),
      ],
    ),
  );
}

class RemoteTrackQualityMenu extends StatelessWidget {
  final IconData icon;
  final RemoteTrackPublication pub;
  const RemoteTrackQualityMenu({
    required this.pub,
    required this.icon,
    super.key,
  });

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.black.withValues(alpha: 0.3),
    child: PopupMenuButton<Function>(
      tooltip: 'Preferred Quality',
      icon: Icon(icon, color: Colors.white),
      onSelected: (value) => value(),
      itemBuilder: (BuildContext context) => <PopupMenuEntry<Function>>[
        PopupMenuItem(
          child: const Text('HIGH'),
          value: () => pub.setVideoQuality(VideoQuality.HIGH),
        ),
        PopupMenuItem(
          child: const Text('MEDIUM'),
          value: () => pub.setVideoQuality(VideoQuality.MEDIUM),
        ),
        PopupMenuItem(
          child: const Text('LOW'),
          value: () => pub.setVideoQuality(VideoQuality.LOW),
        ),
      ],
    ),
  );
}

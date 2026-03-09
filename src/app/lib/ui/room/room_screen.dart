import 'dart:math';

import 'package:flutter/material.dart';
import 'package:gesture/di/providers.dart';
import 'package:gesture/routing/routes.dart';
import 'package:gesture/ui/room/control_bar.dart';
import 'package:gesture/ui/room/participant/participant_tile.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:livekit_client/livekit_client.dart';

class RoomScreen extends ConsumerStatefulWidget {
  const RoomScreen({super.key});

  @override
  ConsumerState<RoomScreen> createState() => _RoomScreenState();
}

class _RoomScreenState extends ConsumerState<RoomScreen> {
  Future<bool?> _showPlayAudioManuallyDialog() => showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Play Audio'),
      content: const Text('You need to manually activate audio PlayBack for iOS Safari !'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Ignore'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Play Audio'),
        ),
      ],
    ),
  );

  Future<bool?> _showRecordingStatusChangedDialog(bool isActiveRecording) => showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Room recording reminder'),
      content: Text(isActiveRecording ? 'Room recording is active.' : 'Room recording is stoped.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('OK'),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final vm = ref.read(roomVieWModelProvider.notifier);
    ref.listen(roomVieWModelProvider, (previous, next) async {
      if (next.unableToPlaybackAudio) {
        final yesno = await _showPlayAudioManuallyDialog();
        if (yesno == true) {
          await vm.manuallyPlayAudio();
        }
        vm.waitForNextAudioPlaybackStatus();
      }

      if (next.roomDisconnected) {
        WidgetsBindingCompatible.instance?.addPostFrameCallback((timeStamp) => context.go(Routes.connect));
      }

      if (previous?.activeRecording == null && next.activeRecording != null) {
        await _showRecordingStatusChangedDialog(next.activeRecording!);
        vm.waitForNextRecordingStatus();
      }
    });

    final state = ref.watch(roomVieWModelProvider);

    return Scaffold(
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: state.participantTracks.isNotEmpty
                    ? ParticipantTile.widgetFor(state.participantTracks.first)
                    : Container(),
              ),
              if (state.hasLocalParticipant)
                SafeArea(
                  top: false,
                  child: ControlBar(),
                ),
            ],
          ),
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            child: SizedBox(
              height: 120,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: max(0, state.participantTracks.length - 1),
                itemBuilder: (BuildContext context, int index) => SizedBox(
                  width: 180,
                  height: 120,
                  child: ParticipantTile.widgetFor(state.participantTracks[index + 1]),
                ),
              ),
            ),
          ),
          Center(
            child: Text(state.glosses.join(' ')),
          ),
        ],
      ),
    );
  }
}

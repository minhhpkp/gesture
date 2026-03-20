import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:gesture/di/providers.dart';
import 'package:gesture/ui/room/control/sign_recognition/select_video_track_dialog.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:flutter/material.dart';
import 'package:livekit_client/livekit_client.dart';

class ControlBar extends ConsumerWidget {
  const ControlBar({super.key});

  Future<void> _showScreenShareUnavailableDialog(BuildContext context) => showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Error'),
      content: Text('Screen share is not supported on mobile web'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('OK'),
        ),
      ],
    ),
  );

  Future<bool?> _showDisconnectDialog(BuildContext context) => showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Disconnect'),
      content: const Text('Are you sure you want to disconnect?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Disconnect'),
        ),
      ],
    ),
  );

  Future<bool?> _showSelectVideoTrackDialog(BuildContext context) => showDialog(
    context: context,
    builder: (ctx) => SelectVideoTrackDialog(
      onCancelPressed: () => Navigator.pop(ctx, false),
      onStartPressed: () => Navigator.pop(ctx, true),
    ),
  );

  Future<void> _showSignRecognitionErrorDialog(BuildContext context, String message) => showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Error'),
      content: SingleChildScrollView(
        child: ListBody(
          children: [
            const Text('An error occurred:'),
            Text(message),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('OK'),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controlVm = ref.read(controlViewModelProvider.notifier);
    final signRecognitionVm = ref.read(signRecognitionNotifierProvider.notifier);

    ref.listen(controlViewModelProvider, (previous, next) async {
      if (previous?.value?.shouldNotifyScreenShare != true && next.value?.shouldNotifyScreenShare == true) {
        if (!context.mounted) return;
        final source = await showDialog<DesktopCapturerSource>(
          context: context,
          builder: (_) => ScreenSelectDialog(),
        );
        controlVm.screenShareNotified();
        if (source != null) {
          print('cancelled screenshare');
          await controlVm.setDesktopCapturerSource(source);
        }
      }
      if (previous?.value?.shouldNotifyScreenShareUnavailable != true &&
          next.value?.shouldNotifyScreenShareUnavailable == true) {
        if (!context.mounted) return;
        await _showScreenShareUnavailableDialog(context);
        controlVm.screenShareUnavailableNotified();
      }
    });

    ref.listen(signRecognitionNotifierProvider, (previous, next) async {
      if (previous?.errorMessage == null && next.errorMessage != null) {
        await _showSignRecognitionErrorDialog(context, next.errorMessage!);
        if (context.mounted) signRecognitionVm.clearError();
      }
    });

    void handleStartSignRecognitionClick() async {
      await _showSelectVideoTrackDialog(context);
      await signRecognitionVm.startSignRecognition();
    }

    void handleDisconnectClick() async {
      final shouldDisconnect = await _showDisconnectDialog(context);
      if (shouldDisconnect == true) {
        await controlVm.disconnect();
      }
    }

    final state = ref.watch(controlViewModelProvider).value;
    final signRecognitionState = ref.watch(signRecognitionNotifierProvider);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      child: state != null
          ? Wrap(
              alignment: WrapAlignment.center,
              spacing: 5,
              runSpacing: 5,
              children: [
                if (signRecognitionState.isLoading)
                  CircularProgressIndicator()
                else if (signRecognitionState.inProgress)
                  IconButton(
                    icon: Icon(Icons.stop),
                    onPressed: signRecognitionVm.stopSignRecognition,
                  )
                else
                  IconButton(
                    icon: Icon(Icons.start),
                    onPressed: handleStartSignRecognitionClick,
                  ),
                if (state.isMicrophoneEnabled)
                  if (lkPlatformIs(PlatformType.android))
                    IconButton(
                      onPressed: controlVm.disableAudio,
                      icon: const Icon(Icons.mic),
                      tooltip: 'mute audio',
                    )
                  else
                    PopupMenuButton<MediaDevice>(
                      icon: const Icon(Icons.settings_voice),
                      offset: const Offset(0, -90),
                      itemBuilder: (BuildContext context) {
                        return [
                          PopupMenuItem<MediaDevice>(
                            value: null,
                            onTap: state.isMuted ? controlVm.enableAudio : controlVm.disableAudio,
                            child: const ListTile(
                              leading: Icon(
                                Icons.mic_off,
                                color: Colors.white,
                              ),
                              title: Text('Mute Microphone'),
                            ),
                          ),
                          if (state.audioInputs.isNotEmpty)
                            ...state.audioInputs.map((device) {
                              return PopupMenuItem<MediaDevice>(
                                value: device,
                                child: ListTile(
                                  leading: (device.deviceId == state.selectedAudioInputDeviceId)
                                      ? const Icon(
                                          Icons.check_box_outlined,
                                          color: Colors.white,
                                        )
                                      : const Icon(
                                          Icons.check_box_outline_blank,
                                          color: Colors.white,
                                        ),
                                  title: Text(device.label),
                                ),
                                onTap: () => controlVm.selectAudioInput(device),
                              );
                            }),
                        ];
                      },
                    )
                else
                  IconButton(
                    onPressed: controlVm.enableAudio,
                    icon: const Icon(Icons.mic_off),
                    tooltip: 'un-mute audio',
                  ),
                if (!lkPlatformIsMobile())
                  PopupMenuButton<MediaDevice>(
                    icon: const Icon(Icons.volume_up),
                    itemBuilder: (BuildContext context) {
                      return [
                        const PopupMenuItem<MediaDevice>(
                          value: null,
                          child: ListTile(
                            leading: Icon(
                              Icons.speaker,
                              color: Colors.white,
                            ),
                            title: Text('Select Audio Output'),
                          ),
                        ),
                        if (state.audioOutputs.isNotEmpty)
                          ...state.audioOutputs.map((device) {
                            return PopupMenuItem<MediaDevice>(
                              value: device,
                              child: ListTile(
                                leading: (device.deviceId == state.selectedAudioOutputDeviceId)
                                    ? const Icon(
                                        Icons.check_box_outlined,
                                        color: Colors.white,
                                      )
                                    : const Icon(
                                        Icons.check_box_outline_blank,
                                        color: Colors.white,
                                      ),
                                title: Text(device.label),
                              ),
                              onTap: () => controlVm.selectAudioOutput(device),
                            );
                          }),
                      ];
                    },
                  ),
                if (!kIsWeb && lkPlatformIsMobile())
                  IconButton(
                    disabledColor: Colors.grey,
                    onPressed: controlVm.setSpeakerphoneOn,
                    icon: Icon(state.isSpeakerphoneOn ? Icons.speaker_phone : Icons.phone_android),
                    tooltip: 'Switch SpeakerPhone',
                  ),
                if (state.isCameraEnabled)
                  PopupMenuButton<MediaDevice>(
                    icon: const Icon(Icons.videocam_sharp),
                    itemBuilder: (BuildContext context) {
                      return [
                        PopupMenuItem<MediaDevice>(
                          value: null,
                          onTap: controlVm.disableVideo,
                          child: const ListTile(
                            leading: Icon(
                              Icons.videocam_off,
                              color: Colors.white,
                            ),
                            title: Text('Disable Camera'),
                          ),
                        ),
                        if (state.videoInputs.isNotEmpty)
                          ...state.videoInputs.map((device) {
                            return PopupMenuItem<MediaDevice>(
                              value: device,
                              child: ListTile(
                                leading: (device.deviceId == state.selectedVideoInputDeviceId)
                                    ? const Icon(
                                        Icons.check_box_outlined,
                                        color: Colors.white,
                                      )
                                    : const Icon(
                                        Icons.check_box_outline_blank,
                                        color: Colors.white,
                                      ),
                                title: Text(device.label),
                              ),
                              onTap: () => controlVm.selectVideoInput(device),
                            );
                          }),
                      ];
                    },
                  )
                else
                  IconButton(
                    onPressed: controlVm.enableVideo,
                    icon: const Icon(Icons.videocam_off),
                    tooltip: 'un-mute video',
                  ),
                IconButton(
                  icon: Icon(
                    state.cameraPosition == CameraPosition.back ? Icons.video_camera_back : Icons.video_camera_front,
                  ),
                  onPressed: controlVm.toggleCamera,
                  tooltip: 'toggle camera',
                ),
                if (state.isScreenShareEnabled)
                  IconButton(
                    icon: const Icon(Icons.monitor_outlined),
                    onPressed: controlVm.disableScreenShare,
                    tooltip: 'unshare screen (experimental)',
                  )
                else
                  IconButton(
                    icon: const Icon(Icons.monitor),
                    onPressed: controlVm.enableScreenShare,
                    tooltip: 'share screen (experimental)',
                  ),
                IconButton(
                  onPressed: handleDisconnectClick,
                  icon: const Icon(Icons.close_sharp),
                  tooltip: 'disconnect',
                ),
              ],
            )
          : const Center(
            child: CircularProgressIndicator(),
          )
    );
  }
}

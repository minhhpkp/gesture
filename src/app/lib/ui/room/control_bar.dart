import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background/flutter_background.dart';
import 'package:gesture/di/providers.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

class ControlBar extends ConsumerStatefulWidget {
  const ControlBar({super.key});

  @override
  ConsumerState<ControlBar> createState() => _ControlBarState();
}

class _ControlBarState extends ConsumerState<ControlBar> {
  late final Room _room;
  late final LocalParticipant _participant;

  bool _isSigning = false;

  CameraPosition position = CameraPosition.front;

  List<MediaDevice>? _audioInputs;
  List<MediaDevice>? _audioOutputs;
  List<MediaDevice>? _videoInputs;

  StreamSubscription? _subscription;

  bool _speakerphoneOn = Hardware.instance.speakerOn ?? false;

  @override
  void initState() {
    super.initState();
    final roomRepository = ref.read(roomRepositoryProvider);
    _room = roomRepository.room!;
    _participant = _room.localParticipant!;

    _participant.addListener(_onChange);
    _subscription = Hardware.instance.onDeviceChange.stream.listen((List<MediaDevice> devices) {
      _loadDevices(devices);
    });
    unawaited(Hardware.instance.enumerateDevices().then(_loadDevices));
  }

  @override
  void dispose() {
    unawaited(_subscription?.cancel());
    _participant.removeListener(_onChange);
    super.dispose();
  }

  void _loadDevices(List<MediaDevice> devices) async {
    _audioInputs = devices.where((d) => d.kind == 'audioinput').toList();
    _audioOutputs = devices.where((d) => d.kind == 'audiooutput').toList();
    _videoInputs = devices.where((d) => d.kind == 'videoinput').toList();
    setState(() {});
  }

  void _onChange() {
    // trigger refresh
    setState(() {});
  }

  void _toggleSignRecognitionMode() async {
    await _participant.publishData(
      _isSigning ? ascii.encode('stop') : ascii.encode('start'),
      reliable: true,
      destinationIdentities: ['moderator'],
      topic: 'sign',
    );
    setState(() {
      _isSigning = !_isSigning;
    });
  }

  bool get isMuted => _participant.isMuted;

  void _disableAudio() async {
    await _participant.setMicrophoneEnabled(false);
  }

  Future<void> _enableAudio() async {
    await _participant.setMicrophoneEnabled(true);
  }

  void _disableVideo() async {
    await _participant.setCameraEnabled(false);
  }

  void _enableVideo() async {
    await _participant.setCameraEnabled(true);
  }

  void _selectAudioOutput(MediaDevice device) async {
    await _room.setAudioOutputDevice(device);
    setState(() {});
  }

  void _selectAudioInput(MediaDevice device) async {
    await _room.setAudioInputDevice(device);
    setState(() {});
  }

  void _selectVideoInput(MediaDevice device) async {
    await _room.setVideoInputDevice(device);
    setState(() {});
  }

  void _setSpeakerphoneOn() async {
    _speakerphoneOn = !_speakerphoneOn;
    await _room.setSpeakerOn(_speakerphoneOn, forceSpeakerOutput: false);
    setState(() {});
  }

  void _toggleCamera() async {
    final track = _participant.videoTrackPublications.firstOrNull?.track;
    if (track == null) return;

    try {
      final newPosition = position.switched();
      await track.setCameraPosition(newPosition);
      setState(() {
        position = newPosition;
      });
    } catch (error) {
      print('could not restart track: $error');
      return;
    }
  }

  void _enableScreenShare() async {
    if (lkPlatformIsDesktop()) {
      try {
        final source = await showDialog<DesktopCapturerSource>(
          context: context,
          builder: (context) => ScreenSelectDialog(),
        );
        if (source == null) {
          print('cancelled screenshare');
          return;
        }
        print('DesktopCapturerSource: ${source.id}');
        final track = await LocalVideoTrack.createScreenShareTrack(
          ScreenShareCaptureOptions(
            sourceId: source.id,
            maxFrameRate: 15.0,
          ),
        );
        await _participant.publishVideoTrack(track);
      } catch (e) {
        print('could not publish video: $e');
      }
      return;
    }
    if (lkPlatformIs(PlatformType.android)) {
      // Android specific
      final hasCapturePermission = await Helper.requestCapturePermission();
      if (!hasCapturePermission) {
        return;
      }

      requestBackgroundPermission([bool isRetry = false]) async {
        // Required for android screenshare.
        try {
          bool hasPermissions = await FlutterBackground.hasPermissions;
          if (!isRetry) {
            const androidConfig = FlutterBackgroundAndroidConfig(
              notificationTitle: 'Screen Sharing',
              notificationText: 'LiveKit Example is sharing the screen.',
              notificationImportance: AndroidNotificationImportance.normal,
              notificationIcon: AndroidResource(name: 'livekit_ic_launcher', defType: 'mipmap'),
            );
            hasPermissions = await FlutterBackground.initialize(androidConfig: androidConfig);
          }
          if (hasPermissions && !FlutterBackground.isBackgroundExecutionEnabled) {
            await FlutterBackground.enableBackgroundExecution();
          }
        } catch (e) {
          if (!isRetry) {
            return await Future<void>.delayed(const Duration(seconds: 1), () => requestBackgroundPermission(true));
          }
          print('could not publish video: $e');
        }
      }

      await requestBackgroundPermission();
    }

    if (lkPlatformIsWebMobile()) {
      if (!mounted) return;
      await _showErrorDialog('Screen share is not supported on mobile web');
      return;
    }
    await _participant.setScreenShareEnabled(true, captureScreenAudio: true);
  }

  void _disableScreenShare() async {
    await _participant.setScreenShareEnabled(false);
    if (lkPlatformIs(PlatformType.android)) {
      // Android specific
      try {
        //   await FlutterBackground.disableBackgroundExecution();
      } catch (error) {
        print('error disabling screen share: $error');
      }
    }
  }

  void _onTapDisconnect() async {
    final result = await _showDisconnectDialog();
    if (result == true) await _room.disconnect();
  }

  Future<bool?> _showDisconnectDialog() => showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Disconnect'),
      content: const Text('Are you sure to disconnect?'),
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

  Future<void> _showErrorDialog(dynamic exception) => showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Error'),
      content: Text(exception.toString()),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('OK'),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 15,
        horizontal: 15,
      ),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 5,
        runSpacing: 5,
        children: [
          IconButton(icon: Icon(_isSigning ? Icons.stop : Icons.play_arrow), onPressed: _toggleSignRecognitionMode),
          if (_participant.isMicrophoneEnabled())
            if (lkPlatformIs(PlatformType.android))
              IconButton(
                onPressed: _disableAudio,
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
                      onTap: isMuted ? _enableAudio : _disableAudio,
                      child: const ListTile(
                        leading: Icon(
                          Icons.mic_off,
                          color: Colors.white,
                        ),
                        title: Text('Mute Microphone'),
                      ),
                    ),
                    if (_audioInputs != null)
                      ..._audioInputs!.map((device) {
                        return PopupMenuItem<MediaDevice>(
                          value: device,
                          child: ListTile(
                            leading: (device.deviceId == _room.selectedAudioInputDeviceId)
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
                          onTap: () => _selectAudioInput(device),
                        );
                      }),
                  ];
                },
              )
          else
            IconButton(
              onPressed: _enableAudio,
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
                  if (_audioOutputs != null)
                    ..._audioOutputs!.map((device) {
                      return PopupMenuItem<MediaDevice>(
                        value: device,
                        child: ListTile(
                          leading: (device.deviceId == _room.selectedAudioOutputDeviceId)
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
                        onTap: () => _selectAudioOutput(device),
                      );
                    }),
                ];
              },
            ),
          if (!kIsWeb && lkPlatformIsMobile())
            IconButton(
              disabledColor: Colors.grey,
              onPressed: _setSpeakerphoneOn,
              icon: Icon(_speakerphoneOn ? Icons.speaker_phone : Icons.phone_android),
              tooltip: 'Switch SpeakerPhone',
            ),
          if (_participant.isCameraEnabled())
            PopupMenuButton<MediaDevice>(
              icon: const Icon(Icons.videocam_sharp),
              itemBuilder: (BuildContext context) {
                return [
                  PopupMenuItem<MediaDevice>(
                    value: null,
                    onTap: _disableVideo,
                    child: const ListTile(
                      leading: Icon(
                        Icons.videocam_off,
                        color: Colors.white,
                      ),
                      title: Text('Disable Camera'),
                    ),
                  ),
                  if (_videoInputs != null)
                    ..._videoInputs!.map((device) {
                      return PopupMenuItem<MediaDevice>(
                        value: device,
                        child: ListTile(
                          leading: (device.deviceId == _room.selectedVideoInputDeviceId)
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
                        onTap: () => _selectVideoInput(device),
                      );
                    }),
                ];
              },
            )
          else
            IconButton(
              onPressed: _enableVideo,
              icon: const Icon(Icons.videocam_off),
              tooltip: 'un-mute video',
            ),
          IconButton(
            icon: Icon(position == CameraPosition.back ? Icons.video_camera_back : Icons.video_camera_front),
            onPressed: () => _toggleCamera(),
            tooltip: 'toggle camera',
          ),
          if (_participant.isScreenShareEnabled())
            IconButton(
              icon: const Icon(Icons.monitor_outlined),
              onPressed: () => _disableScreenShare(),
              tooltip: 'unshare screen (experimental)',
            )
          else
            IconButton(
              icon: const Icon(Icons.monitor),
              onPressed: () => _enableScreenShare(),
              tooltip: 'share screen (experimental)',
            ),
          IconButton(
            onPressed: _onTapDisconnect,
            icon: const Icon(Icons.close_sharp),
            tooltip: 'disconnect',
          ),
        ],
      ),
    );
  }
}

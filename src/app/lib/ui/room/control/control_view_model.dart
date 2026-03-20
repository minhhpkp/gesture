import 'dart:async';

import 'package:flutter_background/flutter_background.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:gesture/di/providers.dart';
import 'package:gesture/ui/room/control/control_state.dart';
import 'package:gesture/utils/convert_stream.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:rxdart/rxdart.dart';

class ControlViewModel extends StreamNotifier<ControlState> {
  late Room _room;
  late LocalParticipant _localParticipant;

  late BehaviorSubject<bool> _speakerphoneStateChanges;
  late BehaviorSubject<CameraPosition> _cameraPositionChanges;
  late BehaviorSubject<bool> _desktopScreenShareNotificationDisplayChanges;
  late BehaviorSubject<bool> _screenScreenUnavailableNotificationDisplayChanges;

  @override
  Stream<ControlState> build() {
    final roomRepository = ref.read(roomRepositoryProvider);
    _room = roomRepository.room!;
    _localParticipant = _room.localParticipant!;
    final roomStream = roomRepository.roomStream;
    final localParticipantStream = roomRepository.localParticipantStream;
    final devicesStream = streamWithInitialValue(
      getCurrent: Hardware.instance.enumerateDevices,
      broadcastStream: Hardware.instance.onDeviceChange.stream,
    );
    _speakerphoneStateChanges = BehaviorSubject.seeded(Hardware.instance.speakerOn ?? false);
    ref.onDispose(_speakerphoneStateChanges.close);
    _cameraPositionChanges = BehaviorSubject.seeded(CameraPosition.front);
    ref.onDispose(_cameraPositionChanges.close);
    _desktopScreenShareNotificationDisplayChanges = BehaviorSubject.seeded(false);
    ref.onDispose(_desktopScreenShareNotificationDisplayChanges.close);
    _screenScreenUnavailableNotificationDisplayChanges = BehaviorSubject.seeded(false);
    ref.onDispose(_screenScreenUnavailableNotificationDisplayChanges.close);

    // combine all state streams into a single one because the view should be
    // in loading state until each and every one of these streams emit its first value
    return CombineLatestStream.combine7(
      roomStream,
      localParticipantStream,
      devicesStream,
      _speakerphoneStateChanges.stream,
      _cameraPositionChanges.stream,
      _desktopScreenShareNotificationDisplayChanges.stream,
      _screenScreenUnavailableNotificationDisplayChanges.stream,
      (
        room,
        localParticipant,
        devices,
        isSpeakerphoneOn,
        cameraPosition,
        shouldNotifyScreenShare,
        shouldNotifyScreenShareUnavailable,
      ) {
        final audioInputs = devices.where((d) => d.kind == 'audioinput').toList();
        final audioOutputs = devices.where((d) => d.kind == 'audiooutput').toList();
        final videoInputs = devices.where((d) => d.kind == 'videoinput').toList();
        return ControlState(
          audioInputs: audioInputs,
          audioOutputs: audioOutputs,
          videoInputs: videoInputs,
          selectedAudioInputDeviceId: room.selectedAudioInputDeviceId,
          selectedAudioOutputDeviceId: room.selectedAudioOutputDeviceId,
          selectedVideoInputDeviceId: room.selectedVideoInputDeviceId,
          cameraPosition: cameraPosition,
          isSpeakerphoneOn: isSpeakerphoneOn,
          isMicrophoneEnabled: localParticipant.isMicrophoneEnabled(),
          isCameraEnabled: localParticipant.isCameraEnabled(),
          isScreenShareEnabled: localParticipant.isScreenShareEnabled(),
          isMuted: localParticipant.isMuted,
          shouldNotifyScreenShare: shouldNotifyScreenShare,
          shouldNotifyScreenShareUnavailable: shouldNotifyScreenShareUnavailable,
        );
      },
    );
  }

  Future<void> disableAudio() async {
    await _localParticipant.setMicrophoneEnabled(false);
  }

  Future<void> enableAudio() async {
    await _localParticipant.setMicrophoneEnabled(true);
  }

  Future<void> disableVideo() async {
    await _localParticipant.setCameraEnabled(false);
  }

  Future<void> enableVideo() async {
    await _localParticipant.setCameraEnabled(true);
  }

  Future<void> selectAudioOutput(MediaDevice device) async {
    await _room.setAudioOutputDevice(device);
  }

  Future<void> selectAudioInput(MediaDevice device) async {
    await _room.setAudioInputDevice(device);
  }

  Future<void> selectVideoInput(MediaDevice device) async {
    await _room.setVideoInputDevice(device);
  }

  Future<void> setSpeakerphoneOn() async {
    final value = !_speakerphoneStateChanges.value;
    _speakerphoneStateChanges.add(value);
    await _room.setSpeakerOn(value, forceSpeakerOutput: false);
  }

  Future<void> toggleCamera() async {
    final track = _localParticipant.videoTrackPublications.firstOrNull?.track;
    if (track == null) return;

    try {
      final newPosition = _cameraPositionChanges.value.switched();
      await track.setCameraPosition(newPosition);
      _cameraPositionChanges.add(newPosition);
    } catch (error) {
      print('could not restart track: $error');
      return;
    }
  }

  Future<bool> _requestBackgroundPermission([bool isRetry = false]) async {
    // Required for android screenshare.
    try {
      bool hasPermissions = await FlutterBackground.hasPermissions;
      if (!isRetry) {
        const androidConfig = FlutterBackgroundAndroidConfig(
          notificationTitle: 'Screen Sharing',
          notificationText: 'Gesture is sharing the screen.',
          notificationImportance: AndroidNotificationImportance.normal,
          notificationIcon: AndroidResource(name: 'ic_launcher', defType: 'mipmap'),
        );
        hasPermissions = await FlutterBackground.initialize(androidConfig: androidConfig);
      }
      if (hasPermissions && !FlutterBackground.isBackgroundExecutionEnabled) {
        return await FlutterBackground.enableBackgroundExecution();
      }
    } catch (e) {
      if (!isRetry) {
        await Future<void>.delayed(const Duration(seconds: 1));
        return await _requestBackgroundPermission(true);
      }
      print('could not publish video: $e');
    }
    return false;
  }

  Future<void> enableScreenShare() async {
    if (lkPlatformIsDesktop()) {
      if (!_desktopScreenShareNotificationDisplayChanges.isClosed) {
        _desktopScreenShareNotificationDisplayChanges.add(true);
      }
    } else if (lkPlatformIs(PlatformType.android)) {
      // Android specific
      final hasCapturePermission = await Helper.requestCapturePermission();
      if (!hasCapturePermission) {
        return;
      }

      final hasBackgroundPermission = await _requestBackgroundPermission();
      if (hasBackgroundPermission) {
        await _localParticipant.setScreenShareEnabled(true, captureScreenAudio: true);
      }
    } else if (lkPlatformIsWebMobile()) {
      if (!_screenScreenUnavailableNotificationDisplayChanges.isClosed) {
        _screenScreenUnavailableNotificationDisplayChanges.add(true);
      }
    }
  }

  Future<void> setDesktopCapturerSource(DesktopCapturerSource source) async {
    try {
      print('DesktopCapturerSource: ${source.id}');
      final track = await LocalVideoTrack.createScreenShareTrack(
        ScreenShareCaptureOptions(
          sourceId: source.id,
          maxFrameRate: 15.0,
        ),
      );
      await _localParticipant.publishVideoTrack(track);
      await _localParticipant.setScreenShareEnabled(true, captureScreenAudio: true);
    } catch (e) {
      print('could not publish video: $e');
    }
  }

  void screenShareNotified() {
    if (!_desktopScreenShareNotificationDisplayChanges.isClosed) {
      _desktopScreenShareNotificationDisplayChanges.add(false);
    }
  }

  Future<void> disableScreenShare() async {
    await _localParticipant.setScreenShareEnabled(false);
  }

  void screenShareUnavailableNotified() {
    if (!_screenScreenUnavailableNotificationDisplayChanges.isClosed) {
      _screenScreenUnavailableNotificationDisplayChanges.add(false);
    }
  }

  Future<void> disconnect() async {
    await _room.disconnect();
  }
}

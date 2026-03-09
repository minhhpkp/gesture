import 'dart:async';

import 'package:gesture/data/repositories/room/room_repository.dart';
import 'package:gesture/di/providers.dart';
import 'package:gesture/ui/prejoin/prejoin_state.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:riverpod/riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PrejoinViewModel extends AsyncNotifier<PrejoinState> {
  static const _prefKeyVideoEnabled = 'prejoin-video-enabled';
  static const _prefKeyAudioEnabled = 'prejoin-audio-enabled';

  late final RoomRepository _roomRepository;

  @override
  Future<PrejoinState> build() async {
    if (lkPlatformIs(PlatformType.android)) {
      await _checkPermissions();
    }

    final prefs = await SharedPreferences.getInstance();
    final isVideoEnabled = prefs.getBool(_prefKeyVideoEnabled) ?? true;
    final isAudioEnabled = prefs.getBool(_prefKeyAudioEnabled) ?? true;

    _roomRepository = ref.read(roomRepositoryProvider);
    final subscription = Hardware.instance.onDeviceChange.stream.listen(_loadDevices);
    ref.onDispose(() {
      unawaited(subscription.cancel());
    });

    return await _loadInitialDevices(isVideoEnabled, isAudioEnabled);
  }

  Future<void> _checkPermissions() async {
    var status = await Permission.bluetooth.request();
    if (status.isPermanentlyDenied) {
      print('Bluetooth Permission disabled');
    }

    status = await Permission.bluetoothConnect.request();
    if (status.isPermanentlyDenied) {
      print('Bluetooth Connect Permission disabled');
    }

    status = await Permission.camera.request();
    if (status.isPermanentlyDenied) {
      print('Camera Permission disabled');
    }

    status = await Permission.microphone.request();
    if (status.isPermanentlyDenied) {
      print('Microphone Permission disabled');
    }
  }

  Future<PrejoinState> _loadInitialDevices(bool isVideoEnabled, bool isAudioEnabled) async {
    final devices = await Hardware.instance.enumerateDevices();
    final audioInputs = devices.where((d) => d.kind == 'audioinput').toList();
    final videoInputs = devices.where((d) => d.kind == 'videoinput').toList();

    MediaDevice? selectedAudioDevice;
    if (isAudioEnabled && audioInputs.isNotEmpty) {
      selectedAudioDevice = audioInputs.first;
    }

    MediaDevice? selectedVideoDevice;
    LocalVideoTrack? videoTrack;
    final selectedVideoParameters = VideoParametersPresets.h720_169;
    if (isVideoEnabled && videoInputs.isNotEmpty) {
      selectedVideoDevice = videoInputs.first;
      await Future.delayed(const Duration(milliseconds: 100));
      videoTrack = await LocalVideoTrack.createCameraTrack(
        CameraCaptureOptions(
          deviceId: selectedVideoDevice.deviceId,
          params: selectedVideoParameters,
        ),
      );
      await videoTrack.start();
    }

    return PrejoinState(
      audioInputs: audioInputs,
      videoInputs: videoInputs,
      isAudioEnabled: isAudioEnabled,
      isVideoEnabled: isVideoEnabled,
      selectedAudioDevice: selectedAudioDevice,
      selectedVideoDevice: selectedVideoDevice,
      videoTrack: videoTrack,
      selectedVideoParameters: selectedVideoParameters,
    );
  }

  Future<void> _loadDevices(List<MediaDevice> devices) async {
    final audioInputs = devices.where((d) => d.kind == 'audioinput').toList();
    final videoInputs = devices.where((d) => d.kind == 'videoinput').toList();

    final current = state.value;
    // build() hasn't finished
    if (current == null) return;

    var selectedAudioDevice = current.selectedAudioDevice;
    if (selectedAudioDevice != null && !audioInputs.contains(selectedAudioDevice)) {
      selectedAudioDevice = null;
    }

    var selectedVideoDevice = current.selectedVideoDevice;
    if (selectedVideoDevice != null && !videoInputs.contains(selectedVideoDevice)) {
      selectedVideoDevice = null;
    }
    var videoTrack = current.videoTrack;
    if (videoInputs.isEmpty) {
      await videoTrack?.stop();
      videoTrack = null;
    }

    if (current.isAudioEnabled && audioInputs.isNotEmpty) {
      selectedAudioDevice ??= audioInputs.first;
    }

    if (current.isVideoEnabled && videoInputs.isNotEmpty) {
      if (selectedVideoDevice == null) {
        selectedVideoDevice = videoInputs.first;
        Future.delayed(const Duration(milliseconds: 100), () async {
          if (!ref.mounted) return;
          await _changeLocalVideoTrack();
        });
      }
    }

    if (ref.mounted) {
      state = AsyncData(
        current.copyWith(
          audioInputs: audioInputs,
          videoInputs: videoInputs,
          selectedAudioDevice: selectedAudioDevice,
          selectedVideoDevice: selectedVideoDevice,
          videoTrack: videoTrack,
        ),
      );
    }
  }

  Future<void> _changeLocalVideoTrack() async {
    final current = state.value;
    if (current == null) return;

    var videoTrack = current.videoTrack;
    if (videoTrack != null) {
      await videoTrack.stop();
      videoTrack = null;
    }

    final selectedVideoDevice = current.selectedVideoDevice;
    if (selectedVideoDevice != null) {
      videoTrack = await LocalVideoTrack.createCameraTrack(
        CameraCaptureOptions(
          deviceId: selectedVideoDevice.deviceId,
          params: current.selectedVideoParameters,
        ),
      );
      await videoTrack.start();
    }

    state = AsyncData(current.copyWith(videoTrack: videoTrack));
  }

  Future<void> toggleEnablingVideo(bool value) async {
    final current = state.value;
    if (current == null) return;

    if (!value) {
      await current.videoTrack?.stop();
      state = AsyncData(
        current.copyWith(
          isVideoEnabled: value,
          selectedVideoDevice: null,
          videoTrack: null,
        ),
      );
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefKeyVideoEnabled, value);
    } else {
      if (current.selectedVideoDevice == null && current.videoInputs.isNotEmpty) {
        state = AsyncData(
          current.copyWith(
            isVideoEnabled: value,
            selectedVideoDevice: current.videoInputs.first,
          ),
        );
      }
      await _changeLocalVideoTrack();
    }
  }

  void setSelectedVideoDevice(MediaDevice device) async {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(current.copyWith(selectedVideoDevice: device));
    await _changeLocalVideoTrack();
  }

  void setSelectedVideoParameters(VideoParameters params) async {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(current.copyWith(selectedVideoParameters: params));
    await _changeLocalVideoTrack();
  }

  Future<void> toggleEnablingAudio(bool value) async {
    final current = state.value;
    if (current == null) return;

    if (!value) {
      state = AsyncData(
        current.copyWith(
          isAudioEnabled: value,
          selectedAudioDevice: null,
        ),
      );
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefKeyAudioEnabled, value);
    } else {
      if (current.selectedAudioDevice == null && current.audioInputs.isNotEmpty) {
        state = AsyncData(
          current.copyWith(
            isAudioEnabled: value,
            selectedAudioDevice: current.audioInputs.first,
          ),
        );
      }
    }
  }

  void setSelectedAudioDevice(MediaDevice device) {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(current.copyWith(selectedAudioDevice: device));
  }

  Future<void> join() async {
    if (state.isLoading) return;
    final current = state.value;
    if (current == null || current.isLoading) return;
    state = AsyncData(current.copyWith(isJoinSuccess: null, isLoading: true));

    try {
      await _roomRepository.createRoomAndListener();

      final audioTrack = await _createAudioTrack();

      await _roomRepository.connect(audioTrack, current.videoTrack);

      if (ref.mounted) {
        state = AsyncData(current.copyWith(isJoinSuccess: true, isLoading: false));
      }
    } catch (e) {
      print('Could not connect: $e');
      if (ref.mounted) {
        state = AsyncData(current.copyWith(isJoinSuccess: false, isLoading: false));
      }
    }
  }

  Future<LocalAudioTrack?> _createAudioTrack() async {
    LocalAudioTrack? audioTrack;
    final selectedAudioDevice = state.value?.selectedAudioDevice;
    if (state.value?.isAudioEnabled == true && selectedAudioDevice != null) {
      audioTrack = await LocalAudioTrack.create(
        AudioCaptureOptions(
          deviceId: selectedAudioDevice.deviceId,
        ),
      );
      await audioTrack.start();
    }
    return audioTrack;
  }
}

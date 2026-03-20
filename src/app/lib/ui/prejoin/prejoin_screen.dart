import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:gesture/di/providers.dart';
import 'package:gesture/routing/routes.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:dropdown_button2/dropdown_button2.dart';

class PrejoinScreen extends ConsumerWidget {
  const PrejoinScreen({super.key});

  void _actionBack(BuildContext context) {
    context.pop();
  }

  Future<void> _showFailureDialog(BuildContext context) => showDialog<void>(
    context: context,
    barrierDismissible: false, // user must tap button!
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('Failure'),
        content: const SingleChildScrollView(
          child: ListBody(
            children: <Widget>[
              Text('Unable to join the room.'),
              Text('Please try again.'),
            ],
          ),
        ),
        actions: <Widget>[
          TextButton(
            child: const Text('OK'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      );
    },
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(prejoinViewModelProvider);
    final stateValue = state.value;
    final vm = ref.read(prejoinViewModelProvider.notifier);

    ref.listen(prejoinViewModelProvider, (previous, next) {
      if (previous?.value?.isJoinSuccess == null) {
        if (next.value?.isJoinSuccess == true) {
          context.go(Routes.room);
        } else if (next.value?.isJoinSuccess == false) {
          unawaited(_showFailureDialog(context));
        }
      }
    });

    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            title: const Text('Select Devices'),
            leading: IconButton(onPressed: () => _actionBack(context), icon: const Icon(Icons.arrow_back)),
          ),
          body: stateValue != null
              ? Container(
                  alignment: Alignment.center,
                  child: SingleChildScrollView(
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: SizedBox(
                              width: 320,
                              height: 240,
                              child: Container(
                                alignment: Alignment.center,
                                color: Colors.black54,
                                child: stateValue.videoTrack != null
                                    ? VideoTrackRenderer(
                                        stateValue.videoTrack!,
                                        renderMode: VideoRenderMode.auto,
                                      )
                                    : Container(
                                        alignment: Alignment.center,
                                        child: LayoutBuilder(
                                          builder: (ctx, constraints) => Icon(
                                            Icons.videocam_off,
                                            color: Colors.blue,
                                            size: min(constraints.maxHeight, constraints.maxWidth) * 0.3,
                                          ),
                                        ),
                                      ),
                              ),
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Camera:'),
                              Switch(
                                value: stateValue.isVideoEnabled,
                                onChanged: (isEnabled) => vm.toggleEnablingVideo(isEnabled),
                              ),
                            ],
                          ),
                          SizedBox(height: 5),
                          DropdownButtonHideUnderline(
                            child: DropdownButton2<MediaDevice>(
                              isExpanded: true,
                              disabledHint: const Text('Camera Disabled'),
                              hint: const Text('Select Camera'),
                              items: stateValue.isVideoEnabled
                                  ? stateValue.videoInputs
                                        .map(
                                          (MediaDevice item) => DropdownMenuItem(
                                            value: item,
                                            child: Text(
                                              item.label,
                                              style: const TextStyle(fontSize: 14),
                                            ),
                                          ),
                                        )
                                        .toList()
                                  : [],
                              value: stateValue.selectedVideoDevice,
                              onChanged: (MediaDevice? device) {
                                if (device != null) {
                                  vm.setSelectedVideoDevice(device);
                                }
                              },
                              buttonStyleData: const ButtonStyleData(
                                padding: EdgeInsets.symmetric(horizontal: 16),
                                height: 40,
                                width: 140,
                              ),
                              menuItemStyleData: const MenuItemStyleData(
                                padding: EdgeInsets.all(4),
                              ),
                            ),
                          ),
                          SizedBox(height: 25),
                          if (stateValue.isVideoEnabled)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 25),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton2<VideoParameters>(
                                  isExpanded: true,
                                  hint: const Text(
                                    'Select Video Dimensions',
                                  ),
                                  items:
                                      [
                                            VideoParametersPresets.h480_43,
                                            VideoParametersPresets.h540_169,
                                            VideoParametersPresets.h720_169,
                                            VideoParametersPresets.h1080_169,
                                          ]
                                          .map(
                                            (VideoParameters item) => DropdownMenuItem<VideoParameters>(
                                              value: item,
                                              child: Text(
                                                '${item.dimensions.width}x${item.dimensions.height}',
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ),
                                          )
                                          .toList(),
                                  value: stateValue.selectedVideoParameters,
                                  onChanged: (VideoParameters? params) async {
                                    if (params != null) {
                                      vm.setSelectedVideoParameters(params);
                                    }
                                  },
                                  buttonStyleData: const ButtonStyleData(
                                    padding: EdgeInsets.symmetric(horizontal: 16),
                                    height: 40,
                                    width: 140,
                                  ),
                                  menuItemStyleData: const MenuItemStyleData(
                                    padding: EdgeInsets.all(4),
                                  ),
                                ),
                              ),
                            ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Microphone:'),
                              Switch(
                                value: stateValue.isAudioEnabled,
                                onChanged: (value) => vm.toggleEnablingAudio(value),
                              ),
                            ],
                          ),
                          SizedBox(height: 5),
                          DropdownButtonHideUnderline(
                            child: DropdownButton2<MediaDevice>(
                              isExpanded: true,
                              disabledHint: const Text('Disable Microphone'),
                              hint: const Text(
                                'Select Microphone',
                              ),
                              items: stateValue.isAudioEnabled
                                  ? stateValue.audioInputs
                                        .map(
                                          (MediaDevice item) => DropdownMenuItem<MediaDevice>(
                                            value: item,
                                            child: Text(
                                              item.label,
                                              style: const TextStyle(
                                                fontSize: 14,
                                              ),
                                            ),
                                          ),
                                        )
                                        .toList()
                                  : [],
                              value: stateValue.selectedAudioDevice,
                              onChanged: (MediaDevice? device) async {
                                if (device != null) {
                                  vm.setSelectedAudioDevice(device);
                                }
                              },
                              buttonStyleData: const ButtonStyleData(
                                padding: EdgeInsets.symmetric(horizontal: 16),
                                height: 40,
                                width: 140,
                              ),
                              menuItemStyleData: const MenuItemStyleData(
                                padding: EdgeInsets.all(4),
                              ),
                            ),
                          ),
                          SizedBox(height: 25),
                          ElevatedButton(
                            onPressed: state.isLoading || stateValue.isLoading ? null : vm.join,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (state.isLoading || stateValue.isLoading)
                                  const Padding(
                                    padding: EdgeInsets.only(right: 10),
                                    child: SizedBox(
                                      height: 15,
                                      width: 15,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    ),
                                  ),
                                const Text('JOIN'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              : Container(),
        ),

        if (state.isLoading || stateValue?.isLoading == true)
          Container(
            color: Colors.black54,
            child: Center(child: CircularProgressIndicator()),
          ),
      ],
    );
  }
}

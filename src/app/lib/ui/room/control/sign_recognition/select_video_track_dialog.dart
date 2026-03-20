import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:gesture/di/providers.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:livekit_client/livekit_client.dart';

class SelectVideoTrackDialog extends ConsumerWidget {
  const SelectVideoTrackDialog({
    super.key,
    required void Function()? onCancelPressed,
    required void Function()? onStartPressed,
  }) : _onCancelPressed = onCancelPressed,
       _onStartPressed = onStartPressed;

  final void Function()? _onCancelPressed;
  final void Function()? _onStartPressed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tracksAsyncState = ref.watch(localVideoPublicationsStreamProvider);
    final signRecogState = ref.watch(signRecognitionNotifierProvider);
    final vm = ref.read(signRecognitionNotifierProvider.notifier);

    return AlertDialog(
      title: const Text('Select video track'),
      content: SingleChildScrollView(
        child: ListBody(
          children: [
            const Text('Which track would you like to use for sign recognition?'),
            tracksAsyncState.when(
              data: (publications) => DropdownButtonHideUnderline(
                child: DropdownButton2<LocalTrackPublication<LocalVideoTrack>>(
                  isExpanded: true,
                  hint: const Text('Select video track'),
                  items: publications
                      .map(
                        (pub) => DropdownMenuItem(
                          value: pub,
                          child: Text(
                            pub.name,
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                      )
                      .toList(),
                  value: signRecogState.selectedVideoPublication,
                  onChanged: (LocalTrackPublication<LocalVideoTrack>? videoPublication) {
                    if (videoPublication != null) {
                      vm.setSelectedVideoPublication(videoPublication);
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
              error: (e, st) {
                print('video track publications stream error: $e');
                return const Text(
                  'An error occurred',
                  style: TextStyle(color: Colors.red),
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: _onCancelPressed, child: const Text('Cancel')),
        if (signRecogState.selectedVideoPublication != null)
          TextButton(onPressed: _onStartPressed, child: const Text('Start')),
      ],
    );
  }
}

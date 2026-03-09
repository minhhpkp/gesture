import 'package:flutter/material.dart';
import 'package:livekit_client/livekit_client.dart';
import 'dart:async';

class SoundWaveform extends StatefulWidget {
  final int barCount;
  final double width;
  final double minHeight;
  final double maxHeight;
  final int durationInMilliseconds;

  final AudioTrack audioTrack;

  const SoundWaveform({
    super.key,
    required this.audioTrack,
    this.barCount = 5,
    this.width = 5,
    this.minHeight = 8,
    this.maxHeight = 100,
    this.durationInMilliseconds = 500,
  });

  @override
  State<SoundWaveform> createState() => _SoundWaveformState();
}

class _SoundWaveformState extends State<SoundWaveform> with TickerProviderStateMixin {
  late AnimationController controller;
  late List<double> samples;
  AudioVisualizer? _visualizer;
  EventsListener<AudioVisualizerEvent>? _listener;

  Future<void> _startVisualizer(AudioTrack track) async {
    samples = List.filled(widget.barCount, 0);
    _visualizer ??= createVisualizer(track, options: AudioVisualizerOptions(barCount: widget.barCount));
    _listener ??= _visualizer?.createListener();
    _listener?.on<AudioVisualizerEvent>((e) {
      if (mounted) {
        setState(() {
          samples = e.event.map((e) => ((e as num) * 100).toDouble()).toList();
        });
      }
    });

    await _visualizer!.start();
  }

  void _stopVisualizer(AudioTrack track) async {
    await _visualizer?.stop();
    await _visualizer?.dispose();
    _visualizer = null;
    await _listener?.dispose();
    _listener = null;
  }

  @override
  void initState() {
    super.initState();

    unawaited(_startVisualizer(widget.audioTrack));

    controller = AnimationController(
      vsync: this,
      duration: Duration(
        milliseconds: widget.durationInMilliseconds,
      ),
    )..repeat(); // ignore: discarded_futures
  }

  @override
  void dispose() {
    controller.dispose();
    _stopVisualizer(widget.audioTrack);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final count = widget.barCount;
    final minHeight = widget.minHeight;
    final maxHeight = widget.maxHeight;
    return AnimatedBuilder(
      animation: controller,
      builder: (c, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(
            count,
            (i) => AnimatedContainer(
              duration: Duration(milliseconds: widget.durationInMilliseconds ~/ count),
              margin: i == (samples.length - 1) ? EdgeInsets.zero : const EdgeInsets.only(right: 5),
              height: samples[i] < minHeight
                  ? minHeight
                  : samples[i] > maxHeight
                  ? maxHeight
                  : samples[i],
              width: widget.width,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(9999),
              ),
            ),
          ),
        );
      },
    );
  }
}

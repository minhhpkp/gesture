import 'dart:async';

/// Creates a single-subscription stream that immediately emits the current value
/// (fetched via [getCurrent]), then continues emitting updates from [broadcastStream].
///
/// - [getCurrent]: async function to fetch the latest value immediately on listen
/// - [broadcastStream]: broadcast stream that emits subsequent updates
Stream<T> streamWithInitialValue<T>({
  required Future<T> Function() getCurrent,
  required Stream<T> broadcastStream,
}) {
  late StreamController<T> controller;

  controller = StreamController<T>(
    onListen: () async {
      // --- STEP 1: Subscribe to the broadcast stream and start buffering ---
      // We subscribe BEFORE calling getCurrent() so we don't miss any events
      // that fire during the async gap.
      final buffer = <({T value, DateTime timestamp})>[];
      bool isBuffering = true;

      final broadcastSubscription = broadcastStream.listen(
        (data) {
          if (isBuffering) {
            buffer.add((value: data, timestamp: DateTime.now()));
          } else {
            controller.add(data);
          }
        },
        onError: (Object e, StackTrace st) => controller.addError(e, st),
        onDone: () => controller.close(),
      );

      // --- STEP 2: Fetch the current value ---
      // During this await, any broadcast events go into the buffer above.
      final T initialValue;
      try {
        initialValue = await getCurrent();
        if (!controller.isClosed) {
          controller.add(initialValue);
        }
      } catch (e, st) {
        if (!controller.isClosed) {
          controller.addError(e, st);
        }
      }

      // --- STEP 3: Drain the buffer, discarding stale events ---
      // Record when getCurrent() resolved. Any buffered event timestamped
      // before this moment is already captured in initialValue, so we
      // discard it. Only events timestamped after this are new changes
      // that the subscriber hasn't seen yet.
      final resolvedAt = DateTime.now();

      isBuffering = false;
      for (final entry in buffer) {
        if (entry.timestamp.isAfter(resolvedAt) && !controller.isClosed) {
          controller.add(entry.value);
        }
      }
      buffer.clear();

      // --- STEP 4: Wire up lifecycle to the broadcast subscription ---
      controller
        ..onPause = broadcastSubscription.pause
        ..onResume = broadcastSubscription.resume
        ..onCancel = broadcastSubscription.cancel;
    },
  );

  return controller.stream;
}

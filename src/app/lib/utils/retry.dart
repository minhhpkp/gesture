Future<bool> retryUntilTrue({
  required Future<bool> Function() action,
  int maxAttempts = 3,
  Duration delay = const Duration(seconds: 3),
}) async {
  for (int attempt = 1; attempt <= maxAttempts; attempt++) {
    final success = await action();

    if (success) {
      return true;
    }

    // Avoid waiting after the last failed attempt
    if (attempt < maxAttempts) {
      await Future.delayed(delay);
    }
  }

  return false;
}
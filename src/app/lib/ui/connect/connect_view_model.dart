import 'dart:async';

import 'package:dio/dio.dart';
import 'package:gesture/data/repositories/join_token/join_token_repository.dart';
import 'package:gesture/di/providers.dart';
import 'package:riverpod/riverpod.dart';

class ConnectViewModel extends Notifier<AsyncValue<void>?> {
  late final JoinTokenRepository _joinTokenRepository;

  CancelToken? _cancelToken;

  @override
  AsyncValue<void>? build() {
    _joinTokenRepository = ref.read(joinTokenRepositoryProvider);
    ref.onDispose(() {
      if (_cancelToken?.isCancelled == false) {
        _cancelToken?.cancel();
      }
    });
    return null;
  }

  Future<void> createJoinToken({required String username, required String roomId}) async {
    if (state?.isLoading == true) return;

    _cancelToken = CancelToken();
    state = AsyncLoading();
    try {
      final res = await AsyncValue.guard(
        () => _joinTokenRepository.createJoinToken(username: username, roomId: roomId, cancelToken: _cancelToken),
        (err) => !(err is DioException && CancelToken.isCancel(err)),
      );
      state = res;
      if (res.hasError) print('Connect error: ${res.error}');
    } on DioException {
      // must be cancel exception, we don't update the state
      return;
    }
  }
}

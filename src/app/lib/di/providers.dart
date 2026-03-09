import 'package:gesture/data/repositories/join_token/join_token_repository.dart';
import 'package:gesture/data/repositories/room/room_repository.dart';
import 'package:gesture/data/services/api/api_client.dart';
import 'package:gesture/ui/connect/connect_view_model.dart';
import 'package:gesture/ui/prejoin/prejoin_view_model.dart';
import 'package:gesture/ui/room/room_view_model.dart';
import 'package:riverpod/riverpod.dart';

final apiClientProvider = Provider((ref) {
  const baseUrl = String.fromEnvironment('API_URL');
  print('baseUrl: $baseUrl');
  return ApiClient(baseUrl: baseUrl);
});

final joinTokenRepositoryProvider = Provider((ref) {
  final apiClient = ref.read(apiClientProvider);
  return JoinTokenRepository(apiClient: apiClient);
});

final roomRepositoryProvider = Provider((ref) {
  final joinTokenRepository = ref.read(joinTokenRepositoryProvider);
  const url = String.fromEnvironment('LIVEKIT_URL');  
  return RoomRepository(joinTokenRepository: joinTokenRepository, url: url);
});

final connectViewModelProvider = NotifierProvider.autoDispose(ConnectViewModel.new);

final prejoinViewModelProvider = AsyncNotifierProvider.autoDispose(PrejoinViewModel.new);

final roomVieWModelProvider = NotifierProvider.autoDispose(RoomViewModel.new);
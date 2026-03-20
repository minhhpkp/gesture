import 'package:gesture/data/repositories/join_token/join_token_repository.dart';
import 'package:gesture/data/repositories/room/room_repository.dart';
import 'package:gesture/data/repositories/sign_recognition_session/sign_recognition_session_repository.dart';
import 'package:gesture/data/services/api/api_client.dart';
import 'package:gesture/ui/connect/connect_view_model.dart';
import 'package:gesture/ui/prejoin/prejoin_view_model.dart';
import 'package:gesture/ui/room/control/control_view_model.dart';
import 'package:gesture/ui/room/control/sign_recognition/sign_recognition_notifier.dart';
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

final localVideoPublicationsStreamProvider = StreamProvider.autoDispose((ref) {
  final roomRepository = ref.read(roomRepositoryProvider);
  roomRepository.room?.onDispose(() async => ref.invalidateSelf());
  return roomRepository.localParticipantStream.map((localParticipant) => localParticipant.videoTrackPublications);
});

final signRecognitionSessionRepository = Provider((ref) {
  final roomRepository = ref.read(roomRepositoryProvider);
  return SignRecognitionSessionRepository(roomRepository: roomRepository);
});

final connectViewModelProvider = NotifierProvider.autoDispose(ConnectViewModel.new);

final prejoinViewModelProvider = AsyncNotifierProvider.autoDispose(PrejoinViewModel.new);

final roomViewModelProvider = NotifierProvider.autoDispose(RoomViewModel.new);

final controlViewModelProvider = StreamNotifierProvider.autoDispose(ControlViewModel.new);

final signRecognitionNotifierProvider = NotifierProvider.autoDispose(SignRecognitionNotifier.new);

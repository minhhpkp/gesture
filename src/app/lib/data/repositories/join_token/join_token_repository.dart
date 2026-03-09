import 'package:dio/dio.dart';
import 'package:gesture/data/services/api/api_client.dart';
import 'package:gesture/data/services/api/models/create_join_token_request/create_join_token_request.dart';

class JoinTokenRepository {
  JoinTokenRepository({
    required ApiClient apiClient,
  }) : _apiClient = apiClient;

  final ApiClient _apiClient;
  String? _joinToken;
  String? get joinToken => _joinToken;  

  Future<void> createJoinToken({required String username, required String roomId, CancelToken? cancelToken}) async {
    final response = await _apiClient.createJoinToken(
      CreateJoinTokenRequest(username: username, roomId: roomId),
      cancelToken: cancelToken,
    );
    _joinToken = response.token;
    print('join token: $_joinToken');
  }
}

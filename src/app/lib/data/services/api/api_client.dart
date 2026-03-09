import 'package:dio/dio.dart';
import 'package:gesture/data/services/api/models/create_join_token_request/create_join_token_request.dart';
import 'package:gesture/data/services/api/models/join_token_response/join_token_response.dart';

class ApiClient {
  ApiClient({String? baseUrl, Dio? dio}) {
    _dio = dio ?? Dio(BaseOptions(baseUrl: baseUrl ?? 'http://localhost:8000'));
  }

  late final Dio _dio;

  Future<JoinTokenResponse> createJoinToken(CreateJoinTokenRequest request, {CancelToken? cancelToken}) async {
    final reqJson = request.toJson();
    final response = await _dio.post('/join-tokens', data: reqJson, cancelToken: cancelToken);
    return JoinTokenResponse.fromJson(response.data);
  }
}

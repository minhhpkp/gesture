import 'package:freezed_annotation/freezed_annotation.dart';

part 'create_join_token_request.freezed.dart';

part 'create_join_token_request.g.dart';

@freezed
abstract class CreateJoinTokenRequest with _$CreateJoinTokenRequest {
  const factory CreateJoinTokenRequest({
    required String username,
    required String roomId,
  }) = _CreateJoinTokenRequest;

  factory CreateJoinTokenRequest.fromJson(Map<String, Object?> json) => _$CreateJoinTokenRequestFromJson(json);
}

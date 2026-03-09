import 'package:freezed_annotation/freezed_annotation.dart';

part 'join_token_response.freezed.dart';

part 'join_token_response.g.dart';

@freezed
abstract class JoinTokenResponse with _$JoinTokenResponse {
  const factory JoinTokenResponse({
    required String token,
  }) = _JoinTokenResponse;

  factory JoinTokenResponse.fromJson(Map<String, Object?> json) => _$JoinTokenResponseFromJson(json);
}

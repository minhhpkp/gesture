// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_join_token_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_CreateJoinTokenRequest _$CreateJoinTokenRequestFromJson(
  Map<String, dynamic> json,
) => _CreateJoinTokenRequest(
  username: json['username'] as String,
  roomId: json['roomId'] as String,
);

Map<String, dynamic> _$CreateJoinTokenRequestToJson(
  _CreateJoinTokenRequest instance,
) => <String, dynamic>{
  'username': instance.username,
  'roomId': instance.roomId,
};

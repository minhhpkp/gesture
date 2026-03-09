// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'create_join_token_request.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$CreateJoinTokenRequest {

 String get username; String get roomId;
/// Create a copy of CreateJoinTokenRequest
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CreateJoinTokenRequestCopyWith<CreateJoinTokenRequest> get copyWith => _$CreateJoinTokenRequestCopyWithImpl<CreateJoinTokenRequest>(this as CreateJoinTokenRequest, _$identity);

  /// Serializes this CreateJoinTokenRequest to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CreateJoinTokenRequest&&(identical(other.username, username) || other.username == username)&&(identical(other.roomId, roomId) || other.roomId == roomId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,username,roomId);

@override
String toString() {
  return 'CreateJoinTokenRequest(username: $username, roomId: $roomId)';
}


}

/// @nodoc
abstract mixin class $CreateJoinTokenRequestCopyWith<$Res>  {
  factory $CreateJoinTokenRequestCopyWith(CreateJoinTokenRequest value, $Res Function(CreateJoinTokenRequest) _then) = _$CreateJoinTokenRequestCopyWithImpl;
@useResult
$Res call({
 String username, String roomId
});




}
/// @nodoc
class _$CreateJoinTokenRequestCopyWithImpl<$Res>
    implements $CreateJoinTokenRequestCopyWith<$Res> {
  _$CreateJoinTokenRequestCopyWithImpl(this._self, this._then);

  final CreateJoinTokenRequest _self;
  final $Res Function(CreateJoinTokenRequest) _then;

/// Create a copy of CreateJoinTokenRequest
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? username = null,Object? roomId = null,}) {
  return _then(_self.copyWith(
username: null == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String,roomId: null == roomId ? _self.roomId : roomId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [CreateJoinTokenRequest].
extension CreateJoinTokenRequestPatterns on CreateJoinTokenRequest {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CreateJoinTokenRequest value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CreateJoinTokenRequest() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CreateJoinTokenRequest value)  $default,){
final _that = this;
switch (_that) {
case _CreateJoinTokenRequest():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CreateJoinTokenRequest value)?  $default,){
final _that = this;
switch (_that) {
case _CreateJoinTokenRequest() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String username,  String roomId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CreateJoinTokenRequest() when $default != null:
return $default(_that.username,_that.roomId);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String username,  String roomId)  $default,) {final _that = this;
switch (_that) {
case _CreateJoinTokenRequest():
return $default(_that.username,_that.roomId);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String username,  String roomId)?  $default,) {final _that = this;
switch (_that) {
case _CreateJoinTokenRequest() when $default != null:
return $default(_that.username,_that.roomId);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CreateJoinTokenRequest implements CreateJoinTokenRequest {
  const _CreateJoinTokenRequest({required this.username, required this.roomId});
  factory _CreateJoinTokenRequest.fromJson(Map<String, dynamic> json) => _$CreateJoinTokenRequestFromJson(json);

@override final  String username;
@override final  String roomId;

/// Create a copy of CreateJoinTokenRequest
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CreateJoinTokenRequestCopyWith<_CreateJoinTokenRequest> get copyWith => __$CreateJoinTokenRequestCopyWithImpl<_CreateJoinTokenRequest>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CreateJoinTokenRequestToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CreateJoinTokenRequest&&(identical(other.username, username) || other.username == username)&&(identical(other.roomId, roomId) || other.roomId == roomId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,username,roomId);

@override
String toString() {
  return 'CreateJoinTokenRequest(username: $username, roomId: $roomId)';
}


}

/// @nodoc
abstract mixin class _$CreateJoinTokenRequestCopyWith<$Res> implements $CreateJoinTokenRequestCopyWith<$Res> {
  factory _$CreateJoinTokenRequestCopyWith(_CreateJoinTokenRequest value, $Res Function(_CreateJoinTokenRequest) _then) = __$CreateJoinTokenRequestCopyWithImpl;
@override @useResult
$Res call({
 String username, String roomId
});




}
/// @nodoc
class __$CreateJoinTokenRequestCopyWithImpl<$Res>
    implements _$CreateJoinTokenRequestCopyWith<$Res> {
  __$CreateJoinTokenRequestCopyWithImpl(this._self, this._then);

  final _CreateJoinTokenRequest _self;
  final $Res Function(_CreateJoinTokenRequest) _then;

/// Create a copy of CreateJoinTokenRequest
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? username = null,Object? roomId = null,}) {
  return _then(_CreateJoinTokenRequest(
username: null == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String,roomId: null == roomId ? _self.roomId : roomId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on

// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'signer_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$SignerState {

 String get signer; SessionState get sessionState;
/// Create a copy of SignerState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SignerStateCopyWith<SignerState> get copyWith => _$SignerStateCopyWithImpl<SignerState>(this as SignerState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SignerState&&(identical(other.signer, signer) || other.signer == signer)&&(identical(other.sessionState, sessionState) || other.sessionState == sessionState));
}


@override
int get hashCode => Object.hash(runtimeType,signer,sessionState);

@override
String toString() {
  return 'SignerState(signer: $signer, sessionState: $sessionState)';
}


}

/// @nodoc
abstract mixin class $SignerStateCopyWith<$Res>  {
  factory $SignerStateCopyWith(SignerState value, $Res Function(SignerState) _then) = _$SignerStateCopyWithImpl;
@useResult
$Res call({
 String signer, SessionState sessionState
});




}
/// @nodoc
class _$SignerStateCopyWithImpl<$Res>
    implements $SignerStateCopyWith<$Res> {
  _$SignerStateCopyWithImpl(this._self, this._then);

  final SignerState _self;
  final $Res Function(SignerState) _then;

/// Create a copy of SignerState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? signer = null,Object? sessionState = null,}) {
  return _then(_self.copyWith(
signer: null == signer ? _self.signer : signer // ignore: cast_nullable_to_non_nullable
as String,sessionState: null == sessionState ? _self.sessionState : sessionState // ignore: cast_nullable_to_non_nullable
as SessionState,
  ));
}

}


/// Adds pattern-matching-related methods to [SignerState].
extension SignerStatePatterns on SignerState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SignerState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SignerState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SignerState value)  $default,){
final _that = this;
switch (_that) {
case _SignerState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SignerState value)?  $default,){
final _that = this;
switch (_that) {
case _SignerState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String signer,  SessionState sessionState)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SignerState() when $default != null:
return $default(_that.signer,_that.sessionState);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String signer,  SessionState sessionState)  $default,) {final _that = this;
switch (_that) {
case _SignerState():
return $default(_that.signer,_that.sessionState);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String signer,  SessionState sessionState)?  $default,) {final _that = this;
switch (_that) {
case _SignerState() when $default != null:
return $default(_that.signer,_that.sessionState);case _:
  return null;

}
}

}

/// @nodoc


class _SignerState implements SignerState {
  const _SignerState({required this.signer, required this.sessionState});
  

@override final  String signer;
@override final  SessionState sessionState;

/// Create a copy of SignerState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SignerStateCopyWith<_SignerState> get copyWith => __$SignerStateCopyWithImpl<_SignerState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SignerState&&(identical(other.signer, signer) || other.signer == signer)&&(identical(other.sessionState, sessionState) || other.sessionState == sessionState));
}


@override
int get hashCode => Object.hash(runtimeType,signer,sessionState);

@override
String toString() {
  return 'SignerState(signer: $signer, sessionState: $sessionState)';
}


}

/// @nodoc
abstract mixin class _$SignerStateCopyWith<$Res> implements $SignerStateCopyWith<$Res> {
  factory _$SignerStateCopyWith(_SignerState value, $Res Function(_SignerState) _then) = __$SignerStateCopyWithImpl;
@override @useResult
$Res call({
 String signer, SessionState sessionState
});




}
/// @nodoc
class __$SignerStateCopyWithImpl<$Res>
    implements _$SignerStateCopyWith<$Res> {
  __$SignerStateCopyWithImpl(this._self, this._then);

  final _SignerState _self;
  final $Res Function(_SignerState) _then;

/// Create a copy of SignerState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? signer = null,Object? sessionState = null,}) {
  return _then(_SignerState(
signer: null == signer ? _self.signer : signer // ignore: cast_nullable_to_non_nullable
as String,sessionState: null == sessionState ? _self.sessionState : sessionState // ignore: cast_nullable_to_non_nullable
as SessionState,
  ));
}


}

// dart format on

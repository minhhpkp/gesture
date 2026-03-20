// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'sign_recognition_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$SignRecognitionState {

 LocalTrackPublication<LocalVideoTrack>? get selectedVideoPublication; bool get shouldNotifyNoVideoTrack; bool get inProgress; bool get isLoading; String? get errorMessage;
/// Create a copy of SignRecognitionState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SignRecognitionStateCopyWith<SignRecognitionState> get copyWith => _$SignRecognitionStateCopyWithImpl<SignRecognitionState>(this as SignRecognitionState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SignRecognitionState&&(identical(other.selectedVideoPublication, selectedVideoPublication) || other.selectedVideoPublication == selectedVideoPublication)&&(identical(other.shouldNotifyNoVideoTrack, shouldNotifyNoVideoTrack) || other.shouldNotifyNoVideoTrack == shouldNotifyNoVideoTrack)&&(identical(other.inProgress, inProgress) || other.inProgress == inProgress)&&(identical(other.isLoading, isLoading) || other.isLoading == isLoading)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage));
}


@override
int get hashCode => Object.hash(runtimeType,selectedVideoPublication,shouldNotifyNoVideoTrack,inProgress,isLoading,errorMessage);

@override
String toString() {
  return 'SignRecognitionState(selectedVideoPublication: $selectedVideoPublication, shouldNotifyNoVideoTrack: $shouldNotifyNoVideoTrack, inProgress: $inProgress, isLoading: $isLoading, errorMessage: $errorMessage)';
}


}

/// @nodoc
abstract mixin class $SignRecognitionStateCopyWith<$Res>  {
  factory $SignRecognitionStateCopyWith(SignRecognitionState value, $Res Function(SignRecognitionState) _then) = _$SignRecognitionStateCopyWithImpl;
@useResult
$Res call({
 LocalTrackPublication<LocalVideoTrack>? selectedVideoPublication, bool shouldNotifyNoVideoTrack, bool inProgress, bool isLoading, String? errorMessage
});




}
/// @nodoc
class _$SignRecognitionStateCopyWithImpl<$Res>
    implements $SignRecognitionStateCopyWith<$Res> {
  _$SignRecognitionStateCopyWithImpl(this._self, this._then);

  final SignRecognitionState _self;
  final $Res Function(SignRecognitionState) _then;

/// Create a copy of SignRecognitionState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? selectedVideoPublication = freezed,Object? shouldNotifyNoVideoTrack = null,Object? inProgress = null,Object? isLoading = null,Object? errorMessage = freezed,}) {
  return _then(_self.copyWith(
selectedVideoPublication: freezed == selectedVideoPublication ? _self.selectedVideoPublication : selectedVideoPublication // ignore: cast_nullable_to_non_nullable
as LocalTrackPublication<LocalVideoTrack>?,shouldNotifyNoVideoTrack: null == shouldNotifyNoVideoTrack ? _self.shouldNotifyNoVideoTrack : shouldNotifyNoVideoTrack // ignore: cast_nullable_to_non_nullable
as bool,inProgress: null == inProgress ? _self.inProgress : inProgress // ignore: cast_nullable_to_non_nullable
as bool,isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [SignRecognitionState].
extension SignRecognitionStatePatterns on SignRecognitionState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SignRecognitionState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SignRecognitionState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SignRecognitionState value)  $default,){
final _that = this;
switch (_that) {
case _SignRecognitionState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SignRecognitionState value)?  $default,){
final _that = this;
switch (_that) {
case _SignRecognitionState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( LocalTrackPublication<LocalVideoTrack>? selectedVideoPublication,  bool shouldNotifyNoVideoTrack,  bool inProgress,  bool isLoading,  String? errorMessage)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SignRecognitionState() when $default != null:
return $default(_that.selectedVideoPublication,_that.shouldNotifyNoVideoTrack,_that.inProgress,_that.isLoading,_that.errorMessage);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( LocalTrackPublication<LocalVideoTrack>? selectedVideoPublication,  bool shouldNotifyNoVideoTrack,  bool inProgress,  bool isLoading,  String? errorMessage)  $default,) {final _that = this;
switch (_that) {
case _SignRecognitionState():
return $default(_that.selectedVideoPublication,_that.shouldNotifyNoVideoTrack,_that.inProgress,_that.isLoading,_that.errorMessage);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( LocalTrackPublication<LocalVideoTrack>? selectedVideoPublication,  bool shouldNotifyNoVideoTrack,  bool inProgress,  bool isLoading,  String? errorMessage)?  $default,) {final _that = this;
switch (_that) {
case _SignRecognitionState() when $default != null:
return $default(_that.selectedVideoPublication,_that.shouldNotifyNoVideoTrack,_that.inProgress,_that.isLoading,_that.errorMessage);case _:
  return null;

}
}

}

/// @nodoc


class _SignRecognitionState implements SignRecognitionState {
  const _SignRecognitionState({this.selectedVideoPublication, this.shouldNotifyNoVideoTrack = false, this.inProgress = false, this.isLoading = false, this.errorMessage});
  

@override final  LocalTrackPublication<LocalVideoTrack>? selectedVideoPublication;
@override@JsonKey() final  bool shouldNotifyNoVideoTrack;
@override@JsonKey() final  bool inProgress;
@override@JsonKey() final  bool isLoading;
@override final  String? errorMessage;

/// Create a copy of SignRecognitionState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SignRecognitionStateCopyWith<_SignRecognitionState> get copyWith => __$SignRecognitionStateCopyWithImpl<_SignRecognitionState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SignRecognitionState&&(identical(other.selectedVideoPublication, selectedVideoPublication) || other.selectedVideoPublication == selectedVideoPublication)&&(identical(other.shouldNotifyNoVideoTrack, shouldNotifyNoVideoTrack) || other.shouldNotifyNoVideoTrack == shouldNotifyNoVideoTrack)&&(identical(other.inProgress, inProgress) || other.inProgress == inProgress)&&(identical(other.isLoading, isLoading) || other.isLoading == isLoading)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage));
}


@override
int get hashCode => Object.hash(runtimeType,selectedVideoPublication,shouldNotifyNoVideoTrack,inProgress,isLoading,errorMessage);

@override
String toString() {
  return 'SignRecognitionState(selectedVideoPublication: $selectedVideoPublication, shouldNotifyNoVideoTrack: $shouldNotifyNoVideoTrack, inProgress: $inProgress, isLoading: $isLoading, errorMessage: $errorMessage)';
}


}

/// @nodoc
abstract mixin class _$SignRecognitionStateCopyWith<$Res> implements $SignRecognitionStateCopyWith<$Res> {
  factory _$SignRecognitionStateCopyWith(_SignRecognitionState value, $Res Function(_SignRecognitionState) _then) = __$SignRecognitionStateCopyWithImpl;
@override @useResult
$Res call({
 LocalTrackPublication<LocalVideoTrack>? selectedVideoPublication, bool shouldNotifyNoVideoTrack, bool inProgress, bool isLoading, String? errorMessage
});




}
/// @nodoc
class __$SignRecognitionStateCopyWithImpl<$Res>
    implements _$SignRecognitionStateCopyWith<$Res> {
  __$SignRecognitionStateCopyWithImpl(this._self, this._then);

  final _SignRecognitionState _self;
  final $Res Function(_SignRecognitionState) _then;

/// Create a copy of SignRecognitionState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? selectedVideoPublication = freezed,Object? shouldNotifyNoVideoTrack = null,Object? inProgress = null,Object? isLoading = null,Object? errorMessage = freezed,}) {
  return _then(_SignRecognitionState(
selectedVideoPublication: freezed == selectedVideoPublication ? _self.selectedVideoPublication : selectedVideoPublication // ignore: cast_nullable_to_non_nullable
as LocalTrackPublication<LocalVideoTrack>?,shouldNotifyNoVideoTrack: null == shouldNotifyNoVideoTrack ? _self.shouldNotifyNoVideoTrack : shouldNotifyNoVideoTrack // ignore: cast_nullable_to_non_nullable
as bool,inProgress: null == inProgress ? _self.inProgress : inProgress // ignore: cast_nullable_to_non_nullable
as bool,isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on

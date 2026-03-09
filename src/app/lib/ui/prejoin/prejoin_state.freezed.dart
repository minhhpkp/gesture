// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'prejoin_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$PrejoinState {

 List<MediaDevice> get audioInputs; List<MediaDevice> get videoInputs; bool get isAudioEnabled; bool get isVideoEnabled; MediaDevice? get selectedAudioDevice; MediaDevice? get selectedVideoDevice; LocalVideoTrack? get videoTrack; VideoParameters get selectedVideoParameters; bool get isLoading; bool? get isJoinSuccess;
/// Create a copy of PrejoinState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PrejoinStateCopyWith<PrejoinState> get copyWith => _$PrejoinStateCopyWithImpl<PrejoinState>(this as PrejoinState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PrejoinState&&const DeepCollectionEquality().equals(other.audioInputs, audioInputs)&&const DeepCollectionEquality().equals(other.videoInputs, videoInputs)&&(identical(other.isAudioEnabled, isAudioEnabled) || other.isAudioEnabled == isAudioEnabled)&&(identical(other.isVideoEnabled, isVideoEnabled) || other.isVideoEnabled == isVideoEnabled)&&(identical(other.selectedAudioDevice, selectedAudioDevice) || other.selectedAudioDevice == selectedAudioDevice)&&(identical(other.selectedVideoDevice, selectedVideoDevice) || other.selectedVideoDevice == selectedVideoDevice)&&(identical(other.videoTrack, videoTrack) || other.videoTrack == videoTrack)&&(identical(other.selectedVideoParameters, selectedVideoParameters) || other.selectedVideoParameters == selectedVideoParameters)&&(identical(other.isLoading, isLoading) || other.isLoading == isLoading)&&(identical(other.isJoinSuccess, isJoinSuccess) || other.isJoinSuccess == isJoinSuccess));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(audioInputs),const DeepCollectionEquality().hash(videoInputs),isAudioEnabled,isVideoEnabled,selectedAudioDevice,selectedVideoDevice,videoTrack,selectedVideoParameters,isLoading,isJoinSuccess);

@override
String toString() {
  return 'PrejoinState(audioInputs: $audioInputs, videoInputs: $videoInputs, isAudioEnabled: $isAudioEnabled, isVideoEnabled: $isVideoEnabled, selectedAudioDevice: $selectedAudioDevice, selectedVideoDevice: $selectedVideoDevice, videoTrack: $videoTrack, selectedVideoParameters: $selectedVideoParameters, isLoading: $isLoading, isJoinSuccess: $isJoinSuccess)';
}


}

/// @nodoc
abstract mixin class $PrejoinStateCopyWith<$Res>  {
  factory $PrejoinStateCopyWith(PrejoinState value, $Res Function(PrejoinState) _then) = _$PrejoinStateCopyWithImpl;
@useResult
$Res call({
 List<MediaDevice> audioInputs, List<MediaDevice> videoInputs, bool isAudioEnabled, bool isVideoEnabled, MediaDevice? selectedAudioDevice, MediaDevice? selectedVideoDevice, LocalVideoTrack? videoTrack, VideoParameters selectedVideoParameters, bool isLoading, bool? isJoinSuccess
});




}
/// @nodoc
class _$PrejoinStateCopyWithImpl<$Res>
    implements $PrejoinStateCopyWith<$Res> {
  _$PrejoinStateCopyWithImpl(this._self, this._then);

  final PrejoinState _self;
  final $Res Function(PrejoinState) _then;

/// Create a copy of PrejoinState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? audioInputs = null,Object? videoInputs = null,Object? isAudioEnabled = null,Object? isVideoEnabled = null,Object? selectedAudioDevice = freezed,Object? selectedVideoDevice = freezed,Object? videoTrack = freezed,Object? selectedVideoParameters = null,Object? isLoading = null,Object? isJoinSuccess = freezed,}) {
  return _then(_self.copyWith(
audioInputs: null == audioInputs ? _self.audioInputs : audioInputs // ignore: cast_nullable_to_non_nullable
as List<MediaDevice>,videoInputs: null == videoInputs ? _self.videoInputs : videoInputs // ignore: cast_nullable_to_non_nullable
as List<MediaDevice>,isAudioEnabled: null == isAudioEnabled ? _self.isAudioEnabled : isAudioEnabled // ignore: cast_nullable_to_non_nullable
as bool,isVideoEnabled: null == isVideoEnabled ? _self.isVideoEnabled : isVideoEnabled // ignore: cast_nullable_to_non_nullable
as bool,selectedAudioDevice: freezed == selectedAudioDevice ? _self.selectedAudioDevice : selectedAudioDevice // ignore: cast_nullable_to_non_nullable
as MediaDevice?,selectedVideoDevice: freezed == selectedVideoDevice ? _self.selectedVideoDevice : selectedVideoDevice // ignore: cast_nullable_to_non_nullable
as MediaDevice?,videoTrack: freezed == videoTrack ? _self.videoTrack : videoTrack // ignore: cast_nullable_to_non_nullable
as LocalVideoTrack?,selectedVideoParameters: null == selectedVideoParameters ? _self.selectedVideoParameters : selectedVideoParameters // ignore: cast_nullable_to_non_nullable
as VideoParameters,isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,isJoinSuccess: freezed == isJoinSuccess ? _self.isJoinSuccess : isJoinSuccess // ignore: cast_nullable_to_non_nullable
as bool?,
  ));
}

}


/// Adds pattern-matching-related methods to [PrejoinState].
extension PrejoinStatePatterns on PrejoinState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PrejoinState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PrejoinState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PrejoinState value)  $default,){
final _that = this;
switch (_that) {
case _PrejoinState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PrejoinState value)?  $default,){
final _that = this;
switch (_that) {
case _PrejoinState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<MediaDevice> audioInputs,  List<MediaDevice> videoInputs,  bool isAudioEnabled,  bool isVideoEnabled,  MediaDevice? selectedAudioDevice,  MediaDevice? selectedVideoDevice,  LocalVideoTrack? videoTrack,  VideoParameters selectedVideoParameters,  bool isLoading,  bool? isJoinSuccess)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PrejoinState() when $default != null:
return $default(_that.audioInputs,_that.videoInputs,_that.isAudioEnabled,_that.isVideoEnabled,_that.selectedAudioDevice,_that.selectedVideoDevice,_that.videoTrack,_that.selectedVideoParameters,_that.isLoading,_that.isJoinSuccess);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<MediaDevice> audioInputs,  List<MediaDevice> videoInputs,  bool isAudioEnabled,  bool isVideoEnabled,  MediaDevice? selectedAudioDevice,  MediaDevice? selectedVideoDevice,  LocalVideoTrack? videoTrack,  VideoParameters selectedVideoParameters,  bool isLoading,  bool? isJoinSuccess)  $default,) {final _that = this;
switch (_that) {
case _PrejoinState():
return $default(_that.audioInputs,_that.videoInputs,_that.isAudioEnabled,_that.isVideoEnabled,_that.selectedAudioDevice,_that.selectedVideoDevice,_that.videoTrack,_that.selectedVideoParameters,_that.isLoading,_that.isJoinSuccess);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<MediaDevice> audioInputs,  List<MediaDevice> videoInputs,  bool isAudioEnabled,  bool isVideoEnabled,  MediaDevice? selectedAudioDevice,  MediaDevice? selectedVideoDevice,  LocalVideoTrack? videoTrack,  VideoParameters selectedVideoParameters,  bool isLoading,  bool? isJoinSuccess)?  $default,) {final _that = this;
switch (_that) {
case _PrejoinState() when $default != null:
return $default(_that.audioInputs,_that.videoInputs,_that.isAudioEnabled,_that.isVideoEnabled,_that.selectedAudioDevice,_that.selectedVideoDevice,_that.videoTrack,_that.selectedVideoParameters,_that.isLoading,_that.isJoinSuccess);case _:
  return null;

}
}

}

/// @nodoc


class _PrejoinState implements PrejoinState {
  const _PrejoinState({required final  List<MediaDevice> audioInputs, required final  List<MediaDevice> videoInputs, this.isAudioEnabled = true, this.isVideoEnabled = true, this.selectedAudioDevice, this.selectedVideoDevice, this.videoTrack, required this.selectedVideoParameters, this.isLoading = false, this.isJoinSuccess}): _audioInputs = audioInputs,_videoInputs = videoInputs;
  

 final  List<MediaDevice> _audioInputs;
@override List<MediaDevice> get audioInputs {
  if (_audioInputs is EqualUnmodifiableListView) return _audioInputs;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_audioInputs);
}

 final  List<MediaDevice> _videoInputs;
@override List<MediaDevice> get videoInputs {
  if (_videoInputs is EqualUnmodifiableListView) return _videoInputs;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_videoInputs);
}

@override@JsonKey() final  bool isAudioEnabled;
@override@JsonKey() final  bool isVideoEnabled;
@override final  MediaDevice? selectedAudioDevice;
@override final  MediaDevice? selectedVideoDevice;
@override final  LocalVideoTrack? videoTrack;
@override final  VideoParameters selectedVideoParameters;
@override@JsonKey() final  bool isLoading;
@override final  bool? isJoinSuccess;

/// Create a copy of PrejoinState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PrejoinStateCopyWith<_PrejoinState> get copyWith => __$PrejoinStateCopyWithImpl<_PrejoinState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PrejoinState&&const DeepCollectionEquality().equals(other._audioInputs, _audioInputs)&&const DeepCollectionEquality().equals(other._videoInputs, _videoInputs)&&(identical(other.isAudioEnabled, isAudioEnabled) || other.isAudioEnabled == isAudioEnabled)&&(identical(other.isVideoEnabled, isVideoEnabled) || other.isVideoEnabled == isVideoEnabled)&&(identical(other.selectedAudioDevice, selectedAudioDevice) || other.selectedAudioDevice == selectedAudioDevice)&&(identical(other.selectedVideoDevice, selectedVideoDevice) || other.selectedVideoDevice == selectedVideoDevice)&&(identical(other.videoTrack, videoTrack) || other.videoTrack == videoTrack)&&(identical(other.selectedVideoParameters, selectedVideoParameters) || other.selectedVideoParameters == selectedVideoParameters)&&(identical(other.isLoading, isLoading) || other.isLoading == isLoading)&&(identical(other.isJoinSuccess, isJoinSuccess) || other.isJoinSuccess == isJoinSuccess));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_audioInputs),const DeepCollectionEquality().hash(_videoInputs),isAudioEnabled,isVideoEnabled,selectedAudioDevice,selectedVideoDevice,videoTrack,selectedVideoParameters,isLoading,isJoinSuccess);

@override
String toString() {
  return 'PrejoinState(audioInputs: $audioInputs, videoInputs: $videoInputs, isAudioEnabled: $isAudioEnabled, isVideoEnabled: $isVideoEnabled, selectedAudioDevice: $selectedAudioDevice, selectedVideoDevice: $selectedVideoDevice, videoTrack: $videoTrack, selectedVideoParameters: $selectedVideoParameters, isLoading: $isLoading, isJoinSuccess: $isJoinSuccess)';
}


}

/// @nodoc
abstract mixin class _$PrejoinStateCopyWith<$Res> implements $PrejoinStateCopyWith<$Res> {
  factory _$PrejoinStateCopyWith(_PrejoinState value, $Res Function(_PrejoinState) _then) = __$PrejoinStateCopyWithImpl;
@override @useResult
$Res call({
 List<MediaDevice> audioInputs, List<MediaDevice> videoInputs, bool isAudioEnabled, bool isVideoEnabled, MediaDevice? selectedAudioDevice, MediaDevice? selectedVideoDevice, LocalVideoTrack? videoTrack, VideoParameters selectedVideoParameters, bool isLoading, bool? isJoinSuccess
});




}
/// @nodoc
class __$PrejoinStateCopyWithImpl<$Res>
    implements _$PrejoinStateCopyWith<$Res> {
  __$PrejoinStateCopyWithImpl(this._self, this._then);

  final _PrejoinState _self;
  final $Res Function(_PrejoinState) _then;

/// Create a copy of PrejoinState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? audioInputs = null,Object? videoInputs = null,Object? isAudioEnabled = null,Object? isVideoEnabled = null,Object? selectedAudioDevice = freezed,Object? selectedVideoDevice = freezed,Object? videoTrack = freezed,Object? selectedVideoParameters = null,Object? isLoading = null,Object? isJoinSuccess = freezed,}) {
  return _then(_PrejoinState(
audioInputs: null == audioInputs ? _self._audioInputs : audioInputs // ignore: cast_nullable_to_non_nullable
as List<MediaDevice>,videoInputs: null == videoInputs ? _self._videoInputs : videoInputs // ignore: cast_nullable_to_non_nullable
as List<MediaDevice>,isAudioEnabled: null == isAudioEnabled ? _self.isAudioEnabled : isAudioEnabled // ignore: cast_nullable_to_non_nullable
as bool,isVideoEnabled: null == isVideoEnabled ? _self.isVideoEnabled : isVideoEnabled // ignore: cast_nullable_to_non_nullable
as bool,selectedAudioDevice: freezed == selectedAudioDevice ? _self.selectedAudioDevice : selectedAudioDevice // ignore: cast_nullable_to_non_nullable
as MediaDevice?,selectedVideoDevice: freezed == selectedVideoDevice ? _self.selectedVideoDevice : selectedVideoDevice // ignore: cast_nullable_to_non_nullable
as MediaDevice?,videoTrack: freezed == videoTrack ? _self.videoTrack : videoTrack // ignore: cast_nullable_to_non_nullable
as LocalVideoTrack?,selectedVideoParameters: null == selectedVideoParameters ? _self.selectedVideoParameters : selectedVideoParameters // ignore: cast_nullable_to_non_nullable
as VideoParameters,isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,isJoinSuccess: freezed == isJoinSuccess ? _self.isJoinSuccess : isJoinSuccess // ignore: cast_nullable_to_non_nullable
as bool?,
  ));
}


}

// dart format on

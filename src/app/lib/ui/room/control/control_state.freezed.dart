// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'control_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ControlState {

 List<MediaDevice> get audioInputs; List<MediaDevice> get audioOutputs; List<MediaDevice> get videoInputs; String? get selectedAudioInputDeviceId; String? get selectedAudioOutputDeviceId; String? get selectedVideoInputDeviceId; CameraPosition get cameraPosition; bool get isSpeakerphoneOn; bool get isMicrophoneEnabled; bool get isCameraEnabled; bool get isScreenShareEnabled; bool get isMuted; bool get shouldNotifyScreenShare; bool get shouldNotifyScreenShareUnavailable;
/// Create a copy of ControlState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ControlStateCopyWith<ControlState> get copyWith => _$ControlStateCopyWithImpl<ControlState>(this as ControlState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ControlState&&const DeepCollectionEquality().equals(other.audioInputs, audioInputs)&&const DeepCollectionEquality().equals(other.audioOutputs, audioOutputs)&&const DeepCollectionEquality().equals(other.videoInputs, videoInputs)&&(identical(other.selectedAudioInputDeviceId, selectedAudioInputDeviceId) || other.selectedAudioInputDeviceId == selectedAudioInputDeviceId)&&(identical(other.selectedAudioOutputDeviceId, selectedAudioOutputDeviceId) || other.selectedAudioOutputDeviceId == selectedAudioOutputDeviceId)&&(identical(other.selectedVideoInputDeviceId, selectedVideoInputDeviceId) || other.selectedVideoInputDeviceId == selectedVideoInputDeviceId)&&(identical(other.cameraPosition, cameraPosition) || other.cameraPosition == cameraPosition)&&(identical(other.isSpeakerphoneOn, isSpeakerphoneOn) || other.isSpeakerphoneOn == isSpeakerphoneOn)&&(identical(other.isMicrophoneEnabled, isMicrophoneEnabled) || other.isMicrophoneEnabled == isMicrophoneEnabled)&&(identical(other.isCameraEnabled, isCameraEnabled) || other.isCameraEnabled == isCameraEnabled)&&(identical(other.isScreenShareEnabled, isScreenShareEnabled) || other.isScreenShareEnabled == isScreenShareEnabled)&&(identical(other.isMuted, isMuted) || other.isMuted == isMuted)&&(identical(other.shouldNotifyScreenShare, shouldNotifyScreenShare) || other.shouldNotifyScreenShare == shouldNotifyScreenShare)&&(identical(other.shouldNotifyScreenShareUnavailable, shouldNotifyScreenShareUnavailable) || other.shouldNotifyScreenShareUnavailable == shouldNotifyScreenShareUnavailable));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(audioInputs),const DeepCollectionEquality().hash(audioOutputs),const DeepCollectionEquality().hash(videoInputs),selectedAudioInputDeviceId,selectedAudioOutputDeviceId,selectedVideoInputDeviceId,cameraPosition,isSpeakerphoneOn,isMicrophoneEnabled,isCameraEnabled,isScreenShareEnabled,isMuted,shouldNotifyScreenShare,shouldNotifyScreenShareUnavailable);

@override
String toString() {
  return 'ControlState(audioInputs: $audioInputs, audioOutputs: $audioOutputs, videoInputs: $videoInputs, selectedAudioInputDeviceId: $selectedAudioInputDeviceId, selectedAudioOutputDeviceId: $selectedAudioOutputDeviceId, selectedVideoInputDeviceId: $selectedVideoInputDeviceId, cameraPosition: $cameraPosition, isSpeakerphoneOn: $isSpeakerphoneOn, isMicrophoneEnabled: $isMicrophoneEnabled, isCameraEnabled: $isCameraEnabled, isScreenShareEnabled: $isScreenShareEnabled, isMuted: $isMuted, shouldNotifyScreenShare: $shouldNotifyScreenShare, shouldNotifyScreenShareUnavailable: $shouldNotifyScreenShareUnavailable)';
}


}

/// @nodoc
abstract mixin class $ControlStateCopyWith<$Res>  {
  factory $ControlStateCopyWith(ControlState value, $Res Function(ControlState) _then) = _$ControlStateCopyWithImpl;
@useResult
$Res call({
 List<MediaDevice> audioInputs, List<MediaDevice> audioOutputs, List<MediaDevice> videoInputs, String? selectedAudioInputDeviceId, String? selectedAudioOutputDeviceId, String? selectedVideoInputDeviceId, CameraPosition cameraPosition, bool isSpeakerphoneOn, bool isMicrophoneEnabled, bool isCameraEnabled, bool isScreenShareEnabled, bool isMuted, bool shouldNotifyScreenShare, bool shouldNotifyScreenShareUnavailable
});




}
/// @nodoc
class _$ControlStateCopyWithImpl<$Res>
    implements $ControlStateCopyWith<$Res> {
  _$ControlStateCopyWithImpl(this._self, this._then);

  final ControlState _self;
  final $Res Function(ControlState) _then;

/// Create a copy of ControlState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? audioInputs = null,Object? audioOutputs = null,Object? videoInputs = null,Object? selectedAudioInputDeviceId = freezed,Object? selectedAudioOutputDeviceId = freezed,Object? selectedVideoInputDeviceId = freezed,Object? cameraPosition = null,Object? isSpeakerphoneOn = null,Object? isMicrophoneEnabled = null,Object? isCameraEnabled = null,Object? isScreenShareEnabled = null,Object? isMuted = null,Object? shouldNotifyScreenShare = null,Object? shouldNotifyScreenShareUnavailable = null,}) {
  return _then(_self.copyWith(
audioInputs: null == audioInputs ? _self.audioInputs : audioInputs // ignore: cast_nullable_to_non_nullable
as List<MediaDevice>,audioOutputs: null == audioOutputs ? _self.audioOutputs : audioOutputs // ignore: cast_nullable_to_non_nullable
as List<MediaDevice>,videoInputs: null == videoInputs ? _self.videoInputs : videoInputs // ignore: cast_nullable_to_non_nullable
as List<MediaDevice>,selectedAudioInputDeviceId: freezed == selectedAudioInputDeviceId ? _self.selectedAudioInputDeviceId : selectedAudioInputDeviceId // ignore: cast_nullable_to_non_nullable
as String?,selectedAudioOutputDeviceId: freezed == selectedAudioOutputDeviceId ? _self.selectedAudioOutputDeviceId : selectedAudioOutputDeviceId // ignore: cast_nullable_to_non_nullable
as String?,selectedVideoInputDeviceId: freezed == selectedVideoInputDeviceId ? _self.selectedVideoInputDeviceId : selectedVideoInputDeviceId // ignore: cast_nullable_to_non_nullable
as String?,cameraPosition: null == cameraPosition ? _self.cameraPosition : cameraPosition // ignore: cast_nullable_to_non_nullable
as CameraPosition,isSpeakerphoneOn: null == isSpeakerphoneOn ? _self.isSpeakerphoneOn : isSpeakerphoneOn // ignore: cast_nullable_to_non_nullable
as bool,isMicrophoneEnabled: null == isMicrophoneEnabled ? _self.isMicrophoneEnabled : isMicrophoneEnabled // ignore: cast_nullable_to_non_nullable
as bool,isCameraEnabled: null == isCameraEnabled ? _self.isCameraEnabled : isCameraEnabled // ignore: cast_nullable_to_non_nullable
as bool,isScreenShareEnabled: null == isScreenShareEnabled ? _self.isScreenShareEnabled : isScreenShareEnabled // ignore: cast_nullable_to_non_nullable
as bool,isMuted: null == isMuted ? _self.isMuted : isMuted // ignore: cast_nullable_to_non_nullable
as bool,shouldNotifyScreenShare: null == shouldNotifyScreenShare ? _self.shouldNotifyScreenShare : shouldNotifyScreenShare // ignore: cast_nullable_to_non_nullable
as bool,shouldNotifyScreenShareUnavailable: null == shouldNotifyScreenShareUnavailable ? _self.shouldNotifyScreenShareUnavailable : shouldNotifyScreenShareUnavailable // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [ControlState].
extension ControlStatePatterns on ControlState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ControlState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ControlState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ControlState value)  $default,){
final _that = this;
switch (_that) {
case _ControlState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ControlState value)?  $default,){
final _that = this;
switch (_that) {
case _ControlState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<MediaDevice> audioInputs,  List<MediaDevice> audioOutputs,  List<MediaDevice> videoInputs,  String? selectedAudioInputDeviceId,  String? selectedAudioOutputDeviceId,  String? selectedVideoInputDeviceId,  CameraPosition cameraPosition,  bool isSpeakerphoneOn,  bool isMicrophoneEnabled,  bool isCameraEnabled,  bool isScreenShareEnabled,  bool isMuted,  bool shouldNotifyScreenShare,  bool shouldNotifyScreenShareUnavailable)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ControlState() when $default != null:
return $default(_that.audioInputs,_that.audioOutputs,_that.videoInputs,_that.selectedAudioInputDeviceId,_that.selectedAudioOutputDeviceId,_that.selectedVideoInputDeviceId,_that.cameraPosition,_that.isSpeakerphoneOn,_that.isMicrophoneEnabled,_that.isCameraEnabled,_that.isScreenShareEnabled,_that.isMuted,_that.shouldNotifyScreenShare,_that.shouldNotifyScreenShareUnavailable);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<MediaDevice> audioInputs,  List<MediaDevice> audioOutputs,  List<MediaDevice> videoInputs,  String? selectedAudioInputDeviceId,  String? selectedAudioOutputDeviceId,  String? selectedVideoInputDeviceId,  CameraPosition cameraPosition,  bool isSpeakerphoneOn,  bool isMicrophoneEnabled,  bool isCameraEnabled,  bool isScreenShareEnabled,  bool isMuted,  bool shouldNotifyScreenShare,  bool shouldNotifyScreenShareUnavailable)  $default,) {final _that = this;
switch (_that) {
case _ControlState():
return $default(_that.audioInputs,_that.audioOutputs,_that.videoInputs,_that.selectedAudioInputDeviceId,_that.selectedAudioOutputDeviceId,_that.selectedVideoInputDeviceId,_that.cameraPosition,_that.isSpeakerphoneOn,_that.isMicrophoneEnabled,_that.isCameraEnabled,_that.isScreenShareEnabled,_that.isMuted,_that.shouldNotifyScreenShare,_that.shouldNotifyScreenShareUnavailable);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<MediaDevice> audioInputs,  List<MediaDevice> audioOutputs,  List<MediaDevice> videoInputs,  String? selectedAudioInputDeviceId,  String? selectedAudioOutputDeviceId,  String? selectedVideoInputDeviceId,  CameraPosition cameraPosition,  bool isSpeakerphoneOn,  bool isMicrophoneEnabled,  bool isCameraEnabled,  bool isScreenShareEnabled,  bool isMuted,  bool shouldNotifyScreenShare,  bool shouldNotifyScreenShareUnavailable)?  $default,) {final _that = this;
switch (_that) {
case _ControlState() when $default != null:
return $default(_that.audioInputs,_that.audioOutputs,_that.videoInputs,_that.selectedAudioInputDeviceId,_that.selectedAudioOutputDeviceId,_that.selectedVideoInputDeviceId,_that.cameraPosition,_that.isSpeakerphoneOn,_that.isMicrophoneEnabled,_that.isCameraEnabled,_that.isScreenShareEnabled,_that.isMuted,_that.shouldNotifyScreenShare,_that.shouldNotifyScreenShareUnavailable);case _:
  return null;

}
}

}

/// @nodoc


class _ControlState implements ControlState {
  const _ControlState({required final  List<MediaDevice> audioInputs, required final  List<MediaDevice> audioOutputs, required final  List<MediaDevice> videoInputs, this.selectedAudioInputDeviceId, this.selectedAudioOutputDeviceId, this.selectedVideoInputDeviceId, required this.cameraPosition, required this.isSpeakerphoneOn, required this.isMicrophoneEnabled, required this.isCameraEnabled, required this.isScreenShareEnabled, required this.isMuted, required this.shouldNotifyScreenShare, required this.shouldNotifyScreenShareUnavailable}): _audioInputs = audioInputs,_audioOutputs = audioOutputs,_videoInputs = videoInputs;
  

 final  List<MediaDevice> _audioInputs;
@override List<MediaDevice> get audioInputs {
  if (_audioInputs is EqualUnmodifiableListView) return _audioInputs;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_audioInputs);
}

 final  List<MediaDevice> _audioOutputs;
@override List<MediaDevice> get audioOutputs {
  if (_audioOutputs is EqualUnmodifiableListView) return _audioOutputs;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_audioOutputs);
}

 final  List<MediaDevice> _videoInputs;
@override List<MediaDevice> get videoInputs {
  if (_videoInputs is EqualUnmodifiableListView) return _videoInputs;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_videoInputs);
}

@override final  String? selectedAudioInputDeviceId;
@override final  String? selectedAudioOutputDeviceId;
@override final  String? selectedVideoInputDeviceId;
@override final  CameraPosition cameraPosition;
@override final  bool isSpeakerphoneOn;
@override final  bool isMicrophoneEnabled;
@override final  bool isCameraEnabled;
@override final  bool isScreenShareEnabled;
@override final  bool isMuted;
@override final  bool shouldNotifyScreenShare;
@override final  bool shouldNotifyScreenShareUnavailable;

/// Create a copy of ControlState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ControlStateCopyWith<_ControlState> get copyWith => __$ControlStateCopyWithImpl<_ControlState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ControlState&&const DeepCollectionEquality().equals(other._audioInputs, _audioInputs)&&const DeepCollectionEquality().equals(other._audioOutputs, _audioOutputs)&&const DeepCollectionEquality().equals(other._videoInputs, _videoInputs)&&(identical(other.selectedAudioInputDeviceId, selectedAudioInputDeviceId) || other.selectedAudioInputDeviceId == selectedAudioInputDeviceId)&&(identical(other.selectedAudioOutputDeviceId, selectedAudioOutputDeviceId) || other.selectedAudioOutputDeviceId == selectedAudioOutputDeviceId)&&(identical(other.selectedVideoInputDeviceId, selectedVideoInputDeviceId) || other.selectedVideoInputDeviceId == selectedVideoInputDeviceId)&&(identical(other.cameraPosition, cameraPosition) || other.cameraPosition == cameraPosition)&&(identical(other.isSpeakerphoneOn, isSpeakerphoneOn) || other.isSpeakerphoneOn == isSpeakerphoneOn)&&(identical(other.isMicrophoneEnabled, isMicrophoneEnabled) || other.isMicrophoneEnabled == isMicrophoneEnabled)&&(identical(other.isCameraEnabled, isCameraEnabled) || other.isCameraEnabled == isCameraEnabled)&&(identical(other.isScreenShareEnabled, isScreenShareEnabled) || other.isScreenShareEnabled == isScreenShareEnabled)&&(identical(other.isMuted, isMuted) || other.isMuted == isMuted)&&(identical(other.shouldNotifyScreenShare, shouldNotifyScreenShare) || other.shouldNotifyScreenShare == shouldNotifyScreenShare)&&(identical(other.shouldNotifyScreenShareUnavailable, shouldNotifyScreenShareUnavailable) || other.shouldNotifyScreenShareUnavailable == shouldNotifyScreenShareUnavailable));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_audioInputs),const DeepCollectionEquality().hash(_audioOutputs),const DeepCollectionEquality().hash(_videoInputs),selectedAudioInputDeviceId,selectedAudioOutputDeviceId,selectedVideoInputDeviceId,cameraPosition,isSpeakerphoneOn,isMicrophoneEnabled,isCameraEnabled,isScreenShareEnabled,isMuted,shouldNotifyScreenShare,shouldNotifyScreenShareUnavailable);

@override
String toString() {
  return 'ControlState(audioInputs: $audioInputs, audioOutputs: $audioOutputs, videoInputs: $videoInputs, selectedAudioInputDeviceId: $selectedAudioInputDeviceId, selectedAudioOutputDeviceId: $selectedAudioOutputDeviceId, selectedVideoInputDeviceId: $selectedVideoInputDeviceId, cameraPosition: $cameraPosition, isSpeakerphoneOn: $isSpeakerphoneOn, isMicrophoneEnabled: $isMicrophoneEnabled, isCameraEnabled: $isCameraEnabled, isScreenShareEnabled: $isScreenShareEnabled, isMuted: $isMuted, shouldNotifyScreenShare: $shouldNotifyScreenShare, shouldNotifyScreenShareUnavailable: $shouldNotifyScreenShareUnavailable)';
}


}

/// @nodoc
abstract mixin class _$ControlStateCopyWith<$Res> implements $ControlStateCopyWith<$Res> {
  factory _$ControlStateCopyWith(_ControlState value, $Res Function(_ControlState) _then) = __$ControlStateCopyWithImpl;
@override @useResult
$Res call({
 List<MediaDevice> audioInputs, List<MediaDevice> audioOutputs, List<MediaDevice> videoInputs, String? selectedAudioInputDeviceId, String? selectedAudioOutputDeviceId, String? selectedVideoInputDeviceId, CameraPosition cameraPosition, bool isSpeakerphoneOn, bool isMicrophoneEnabled, bool isCameraEnabled, bool isScreenShareEnabled, bool isMuted, bool shouldNotifyScreenShare, bool shouldNotifyScreenShareUnavailable
});




}
/// @nodoc
class __$ControlStateCopyWithImpl<$Res>
    implements _$ControlStateCopyWith<$Res> {
  __$ControlStateCopyWithImpl(this._self, this._then);

  final _ControlState _self;
  final $Res Function(_ControlState) _then;

/// Create a copy of ControlState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? audioInputs = null,Object? audioOutputs = null,Object? videoInputs = null,Object? selectedAudioInputDeviceId = freezed,Object? selectedAudioOutputDeviceId = freezed,Object? selectedVideoInputDeviceId = freezed,Object? cameraPosition = null,Object? isSpeakerphoneOn = null,Object? isMicrophoneEnabled = null,Object? isCameraEnabled = null,Object? isScreenShareEnabled = null,Object? isMuted = null,Object? shouldNotifyScreenShare = null,Object? shouldNotifyScreenShareUnavailable = null,}) {
  return _then(_ControlState(
audioInputs: null == audioInputs ? _self._audioInputs : audioInputs // ignore: cast_nullable_to_non_nullable
as List<MediaDevice>,audioOutputs: null == audioOutputs ? _self._audioOutputs : audioOutputs // ignore: cast_nullable_to_non_nullable
as List<MediaDevice>,videoInputs: null == videoInputs ? _self._videoInputs : videoInputs // ignore: cast_nullable_to_non_nullable
as List<MediaDevice>,selectedAudioInputDeviceId: freezed == selectedAudioInputDeviceId ? _self.selectedAudioInputDeviceId : selectedAudioInputDeviceId // ignore: cast_nullable_to_non_nullable
as String?,selectedAudioOutputDeviceId: freezed == selectedAudioOutputDeviceId ? _self.selectedAudioOutputDeviceId : selectedAudioOutputDeviceId // ignore: cast_nullable_to_non_nullable
as String?,selectedVideoInputDeviceId: freezed == selectedVideoInputDeviceId ? _self.selectedVideoInputDeviceId : selectedVideoInputDeviceId // ignore: cast_nullable_to_non_nullable
as String?,cameraPosition: null == cameraPosition ? _self.cameraPosition : cameraPosition // ignore: cast_nullable_to_non_nullable
as CameraPosition,isSpeakerphoneOn: null == isSpeakerphoneOn ? _self.isSpeakerphoneOn : isSpeakerphoneOn // ignore: cast_nullable_to_non_nullable
as bool,isMicrophoneEnabled: null == isMicrophoneEnabled ? _self.isMicrophoneEnabled : isMicrophoneEnabled // ignore: cast_nullable_to_non_nullable
as bool,isCameraEnabled: null == isCameraEnabled ? _self.isCameraEnabled : isCameraEnabled // ignore: cast_nullable_to_non_nullable
as bool,isScreenShareEnabled: null == isScreenShareEnabled ? _self.isScreenShareEnabled : isScreenShareEnabled // ignore: cast_nullable_to_non_nullable
as bool,isMuted: null == isMuted ? _self.isMuted : isMuted // ignore: cast_nullable_to_non_nullable
as bool,shouldNotifyScreenShare: null == shouldNotifyScreenShare ? _self.shouldNotifyScreenShare : shouldNotifyScreenShare // ignore: cast_nullable_to_non_nullable
as bool,shouldNotifyScreenShareUnavailable: null == shouldNotifyScreenShareUnavailable ? _self.shouldNotifyScreenShareUnavailable : shouldNotifyScreenShareUnavailable // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on

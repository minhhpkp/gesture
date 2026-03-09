// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'room_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$RoomState {

 List<ParticipantTrack> get participantTracks; Queue<String> get glosses; bool get unableToPlaybackAudio; bool get roomDisconnected; bool? get activeRecording; bool get hasLocalParticipant;
/// Create a copy of RoomState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RoomStateCopyWith<RoomState> get copyWith => _$RoomStateCopyWithImpl<RoomState>(this as RoomState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RoomState&&const DeepCollectionEquality().equals(other.participantTracks, participantTracks)&&const DeepCollectionEquality().equals(other.glosses, glosses)&&(identical(other.unableToPlaybackAudio, unableToPlaybackAudio) || other.unableToPlaybackAudio == unableToPlaybackAudio)&&(identical(other.roomDisconnected, roomDisconnected) || other.roomDisconnected == roomDisconnected)&&(identical(other.activeRecording, activeRecording) || other.activeRecording == activeRecording)&&(identical(other.hasLocalParticipant, hasLocalParticipant) || other.hasLocalParticipant == hasLocalParticipant));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(participantTracks),const DeepCollectionEquality().hash(glosses),unableToPlaybackAudio,roomDisconnected,activeRecording,hasLocalParticipant);

@override
String toString() {
  return 'RoomState(participantTracks: $participantTracks, glosses: $glosses, unableToPlaybackAudio: $unableToPlaybackAudio, roomDisconnected: $roomDisconnected, activeRecording: $activeRecording, hasLocalParticipant: $hasLocalParticipant)';
}


}

/// @nodoc
abstract mixin class $RoomStateCopyWith<$Res>  {
  factory $RoomStateCopyWith(RoomState value, $Res Function(RoomState) _then) = _$RoomStateCopyWithImpl;
@useResult
$Res call({
 List<ParticipantTrack> participantTracks, Queue<String> glosses, bool unableToPlaybackAudio, bool roomDisconnected, bool? activeRecording, bool hasLocalParticipant
});




}
/// @nodoc
class _$RoomStateCopyWithImpl<$Res>
    implements $RoomStateCopyWith<$Res> {
  _$RoomStateCopyWithImpl(this._self, this._then);

  final RoomState _self;
  final $Res Function(RoomState) _then;

/// Create a copy of RoomState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? participantTracks = null,Object? glosses = null,Object? unableToPlaybackAudio = null,Object? roomDisconnected = null,Object? activeRecording = freezed,Object? hasLocalParticipant = null,}) {
  return _then(_self.copyWith(
participantTracks: null == participantTracks ? _self.participantTracks : participantTracks // ignore: cast_nullable_to_non_nullable
as List<ParticipantTrack>,glosses: null == glosses ? _self.glosses : glosses // ignore: cast_nullable_to_non_nullable
as Queue<String>,unableToPlaybackAudio: null == unableToPlaybackAudio ? _self.unableToPlaybackAudio : unableToPlaybackAudio // ignore: cast_nullable_to_non_nullable
as bool,roomDisconnected: null == roomDisconnected ? _self.roomDisconnected : roomDisconnected // ignore: cast_nullable_to_non_nullable
as bool,activeRecording: freezed == activeRecording ? _self.activeRecording : activeRecording // ignore: cast_nullable_to_non_nullable
as bool?,hasLocalParticipant: null == hasLocalParticipant ? _self.hasLocalParticipant : hasLocalParticipant // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [RoomState].
extension RoomStatePatterns on RoomState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RoomState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RoomState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RoomState value)  $default,){
final _that = this;
switch (_that) {
case _RoomState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RoomState value)?  $default,){
final _that = this;
switch (_that) {
case _RoomState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<ParticipantTrack> participantTracks,  Queue<String> glosses,  bool unableToPlaybackAudio,  bool roomDisconnected,  bool? activeRecording,  bool hasLocalParticipant)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RoomState() when $default != null:
return $default(_that.participantTracks,_that.glosses,_that.unableToPlaybackAudio,_that.roomDisconnected,_that.activeRecording,_that.hasLocalParticipant);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<ParticipantTrack> participantTracks,  Queue<String> glosses,  bool unableToPlaybackAudio,  bool roomDisconnected,  bool? activeRecording,  bool hasLocalParticipant)  $default,) {final _that = this;
switch (_that) {
case _RoomState():
return $default(_that.participantTracks,_that.glosses,_that.unableToPlaybackAudio,_that.roomDisconnected,_that.activeRecording,_that.hasLocalParticipant);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<ParticipantTrack> participantTracks,  Queue<String> glosses,  bool unableToPlaybackAudio,  bool roomDisconnected,  bool? activeRecording,  bool hasLocalParticipant)?  $default,) {final _that = this;
switch (_that) {
case _RoomState() when $default != null:
return $default(_that.participantTracks,_that.glosses,_that.unableToPlaybackAudio,_that.roomDisconnected,_that.activeRecording,_that.hasLocalParticipant);case _:
  return null;

}
}

}

/// @nodoc


class _RoomState implements RoomState {
  const _RoomState({required final  List<ParticipantTrack> participantTracks, required this.glosses, this.unableToPlaybackAudio = false, this.roomDisconnected = false, this.activeRecording, this.hasLocalParticipant = false}): _participantTracks = participantTracks;
  

 final  List<ParticipantTrack> _participantTracks;
@override List<ParticipantTrack> get participantTracks {
  if (_participantTracks is EqualUnmodifiableListView) return _participantTracks;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_participantTracks);
}

@override final  Queue<String> glosses;
@override@JsonKey() final  bool unableToPlaybackAudio;
@override@JsonKey() final  bool roomDisconnected;
@override final  bool? activeRecording;
@override@JsonKey() final  bool hasLocalParticipant;

/// Create a copy of RoomState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RoomStateCopyWith<_RoomState> get copyWith => __$RoomStateCopyWithImpl<_RoomState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RoomState&&const DeepCollectionEquality().equals(other._participantTracks, _participantTracks)&&const DeepCollectionEquality().equals(other.glosses, glosses)&&(identical(other.unableToPlaybackAudio, unableToPlaybackAudio) || other.unableToPlaybackAudio == unableToPlaybackAudio)&&(identical(other.roomDisconnected, roomDisconnected) || other.roomDisconnected == roomDisconnected)&&(identical(other.activeRecording, activeRecording) || other.activeRecording == activeRecording)&&(identical(other.hasLocalParticipant, hasLocalParticipant) || other.hasLocalParticipant == hasLocalParticipant));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_participantTracks),const DeepCollectionEquality().hash(glosses),unableToPlaybackAudio,roomDisconnected,activeRecording,hasLocalParticipant);

@override
String toString() {
  return 'RoomState(participantTracks: $participantTracks, glosses: $glosses, unableToPlaybackAudio: $unableToPlaybackAudio, roomDisconnected: $roomDisconnected, activeRecording: $activeRecording, hasLocalParticipant: $hasLocalParticipant)';
}


}

/// @nodoc
abstract mixin class _$RoomStateCopyWith<$Res> implements $RoomStateCopyWith<$Res> {
  factory _$RoomStateCopyWith(_RoomState value, $Res Function(_RoomState) _then) = __$RoomStateCopyWithImpl;
@override @useResult
$Res call({
 List<ParticipantTrack> participantTracks, Queue<String> glosses, bool unableToPlaybackAudio, bool roomDisconnected, bool? activeRecording, bool hasLocalParticipant
});




}
/// @nodoc
class __$RoomStateCopyWithImpl<$Res>
    implements _$RoomStateCopyWith<$Res> {
  __$RoomStateCopyWithImpl(this._self, this._then);

  final _RoomState _self;
  final $Res Function(_RoomState) _then;

/// Create a copy of RoomState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? participantTracks = null,Object? glosses = null,Object? unableToPlaybackAudio = null,Object? roomDisconnected = null,Object? activeRecording = freezed,Object? hasLocalParticipant = null,}) {
  return _then(_RoomState(
participantTracks: null == participantTracks ? _self._participantTracks : participantTracks // ignore: cast_nullable_to_non_nullable
as List<ParticipantTrack>,glosses: null == glosses ? _self.glosses : glosses // ignore: cast_nullable_to_non_nullable
as Queue<String>,unableToPlaybackAudio: null == unableToPlaybackAudio ? _self.unableToPlaybackAudio : unableToPlaybackAudio // ignore: cast_nullable_to_non_nullable
as bool,roomDisconnected: null == roomDisconnected ? _self.roomDisconnected : roomDisconnected // ignore: cast_nullable_to_non_nullable
as bool,activeRecording: freezed == activeRecording ? _self.activeRecording : activeRecording // ignore: cast_nullable_to_non_nullable
as bool?,hasLocalParticipant: null == hasLocalParticipant ? _self.hasLocalParticipant : hasLocalParticipant // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on

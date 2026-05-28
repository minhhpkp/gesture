import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:gesture/ui/room/control/sign_recognition/sign_recognition_state.dart';

part 'signer_state.freezed.dart';

@freezed
abstract class SignerState with _$SignerState {
  const factory SignerState({
    required String signer,
    required SessionState sessionState,
  }) = _SignerState;
}
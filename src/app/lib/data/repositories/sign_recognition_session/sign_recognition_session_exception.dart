import 'package:livekit_client/livekit_client.dart';

// Convenient for development, will change to result pattern in the future
sealed class SignRecognitionSessionException implements Exception {
  final String message;
  SignRecognitionSessionException(this.message);

  factory SignRecognitionSessionException.fromRpcError(RpcError error) {
    switch (error.code) {
      case SignRecognitionAlreadyInUseException.code:
        return SignRecognitionAlreadyInUseException();
      case NoVideoTracksPublishedException.code:
        return NoVideoTracksPublishedException();
      case NoActiveSessionException.code:
        return NoActiveSessionException();
      case UnauthorizedSessionStopException.code:
        return UnauthorizedSessionStopException();
    }
    return UnknownRpcException(error);
  }
}

class LocalParticipantNotPresentException extends SignRecognitionSessionException {
  LocalParticipantNotPresentException() : super('No local participant is present');
}

class SignRecognitionAlreadyInUseException extends SignRecognitionSessionException {
  static const code = 2001;
  SignRecognitionAlreadyInUseException() : super('Another participant is already using the sign recognition service');
}

class NoVideoTracksPublishedException extends SignRecognitionSessionException {
  static const code = 2002;
  NoVideoTracksPublishedException() : super('No video tracks have been published');
}

class NoActiveSessionException extends SignRecognitionSessionException {
  static const code = 3001;
  NoActiveSessionException() : super('No active session at the moment');
}

class UnauthorizedSessionStopException extends SignRecognitionSessionException {
  static const code = 3002;
  UnauthorizedSessionStopException() : super('User is not the current participant using the sign recognition service');
}

class UnknownRpcException extends SignRecognitionSessionException {
  final RpcError error;
  UnknownRpcException(this.error) : super(error.message);
}

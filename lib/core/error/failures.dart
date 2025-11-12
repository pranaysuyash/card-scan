/// Base class for all failures in the application
/// Follows clean architecture principles for error handling
abstract class Failure {
  final String message;
  final String? code;
  final dynamic details;

  const Failure({
    required this.message,
    this.code,
    this.details,
  });

  @override
  String toString() => 'Failure(message: $message, code: $code)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Failure &&
        other.message == message &&
        other.code == code;
  }

  @override
  int get hashCode => message.hashCode ^ code.hashCode;
}

/// OCR related failures
class OcrFailure extends Failure {
  const OcrFailure({
    required super.message,
    super.code,
    super.details,
  });
}

/// Storage/Database failures
class StorageFailure extends Failure {
  const StorageFailure({
    required super.message,
    super.code,
    super.details,
  });
}

/// Network/API failures
class NetworkFailure extends Failure {
  const NetworkFailure({
    required super.message,
    super.code,
    super.details,
  });
}

/// Authentication failures
class AuthFailure extends Failure {
  const AuthFailure({
    required super.message,
    super.code,
    super.details,
  });
}

/// Permission failures
class PermissionFailure extends Failure {
  const PermissionFailure({
    required super.message,
    super.code,
    super.details,
  });
}

/// Camera failures
class CameraFailure extends Failure {
  const CameraFailure({
    required super.message,
    super.code,
    super.details,
  });
}

/// Parse failures
class ParseFailure extends Failure {
  const ParseFailure({
    required super.message,
    super.code,
    super.details,
  });
}

/// Validation failures
class ValidationFailure extends Failure {
  const ValidationFailure({
    required super.message,
    super.code,
    super.details,
  });
}

/// Payment/Subscription failures
class PaymentFailure extends Failure {
  const PaymentFailure({
    required super.message,
    super.code,
    super.details,
  });
}

/// Sync failures
class SyncFailure extends Failure {
  const SyncFailure({
    required super.message,
    super.code,
    super.details,
  });
}

/// Unknown/unexpected failures
class UnknownFailure extends Failure {
  const UnknownFailure({
    required super.message,
    super.code,
    super.details,
  });
}

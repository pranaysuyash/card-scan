/// Base exception class for application-specific exceptions
class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic details;

  const AppException({
    required this.message,
    this.code,
    this.details,
  });

  @override
  String toString() => 'AppException: $message (code: $code)';
}

/// OCR processing exceptions
class OcrException extends AppException {
  const OcrException({
    required super.message,
    super.code,
    super.details,
  });
}

/// Storage/Database exceptions
class StorageException extends AppException {
  const StorageException({
    required super.message,
    super.code,
    super.details,
  });
}

/// Network/API exceptions
class NetworkException extends AppException {
  const NetworkException({
    required super.message,
    super.code,
    super.details,
  });
}

/// Authentication exceptions
class AuthException extends AppException {
  const AuthException({
    required super.message,
    super.code,
    super.details,
  });
}

/// Permission exceptions
class PermissionException extends AppException {
  const PermissionException({
    required super.message,
    super.code,
    super.details,
  });
}

/// Camera exceptions
class CameraException extends AppException {
  const CameraException({
    required super.message,
    super.code,
    super.details,
  });
}

/// Parse exceptions
class ParseException extends AppException {
  const ParseException({
    required super.message,
    super.code,
    super.details,
  });
}

/// Cache exceptions
class CacheException extends AppException {
  const CacheException({
    required super.message,
    super.code,
    super.details,
  });
}

/// Payment/Subscription exceptions
class PaymentException extends AppException {
  const PaymentException({
    required super.message,
    super.code,
    super.details,
  });
}

/// Sync exceptions
class SyncException extends AppException {
  const SyncException({
    required super.message,
    super.code,
    super.details,
  });
}

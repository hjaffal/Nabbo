/// Base exception for all Nabbo app errors.
sealed class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;

  const AppException(this.message, {this.code, this.originalError});

  @override
  String toString() => 'AppException($code): $message';
}

/// Authentication errors
class AuthException extends AppException {
  const AuthException(super.message, {super.code, super.originalError});
}

/// Firestore / data layer errors
class DataException extends AppException {
  const DataException(super.message, {super.code, super.originalError});
}

/// Network / connectivity errors
class NetworkException extends AppException {
  const NetworkException(super.message, {super.code, super.originalError});
}

/// Capture errors (share, voice, image, email)
class CaptureException extends AppException {
  const CaptureException(super.message, {super.code, super.originalError});
}

/// Extraction / AI errors
class ExtractionException extends AppException {
  const ExtractionException(super.message, {super.code, super.originalError});
}

/// Validation errors
class ValidationException extends AppException {
  final Map<String, String>? fieldErrors;

  const ValidationException(super.message, {super.code, this.fieldErrors});
}

/// Permission / authorization errors
class PermissionException extends AppException {
  const PermissionException(super.message, {super.code, super.originalError});
}

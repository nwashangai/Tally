/// Base sealed hierarchy for application and domain errors.
/// Presentation layers inspect these strongly-typed errors instead of catching
/// raw low-level exceptions.
sealed class AppError implements Exception {
  final String message;
  final Object? cause;

  const AppError(this.message, {this.cause});

  @override
  String toString() =>
      '$runtimeType: $message${cause != null ? ' (Cause: $cause)' : ''}';
}

/// Occurs when input validation fails (e.g., negative stock, empty name).
final class ValidationError extends AppError {
  final String field;

  const ValidationError(super.message, {required this.field, super.cause});
}

/// Occurs when an authentication operation fails or credentials are invalid.
final class AuthenticationError extends AppError {
  const AuthenticationError(super.message, {super.cause});
}

/// Occurs when an authenticated user lacks permission for an operation.
final class AuthorizationError extends AppError {
  const AuthorizationError(super.message, {super.cause});
}

/// Occurs during network communication (timeout, DNS, server unavailable).
final class NetworkError extends AppError {
  final int? statusCode;

  const NetworkError(super.message, {this.statusCode, super.cause});
}

/// Occurs during local store file reading, writing, or serialization.
final class StorageError extends AppError {
  const StorageError(super.message, {super.cause});
}

/// Occurs when data fails integrity verification (checksum mismatch, corrupt format).
final class CorruptDataError extends AppError {
  const CorruptDataError(super.message, {super.cause});
}

/// Occurs during synchronization between local store files and remote storage.
final class SynchronizationError extends AppError {
  const SynchronizationError(super.message, {super.cause});
}

/// Occurs when concurrent mutations produce an unresolvable version conflict.
final class ConflictError extends AppError {
  final String conflictDetails;

  const ConflictError(super.message,
      {required this.conflictDetails, super.cause});
}

/// Occurs when a requested entity or file does not exist.
final class NotFoundError extends AppError {
  const NotFoundError(super.message, {super.cause});
}

/// Fallback for unexpected or unmapped failures.
final class UnknownError extends AppError {
  const UnknownError(super.message, {super.cause});
}

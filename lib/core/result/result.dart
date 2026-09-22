/// A functional result type representing either a successful computation [Success]
/// or a failed computation [Failure].
sealed class Result<T> {
  const Result();

  /// Returns `true` if this instance represents a [Success].
  bool get isSuccess => this is Success<T>;

  /// Returns `true` if this instance represents a [Failure].
  bool get isFailure => this is Failure<T>;

  /// Returns the encapsulated value if this is a [Success], or null otherwise.
  T? get valueOrNull => switch (this) {
        Success(:final value) => value,
        Failure() => null,
      };

  /// Returns the encapsulated error if this is a [Failure], or null otherwise.
  Object? get errorOrNull => switch (this) {
        Success() => null,
        Failure(:final error) => error,
      };

  /// Transforms the success value with [mapper] while preserving failure.
  Result<R> map<R>(R Function(T value) mapper) => switch (this) {
        Success(:final value) => Success(mapper(value)),
        Failure(:final error, :final stackTrace) =>
          Failure(error, stackTrace: stackTrace),
      };

  /// Unfolds the result into an [onSuccess] or [onFailure] callback.
  R fold<R>({
    required R Function(T value) onSuccess,
    required R Function(Object error, StackTrace? stackTrace) onFailure,
  }) =>
      switch (this) {
        Success(:final value) => onSuccess(value),
        Failure(:final error, :final stackTrace) =>
          onFailure(error, stackTrace),
      };
}

/// A successful computation containing a non-null [value].
final class Success<T> extends Result<T> {
  final T value;

  const Success(this.value);

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Success<T> && other.value == value);

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'Success($value)';
}

/// A failed computation containing an [error] and optional [stackTrace].
final class Failure<T> extends Result<T> {
  final Object error;
  final StackTrace? stackTrace;

  const Failure(this.error, {this.stackTrace});

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Failure<T> && other.error == error);

  @override
  int get hashCode => error.hashCode;

  @override
  String toString() => 'Failure($error)';
}

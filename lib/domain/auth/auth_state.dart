import 'auth_session.dart';
import 'user.dart';

/// Discriminated union representing the authentication state of the application.
sealed class AuthState {
  const AuthState();
}

/// The initial state before any auth check has been performed.
final class AuthStateInitial extends AuthState {
  const AuthStateInitial();
}

/// Currently checking persisted credentials (e.g., on app launch).
final class AuthStateLoading extends AuthState {
  const AuthStateLoading();
}

/// The user is authenticated and holds a valid [session].
final class AuthStateAuthenticated extends AuthState {
  final AuthSession session;

  const AuthStateAuthenticated(this.session);

  User get user => session.user;

  @override
  String toString() => 'AuthStateAuthenticated(user: ${user.email})';
}

/// The user is not authenticated.
final class AuthStateUnauthenticated extends AuthState {
  const AuthStateUnauthenticated();
}

/// An authentication error occurred (wrong credentials, server failure, etc.).
final class AuthStateError extends AuthState {
  final String message;
  final Object? cause;

  const AuthStateError(this.message, {this.cause});

  @override
  String toString() => 'AuthStateError($message)';
}

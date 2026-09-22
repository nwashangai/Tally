import '../../core/result/result.dart';
import 'auth_session.dart';
import 'auth_state.dart';

/// Abstract port for authentication operations.
/// Concrete implementations are isolated in the infrastructure layer.
/// Supports Google, Apple, and Facebook social sign-in.
abstract interface class AuthRepository {
  /// Emits the current authentication state and all future changes.
  Stream<AuthState> watchAuthState();

  /// Returns the current cached auth state synchronously (may be [AuthStateInitial]).
  AuthState get currentState;

  /// Attempts to restore a persisted session from secure storage.
  Future<Result<AuthSession?>> restoreSession();

  /// Initiates Google sign-in.
  Future<Result<AuthSession>> signInWithGoogle();

  /// Initiates Apple sign-in.
  Future<Result<AuthSession>> signInWithApple();

  /// Initiates Facebook sign-in.
  Future<Result<AuthSession>> signInWithFacebook();

  /// Signs out the current user and clears local session data.
  Future<Result<void>> signOut();
}

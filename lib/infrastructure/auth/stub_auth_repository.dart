import 'dart:async';
import '../../core/result/result.dart';
import '../../domain/auth/auth_repository.dart';
import '../../domain/auth/auth_session.dart';
import '../../domain/auth/auth_state.dart';

/// Stub AuthRepository for use during development before a backend provider is selected (ADR 0002).
/// This stub keeps the application compilable and testable without a real auth backend.
/// Replace with a provider-specific implementation once ADR 0002 is accepted.
class StubAuthRepository implements AuthRepository {
  final _controller = StreamController<AuthState>.broadcast(sync: true);
  AuthState _currentState = const AuthStateUnauthenticated();

  @override
  Stream<AuthState> watchAuthState() => _controller.stream;

  @override
  AuthState get currentState => _currentState;

  void _emit(AuthState state) {
    _currentState = state;
    _controller.add(state);
  }

  @override
  Future<Result<AuthSession?>> restoreSession() async {
    _emit(const AuthStateLoading());
    // No persisted session in stub — transition to unauthenticated.
    await Future<void>.delayed(const Duration(milliseconds: 100));
    _emit(const AuthStateUnauthenticated());
    return const Success(null);
  }

  @override
  Future<Result<AuthSession>> signInWithGoogle() async {
    throw UnimplementedError(
      'StubAuthRepository: signInWithGoogle is not implemented. '
      'Create an infrastructure adapter after ADR 0002 is accepted.',
    );
  }

  @override
  Future<Result<AuthSession>> signInWithApple() async {
    throw UnimplementedError(
      'StubAuthRepository: signInWithApple is not implemented. '
      'Create an infrastructure adapter after ADR 0002 is accepted.',
    );
  }

  @override
  Future<Result<AuthSession>> signInWithFacebook() async {
    throw UnimplementedError(
      'StubAuthRepository: signInWithFacebook is not implemented. '
      'Create an infrastructure adapter after ADR 0002 is accepted.',
    );
  }

  @override
  Future<Result<void>> signOut() async {
    _emit(const AuthStateUnauthenticated());
    return const Success(null);
  }

  void dispose() => _controller.close();
}

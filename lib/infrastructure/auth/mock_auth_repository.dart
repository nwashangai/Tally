import 'dart:async';
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../core/error/app_error.dart';
import '../../core/result/result.dart';
import '../../domain/auth/auth_repository.dart';
import '../../domain/auth/auth_session.dart';
import '../../domain/auth/auth_state.dart';
import '../../domain/auth/user.dart';

/// Mock implementation of [AuthRepository] for development, testing, and offline use.
/// Simulates Google, Apple, and Facebook authentication and persists session state
/// in [FlutterSecureStorage].
class MockAuthRepository implements AuthRepository {
  final FlutterSecureStorage _storage;
  final _controller = StreamController<AuthState>.broadcast(sync: true);
  AuthState _currentState = const AuthStateInitial();

  static const _sessionKey = 'tally_auth_session';

  MockAuthRepository({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  @override
  Stream<AuthState> watchAuthState() async* {
    yield _currentState;
    yield* _controller.stream;
  }

  @override
  AuthState get currentState => _currentState;

  void _emit(AuthState state) {
    _currentState = state;
    _controller.add(state);
  }

  @override
  Future<Result<AuthSession?>> restoreSession() async {
    try {
      _emit(const AuthStateLoading());
      final rawSession = await _storage.read(key: _sessionKey);
      if (rawSession != null && rawSession.isNotEmpty) {
        final json = jsonDecode(rawSession) as Map<String, Object?>;
        final session = AuthSession.fromJson(json);
        _emit(AuthStateAuthenticated(session));
        return Success(session);
      }

      _emit(const AuthStateUnauthenticated());
      return const Success(null);
    } catch (e, st) {
      _emit(const AuthStateUnauthenticated());
      return Failure(
        AuthenticationError('Failed to restore auth session: $e'),
        stackTrace: st,
      );
    }
  }

  @override
  Future<Result<AuthSession>> signInWithGoogle() async {
    return _mockSignIn(
      provider: 'google',
      userId: 'usr_google_101',
      email: 'alex.merchant@gmail.com',
      displayName: 'Alex (Google)',
    );
  }

  @override
  Future<Result<AuthSession>> signInWithApple() async {
    return _mockSignIn(
      provider: 'apple',
      userId: 'usr_apple_202',
      email: 'alex.merchant@icloud.com',
      displayName: 'Alex (Apple ID)',
    );
  }

  @override
  Future<Result<AuthSession>> signInWithFacebook() async {
    return _mockSignIn(
      provider: 'facebook',
      userId: 'usr_fb_303',
      email: 'alex.merchant@facebook.com',
      displayName: 'Alex (Facebook)',
    );
  }

  Future<Result<AuthSession>> _mockSignIn({
    required String provider,
    required String userId,
    required String email,
    required String displayName,
  }) async {
    try {
      _emit(const AuthStateLoading());
      await Future<void>.delayed(const Duration(milliseconds: 150));

      final user = User(
        id: userId,
        email: email,
        displayName: displayName,
      );

      final session = AuthSession(
        token: 'mock_jwt_token_${provider}_$userId',
        user: user,
        expiresAt: DateTime.now().toUtc().add(const Duration(days: 30)),
      );

      // Persist to secure storage
      await _storage.write(
        key: _sessionKey,
        value: jsonEncode(session.toJson()),
      );

      _emit(AuthStateAuthenticated(session));
      return Success(session);
    } catch (e, st) {
      _emit(const AuthStateUnauthenticated());
      return Failure(
        AuthenticationError('Failed to sign in with $provider: $e'),
        stackTrace: st,
      );
    }
  }

  @override
  Future<Result<void>> signOut() async {
    try {
      _emit(const AuthStateLoading());
      await _storage.delete(key: _sessionKey);
      _emit(const AuthStateUnauthenticated());
      return const Success(null);
    } catch (e, st) {
      return Failure(
        AuthenticationError('Failed to sign out: $e'),
        stackTrace: st,
      );
    }
  }

  void dispose() => _controller.close();
}

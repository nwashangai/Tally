import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tally/domain/auth/auth_state.dart';
import 'package:tally/infrastructure/auth/mock_auth_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  FlutterSecureStorage.setMockInitialValues({});

  group('MockAuthRepository', () {
    late MockAuthRepository repo;

    setUp(() {
      FlutterSecureStorage.setMockInitialValues({});
      repo = MockAuthRepository();
    });

    tearDown(() {
      repo.dispose();
    });

    test('initial state is AuthStateInitial', () {
      expect(repo.currentState, isA<AuthStateInitial>());
    });

    test('signInWithGoogle emits authenticated state and creates user',
        () async {
      final result = await repo.signInWithGoogle();

      expect(result.isSuccess, isTrue);
      final session = result.valueOrNull!;
      expect(session.user.id, 'usr_google_101');
      expect(session.user.email, 'alex.merchant@gmail.com');
      expect(repo.currentState, isA<AuthStateAuthenticated>());
    });

    test('signInWithApple produces Apple user identity', () async {
      final result = await repo.signInWithApple();

      expect(result.isSuccess, isTrue);
      final session = result.valueOrNull!;
      expect(session.user.id, 'usr_apple_202');
      expect(session.user.email, 'alex.merchant@icloud.com');
      expect(repo.currentState, isA<AuthStateAuthenticated>());
    });

    test('signInWithFacebook produces Facebook user identity', () async {
      final result = await repo.signInWithFacebook();

      expect(result.isSuccess, isTrue);
      final session = result.valueOrNull!;
      expect(session.user.id, 'usr_fb_303');
      expect(session.user.email, 'alex.merchant@facebook.com');
      expect(repo.currentState, isA<AuthStateAuthenticated>());
    });

    test('restoreSession recovers saved session from secure storage', () async {
      await repo.signInWithGoogle();

      // Create new repo instance sharing the same storage
      final repo2 = MockAuthRepository();
      final restoreResult = await repo2.restoreSession();

      expect(restoreResult.isSuccess, isTrue);
      expect(restoreResult.valueOrNull?.user.email, 'alex.merchant@gmail.com');
      expect(repo2.currentState, isA<AuthStateAuthenticated>());

      repo2.dispose();
    });

    test('signOut clears stored session and emits unauthenticated', () async {
      await repo.signInWithGoogle();
      expect(repo.currentState, isA<AuthStateAuthenticated>());

      final outResult = await repo.signOut();
      expect(outResult.isSuccess, isTrue);
      expect(repo.currentState, isA<AuthStateUnauthenticated>());

      // Verifying persistence cleared
      final repo3 = MockAuthRepository();
      final restore = await repo3.restoreSession();
      expect(restore.valueOrNull, isNull);
      expect(repo3.currentState, isA<AuthStateUnauthenticated>());
      repo3.dispose();
    });
  });
}

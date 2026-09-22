import 'package:flutter_test/flutter_test.dart';
import 'package:tally/domain/auth/auth_state.dart';
import 'package:tally/infrastructure/auth/stub_auth_repository.dart';

void main() {
  group('StubAuthRepository', () {
    late StubAuthRepository repo;

    setUp(() => repo = StubAuthRepository());
    tearDown(() => repo.dispose());

    test('initial state is unauthenticated', () {
      expect(repo.currentState, isA<AuthStateUnauthenticated>());
    });

    test('restoreSession transitions through loading then unauthenticated',
        () async {
      final states = <AuthState>[];
      final sub = repo.watchAuthState().listen(states.add);

      await repo.restoreSession();
      await sub.cancel();

      expect(states, [
        isA<AuthStateLoading>(),
        isA<AuthStateUnauthenticated>(),
      ]);
    });

    test('signOut emits unauthenticated', () async {
      final states = <AuthState>[];
      final sub = repo.watchAuthState().listen(states.add);

      await repo.signOut();
      await sub.cancel();

      expect(states, [isA<AuthStateUnauthenticated>()]);
    });

    test('restoreSession returns null session in stub', () async {
      final result = await repo.restoreSession();
      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull, isNull);
    });
  });
}

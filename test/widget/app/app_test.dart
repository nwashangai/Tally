import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tally/app/app.dart';
import 'package:tally/app/providers/core_providers.dart';
import 'package:tally/infrastructure/auth/stub_auth_repository.dart';

void main() {
  group('TallyApp', () {
    testWidgets('boots and displays initial splash/auth flow', (tester) async {
      final stubAuth = StubAuthRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(stubAuth),
          ],
          child: const TallyApp(),
        ),
      );

      // Verify app widget builds cleanly
      expect(find.byType(TallyApp), findsOneWidget);

      stubAuth.dispose();
    });
  });
}

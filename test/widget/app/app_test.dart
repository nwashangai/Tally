import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tally/app/app.dart';
import 'package:tally/app/providers/core_providers.dart';
import 'package:tally/application/auth/auth_state_provider.dart';
import 'package:tally/application/splash/splash_state_provider.dart';
import 'package:tally/domain/auth/auth_state.dart';
import 'package:tally/infrastructure/auth/mock_auth_repository.dart';
import 'package:tally/presentation/auth/sign_in_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  FlutterSecureStorage.setMockInitialValues({});

  group('TallyApp', () {
    testWidgets('boots and displays sign-in screen when unauthenticated',
        (tester) async {
      final mockAuth = MockAuthRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            splashCompletedProvider.overrideWith((ref) => true),
            authRepositoryProvider.overrideWithValue(mockAuth),
            authStateProvider.overrideWith(
              (ref) => Stream.value(const AuthStateUnauthenticated()),
            ),
          ],
          child: const TallyApp(),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Verify app renders sign-in screen
      expect(find.byType(TallyApp), findsOneWidget);
      expect(find.byType(SignInScreen), findsOneWidget);
      expect(find.text('Continue with Google'), findsOneWidget);
      expect(find.text('Continue with Apple'), findsOneWidget);
      expect(find.text('Continue with Facebook'), findsOneWidget);

      mockAuth.dispose();
    });
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tally/presentation/auth/sign_in_screen.dart';
import 'package:tally/presentation/design_system/widgets/tally_logo.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  FlutterSecureStorage.setMockInitialValues({});

  group('SignInScreen', () {
    testWidgets('renders brand logo, subtitle, and provider buttons',
        (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: SignInScreen(),
          ),
        ),
      );

      expect(find.byType(TallyLogo), findsOneWidget);
      expect(find.text('Small-Business Inventory & Stock Balancing'),
          findsOneWidget);
      expect(find.text('Continue with Google'), findsOneWidget);
      expect(find.text('Continue with Apple'), findsOneWidget);
      expect(find.text('Continue with Facebook'), findsOneWidget);
    });
  });
}

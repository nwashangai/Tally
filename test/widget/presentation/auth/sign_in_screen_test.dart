import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tally/presentation/auth/sign_in_screen.dart';

void main() {
  group('SignInScreen', () {
    testWidgets('renders brand title and subtitle', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SignInScreen(),
        ),
      );

      expect(find.text('Tally'), findsOneWidget);
      expect(find.text('Inventory simplified.'), findsOneWidget);
      expect(find.text('Authentication provider pending ADR 0002.'),
          findsOneWidget);
    });
  });
}

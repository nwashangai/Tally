import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tally/presentation/shell/tally_shell.dart';

void main() {
  group('TallyShell', () {
    testWidgets('renders app bar and placeholder message', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: TallyShell(),
        ),
      );

      expect(find.text('Tally'), findsOneWidget);
      expect(
        find.text('Foundation ready.'),
        findsOneWidget,
      );
    });
  });
}

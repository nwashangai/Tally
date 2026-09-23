import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tally/application/splash/splash_state_provider.dart';
import 'package:tally/presentation/design_system/widgets/orbiting_inventory_canvas.dart';
import 'package:tally/presentation/design_system/widgets/progressive_tally_writer.dart';
import 'package:tally/presentation/shell/splash_screen.dart';

void main() {
  group('SplashScreen', () {
    testWidgets(
        'renders orbiting canvas, progressive writer, tagline, and encryption badge',
        (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: SplashScreen(),
          ),
        ),
      );

      // Phase 1 (t = 0..1000ms): 3D Orbiting canvas is active
      expect(find.byType(OrbitingInventoryCanvas), findsOneWidget);

      // Advance animation to Phase 2 (t ~ 1500ms): Progressive writer becomes active
      await tester.pump(const Duration(milliseconds: 1500));
      expect(find.byType(ProgressiveTallyWriter), findsOneWidget);

      // Advance animation to Phase 3 (t ~ 2500ms): Taglines appear
      await tester.pump(const Duration(milliseconds: 1000));
      expect(find.text('Offline-First Inventory Ledger'), findsOneWidget);
      expect(find.text('Precision Stock Balancing'), findsOneWidget);
      expect(find.text('Encrypted Local Storage Active'), findsOneWidget);

      // Advance to full completion (past 2600ms)
      await tester.pump(const Duration(milliseconds: 500));
    });

    testWidgets('triggers splashCompletedProvider on completion',
        (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: SplashScreen(),
          ),
        ),
      );

      expect(container.read(splashCompletedProvider), isFalse);

      // Pump through animation duration (2600ms)
      await tester.pump(const Duration(milliseconds: 3000));

      expect(container.read(splashCompletedProvider), isTrue);
    });
  });
}

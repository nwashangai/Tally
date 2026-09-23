import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tally/presentation/design_system/widgets/animated_tally_logo.dart';
import 'package:tally/presentation/design_system/widgets/tally_logo.dart';

void main() {
  group('TallyLogo', () {
    testWidgets('renders all variants cleanly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                TallyLogo(variant: TallyLogoVariant.markOnly),
                TallyLogo(variant: TallyLogoVariant.fullWordmark),
                TallyLogo(variant: TallyLogoVariant.horizontalWithMark),
              ],
            ),
          ),
        ),
      );

      expect(find.byType(TallyLogo), findsNWidgets(3));
      expect(find.text('Tally'), findsOneWidget); // In horizontalWithMark
    });

    testWidgets('AnimatedTallyLogo animates and executes callback on finish',
        (tester) async {
      var completed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AnimatedTallyLogo(
              duration: const Duration(milliseconds: 200),
              onAnimationComplete: () => completed = true,
            ),
          ),
        ),
      );

      expect(find.byType(AnimatedTallyLogo), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 300));
      expect(completed, isTrue);
    });
  });
}

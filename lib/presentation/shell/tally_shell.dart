import 'package:flutter/material.dart';
import '../design_system/tokens/colors.dart';

/// Authenticated application shell.
/// Navigation structure will be implemented in subsequent feature slices.
class TallyShell extends StatelessWidget {
  const TallyShell({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: TallyColors.lightCanvas,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Tally',
              style: TextStyle(
                color: TallyColors.primaryNavy,
                fontSize: 40,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Foundation ready.',
              style: TextStyle(
                color: TallyColors.slateMuted,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

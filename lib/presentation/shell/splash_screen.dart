import 'package:flutter/material.dart';
import '../design_system/tokens/colors.dart';

/// Application splash screen displayed during initial auth resolution.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: TallyColors.primaryNavy,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Tally',
              style: TextStyle(
                color: TallyColors.iceFrost,
                fontSize: 40,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
              ),
            ),
            SizedBox(height: 24),
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: TallyColors.slateMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../design_system/tokens/colors.dart';

/// Placeholder sign-in screen.
/// Real implementation depends on ADR 0002 (backend provider) and ADR 0006 (auth architecture).
class SignInScreen extends StatelessWidget {
  const SignInScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: TallyColors.primaryNavy,
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(32),
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
              SizedBox(height: 8),
              Text(
                'Inventory simplified.',
                style: TextStyle(
                  color: TallyColors.slateMuted,
                  fontSize: 14,
                  letterSpacing: 0.5,
                ),
              ),
              SizedBox(height: 64),
              Text(
                'Authentication provider pending ADR 0002.',
                textAlign: TextAlign.center,
                style: TextStyle(color: TallyColors.slateMuted, fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

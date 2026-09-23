import 'package:flutter/material.dart';
import '../design_system/tokens/colors.dart';
import '../design_system/tokens/dimensions.dart';

class SalesPlaceholderScreen extends StatelessWidget {
  const SalesPlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TallyColors.lightCanvas,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(TallySpacing.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(TallySpacing.xl),
                decoration: BoxDecoration(
                  color: TallyColors.primaryNavy.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.point_of_sale_rounded,
                  size: 56,
                  color: TallyColors.primaryNavy,
                ),
              ),
              const SizedBox(height: TallySpacing.lg),
              const Text(
                'Sales & Register',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: TallyColors.primaryNavy,
                ),
              ),
              const SizedBox(height: TallySpacing.sm),
              const Text(
                'Point of Sale, instant checkout, and sales ledger entries.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: TallyColors.slateMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

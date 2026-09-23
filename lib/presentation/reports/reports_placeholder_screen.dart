import 'package:flutter/material.dart';
import '../design_system/tokens/colors.dart';
import '../design_system/tokens/dimensions.dart';

class ReportsPlaceholderScreen extends StatelessWidget {
  const ReportsPlaceholderScreen({super.key});

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
                  color: const Color(0xFF8B5CF6).withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.insert_chart_outlined_rounded,
                  size: 56,
                  color: Color(0xFF8B5CF6),
                ),
              ),
              const SizedBox(height: TallySpacing.lg),
              const Text(
                'Reports & Analytics',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: TallyColors.primaryNavy,
                ),
              ),
              const SizedBox(height: TallySpacing.sm),
              const Text(
                'Stock variance reconciliation, movement audit trails, inventory valuation, and sales velocity.',
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

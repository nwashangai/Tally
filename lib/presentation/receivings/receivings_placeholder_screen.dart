import 'package:flutter/material.dart';
import '../design_system/tokens/colors.dart';
import '../design_system/tokens/dimensions.dart';

class ReceivingsPlaceholderScreen extends StatelessWidget {
  const ReceivingsPlaceholderScreen({super.key});

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
                  color: const Color(0xFF0284C7).withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.local_shipping_outlined,
                  size: 56,
                  color: Color(0xFF0284C7),
                ),
              ),
              const SizedBox(height: TallySpacing.lg),
              const Text(
                'Receivings & Inbound Stock',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: TallyColors.primaryNavy,
                ),
              ),
              const SizedBox(height: TallySpacing.sm),
              const Text(
                'Supplier purchase orders, inbound goods verification, and stock additions.',
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

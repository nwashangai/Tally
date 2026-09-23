import 'package:flutter/material.dart';
import '../design_system/tokens/colors.dart';
import '../design_system/tokens/dimensions.dart';

class ItemsPlaceholderScreen extends StatelessWidget {
  const ItemsPlaceholderScreen({super.key});

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
                  color: TallyColors.varianceZeroLight.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.inventory_2_outlined,
                  size: 56,
                  color: TallyColors.varianceZeroLight,
                ),
              ),
              const SizedBox(height: TallySpacing.lg),
              const Text(
                'Items & Inventory',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: TallyColors.primaryNavy,
                ),
              ),
              const SizedBox(height: TallySpacing.sm),
              const Text(
                'Item catalog, SKUs, barcode scanning, stock levels, and price tags.',
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

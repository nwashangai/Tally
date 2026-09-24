import 'package:flutter/material.dart';
import '../tokens/colors.dart';
import '../tokens/dimensions.dart';

/// Standardized removable filter chip for enterprise filter bars.
class TallyFilterChip extends StatelessWidget {
  final String label;
  final VoidCallback onDeleted;
  final Color? backgroundColor;
  final TextStyle? labelStyle;

  const TallyFilterChip({
    super.key,
    required this.label,
    required this.onDeleted,
    this.backgroundColor,
    this.labelStyle,
  });

  @override
  Widget build(BuildContext context) {
    return InputChip(
      label: Text(label),
      onDeleted: onDeleted,
      deleteIconColor: TallyColors.slateMuted,
      backgroundColor: backgroundColor ?? TallyColors.iceFrost,
      labelStyle: labelStyle ??
          const TextStyle(
            fontSize: 12,
            color: TallyColors.primaryNavy,
          ),
    );
  }
}

/// Standardized horizontal strip displaying active filter chips and a "Clear all" button.
class TallyFilterChipsBar extends StatelessWidget {
  final List<Widget> chips;
  final VoidCallback onClearAll;
  final String clearAllLabel;
  final Color clearAllColor;

  const TallyFilterChipsBar({
    super.key,
    required this.chips,
    required this.onClearAll,
    this.clearAllLabel = 'Clear all',
    this.clearAllColor = TallyColors.stockCritical,
  });

  @override
  Widget build(BuildContext context) {
    if (chips.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: TallySpacing.xs),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            ...chips.map(
              (chip) => Padding(
                padding: const EdgeInsets.only(right: TallySpacing.xs),
                child: chip,
              ),
            ),
            TextButton(
              onPressed: onClearAll,
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                foregroundColor: clearAllColor,
              ),
              child: Text(
                clearAllLabel,
                style: TextStyle(
                  fontSize: 12,
                  color: clearAllColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

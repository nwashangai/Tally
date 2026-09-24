import 'package:flutter/material.dart';
import '../tokens/colors.dart';
import '../tokens/dimensions.dart';

/// Uniform cancel / dismiss button across all Tally screens, dialogs, and sheets.
class TallyCancelButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String label;
  final EdgeInsetsGeometry? padding;

  const TallyCancelButton({
    super.key,
    required this.onPressed,
    this.label = 'Cancel',
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: TallyColors.buttonCancelBackground,
        foregroundColor: TallyColors.buttonCancelForeground,
        elevation: 0,
        shadowColor: Colors.transparent,
        padding: padding ??
            const EdgeInsets.symmetric(
              horizontal: TallySpacing.xl,
              vertical: TallySpacing.md,
            ),
        shape: const StadiumBorder(),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
    );
  }
}

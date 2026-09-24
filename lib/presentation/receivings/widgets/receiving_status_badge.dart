import 'package:flutter/material.dart';
import '../../../domain/receiving/receiving_status.dart';
import '../../design_system/tokens/colors.dart';
import '../../design_system/tokens/dimensions.dart';

/// Uniform status badge for Receiving transactions (Draft, Completed, Voided).
class ReceivingStatusBadge extends StatelessWidget {
  final ReceivingStatus status;

  const ReceivingStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    IconData icon;
    String label;

    switch (status) {
      case ReceivingStatus.draft:
        bg = TallyColors.slateMuted.withValues(alpha: 0.12);
        fg = TallyColors.slateMuted;
        icon = Icons.edit_note_outlined;
        label = 'Draft';
        break;
      case ReceivingStatus.completed:
        bg = TallyColors.varianceZeroLight.withValues(alpha: 0.15);
        fg = TallyColors.varianceZeroLight;
        icon = Icons.check_circle_outline;
        label = 'Completed';
        break;
      case ReceivingStatus.voided:
        bg = TallyColors.stockCritical.withValues(alpha: 0.12);
        fg = TallyColors.stockCritical;
        icon = Icons.cancel_outlined;
        label = 'Voided';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(TallyRadii.full),
        border: Border.all(color: fg.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: fg),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: fg,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

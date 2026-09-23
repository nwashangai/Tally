import 'package:flutter/material.dart';
import '../../../domain/item/item.dart';
import '../../design_system/tokens/colors.dart';
import '../../design_system/tokens/dimensions.dart';
import '../../design_system/widgets/tally_cancel_button.dart';

enum ItemDeleteAction {
  archive,
  delete,
}

/// Confirmation dialog enforcing domain rules for Item deletion vs archiving.
///
/// **Domain Rule (ADR 0012)**:
/// - Items with transaction history cannot be deleted; they must be archived to protect ledger integrity.
/// - Items with NO transaction history can be permanently deleted or archived.
class ItemDeleteConfirmDialog extends StatelessWidget {
  final Item item;

  const ItemDeleteConfirmDialog({
    super.key,
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    final hasHistory = item.hasTransactions;

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(TallyRadii.lg),
      ),
      title: Row(
        children: [
          Icon(
            hasHistory ? Icons.archive_outlined : Icons.warning_amber_rounded,
            color:
                hasHistory ? TallyColors.slateMuted : TallyColors.stockCritical,
            size: 28,
          ),
          const SizedBox(width: TallySpacing.sm),
          Expanded(
            child: Text(
              hasHistory ? 'Archive Item' : 'Delete or Archive Item',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: TallyColors.primaryNavy,
              ),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: TextSpan(
              style: const TextStyle(
                fontSize: 14,
                color: TallyColors.primaryNavy,
                height: 1.4,
              ),
              children: [
                const TextSpan(text: 'Are you sure you want to proceed for '),
                TextSpan(
                  text: '"${item.name}"',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const TextSpan(text: '?'),
              ],
            ),
          ),
          const SizedBox(height: TallySpacing.md),
          if (hasHistory)
            Container(
              padding: const EdgeInsets.all(TallySpacing.md),
              decoration: BoxDecoration(
                color: TallyColors.iceFrost,
                borderRadius: BorderRadius.circular(TallyRadii.md),
                border: Border.all(color: TallyColors.lightBorderStrong),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 20,
                    color: TallyColors.primaryNavy,
                  ),
                  SizedBox(width: TallySpacing.sm),
                  Expanded(
                    child: Text(
                      'This item has transaction history in your record book. Permanent deletion is disabled to preserve ledger consistency. Archiving will hide it from active lists while maintaining past records.',
                      style: TextStyle(
                        fontSize: 13,
                        color: TallyColors.primaryNavy,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(TallySpacing.md),
              decoration: BoxDecoration(
                color: TallyColors.stockCritical.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(TallyRadii.md),
                border: Border.all(
                  color: TallyColors.stockCritical.withValues(alpha: 0.3),
                ),
              ),
              child: const Text(
                'This item has no recorded transactions. You can permanently delete it, or archive it to keep it for later.',
                style: TextStyle(
                  fontSize: 13,
                  color: TallyColors.stockCritical,
                ),
              ),
            ),
        ],
      ),
      actionsOverflowButtonSpacing: TallySpacing.xs,
      actionsOverflowDirection: VerticalDirection.down,
      actionsPadding: const EdgeInsets.symmetric(
        horizontal: TallySpacing.md,
        vertical: TallySpacing.sm,
      ),
      actions: [
        TallyCancelButton(
          onPressed: () => Navigator.of(context).pop(),
        ),
        ElevatedButton.icon(
          onPressed: () => Navigator.of(context).pop(ItemDeleteAction.archive),
          icon: const Icon(Icons.archive_outlined, size: 18),
          label: const Text('Archive'),
          style: ElevatedButton.styleFrom(
            backgroundColor: TallyColors.iceFrost,
            foregroundColor: TallyColors.primaryNavy,
            elevation: 0,
            shape: const StadiumBorder(),
          ),
        ),
        if (!hasHistory)
          ElevatedButton.icon(
            onPressed: () => Navigator.of(context).pop(ItemDeleteAction.delete),
            icon: const Icon(Icons.delete_forever, size: 18),
            label: const Text('Permanent Delete'),
            style: ElevatedButton.styleFrom(
              backgroundColor: TallyColors.stockCritical,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: const StadiumBorder(),
            ),
          ),
      ],
    );
  }
}

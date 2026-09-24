import 'package:flutter/material.dart';
import '../../../domain/store/store.dart';
import '../../design_system/tokens/colors.dart';
import '../../design_system/tokens/dimensions.dart';
import '../../design_system/widgets/tally_cancel_button.dart';

/// Confirmation dialog enforcing double-opt-in confirmation for permanent store deletion.
///
/// **Safety Invariant**:
/// - Deleting a store permanently wipes its encrypted SQLite database, catalogs, receivings,
///   transactions, audit logs, and reports.
/// - Requires user to explicitly type "delete" (case-insensitive) before the destructive action is unlocked.
class StoreDeleteConfirmDialog extends StatefulWidget {
  final Store store;

  const StoreDeleteConfirmDialog({
    super.key,
    required this.store,
  });

  @override
  State<StoreDeleteConfirmDialog> createState() =>
      _StoreDeleteConfirmDialogState();
}

class _StoreDeleteConfirmDialogState extends State<StoreDeleteConfirmDialog> {
  final TextEditingController _confirmController = TextEditingController();
  bool _isConfirmed = false;

  @override
  void initState() {
    super.initState();
    _confirmController.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    final matches = _confirmController.text.trim().toLowerCase() == 'delete';
    if (matches != _isConfirmed) {
      setState(() {
        _isConfirmed = matches;
      });
    }
  }

  @override
  void dispose() {
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(TallyRadii.lg),
      ),
      titlePadding: const EdgeInsets.fromLTRB(
        TallySpacing.xl,
        TallySpacing.xl,
        TallySpacing.xl,
        TallySpacing.sm,
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: TallySpacing.xl,
        vertical: TallySpacing.sm,
      ),
      actionsPadding: const EdgeInsets.all(TallySpacing.md),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(TallySpacing.xs),
            decoration: BoxDecoration(
              color: TallyColors.stockCritical.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.warning_amber_rounded,
              color: TallyColors.stockCritical,
              size: 26,
            ),
          ),
          const SizedBox(width: TallySpacing.sm),
          const Expanded(
            child: Text(
              'Delete Store',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: TallyColors.primaryNavy,
              ),
            ),
          ),
        ],
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Column(
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
                  const TextSpan(
                    text: 'Are you sure you want to permanently delete ',
                  ),
                  TextSpan(
                    text: '"${widget.store.name}"',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const TextSpan(text: '?'),
                ],
              ),
            ),
            const SizedBox(height: TallySpacing.md),
            Container(
              padding: const EdgeInsets.all(TallySpacing.md),
              decoration: BoxDecoration(
                color: TallyColors.stockCritical.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(TallyRadii.md),
                border: Border.all(
                  color: TallyColors.stockCritical.withValues(alpha: 0.3),
                ),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 20,
                    color: TallyColors.stockCritical,
                  ),
                  SizedBox(width: TallySpacing.sm),
                  Expanded(
                    child: Text(
                      'Warning: This action is permanent and cannot be undone. All local SQLite database files, items, receivings, stock movements, and financial reports will be erased.',
                      style: TextStyle(
                        fontSize: 12,
                        color: TallyColors.stockCritical,
                        fontWeight: FontWeight.w500,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: TallySpacing.lg),
            const Text(
              'Type "delete" to confirm:',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: TallyColors.primaryNavy,
              ),
            ),
            const SizedBox(height: TallySpacing.xs),
            TextField(
              controller: _confirmController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'delete',
                hintStyle: const TextStyle(color: TallyColors.slateMuted),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: TallySpacing.md,
                  vertical: TallySpacing.sm,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(TallyRadii.md),
                  borderSide: const BorderSide(color: TallyColors.lightBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(TallyRadii.md),
                  borderSide: const BorderSide(
                    color: TallyColors.stockCritical,
                    width: 1.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TallyCancelButton(
          onPressed: () => Navigator.of(context).pop(false),
        ),
        ElevatedButton.icon(
          onPressed: _isConfirmed
              ? () => Navigator.of(context).pop(true)
              : null,
          icon: const Icon(Icons.delete_forever, size: 18),
          label: const Text('Delete Store'),
          style: ElevatedButton.styleFrom(
            backgroundColor: TallyColors.stockCritical,
            disabledBackgroundColor:
                TallyColors.stockCritical.withValues(alpha: 0.3),
            foregroundColor: Colors.white,
            disabledForegroundColor: Colors.white.withValues(alpha: 0.6),
            elevation: 0,
            shape: const StadiumBorder(),
          ),
        ),
      ],
    );
  }
}

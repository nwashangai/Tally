import 'package:flutter/material.dart';
import '../tokens/colors.dart';
import '../tokens/dimensions.dart';

/// Reusable sortable column header widget for enterprise data tables.
class TallySortableHeader extends StatelessWidget {
  final String label;
  final bool isSorted;
  final bool isAscending;
  final VoidCallback? onTap;

  const TallySortableHeader({
    super.key,
    required this.label,
    required this.isSorted,
    this.isAscending = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(TallyRadii.sm),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color:
                    isSorted ? TallyColors.primaryNavy : TallyColors.slateMuted,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              isSorted
                  ? (isAscending ? Icons.arrow_upward : Icons.arrow_downward)
                  : Icons.sort,
              size: 14,
              color:
                  isSorted ? TallyColors.primaryNavy : TallyColors.slateMuted,
            ),
          ],
        ),
      ),
    );
  }
}

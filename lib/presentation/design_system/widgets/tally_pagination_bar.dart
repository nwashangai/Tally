import 'package:flutter/material.dart';
import '../tokens/colors.dart';
import '../tokens/dimensions.dart';

/// Standardized enterprise pagination bar for list and table views.
class TallyPaginationBar extends StatelessWidget {
  final int page;
  final int totalPages;
  final int totalItems;
  final int startIndex;
  final int endIndex;
  final String itemLabel;
  final bool hasPreviousPage;
  final bool hasNextPage;
  final VoidCallback? onPreviousPage;
  final VoidCallback? onNextPage;
  final int? pageSize;
  final List<int>? availablePageSizes;
  final ValueChanged<int>? onPageSizeChanged;
  final bool isPhone;

  const TallyPaginationBar({
    super.key,
    required this.page,
    required this.totalPages,
    required this.totalItems,
    required this.startIndex,
    required this.endIndex,
    this.itemLabel = 'items',
    required this.hasPreviousPage,
    required this.hasNextPage,
    required this.onPreviousPage,
    required this.onNextPage,
    this.pageSize,
    this.availablePageSizes,
    this.onPageSizeChanged,
    this.isPhone = false,
  });

  @override
  Widget build(BuildContext context) {
    final rangeText = totalItems == 0
        ? '0 $itemLabel'
        : isPhone
            ? '$startIndex–$endIndex of $totalItems'
            : 'Showing $startIndex–$endIndex of $totalItems $itemLabel';

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: TallySpacing.md,
        vertical: TallySpacing.xs,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(TallyRadii.md),
        border: Border.all(color: TallyColors.lightBorder),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Range summary
          Expanded(
            child: Text(
              rangeText,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: TallyColors.slateMuted,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // Controls
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Optional per-page dropdown on tablet/desktop
              if (!isPhone &&
                  pageSize != null &&
                  onPageSizeChanged != null &&
                  availablePageSizes != null &&
                  availablePageSizes!.isNotEmpty) ...[
                const Text(
                  'Per page: ',
                  style: TextStyle(fontSize: 12, color: TallyColors.slateMuted),
                ),
                DropdownButton<int>(
                  value: pageSize,
                  underline: const SizedBox.shrink(),
                  items: availablePageSizes!
                      .map(
                        (size) => DropdownMenuItem(
                          value: size,
                          child: Text('$size'),
                        ),
                      )
                      .toList(),
                  onChanged: (val) {
                    if (val != null) onPageSizeChanged!(val);
                  },
                ),
                const SizedBox(width: TallySpacing.md),
              ],

              // Previous page chevron
              IconButton(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.all(4),
                constraints: const BoxConstraints(),
                icon: const Icon(Icons.chevron_left, size: 20),
                onPressed: hasPreviousPage ? onPreviousPage : null,
                tooltip: 'Previous page',
              ),
              const SizedBox(width: 4),

              // Page counter
              Text(
                '$page / $totalPages',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: TallyColors.primaryNavy,
                ),
              ),
              const SizedBox(width: 4),

              // Next page chevron
              IconButton(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.all(4),
                constraints: const BoxConstraints(),
                icon: const Icon(Icons.chevron_right, size: 20),
                onPressed: hasNextPage ? onNextPage : null,
                tooltip: 'Next page',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

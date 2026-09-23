import 'package:flutter/material.dart';
import '../../../domain/item/item.dart';
import '../../design_system/tokens/colors.dart';
import '../../design_system/tokens/dimensions.dart';

/// Scannable, information-rich card presentation for phone viewports.
class ItemMobileCard extends StatelessWidget {
  final Item item;
  final bool isSelected;
  final ValueChanged<bool?>? onSelectChanged;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onArchive;
  final VoidCallback onDelete;

  const ItemMobileCard({
    super.key,
    required this.item,
    required this.isSelected,
    this.onSelectChanged,
    required this.onTap,
    required this.onEdit,
    required this.onArchive,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final inventory = item.inventory;
    final pricing = item.pricing;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(TallyRadii.md),
        side: BorderSide(
          color: isSelected ? TallyColors.primaryNavy : TallyColors.lightBorder,
          width: isSelected ? 1.5 : 1.0,
        ),
      ),
      color: isSelected
          ? TallyColors.iceFrost.withValues(alpha: 0.3)
          : Colors.white,
      margin: const EdgeInsets.only(bottom: TallySpacing.sm),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(TallyRadii.md),
        child: Padding(
          padding: const EdgeInsets.all(TallySpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Header: Name, Category, & Context Menu
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (onSelectChanged != null)
                    Padding(
                      padding: const EdgeInsets.only(right: TallySpacing.xs),
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: Checkbox(
                          value: isSelected,
                          onChanged: onSelectChanged,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: TallyColors.primaryNavy,
                          ),
                        ),
                        if (item.sku != null && item.sku!.isNotEmpty)
                          Text(
                            'SKU: ${item.sku}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: TallyColors.slateMuted,
                            ),
                          ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(
                      Icons.more_vert,
                      size: 20,
                      color: TallyColors.slateMuted,
                    ),
                    padding: EdgeInsets.zero,
                    onSelected: (action) {
                      switch (action) {
                        case 'view':
                          onTap();
                          break;
                        case 'edit':
                          onEdit();
                          break;
                        case 'archive':
                          onArchive();
                          break;
                        case 'delete':
                          onDelete();
                          break;
                      }
                    },
                    itemBuilder: (ctx) => [
                      const PopupMenuItem(
                        value: 'view',
                        child: Row(
                          children: [
                            Icon(Icons.visibility_outlined, size: 18),
                            SizedBox(width: TallySpacing.sm),
                            Text('View details'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit_outlined, size: 18),
                            SizedBox(width: TallySpacing.sm),
                            Text('Edit item'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'archive',
                        child: Row(
                          children: [
                            Icon(
                              item.isActive
                                  ? Icons.archive_outlined
                                  : Icons.unarchive_outlined,
                              size: 18,
                            ),
                            const SizedBox(width: TallySpacing.sm),
                            Text(item.isActive ? 'Archive' : 'Reactivate'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(
                              Icons.delete_outline,
                              size: 18,
                              color: TallyColors.stockCritical,
                            ),
                            SizedBox(width: TallySpacing.sm),
                            Text(
                              'Delete',
                              style:
                                  TextStyle(color: TallyColors.stockCritical),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: TallySpacing.sm),

              // 2. Stock & Pricing Metrics Grid
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: TallySpacing.sm,
                  vertical: TallySpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: TallyColors.iceFrost.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(TallyRadii.sm),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Stock
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Stock',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: TallyColors.slateMuted,
                          ),
                        ),
                        Row(
                          children: [
                            Text(
                              '${inventory.quantity.toStringAsFixed(inventory.quantity % 1 == 0 ? 0 : 2)} ${item.unit.abbreviation}',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: TallyColors.primaryNavy,
                              ),
                            ),
                            if (inventory.isLowStock) ...[
                              const SizedBox(width: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 1,
                                ),
                                decoration: BoxDecoration(
                                  color: TallyColors.varianceDiscrepancy
                                      .withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'LOW',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    color: TallyColors.varianceDiscrepancy,
                                  ),
                                ),
                              ),
                            ] else if (inventory.isOutOfStock) ...[
                              const SizedBox(width: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 1,
                                ),
                                decoration: BoxDecoration(
                                  color: TallyColors.stockCritical
                                      .withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'OUT',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    color: TallyColors.stockCritical,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),

                    // Cost Price
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Cost',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: TallyColors.slateMuted,
                          ),
                        ),
                        Text(
                          '₦${pricing.costPrice.toStringAsFixed(pricing.costPrice % 1 == 0 ? 0 : 2)}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: TallyColors.slateMuted,
                          ),
                        ),
                      ],
                    ),

                    // Selling Price
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Selling',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: TallyColors.slateMuted,
                          ),
                        ),
                        Text(
                          '₦${pricing.baseSellingPrice.toStringAsFixed(pricing.baseSellingPrice % 1 == 0 ? 0 : 2)}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: TallyColors.varianceZeroLight,
                          ),
                        ),
                      ],
                    ),

                    // Min Price
                    if (pricing.minSellingPrice != null)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Min Price',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: TallyColors.slateMuted,
                            ),
                          ),
                          Text(
                            '₦${pricing.minSellingPrice!.toStringAsFixed(pricing.minSellingPrice! % 1 == 0 ? 0 : 2)}',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: TallyColors.primaryNavy,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              const SizedBox(height: TallySpacing.xs),

              // 3. Category & Status Footer
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    item.categoryId != null && item.categoryId!.isNotEmpty
                        ? item.categoryId!
                        : 'Uncategorized',
                    style: const TextStyle(
                      fontSize: 11,
                      color: TallyColors.slateMuted,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: item.isActive
                          ? TallyColors.varianceZeroLight
                              .withValues(alpha: 0.12)
                          : TallyColors.slateMuted.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      item.isActive ? 'Active' : 'Archived',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: item.isActive
                            ? TallyColors.varianceZeroLight
                            : TallyColors.slateMuted,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../app/providers/core_providers.dart';
import '../../../domain/item/item.dart';
import '../../../domain/item/item_column.dart';
import '../../../domain/item/item_query.dart';
import '../../design_system/tokens/colors.dart';
import '../../design_system/tokens/dimensions.dart';
import '../../design_system/widgets/tally_sortable_header.dart';
import '../../design_system/widgets/tally_table_container.dart';

/// Full-featured data table for desktop and tablet viewports.
class ItemDesktopTable extends ConsumerWidget {
  final List<Item> items;
  final ValueChanged<Item> onViewItem;
  final ValueChanged<Item> onEditItem;
  final ValueChanged<Item> onArchiveItem;
  final ValueChanged<Item> onDeleteItem;

  const ItemDesktopTable({
    super.key,
    required this.items,
    required this.onViewItem,
    required this.onEditItem,
    required this.onArchiveItem,
    required this.onDeleteItem,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = ref.watch(itemQueryProvider);
    final columnState = ref.watch(itemColumnPreferencesProvider);
    final selectedIds = ref.watch(itemSelectionProvider);
    final selectionNotifier = ref.read(itemSelectionProvider.notifier);
    final queryNotifier = ref.read(itemQueryProvider.notifier);

    final visibleColumns =
        ItemColumn.values.where(columnState.visibleColumns.contains).toList();

    final allVisibleSelected =
        items.isNotEmpty && items.every((i) => selectedIds.contains(i.id));

    final dateFormat = DateFormat('yyyy-MM-dd HH:mm');

    return TallyTableContainer(
      child: DataTable(
        showCheckboxColumn: false,
        headingRowHeight: 44,
        dataRowMinHeight: 48,
        dataRowMaxHeight: 52,
        horizontalMargin: 16,
        columnSpacing: 24,
        headingRowColor: WidgetStateProperty.all(
          TallyColors.iceFrost.withValues(alpha: 0.5),
        ),
        columns: [
          // Selection Checkbox Column
          DataColumn(
            label: SizedBox(
              width: 24,
              height: 24,
              child: Checkbox(
                value: allVisibleSelected,
                tristate: selectedIds.isNotEmpty && !allVisibleSelected,
                onChanged: (_) =>
                    selectionNotifier.toggleAllVisible(items),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ),

          // Dynamic Visible Columns
          ...visibleColumns.map((col) {
            final sortField = _sortFieldFor(col);
            final isSorted =
                sortField != null && query.sort.field == sortField;

            return DataColumn(
              label: TallySortableHeader(
                label: col.label,
                isSorted: isSorted,
                isAscending: query.sort.order == SortOrder.ascending,
                onTap: sortField != null
                    ? () => queryNotifier.setSortField(sortField)
                    : null,
              ),
            );
          }),

          // Actions Column
                const DataColumn(
                  label: Text(
                    'Actions',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: TallyColors.slateMuted,
                    ),
                  ),
                ),
              ],
              rows: items.map((item) {
                final isSelected = selectedIds.contains(item.id);

                return DataRow(
                  selected: isSelected,
                  onSelectChanged: (_) => selectionNotifier.toggle(item.id),
                  cells: [
                    // Checkbox Cell
                    DataCell(
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: Checkbox(
                          value: isSelected,
                          onChanged: (_) => selectionNotifier.toggle(item.id),
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ),

                    // Dynamic Column Cells
                    ...visibleColumns.map((col) => _buildCell(
                          item,
                          col,
                          dateFormat,
                          () => onViewItem(item),
                        )),

                    // Actions Cell
                    DataCell(
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon:
                                const Icon(Icons.visibility_outlined, size: 18),
                            tooltip: 'View details',
                            onPressed: () => onViewItem(item),
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, size: 18),
                            tooltip: 'Edit item',
                            onPressed: () => onEditItem(item),
                          ),
                          PopupMenuButton<String>(
                            icon: const Icon(Icons.more_vert, size: 18),
                            onSelected: (action) {
                              if (action == 'archive') {
                                onArchiveItem(item);
                              } else if (action == 'delete') {
                                onDeleteItem(item);
                              }
                            },
                            itemBuilder: (_) => [
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
                                    Text(item.isActive
                                        ? 'Archive'
                                        : 'Reactivate'),
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
                                      style: TextStyle(
                                        color: TallyColors.stockCritical,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
    );
  }

  DataCell _buildCell(
    Item item,
    ItemColumn column,
    DateFormat dateFormat,
    VoidCallback onTapName,
  ) {
    switch (column) {
      case ItemColumn.name:
        return DataCell(
          InkWell(
            onTap: onTapName,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: TallyColors.primaryNavy,
                  ),
                ),
                if (item.sku != null && item.sku!.isNotEmpty)
                  Text(
                    item.sku!,
                    style: const TextStyle(
                      fontSize: 11,
                      color: TallyColors.slateMuted,
                    ),
                  ),
              ],
            ),
          ),
        );
      case ItemColumn.sku:
        return DataCell(
          Text(
            item.sku ?? '-',
            style: const TextStyle(fontSize: 13, color: TallyColors.slateMuted),
          ),
        );
      case ItemColumn.barcode:
        return DataCell(
          Text(
            item.barcode ?? '-',
            style: const TextStyle(fontSize: 13, color: TallyColors.slateMuted),
          ),
        );
      case ItemColumn.category:
        return DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: TallyColors.iceFrost,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              item.categoryId ?? 'Uncategorized',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: TallyColors.primaryNavy,
              ),
            ),
          ),
        );
      case ItemColumn.unit:
        return DataCell(
          Text(
            item.unit.label,
            style:
                const TextStyle(fontSize: 13, color: TallyColors.primaryNavy),
          ),
        );
      case ItemColumn.stock:
        final qty = item.inventory.quantity;
        return DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${qty.toStringAsFixed(qty % 1 == 0 ? 0 : 2)} ${item.unit.abbreviation}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: TallyColors.primaryNavy,
                ),
              ),
              if (item.inventory.isLowStock) ...[
                const SizedBox(width: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color:
                        TallyColors.varianceDiscrepancy.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        size: 10,
                        color: TallyColors.varianceDiscrepancy,
                      ),
                      SizedBox(width: 2),
                      Text(
                        'LOW',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: TallyColors.varianceDiscrepancy,
                        ),
                      ),
                    ],
                  ),
                ),
              ] else if (item.inventory.isOutOfStock) ...[
                const SizedBox(width: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: TallyColors.stockCritical.withValues(alpha: 0.2),
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
        );
      case ItemColumn.reorderLevel:
        return DataCell(
          Text(
            item.inventory.reorderLevel != null
                ? item.inventory.reorderLevel!.toStringAsFixed(0)
                : '-',
            style: const TextStyle(fontSize: 13, color: TallyColors.slateMuted),
          ),
        );
      case ItemColumn.costPrice:
        return DataCell(
          Text(
            '₦${item.pricing.costPrice.toStringAsFixed(item.pricing.costPrice % 1 == 0 ? 0 : 2)}',
            style: const TextStyle(fontSize: 13, color: TallyColors.slateMuted),
          ),
        );
      case ItemColumn.baseSellingPrice:
        return DataCell(
          Text(
            '₦${item.pricing.baseSellingPrice.toStringAsFixed(item.pricing.baseSellingPrice % 1 == 0 ? 0 : 2)}',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: TallyColors.varianceZeroLight,
            ),
          ),
        );
      case ItemColumn.minSellingPrice:
        return DataCell(
          Text(
            item.pricing.minSellingPrice != null
                ? '₦${item.pricing.minSellingPrice!.toStringAsFixed(item.pricing.minSellingPrice! % 1 == 0 ? 0 : 2)}'
                : '-',
            style:
                const TextStyle(fontSize: 13, color: TallyColors.primaryNavy),
          ),
        );
      case ItemColumn.margin:
        final margin = item.pricing.margin;
        return DataCell(
          Text(
            '₦${margin.toStringAsFixed(margin % 1 == 0 ? 0 : 2)} (${item.pricing.markupPercentage.toStringAsFixed(0)}%)',
            style: TextStyle(
              fontSize: 13,
              color: margin >= 0
                  ? TallyColors.varianceZeroLight
                  : TallyColors.stockCritical,
            ),
          ),
        );
      case ItemColumn.status:
        return DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: item.isActive
                  ? TallyColors.varianceZeroLight.withValues(alpha: 0.12)
                  : TallyColors.slateMuted.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              item.isActive ? 'Active' : 'Archived',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: item.isActive
                    ? TallyColors.varianceZeroLight
                    : TallyColors.slateMuted,
              ),
            ),
          ),
        );
      case ItemColumn.updatedAt:
        return DataCell(
          Text(
            dateFormat.format(item.updatedAt.toLocal()),
            style: const TextStyle(fontSize: 12, color: TallyColors.slateMuted),
          ),
        );
    }
  }

  ItemSortField? _sortFieldFor(ItemColumn column) {
    switch (column) {
      case ItemColumn.name:
        return ItemSortField.name;
      case ItemColumn.stock:
        return ItemSortField.quantity;
      case ItemColumn.costPrice:
        return ItemSortField.costPrice;
      case ItemColumn.baseSellingPrice:
        return ItemSortField.baseSellingPrice;
      case ItemColumn.minSellingPrice:
        return ItemSortField.minSellingPrice;
      case ItemColumn.updatedAt:
        return ItemSortField.updatedAt;
      default:
        return null;
    }
  }
}

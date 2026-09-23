import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/providers/core_providers.dart';
import '../../../domain/item/item_query.dart';
import '../../design_system/extensions/responsive.dart';
import '../../design_system/tokens/colors.dart';
import '../../design_system/tokens/dimensions.dart';
import 'item_column_dialog.dart';
import 'item_export_dialog.dart';
import 'item_filter_sheet.dart';
import 'item_import_dialog.dart';

/// Interactive top toolbar for searching, filtering, configuring columns, and exporting.
class ItemSearchFilterBar extends ConsumerStatefulWidget {
  final int totalItems;
  final VoidCallback onAddItem;

  const ItemSearchFilterBar({
    super.key,
    required this.totalItems,
    required this.onAddItem,
  });

  @override
  ConsumerState<ItemSearchFilterBar> createState() =>
      _ItemSearchFilterBarState();
}

class _ItemSearchFilterBarState extends ConsumerState<ItemSearchFilterBar> {
  late final TextEditingController _searchCtrl;
  late final FocusNode _searchFocusNode;
  bool _isSearchFocused = false;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    final query = ref.read(itemQueryProvider);
    _searchCtrl = TextEditingController(text: query.search);
    _searchFocusNode = FocusNode();
    _searchFocusNode.addListener(_onFocusChanged);
  }

  void _onFocusChanged() {
    if (_isSearchFocused != _searchFocusNode.hasFocus) {
      setState(() {
        _isSearchFocused = _searchFocusNode.hasFocus;
      });
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchFocusNode.removeListener(_onFocusChanged);
    _searchFocusNode.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearchChanged(String text) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 250), () {
      ref.read(itemQueryProvider.notifier).setSearch(text.trim());
    });
  }

  Future<void> _openFilterDialog() async {
    final currentQuery = ref.read(itemQueryProvider);
    final isPhone = context.isPhone;

    final result = isPhone
        ? await showModalBottomSheet<ItemFilter>(
            context: context,
            isScrollControlled: true,
            useSafeArea: true,
            builder: (_) => ItemFilterSheet(initialFilter: currentQuery.filter),
          )
        : await showDialog<ItemFilter>(
            context: context,
            builder: (_) => Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(TallyRadii.lg),
              ),
              child: ItemFilterSheet(initialFilter: currentQuery.filter),
            ),
          );

    if (result != null) {
      ref.read(itemQueryProvider.notifier).setFilter(result);
    }
  }

  void _openColumnDialog() {
    showDialog<void>(
      context: context,
      builder: (_) => const ItemColumnDialog(),
    );
  }

  void _openExportDialog() {
    showDialog<void>(
      context: context,
      builder: (_) => ItemExportDialog(totalMatchingItems: widget.totalItems),
    );
  }

  Future<void> _openImportDialog() async {
    final importedCount = await showDialog<int>(
      context: context,
      builder: (_) => const ItemImportDialog(),
    );

    if (importedCount != null && importedCount > 0 && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Successfully imported $importedCount items to catalog.',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          backgroundColor: TallyColors.varianceZeroLight,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final query = ref.watch(itemQueryProvider);
    final filter = query.filter;
    final activeFilterCount = filter.activeFilterCount;
    return LayoutBuilder(
      builder: (context, constraints) {
        final isPhone = context.isPhone || constraints.maxWidth < 600;
        final isCompact = constraints.maxWidth < 800;
        final showColumnBtn = !isPhone && constraints.maxWidth >= 740;
        final showExpandedSearch = isPhone && _isSearchFocused;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Main action row
            Row(
              children: [
                // 1. Search Bar (Takes full row when focused on mobile)
                Expanded(
                  child: Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(TallyRadii.md),
                      border: Border.all(
                        color: _isSearchFocused
                            ? TallyColors.primaryNavy
                            : TallyColors.lightBorder,
                        width: _isSearchFocused ? 1.5 : 1.0,
                      ),
                    ),
                    child: TextField(
                      key: const Key('item_search_field'),
                      controller: _searchCtrl,
                      focusNode: _searchFocusNode,
                      onChanged: (text) {
                        setState(() {});
                        _onSearchChanged(text);
                      },
                      decoration: InputDecoration(
                        hintText: isPhone
                            ? 'Search items...'
                            : 'Search by item name, SKU, or barcode...',
                        hintStyle: const TextStyle(
                          fontSize: 13,
                          color: TallyColors.slateMuted,
                        ),
                        prefixIcon: Icon(
                          Icons.search,
                          size: 20,
                          color: _isSearchFocused
                              ? TallyColors.primaryNavy
                              : TallyColors.slateMuted,
                        ),
                        suffixIcon: _searchCtrl.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 18),
                                onPressed: () {
                                  _searchCtrl.clear();
                                  ref
                                      .read(itemQueryProvider.notifier)
                                      .setSearch('');
                                  setState(() {});
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 10,
                          horizontal: 12,
                        ),
                      ),
                    ),
                  ),
                ),

                // Mobile focused state: show Cancel button to unfocus
                if (showExpandedSearch) ...[
                  const SizedBox(width: TallySpacing.xs),
                  TextButton(
                    key: const Key('item_search_cancel_button'),
                    onPressed: () {
                      _searchFocusNode.unfocus();
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: TallyColors.primaryNavy,
                      padding: const EdgeInsets.symmetric(
                        horizontal: TallySpacing.sm,
                      ),
                      visualDensity: VisualDensity.compact,
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ] else ...[
                  const SizedBox(width: TallySpacing.sm),

                  // 2. Filters Button
                  OutlinedButton.icon(
                    onPressed: _openFilterDialog,
                    icon: Badge(
                      isLabelVisible: activeFilterCount > 0,
                      label: Text(
                        activeFilterCount.toString(),
                        style: const TextStyle(fontSize: 10),
                      ),
                      backgroundColor: TallyColors.primaryNavy,
                      child: const Icon(Icons.tune, size: 18),
                    ),
                    label: Text(
                      isPhone
                          ? (activeFilterCount > 0
                              ? 'Filters · $activeFilterCount'
                              : 'Filters')
                          : 'Filters',
                      style: const TextStyle(fontSize: 13),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: TallyColors.primaryNavy,
                      side: BorderSide(
                        color: activeFilterCount > 0
                            ? TallyColors.primaryNavy
                            : TallyColors.lightBorder,
                        width: activeFilterCount > 0 ? 1.5 : 1.0,
                      ),
                      padding: EdgeInsets.symmetric(
                        horizontal: isPhone ? TallySpacing.sm : TallySpacing.md,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(TallyRadii.md),
                      ),
                    ),
                  ),

                  // 3. Columns Button (Tablet/Desktop when wide enough)
                  if (showColumnBtn) ...[
                    const SizedBox(width: TallySpacing.xs),
                    OutlinedButton.icon(
                      onPressed: _openColumnDialog,
                      icon: const Icon(Icons.view_column_outlined, size: 18),
                      label:
                          const Text('Columns', style: TextStyle(fontSize: 13)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: TallyColors.primaryNavy,
                        side: const BorderSide(color: TallyColors.lightBorder),
                        padding: const EdgeInsets.symmetric(
                          horizontal: TallySpacing.md,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(TallyRadii.md),
                        ),
                      ),
                    ),
                  ],

                  // 4. Export Button
                  const SizedBox(width: TallySpacing.xs),
                  Tooltip(
                    message: 'Export catalog to Excel or CSV',
                    child: OutlinedButton.icon(
                      onPressed: _openExportDialog,
                      icon: const Icon(Icons.file_download_outlined, size: 18),
                      label: (isPhone || isCompact)
                          ? const SizedBox.shrink()
                          : const Text('Export',
                              style: TextStyle(fontSize: 13)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: TallyColors.primaryNavy,
                        side: const BorderSide(color: TallyColors.lightBorder),
                        padding: EdgeInsets.symmetric(
                          horizontal: (isPhone || isCompact)
                              ? TallySpacing.sm
                              : TallySpacing.md,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(TallyRadii.md),
                        ),
                      ),
                    ),
                  ),

                  // 5. Import Button
                  const SizedBox(width: TallySpacing.xs),
                  Tooltip(
                    message: 'Import items from Excel or CSV',
                    child: OutlinedButton.icon(
                      onPressed: _openImportDialog,
                      icon: const Icon(Icons.file_upload_outlined, size: 18),
                      label: (isPhone || isCompact)
                          ? const SizedBox.shrink()
                          : const Text('Import',
                              style: TextStyle(fontSize: 13)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: TallyColors.primaryNavy,
                        side: const BorderSide(color: TallyColors.lightBorder),
                        padding: EdgeInsets.symmetric(
                          horizontal: (isPhone || isCompact)
                              ? TallySpacing.sm
                              : TallySpacing.md,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(TallyRadii.md),
                        ),
                      ),
                    ),
                  ),

                  // 6. Add Item Button
                  const SizedBox(width: TallySpacing.sm),
                  ElevatedButton.icon(
                    onPressed: widget.onAddItem,
                    icon: const Icon(Icons.add, size: 18),
                    label: isPhone
                        ? const SizedBox.shrink()
                        : const Text('Add Item',
                            style: TextStyle(fontSize: 13)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: TallyColors.primaryNavy,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        horizontal:
                            isPhone ? TallySpacing.sm : TallySpacing.base,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(TallyRadii.md),
                      ),
                    ),
                  ),
                ],
              ],
            ),

            // Active Filter Chips Row
            if (activeFilterCount > 0 || query.search.isNotEmpty) ...[
              const SizedBox(height: TallySpacing.xs),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    if (query.search.isNotEmpty) ...[
                      InputChip(
                        label: Text('Search: "${query.search}"'),
                        onDeleted: () {
                          _searchCtrl.clear();
                          ref.read(itemQueryProvider.notifier).setSearch('');
                        },
                        deleteIconColor: TallyColors.slateMuted,
                      ),
                      const SizedBox(width: TallySpacing.xs),
                    ],
                    if (filter.categoryId != null) ...[
                      InputChip(
                        label: Text('Category: ${filter.categoryId}'),
                        onDeleted: () {
                          ref.read(itemQueryProvider.notifier).updateFilter(
                              (ItemFilter f) =>
                                  f.copyWith(clearCategory: true));
                        },
                      ),
                      const SizedBox(width: TallySpacing.xs),
                    ],
                    if (filter.stockFilter != StockFilter.all) ...[
                      InputChip(
                        label: Text(filter.stockFilter.label),
                        onDeleted: () {
                          ref.read(itemQueryProvider.notifier).updateFilter(
                              (ItemFilter f) =>
                                  f.copyWith(stockFilter: StockFilter.all));
                        },
                      ),
                      const SizedBox(width: TallySpacing.xs),
                    ],
                    if (filter.statusFilter != StatusFilter.active) ...[
                      InputChip(
                        label: Text(filter.statusFilter.label),
                        onDeleted: () {
                          ref.read(itemQueryProvider.notifier).updateFilter(
                              (ItemFilter f) => f.copyWith(
                                  statusFilter: StatusFilter.active));
                        },
                      ),
                      const SizedBox(width: TallySpacing.xs),
                    ],
                    if (filter.minSellingPrice != null ||
                        filter.maxSellingPrice != null) ...[
                      InputChip(
                        label: Text(
                          'Price: ₦${filter.minSellingPrice ?? 0} - ₦${filter.maxSellingPrice ?? '∞'}',
                        ),
                        onDeleted: () {
                          ref.read(itemQueryProvider.notifier).updateFilter(
                                (ItemFilter f) => f.copyWith(
                                  clearMinSellingPrice: true,
                                  clearMaxSellingPrice: true,
                                ),
                              );
                        },
                      ),
                      const SizedBox(width: TallySpacing.xs),
                    ],
                    TextButton(
                      onPressed: () {
                        _searchCtrl.clear();
                        ref.read(itemQueryProvider.notifier).reset();
                      },
                      child: const Text(
                        'Clear all',
                        style: TextStyle(
                            fontSize: 12, color: TallyColors.stockCritical),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/providers/core_providers.dart';
import '../../application/item/item_query_notifier.dart';
import '../../domain/item/item.dart';
import '../../domain/item/item_query.dart';
import '../design_system/extensions/responsive.dart';
import '../design_system/tokens/colors.dart';
import '../design_system/tokens/dimensions.dart';
import '../design_system/widgets/tally_empty_state.dart';
import '../design_system/widgets/tally_error_state.dart';
import '../design_system/widgets/tally_pagination_bar.dart';
import 'item_details_screen.dart';
import 'item_form_screen.dart';
import 'widgets/item_delete_confirm_dialog.dart';
import 'widgets/item_desktop_table.dart';
import 'widgets/item_import_dialog.dart';
import 'widgets/item_mobile_card.dart';
import 'widgets/item_search_filter_bar.dart';

/// Main Items & Inventory Catalog Screen.
/// Provides responsive presentation across Phone, Tablet, and Desktop surfaces.
class ItemsScreen extends ConsumerWidget {
  const ItemsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsAsync = ref.watch(itemListProvider);
    final query = ref.watch(itemQueryProvider);
    final queryNotifier = ref.read(itemQueryProvider.notifier);
    final isPhone = context.isPhone;

    return Scaffold(
      backgroundColor: TallyColors.lightCanvas,
      body: Padding(
        padding: EdgeInsets.all(isPhone ? TallySpacing.md : TallySpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Module Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Items Catalog',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: TallyColors.primaryNavy,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Manage products, cost & retail pricing, and stock levels',
                        style: TextStyle(
                          fontSize: isPhone ? 12 : 13,
                          color: TallyColors.slateMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                // Subtle offline/sync status indicator
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: TallyColors.iceFrost,
                    borderRadius: BorderRadius.circular(TallyRadii.full),
                    border: Border.all(color: TallyColors.lightBorderStrong),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        size: 14,
                        color: TallyColors.varianceZeroLight,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Local DB',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: TallyColors.primaryNavy,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: TallySpacing.md),

            // 2. Interactive Search, Filter, and Action Bar
            ItemSearchFilterBar(
              totalItems: itemsAsync.valueOrNull?.totalItems ?? 0,
              onAddItem: () => _openAddScreen(context),
            ),
            const SizedBox(height: TallySpacing.md),

            // 3. Main Data Content Area
            Expanded(
              child: itemsAsync.when(
                loading: () => _buildLoadingSkeleton(isPhone),
                error: (error, _) => _buildErrorState(context, ref, error),
                data: (paginatedResult) {
                  final items = paginatedResult.items;

                  if (items.isEmpty) {
                    if (query.search.isNotEmpty || !query.filter.isEmpty) {
                      return _buildSearchEmptyState(ref, query);
                    }
                    return _buildInitialEmptyState(context);
                  }

                  return Column(
                    children: [
                      Expanded(
                        child: isPhone
                            ? ListView.builder(
                                itemCount: items.length,
                                itemBuilder: (ctx, idx) {
                                  final item = items[idx];
                                  return ItemMobileCard(
                                    item: item,
                                    isSelected: ref
                                        .watch(itemSelectionProvider)
                                        .contains(item.id),
                                    onSelectChanged: (_) => ref
                                        .read(itemSelectionProvider.notifier)
                                        .toggle(item.id),
                                    onTap: () =>
                                        _openDetailsScreen(context, item),
                                    onEdit: () =>
                                        _openEditScreen(context, item),
                                    onArchive: () => _handleArchive(ref, item),
                                    onDelete: () =>
                                        _handleDelete(context, ref, item),
                                  );
                                },
                              )
                            : ItemDesktopTable(
                                items: items,
                                onViewItem: (item) =>
                                    _openDetailsScreen(context, item),
                                onEditItem: (item) =>
                                    _openEditScreen(context, item),
                                onArchiveItem: (item) =>
                                    _handleArchive(ref, item),
                                onDeleteItem: (item) =>
                                    _handleDelete(context, ref, item),
                              ),
                      ),
                      const SizedBox(height: TallySpacing.sm),

                      // 4. Pagination Footer
                      _buildPaginationFooter(
                        context,
                        paginatedResult,
                        query,
                        queryNotifier,
                        isPhone,
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openAddScreen(BuildContext context) async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => const ItemFormScreen(),
      ),
    );
  }

  Future<void> _openEditScreen(BuildContext context, Item item) async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => ItemFormScreen(existingItem: item),
      ),
    );
  }

  Future<void> _openDetailsScreen(BuildContext context, Item item) async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => ItemDetailsScreen(item: item),
      ),
    );
  }

  Future<void> _handleArchive(WidgetRef ref, Item item) async {
    if (item.isActive) {
      await ref.read(itemListProvider.notifier).archiveItem(item.id);
    } else {
      await ref.read(itemListProvider.notifier).activateItem(item.id);
    }
  }

  Future<void> _handleDelete(
    BuildContext context,
    WidgetRef ref,
    Item item,
  ) async {
    final action = await showDialog<ItemDeleteAction>(
      context: context,
      builder: (_) => ItemDeleteConfirmDialog(item: item),
    );
    if (action == null || !context.mounted) return;

    if (action == ItemDeleteAction.archive) {
      await ref.read(itemListProvider.notifier).archiveItem(item.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Archived "${item.name}"')),
        );
      }
    } else if (action == ItemDeleteAction.delete) {
      final deleteRes =
          await ref.read(itemListProvider.notifier).deleteItem(item.id);
      if (!context.mounted) return;
      if (deleteRes.isSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Deleted "${item.name}" permanently')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              deleteRes.errorMessageOrNull ?? 'Delete failed',
            ),
            backgroundColor: TallyColors.stockCritical,
          ),
        );
      }
    }
  }

  Widget _buildPaginationFooter(
    BuildContext context,
    PaginatedResult<Item> result,
    ItemQuery query,
    ItemQueryNotifier notifier,
    bool isPhone,
  ) {
    return TallyPaginationBar(
      page: result.page,
      totalPages: result.totalPages,
      totalItems: result.totalItems,
      startIndex: result.startIndex,
      endIndex: result.endIndex,
      itemLabel: 'items',
      hasPreviousPage: result.hasPreviousPage,
      hasNextPage: result.hasNextPage,
      onPreviousPage: () => notifier.previousPage(),
      onNextPage: () => notifier.nextPage(),
      pageSize: query.pageSize,
      availablePageSizes: const [25, 50, 100],
      onPageSizeChanged: (val) => notifier.setPageSize(val),
      isPhone: isPhone,
    );
  }


  Widget _buildLoadingSkeleton(bool isPhone) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: TallyColors.primaryNavy,
            strokeWidth: 2.5,
          ),
          SizedBox(height: TallySpacing.md),
          Text(
            'Loading inventory catalog...',
            style: TextStyle(
              fontSize: 13,
              color: TallyColors.slateMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(
    BuildContext context,
    WidgetRef ref,
    Object error,
  ) {
    return TallyErrorState(
      title: "We couldn't load your items",
      description: 'Your store data has not been deleted. Please try again.',
      onRetry: () => ref.read(itemListProvider.notifier).load(),
    );
  }

  Widget _buildInitialEmptyState(BuildContext context) {
    return TallyEmptyState.zeroData(
      icon: Icons.inventory_2_outlined,
      iconSize: 56,
      title: 'No items yet',
      description:
          'Add the products you buy, hold, and sell to start tracking your inventory.',
      action: Wrap(
        spacing: TallySpacing.md,
        runSpacing: TallySpacing.sm,
        alignment: WrapAlignment.center,
        children: [
          ElevatedButton.icon(
            onPressed: () => _openAddScreen(context),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add First Item'),
            style: ElevatedButton.styleFrom(
              backgroundColor: TallyColors.primaryNavy,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: TallySpacing.xl,
                vertical: TallySpacing.md,
              ),
            ),
          ),
          OutlinedButton.icon(
            onPressed: () async {
              final count = await showDialog<int>(
                context: context,
                builder: (_) => const ItemImportDialog(),
              );
              if (count != null && count > 0 && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Successfully imported $count items.'),
                    backgroundColor: TallyColors.varianceZeroLight,
                  ),
                );
              }
            },
            icon: const Icon(Icons.file_upload_outlined, size: 18),
            label: const Text('Import from File'),
            style: OutlinedButton.styleFrom(
              foregroundColor: TallyColors.primaryNavy,
              side: const BorderSide(color: TallyColors.lightBorder),
              padding: const EdgeInsets.symmetric(
                horizontal: TallySpacing.lg,
                vertical: TallySpacing.md,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchEmptyState(WidgetRef ref, ItemQuery query) {
    return TallyEmptyState.searchEmpty(
      title: 'No items found',
      description: query.search.isNotEmpty
          ? 'We couldn\'t find any item matching "${query.search}".\nTry another name, SKU, or barcode.'
          : 'No items match your active filters.',
      action: OutlinedButton(
        onPressed: () => ref.read(itemQueryProvider.notifier).reset(),
        style: OutlinedButton.styleFrom(
          foregroundColor: TallyColors.primaryNavy,
          side: const BorderSide(color: TallyColors.lightBorderStrong),
        ),
        child: const Text('Clear Search & Filters'),
      ),
    );
  }
}


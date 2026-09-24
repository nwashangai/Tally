import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/providers/core_providers.dart';
import '../../application/receiving/receiving_query_notifier.dart';
import '../../domain/item/item_query.dart';
import '../../domain/receiving/receiving.dart';
import '../../domain/receiving/receiving_query.dart';
import '../design_system/extensions/responsive.dart';
import '../design_system/tokens/colors.dart';
import '../design_system/tokens/dimensions.dart';
import '../design_system/widgets/tally_cancel_button.dart';
import '../design_system/widgets/tally_empty_state.dart';
import '../design_system/widgets/tally_error_state.dart';
import '../design_system/widgets/tally_pagination_bar.dart';
import 'new_receiving_screen.dart';
import 'receiving_details_screen.dart';
import 'widgets/receiving_desktop_table.dart';
import 'widgets/receiving_mobile_card.dart';
import 'widgets/receiving_search_filter_bar.dart';

/// Main Receivings Module Screen.
/// Provides responsive views for tracking, filtering, and receiving supplier inventory.
class ReceivingsScreen extends ConsumerWidget {
  const ReceivingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final receivingsAsync = ref.watch(receivingListProvider);
    final query = ref.watch(receivingQueryProvider);
    final queryNotifier = ref.read(receivingQueryProvider.notifier);
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
                        'Receiving & Stock Intake',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: TallyColors.primaryNavy,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Track inbound shipments, acquisition costs, and supplier intake',
                        style: TextStyle(
                          fontSize: isPhone ? 12 : 13,
                          color: TallyColors.slateMuted,
                        ),
                      ),
                    ],
                  ),
                ),
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

            // 2. Interactive Search & Filter Toolbar
            ReceivingSearchFilterBar(
              totalReceivings: receivingsAsync.valueOrNull?.totalItems ?? 0,
              onNewReceiving: () => _openNewReceivingScreen(context),
            ),
            const SizedBox(height: TallySpacing.md),

            // 3. Main Data Content Area
            Expanded(
              child: receivingsAsync.when(
                loading: () => _buildLoadingSkeleton(),
                error: (error, _) => _buildErrorState(context, ref, error),
                data: (paginatedResult) {
                  final receivings = paginatedResult.items;

                  if (receivings.isEmpty) {
                    if (query.search.isNotEmpty ||
                        query.status != null ||
                        query.supplier != null ||
                        query.startDate != null ||
                        query.endDate != null) {
                      return _buildSearchEmptyState(ref, query);
                    }
                    return _buildInitialEmptyState(context);
                  }

                  return Column(
                    children: [
                      Expanded(
                        child: isPhone
                            ? ListView.builder(
                                itemCount: receivings.length,
                                itemBuilder: (ctx, idx) {
                                  final rec = receivings[idx];
                                  return ReceivingMobileCard(
                                    receiving: rec,
                                    onTap: () =>
                                        _openDetailsScreen(context, rec),
                                    onEditDraft: () =>
                                        _editDraft(context, rec),
                                    onDeleteDraft: () =>
                                        _deleteDraft(context, ref, rec),
                                  );
                                },
                              )
                            : ReceivingDesktopTable(
                                receivings: receivings,
                                onViewDetails: (rec) =>
                                    _openDetailsScreen(context, rec),
                                onEditDraft: (rec) =>
                                    _editDraft(context, rec),
                                onDeleteDraft: (rec) =>
                                    _deleteDraft(context, ref, rec),
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

  Future<void> _openNewReceivingScreen(BuildContext context) async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => const NewReceivingScreen(),
      ),
    );
  }

  Future<void> _openDetailsScreen(
    BuildContext context,
    Receiving receiving,
  ) async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => ReceivingDetailsScreen(receiving: receiving),
      ),
    );
  }

  Future<void> _editDraft(BuildContext context, Receiving receiving) async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => NewReceivingScreen(initialDraft: receiving),
      ),
    );
  }

  Future<void> _deleteDraft(
    BuildContext context,
    WidgetRef ref,
    Receiving receiving,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(TallyRadii.lg),
        ),
        title: const Row(
          children: [
            Icon(Icons.delete_outline, color: TallyColors.stockCritical),
            SizedBox(width: TallySpacing.sm),
            Text(
              'Delete Draft?',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: TallyColors.primaryNavy,
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to delete draft receiving ${receiving.referenceNumber}? This action cannot be undone.',
          style: const TextStyle(
            fontSize: 14,
            color: TallyColors.slateMuted,
          ),
        ),
        actions: [
          TallyCancelButton(
            onPressed: () => Navigator.of(ctx).pop(false),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: TallyColors.stockCritical,
              foregroundColor: Colors.white,
              shape: const StadiumBorder(),
              padding: const EdgeInsets.symmetric(
                horizontal: TallySpacing.xl,
                vertical: TallySpacing.md,
              ),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final res = await ref
          .read(receivingListProvider.notifier)
          .deleteDraft(receiving.id);
      if (!context.mounted) return;
      if (res.isSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('Draft receiving ${receiving.referenceNumber} deleted.'),
            backgroundColor: TallyColors.varianceZeroLight,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to delete draft: ${res.errorOrNull?.toString() ?? "Unknown error"}',
            ),
            backgroundColor: TallyColors.stockCritical,
          ),
        );
      }
    }
  }

  Widget _buildLoadingSkeleton() {
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
            'Loading receiving transactions...',
            style: TextStyle(
              fontSize: 13,
              color: TallyColors.slateMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, WidgetRef ref, Object error) {
    return TallyErrorState(
      title: "We couldn't load receivings",
      description:
          'Your store data is safe in local encrypted storage. Please retry.',
      onRetry: () => ref.read(receivingListProvider.notifier).load(),
    );
  }

  Widget _buildInitialEmptyState(BuildContext context) {
    return TallyEmptyState.zeroData(
      icon: Icons.local_shipping_outlined,
      iconSize: 56,
      title: 'No receivings yet',
      description:
          'Record stock inbound from suppliers or manufacturers to update inventory and audit acquisition costs.',
      action: ElevatedButton.icon(
        onPressed: () => _openNewReceivingScreen(context),
        icon: const Icon(Icons.add, size: 18),
        label: const Text('New Receiving'),
        style: ElevatedButton.styleFrom(
          backgroundColor: TallyColors.primaryNavy,
          foregroundColor: Colors.white,
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(
            horizontal: TallySpacing.xl,
            vertical: TallySpacing.md,
          ),
        ),
      ),
    );
  }

  Widget _buildSearchEmptyState(WidgetRef ref, ReceivingQuery query) {
    return TallyEmptyState.searchEmpty(
      title: 'No receivings found',
      description: query.search.isNotEmpty
          ? 'We couldn\'t find any receiving matching "${query.search}".\nTry searching another reference number or supplier.'
          : 'No receivings match your active filters.',
      action: OutlinedButton(
        onPressed: () =>
            ref.read(receivingQueryProvider.notifier).clearFilters(),
        style: OutlinedButton.styleFrom(
          foregroundColor: TallyColors.primaryNavy,
          side: const BorderSide(color: TallyColors.lightBorderStrong),
          shape: const StadiumBorder(),
        ),
        child: const Text('Clear Search & Filters'),
      ),
    );
  }

  Widget _buildPaginationFooter(
    BuildContext context,
    PaginatedResult<Receiving> result,
    ReceivingQuery query,
    ReceivingQueryNotifier notifier,
    bool isPhone,
  ) {
    final startItem =
        result.totalItems == 0 ? 0 : (result.page - 1) * result.pageSize + 1;
    final endItem = (result.page * result.pageSize).clamp(0, result.totalItems);

    return TallyPaginationBar(
      page: result.page,
      totalPages: result.totalPages > 0 ? result.totalPages : 1,
      totalItems: result.totalItems,
      startIndex: startItem,
      endIndex: endItem,
      itemLabel: 'receivings',
      hasPreviousPage: result.hasPreviousPage,
      hasNextPage: result.hasNextPage,
      onPreviousPage: notifier.previousPage,
      onNextPage: notifier.nextPage,
      isPhone: isPhone,
    );
  }
}

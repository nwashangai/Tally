import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../app/providers/core_providers.dart';
import '../../../domain/receiving/receiving_query.dart';
import '../../../domain/receiving/receiving_status.dart';
import '../../design_system/extensions/responsive.dart';
import '../../design_system/tokens/colors.dart';
import '../../design_system/tokens/dimensions.dart';

/// Top toolbar for searching, filtering by status/date/supplier, and initiating new Receivings.
class ReceivingSearchFilterBar extends ConsumerStatefulWidget {
  final int totalReceivings;
  final VoidCallback onNewReceiving;

  const ReceivingSearchFilterBar({
    super.key,
    required this.totalReceivings,
    required this.onNewReceiving,
  });

  @override
  ConsumerState<ReceivingSearchFilterBar> createState() =>
      _ReceivingSearchFilterBarState();
}

class _ReceivingSearchFilterBarState
    extends ConsumerState<ReceivingSearchFilterBar> {
  late final TextEditingController _searchCtrl;
  late final FocusNode _searchFocusNode;
  bool _isSearchFocused = false;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    final query = ref.read(receivingQueryProvider);
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
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      ref.read(receivingQueryProvider.notifier).setSearch(text);
    });
  }

  int _countActiveFilters(ReceivingQuery query) {
    int count = 0;
    if (query.status != null) count++;
    if (query.supplier != null && query.supplier!.isNotEmpty) count++;
    if (query.startDate != null || query.endDate != null) count++;
    return count;
  }

  Future<void> _showFilterDialog(BuildContext context) async {
    final query = ref.read(receivingQueryProvider);
    ReceivingStatus? selectedStatus = query.status;
    DateTime? startDate = query.startDate;
    DateTime? endDate = query.endDate;
    final supplierCtrl = TextEditingController(text: query.supplier ?? '');

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(TallyRadii.lg)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: TallySpacing.lg,
                right: TallySpacing.lg,
                top: TallySpacing.lg,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + TallySpacing.lg,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Filter Receivings',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: TallyColors.primaryNavy,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            setSheetState(() {
                              selectedStatus = null;
                              startDate = null;
                              endDate = null;
                              supplierCtrl.clear();
                            });
                          },
                          child: const Text('Reset'),
                        ),
                      ],
                    ),
                    const SizedBox(height: TallySpacing.md),

                    // Status Filter
                    const Text(
                      'Status',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: TallyColors.primaryNavy,
                      ),
                    ),
                    const SizedBox(height: TallySpacing.xs),
                    Wrap(
                      spacing: 8,
                      children: [
                        ChoiceChip(
                          label: const Text('All'),
                          selected: selectedStatus == null,
                          onSelected: (val) {
                            if (val) setSheetState(() => selectedStatus = null);
                          },
                        ),
                        ChoiceChip(
                          label: const Text('Completed'),
                          selected: selectedStatus == ReceivingStatus.completed,
                          onSelected: (val) {
                            setSheetState(() => selectedStatus =
                                val ? ReceivingStatus.completed : null);
                          },
                        ),
                        ChoiceChip(
                          label: const Text('Draft'),
                          selected: selectedStatus == ReceivingStatus.draft,
                          onSelected: (val) {
                            setSheetState(() => selectedStatus =
                                val ? ReceivingStatus.draft : null);
                          },
                        ),
                        ChoiceChip(
                          label: const Text('Voided'),
                          selected: selectedStatus == ReceivingStatus.voided,
                          onSelected: (val) {
                            setSheetState(() => selectedStatus =
                                val ? ReceivingStatus.voided : null);
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: TallySpacing.md),

                    // Supplier Filter
                    const Text(
                      'Supplier',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: TallyColors.primaryNavy,
                      ),
                    ),
                    const SizedBox(height: TallySpacing.xs),
                    TextField(
                      controller: supplierCtrl,
                      decoration: InputDecoration(
                        hintText: 'Filter by supplier name...',
                        hintStyle: const TextStyle(
                          fontSize: 13,
                          color: TallyColors.slateMuted,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(TallyRadii.md),
                          borderSide:
                              const BorderSide(color: TallyColors.lightBorder),
                        ),
                      ),
                    ),
                    const SizedBox(height: TallySpacing.md),

                    // Date Range
                    const Text(
                      'Date Range',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: TallyColors.primaryNavy,
                      ),
                    ),
                    const SizedBox(height: TallySpacing.xs),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: startDate ?? DateTime.now(),
                                firstDate: DateTime(2020),
                                lastDate: DateTime.now()
                                    .add(const Duration(days: 365)),
                              );
                              if (picked != null) {
                                setSheetState(() => startDate = picked);
                              }
                            },
                            icon: const Icon(Icons.date_range, size: 16),
                            label: Text(
                              startDate != null
                                  ? DateFormat('MMM d, yyyy').format(startDate!)
                                  : 'From Date',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: TallySpacing.sm),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: endDate ?? DateTime.now(),
                                firstDate: DateTime(2020),
                                lastDate: DateTime.now()
                                    .add(const Duration(days: 365)),
                              );
                              if (picked != null) {
                                setSheetState(() => endDate = picked);
                              }
                            },
                            icon: const Icon(Icons.date_range, size: 16),
                            label: Text(
                              endDate != null
                                  ? DateFormat('MMM d, yyyy').format(endDate!)
                                  : 'To Date',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: TallySpacing.xl),

                    // Apply Button
                    ElevatedButton(
                      onPressed: () {
                        final notifier =
                            ref.read(receivingQueryProvider.notifier);
                        notifier.setStatus(selectedStatus);
                        notifier.setSupplier(supplierCtrl.text);
                        notifier.setDateRange(
                          startDate: startDate,
                          endDate: endDate,
                        );
                        Navigator.of(ctx).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: TallyColors.primaryNavy,
                        foregroundColor: Colors.white,
                        shape: const StadiumBorder(),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Apply Filters'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final query = ref.watch(receivingQueryProvider);
    final isPhone = context.isPhone;
    final activeFiltersCount = _countActiveFilters(query);
    final showExpandedSearch = isPhone && _isSearchFocused;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            // Search Input
            Expanded(
              child: Container(
                height: 42,
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
                  controller: _searchCtrl,
                  focusNode: _searchFocusNode,
                  onChanged: _onSearchChanged,
                  style: const TextStyle(fontSize: 13),
                  decoration: InputDecoration(
                    hintText: isPhone
                        ? 'Search reference or supplier...'
                        : 'Search by reference number, supplier, or notes...',
                    hintStyle: const TextStyle(
                      fontSize: 13,
                      color: TallyColors.slateMuted,
                    ),
                    prefixIcon: const Icon(
                      Icons.search,
                      size: 18,
                      color: TallyColors.slateMuted,
                    ),
                    suffixIcon: _searchCtrl.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 16),
                            onPressed: () {
                              _searchCtrl.clear();
                              ref
                                  .read(receivingQueryProvider.notifier)
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

            if (showExpandedSearch) ...[
              const SizedBox(width: TallySpacing.xs),
              TextButton(
                onPressed: () => _searchFocusNode.unfocus(),
                style: TextButton.styleFrom(
                  foregroundColor: TallyColors.primaryNavy,
                  visualDensity: VisualDensity.compact,
                ),
                child: const Text('Cancel'),
              ),
            ] else ...[
              const SizedBox(width: TallySpacing.sm),

              // Filter button with badge
              OutlinedButton.icon(
                onPressed: () => _showFilterDialog(context),
                icon: Badge(
                  isLabelVisible: activeFiltersCount > 0,
                  label: Text(
                    activeFiltersCount.toString(),
                    style: const TextStyle(fontSize: 10),
                  ),
                  backgroundColor: TallyColors.primaryNavy,
                  child: const Icon(Icons.tune, size: 18),
                ),
                label: Text(
                  isPhone
                      ? (activeFiltersCount > 0
                          ? 'Filters · $activeFiltersCount'
                          : 'Filters')
                      : 'Filters',
                  style: const TextStyle(fontSize: 13),
                ),
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
              const SizedBox(width: TallySpacing.sm),

              // New Receiving CTA button
              ElevatedButton.icon(
                onPressed: widget.onNewReceiving,
                icon: const Icon(Icons.add, size: 18),
                label: isPhone
                    ? const SizedBox.shrink()
                    : const Text(
                        'New Receiving',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: TallyColors.primaryNavy,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: EdgeInsets.symmetric(
                    horizontal: isPhone ? TallySpacing.sm : TallySpacing.base,
                    vertical: 12,
                  ),
                  shape: const StadiumBorder(),
                ),
              ),
            ],
          ],
        ),

        // Active Filter Chips Row
        if (activeFiltersCount > 0 || query.search.isNotEmpty) ...[
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
                      ref.read(receivingQueryProvider.notifier).setSearch('');
                      setState(() {});
                    },
                    deleteIconColor: TallyColors.slateMuted,
                    backgroundColor: TallyColors.iceFrost,
                    labelStyle: const TextStyle(
                      fontSize: 12,
                      color: TallyColors.primaryNavy,
                    ),
                  ),
                  const SizedBox(width: TallySpacing.xs),
                ],
                if (query.status != null) ...[
                  InputChip(
                    label: Text('Status: ${query.status!.name.toUpperCase()}'),
                    onDeleted: () => ref
                        .read(receivingQueryProvider.notifier)
                        .setStatus(null),
                    deleteIconColor: TallyColors.slateMuted,
                    backgroundColor: TallyColors.iceFrost,
                    labelStyle: const TextStyle(
                      fontSize: 12,
                      color: TallyColors.primaryNavy,
                    ),
                  ),
                  const SizedBox(width: TallySpacing.xs),
                ],
                if (query.supplier != null) ...[
                  InputChip(
                    label: Text('Supplier: ${query.supplier}'),
                    onDeleted: () => ref
                        .read(receivingQueryProvider.notifier)
                        .setSupplier(null),
                    deleteIconColor: TallyColors.slateMuted,
                    backgroundColor: TallyColors.iceFrost,
                    labelStyle: const TextStyle(
                      fontSize: 12,
                      color: TallyColors.primaryNavy,
                    ),
                  ),
                  const SizedBox(width: TallySpacing.xs),
                ],
                if (query.startDate != null || query.endDate != null) ...[
                  InputChip(
                    label: Text(
                      'Dates: ${query.startDate != null ? DateFormat('MM/dd').format(query.startDate!) : '...'} - ${query.endDate != null ? DateFormat('MM/dd').format(query.endDate!) : '...'}',
                    ),
                    onDeleted: () => ref
                        .read(receivingQueryProvider.notifier)
                        .setDateRange(),
                    deleteIconColor: TallyColors.slateMuted,
                    backgroundColor: TallyColors.iceFrost,
                    labelStyle: const TextStyle(
                      fontSize: 12,
                      color: TallyColors.primaryNavy,
                    ),
                  ),
                  const SizedBox(width: TallySpacing.xs),
                ],
                TextButton(
                  onPressed: () {
                    _searchCtrl.clear();
                    ref.read(receivingQueryProvider.notifier).clearFilters();
                    setState(() {});
                  },
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    foregroundColor: TallyColors.slateMuted,
                  ),
                  child:
                      const Text('Clear All', style: TextStyle(fontSize: 11)),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/providers/core_providers.dart';
import '../../../domain/item/item_query.dart';
import '../../../domain/item/item_unit.dart';
import '../../design_system/tokens/colors.dart';
import '../../design_system/tokens/dimensions.dart';

/// Modal filter panel for refining the items catalog view.
class ItemFilterSheet extends ConsumerStatefulWidget {
  final ItemFilter initialFilter;

  const ItemFilterSheet({
    super.key,
    required this.initialFilter,
  });

  @override
  ConsumerState<ItemFilterSheet> createState() => _ItemFilterSheetState();
}

class _ItemFilterSheetState extends ConsumerState<ItemFilterSheet> {
  late String? _categoryId;
  late StockFilter _stockFilter;
  late StatusFilter _statusFilter;
  late ItemUnit? _unit;
  late final TextEditingController _minCostCtrl;
  late final TextEditingController _maxCostCtrl;
  late final TextEditingController _minSellingCtrl;
  late final TextEditingController _maxSellingCtrl;

  @override
  void initState() {
    super.initState();
    _categoryId = widget.initialFilter.categoryId;
    _stockFilter = widget.initialFilter.stockFilter;
    _statusFilter = widget.initialFilter.statusFilter;
    _unit = widget.initialFilter.unit;

    _minCostCtrl = TextEditingController(
      text: widget.initialFilter.minCostPrice != null
          ? widget.initialFilter.minCostPrice!.toStringAsFixed(0)
          : '',
    );
    _maxCostCtrl = TextEditingController(
      text: widget.initialFilter.maxCostPrice != null
          ? widget.initialFilter.maxCostPrice!.toStringAsFixed(0)
          : '',
    );
    _minSellingCtrl = TextEditingController(
      text: widget.initialFilter.minSellingPrice != null
          ? widget.initialFilter.minSellingPrice!.toStringAsFixed(0)
          : '',
    );
    _maxSellingCtrl = TextEditingController(
      text: widget.initialFilter.maxSellingPrice != null
          ? widget.initialFilter.maxSellingPrice!.toStringAsFixed(0)
          : '',
    );
  }

  @override
  void dispose() {
    _minCostCtrl.dispose();
    _maxCostCtrl.dispose();
    _minSellingCtrl.dispose();
    _maxSellingCtrl.dispose();
    super.dispose();
  }

  void _applyFilters() {
    final minCost = double.tryParse(_minCostCtrl.text.trim());
    final maxCost = double.tryParse(_maxCostCtrl.text.trim());
    final minSelling = double.tryParse(_minSellingCtrl.text.trim());
    final maxSelling = double.tryParse(_maxSellingCtrl.text.trim());

    final updatedFilter = ItemFilter(
      categoryId: _categoryId,
      stockFilter: _stockFilter,
      statusFilter: _statusFilter,
      minCostPrice: minCost,
      maxCostPrice: maxCost,
      minSellingPrice: minSelling,
      maxSellingPrice: maxSelling,
      unit: _unit,
    );

    Navigator.of(context).pop(updatedFilter);
  }

  void _clearFilters() {
    setState(() {
      _categoryId = null;
      _stockFilter = StockFilter.all;
      _statusFilter = StatusFilter.active;
      _unit = null;
      _minCostCtrl.clear();
      _maxCostCtrl.clear();
      _minSellingCtrl.clear();
      _maxSellingCtrl.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(itemCategoriesProvider);
    final categories = categoriesAsync.valueOrNull ?? [];

    return Container(
      constraints: const BoxConstraints(maxWidth: 520),
      padding: const EdgeInsets.all(TallySpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Filter Catalog',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: TallyColors.primaryNavy,
                ),
              ),
              TextButton(
                onPressed: _clearFilters,
                child: const Text('Reset All'),
              ),
            ],
          ),
          const SizedBox(height: TallySpacing.md),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Stock Status
                  const Text(
                    'Stock Level',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: TallyColors.slateMuted,
                    ),
                  ),
                  const SizedBox(height: TallySpacing.xs),
                  Wrap(
                    spacing: TallySpacing.xs,
                    runSpacing: TallySpacing.xs,
                    children: StockFilter.values.map((stock) {
                      final isSelected = _stockFilter == stock;
                      return ChoiceChip(
                        label: Text(stock.label),
                        selected: isSelected,
                        onSelected: (_) => setState(() => _stockFilter = stock),
                        selectedColor: TallyColors.iceFrost,
                        labelStyle: TextStyle(
                          fontSize: 12,
                          fontWeight:
                              isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected
                              ? TallyColors.primaryNavy
                              : TallyColors.slateMuted,
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: TallySpacing.md),

                  // 2. Active Status
                  const Text(
                    'Item Status',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: TallyColors.slateMuted,
                    ),
                  ),
                  const SizedBox(height: TallySpacing.xs),
                  Wrap(
                    spacing: TallySpacing.xs,
                    runSpacing: TallySpacing.xs,
                    children: StatusFilter.values.map((status) {
                      final isSelected = _statusFilter == status;
                      return ChoiceChip(
                        label: Text(status.label),
                        selected: isSelected,
                        onSelected: (_) =>
                            setState(() => _statusFilter = status),
                        selectedColor: TallyColors.iceFrost,
                        labelStyle: TextStyle(
                          fontSize: 12,
                          fontWeight:
                              isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected
                              ? TallyColors.primaryNavy
                              : TallyColors.slateMuted,
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: TallySpacing.md),

                  // 3. Category
                  if (categories.isNotEmpty) ...[
                    const Text(
                      'Category',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: TallyColors.slateMuted,
                      ),
                    ),
                    const SizedBox(height: TallySpacing.xs),
                    Wrap(
                      spacing: TallySpacing.xs,
                      runSpacing: TallySpacing.xs,
                      children: [
                        ChoiceChip(
                          label: const Text('All Categories'),
                          selected: _categoryId == null,
                          onSelected: (_) => setState(() => _categoryId = null),
                          selectedColor: TallyColors.iceFrost,
                        ),
                        ...categories.map((cat) {
                          final isSelected = _categoryId == cat;
                          return ChoiceChip(
                            label: Text(cat),
                            selected: isSelected,
                            onSelected: (_) => setState(
                                () => _categoryId = isSelected ? null : cat),
                            selectedColor: TallyColors.iceFrost,
                          );
                        }),
                      ],
                    ),
                    const SizedBox(height: TallySpacing.md),
                  ],

                  // 4. Selling Price Range
                  const Text(
                    'Selling Price Range (₦)',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: TallyColors.slateMuted,
                    ),
                  ),
                  const SizedBox(height: TallySpacing.xs),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _minSellingCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Min Price',
                            isDense: true,
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: TallySpacing.sm),
                      Expanded(
                        child: TextField(
                          controller: _maxSellingCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Max Price',
                            isDense: true,
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: TallySpacing.md),

                  // 5. Unit
                  const Text(
                    'Measurement Unit',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: TallyColors.slateMuted,
                    ),
                  ),
                  const SizedBox(height: TallySpacing.xs),
                  DropdownButtonFormField<ItemUnit?>(
                    initialValue: _unit,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem<ItemUnit?>(
                        value: null,
                        child: Text('Any Unit'),
                      ),
                      ...ItemUnit.values.map(
                        (u) => DropdownMenuItem<ItemUnit?>(
                          value: u,
                          child: Text('${u.label} (${u.abbreviation})'),
                        ),
                      ),
                    ],
                    onChanged: (val) => setState(() => _unit = val),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: TallySpacing.md),
          ElevatedButton(
            onPressed: _applyFilters,
            style: ElevatedButton.styleFrom(
              backgroundColor: TallyColors.primaryNavy,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: TallySpacing.md),
            ),
            child: const Text('Apply Filters'),
          ),
        ],
      ),
    );
  }
}

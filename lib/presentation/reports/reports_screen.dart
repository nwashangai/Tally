import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../app/providers/core_providers.dart';
import '../../application/reports/reports_notifier.dart';
import '../../domain/reports/sales_profit_report.dart';
import '../design_system/extensions/responsive.dart';
import '../design_system/tokens/colors.dart';
import '../design_system/tokens/dimensions.dart';
import '../design_system/widgets/tally_empty_state.dart';

/// Screen for viewing historical sales and profitability reports.
///
/// Strictly computes revenue, COGS, and profit factoring in the different costs
/// and selling prices the item was actually sold at during different time periods.
class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickCustomRange(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: now.add(const Duration(days: 365)),
      initialDateRange: DateTimeRange(
        start: now.subtract(const Duration(days: 30)),
        end: now,
      ),
    );

    if (picked != null) {
      ref
          .read(reportsNotifierProvider.notifier)
          .setCustomRange(picked.start, picked.end);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(reportsNotifierProvider);
    final notifier = ref.read(reportsNotifierProvider.notifier);
    final isPhone = context.isPhone;
    final currencyFormat = NumberFormat('#,##0.00', 'en_US');

    return Scaffold(
      backgroundColor: TallyColors.lightCanvas,
      appBar: AppBar(
        title: const Text(
          'Sales & Profit Reports',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: TallyColors.primaryNavy,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: TallyColors.primaryNavy),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: TallyColors.primaryNavy),
            tooltip: 'Refresh Report',
            onPressed: () => notifier.loadReport(),
          ),
          const SizedBox(width: TallySpacing.sm),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: TallyColors.lightBorder, height: 1),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () => notifier.loadReport(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.all(isPhone ? TallySpacing.md : TallySpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Explanatory Banner: Historical Multi-era Principle
              Container(
                padding: const EdgeInsets.all(TallySpacing.md),
                decoration: BoxDecoration(
                  color: TallyColors.iceFrost,
                  borderRadius: BorderRadius.circular(TallyRadii.md),
                  border: Border.all(color: TallyColors.lightBorder),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: TallyColors.primaryNavy.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.history_edu,
                        size: 20,
                        color: TallyColors.primaryNavy,
                      ),
                    ),
                    const SizedBox(width: TallySpacing.md),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Historical Accuracy Engine',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: TallyColors.primaryNavy,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Profit is calculated using the exact cost and price recorded at each sale timestamp. Catalog price adjustments during receiving do not alter past sales.',
                            style: TextStyle(
                              fontSize: 12,
                              color: TallyColors.slateMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: TallySpacing.md),

              // 2. Date Range Filter Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: ReportsDateRange.values.map((range) {
                    final isSelected = state.dateRange == range;
                    return Padding(
                      padding: const EdgeInsets.only(right: TallySpacing.xs),
                      child: ChoiceChip(
                        label: Text(
                          range == ReportsDateRange.custom &&
                                  state.customStartDate != null
                              ? '${DateFormat('MM/dd').format(state.customStartDate!)} - ${DateFormat('MM/dd').format(state.customEndDate!)}'
                              : range.label,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight:
                                isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected
                                ? Colors.white
                                : TallyColors.primaryNavy,
                          ),
                        ),
                        selected: isSelected,
                        selectedColor: TallyColors.primaryNavy,
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(TallyRadii.full),
                          side: BorderSide(
                            color: isSelected
                                ? TallyColors.primaryNavy
                                : TallyColors.lightBorder,
                          ),
                        ),
                        onSelected: (selected) {
                          if (range == ReportsDateRange.custom) {
                            _pickCustomRange(context);
                          } else {
                            notifier.setDateRange(range);
                          }
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: TallySpacing.md),

              // 3. Summary Metric Cards
              if (state.isLoading) ...[
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(TallySpacing.xl),
                    child: CircularProgressIndicator(),
                  ),
                ),
              ] else if (state.report != null) ...[
                _buildSummaryCards(state.report!, isPhone, currencyFormat),
                const SizedBox(height: TallySpacing.lg),

                // 4. Search Filter
                TextField(
                  controller: _searchCtrl,
                  decoration: InputDecoration(
                    hintText: 'Search items by name or SKU...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: _searchCtrl.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchCtrl.clear();
                              notifier.setSearchQuery('');
                            },
                          )
                        : null,
                    isDense: true,
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: TallySpacing.md,
                      vertical: TallySpacing.sm,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(TallyRadii.md),
                      borderSide:
                          const BorderSide(color: TallyColors.lightBorder),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(TallyRadii.md),
                      borderSide:
                          const BorderSide(color: TallyColors.lightBorder),
                    ),
                  ),
                  onChanged: (val) => notifier.setSearchQuery(val),
                ),
                const SizedBox(height: TallySpacing.md),

                // 5. Item Profit Breakdown Section Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Item Breakdown (${state.filteredItemReports.length})',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: TallyColors.primaryNavy,
                      ),
                    ),
                    Text(
                      '${state.report!.transactionCount} sales recorded',
                      style: const TextStyle(
                        fontSize: 12,
                        color: TallyColors.slateMuted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: TallySpacing.sm),

                // 6. Items List or Empty State
                if (state.filteredItemReports.isEmpty)
                  _buildEmptyState(state.report!.transactionCount == 0)
                else
                  ...state.filteredItemReports.map(
                    (item) => _ItemProfitCard(
                      item: item,
                      currencyFormat: currencyFormat,
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCards(
    SalesProfitReport report,
    bool isPhone,
    NumberFormat currencyFormat,
  ) {
    final revenue = report.totalRevenue;
    final cogs = report.totalCogs;
    final profit = report.totalGrossProfit;
    final margin = report.overallMarginPercentage;
    final units = report.totalUnitsSold;

    final cards = [
      _MetricTile(
        title: 'Total Revenue',
        value: '₦${currencyFormat.format(revenue)}',
        icon: Icons.payments_outlined,
        color: TallyColors.primaryNavy,
      ),
      _MetricTile(
        title: 'Cost of Goods (COGS)',
        value: '₦${currencyFormat.format(cogs)}',
        icon: Icons.inventory_2_outlined,
        color: TallyColors.slateMuted,
      ),
      _MetricTile(
        title: 'Gross Profit',
        value: '₦${currencyFormat.format(profit)}',
        subtitle: '${margin.toStringAsFixed(1)}% margin',
        icon: Icons.trending_up,
        color: profit >= 0
            ? TallyColors.varianceZeroLight
            : TallyColors.stockCritical,
      ),
      _MetricTile(
        title: 'Units Sold',
        value: units.toStringAsFixed(units % 1 == 0 ? 0 : 2),
        icon: Icons.shopping_bag_outlined,
        color: const Color(0xFF8B5CF6),
      ),
    ];

    if (isPhone) {
      return GridView.count(
        crossAxisCount: 2,
        mainAxisSpacing: TallySpacing.sm,
        crossAxisSpacing: TallySpacing.sm,
        childAspectRatio: 1.4,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        children: cards,
      );
    } else {
      return Row(
        children: cards
            .map((c) => Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: TallySpacing.sm),
                    child: c,
                  ),
                ))
            .toList(),
      );
    }
  }

  Widget _buildEmptyState(bool noSalesAtAll) {
    return Container(
      margin: const EdgeInsets.only(top: TallySpacing.lg),
      padding: const EdgeInsets.all(TallySpacing.xl),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(TallyRadii.lg),
        border: Border.all(color: TallyColors.lightBorder),
      ),
      child: noSalesAtAll
          ? TallyEmptyState.zeroData(
              icon: Icons.receipt_long_outlined,
              title: 'No Sales Recorded Yet',
              description:
                  'When items are sold at the point of sale, transactions capture unit costs and selling prices at that exact time.\nHistorical reports will analyze profitability across all past price eras.',
            )
          : TallyEmptyState.searchEmpty(
              title: 'No Items Match Current Filter',
              description:
                  'Try adjusting your search query or selecting a different date range above.',
            ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  final String title;
  final String value;
  final String? subtitle;
  final IconData icon;
  final Color color;

  const _MetricTile({
    required this.title,
    required this.value,
    this.subtitle,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(TallySpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(TallyRadii.md),
        border: Border.all(color: TallyColors.lightBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: TallyColors.slateMuted,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(icon, size: 16, color: color),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: color,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          if (subtitle != null)
            Text(
              subtitle!,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
        ],
      ),
    );
  }
}

/// Item Profitability Card displaying aggregate metrics and multi-era breakdown.
class _ItemProfitCard extends StatelessWidget {
  final ItemProfitReport item;
  final NumberFormat currencyFormat;

  const _ItemProfitCard({
    required this.item,
    required this.currencyFormat,
  });

  @override
  Widget build(BuildContext context) {
    final revenue = item.totalRevenue;
    final profit = item.totalGrossProfit;
    final margin = item.marginPercentage;
    final qty = item.totalQuantitySold;
    final isPositive = profit >= 0;

    return Container(
      margin: const EdgeInsets.only(bottom: TallySpacing.sm),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(TallyRadii.md),
        border: Border.all(color: TallyColors.lightBorder),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: false,
          tilePadding: const EdgeInsets.symmetric(
            horizontal: TallySpacing.md,
            vertical: 4,
          ),
          childrenPadding: const EdgeInsets.only(
            left: TallySpacing.md,
            right: TallySpacing.md,
            bottom: TallySpacing.md,
          ),
          title: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.itemName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: TallyColors.primaryNavy,
                      ),
                    ),
                    if (item.sku != null && item.sku!.isNotEmpty)
                      Text(
                        'SKU: ${item.sku}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: TallyColors.slateMuted,
                        ),
                      ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '₦${currencyFormat.format(profit)}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: isPositive
                          ? TallyColors.varianceZeroLight
                          : TallyColors.stockCritical,
                    ),
                  ),
                  Text(
                    '${margin.toStringAsFixed(1)}% margin',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isPositive
                          ? TallyColors.varianceZeroLight
                          : TallyColors.stockCritical,
                    ),
                  ),
                ],
              ),
            ],
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              children: [
                Text(
                  'Sold: ${qty.toStringAsFixed(qty % 1 == 0 ? 0 : 2)} ${item.unit}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: TallyColors.slateMuted,
                  ),
                ),
                const SizedBox(width: 8),
                const Text('•',
                    style: TextStyle(color: TallyColors.lightBorderStrong)),
                const SizedBox(width: 8),
                Text(
                  'Revenue: ₦${currencyFormat.format(revenue)}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: TallyColors.primaryNavy,
                  ),
                ),
              ],
            ),
          ),
          children: [
            const Divider(color: TallyColors.lightBorder, height: 1),
            const SizedBox(height: TallySpacing.sm),

            // Header for Price Eras
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Pricing & Cost History Eras',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: TallyColors.slateMuted,
                  ),
                ),
                Text(
                  '${item.priceEras.length} distinct price era${item.priceEras.length > 1 ? 's' : ''}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: TallyColors.slateMuted,
                  ),
                ),
              ],
            ),
            const SizedBox(height: TallySpacing.xs),

            // Eras list
            ...item.priceEras.map((era) {
              final eraProfit = era.grossProfit;
              final eraMargin = era.marginPercentage;
              final eraPositive = eraProfit >= 0;
              final eraQty = era.quantitySold;

              return Container(
                margin: const EdgeInsets.only(top: 6),
                padding: const EdgeInsets.all(TallySpacing.sm),
                decoration: BoxDecoration(
                  color: TallyColors.iceFrost.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(TallyRadii.sm),
                  border: Border.all(color: TallyColors.lightBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: TallyColors.primaryNavy,
                                borderRadius:
                                    BorderRadius.circular(TallyRadii.sm),
                              ),
                              child: Text(
                                'Sold @ ₦${currencyFormat.format(era.unitPrice)}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '(Cost: ₦${currencyFormat.format(era.unitCost)})',
                              style: const TextStyle(
                                fontSize: 11,
                                color: TallyColors.slateMuted,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          '${eraQty.toStringAsFixed(eraQty % 1 == 0 ? 0 : 2)} ${item.unit} sold',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: TallyColors.primaryNavy,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Revenue: ₦${currencyFormat.format(era.revenue)} | COGS: ₦${currencyFormat.format(era.cogs)}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: TallyColors.slateMuted,
                          ),
                        ),
                        Text(
                          'Profit: ₦${currencyFormat.format(eraProfit)} (${eraMargin.toStringAsFixed(1)}%)',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: eraPositive
                                ? TallyColors.varianceZeroLight
                                : TallyColors.stockCritical,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

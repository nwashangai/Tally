import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../app/providers/core_providers.dart';
import '../../core/error/app_error.dart';
import '../../domain/receiving/receiving.dart';
import '../design_system/extensions/responsive.dart';
import '../design_system/tokens/colors.dart';
import '../design_system/tokens/dimensions.dart';
import '../design_system/widgets/tally_cancel_button.dart';
import 'widgets/receiving_status_badge.dart';

/// Detailed view of a historical Receiving transaction, including immutable item snapshots and voiding capability.
class ReceivingDetailsScreen extends ConsumerStatefulWidget {
  final Receiving receiving;

  const ReceivingDetailsScreen({super.key, required this.receiving});

  @override
  ConsumerState<ReceivingDetailsScreen> createState() =>
      _ReceivingDetailsScreenState();
}

class _ReceivingDetailsScreenState
    extends ConsumerState<ReceivingDetailsScreen> {
  late Receiving _receiving;
  bool _isVoiding = false;

  @override
  void initState() {
    super.initState();
    _receiving = widget.receiving;
    _refreshReceiving();
  }

  Future<void> _refreshReceiving() async {
    final repo = ref.read(receivingRepositoryProvider);
    final res = await repo.getById(_receiving.id);
    if (res.isSuccess && res.valueOrNull != null && mounted) {
      setState(() => _receiving = res.valueOrNull!);
    }
  }

  Future<void> _handleVoid() async {
    final reasonCtrl = TextEditingController();

    final shouldVoid = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(TallyRadii.lg),
        ),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: TallyColors.stockCritical),
            SizedBox(width: TallySpacing.sm),
            Text(
              'Void Receiving?',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: TallyColors.primaryNavy,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Voiding transaction ${_receiving.referenceNumber} will deduct ${_receiving.totalQuantity.toStringAsFixed(_receiving.totalQuantity % 1 == 0 ? 0 : 2)} units from current stock levels and record an audited reversal movement.',
              style: const TextStyle(
                fontSize: 14,
                color: TallyColors.primaryNavy,
              ),
            ),
            const SizedBox(height: TallySpacing.md),
            TextField(
              controller: reasonCtrl,
              decoration: InputDecoration(
                labelText: 'Reason for voiding (optional)',
                hintText: 'e.g. Returned to supplier / Input error',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(TallyRadii.md),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
              ),
            ),
          ],
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
            child: const Text('Confirm Void'),
          ),
        ],
      ),
    );

    if (shouldVoid != true) return;

    setState(() => _isVoiding = true);
    final repo = ref.read(receivingRepositoryProvider);
    final result = await repo.voidReceiving(
      _receiving.id,
      reason: reasonCtrl.text.trim().isNotEmpty ? reasonCtrl.text.trim() : null,
    );

    setState(() => _isVoiding = false);

    result.fold(
      onSuccess: (updated) {
        setState(() => _receiving = updated);
        ref.read(receivingListProvider.notifier).refresh();
        ref.read(itemListProvider.notifier).load();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Receiving ${_receiving.referenceNumber} has been voided. Stock reversed.',
            ),
            backgroundColor: TallyColors.stockCritical,
          ),
        );
      },
      onFailure: (err, _) {
        final msg = err is AppError ? err.message : '$err';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to void receiving: $msg'),
            backgroundColor: TallyColors.stockCritical,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isPhone = context.isPhone;
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm');
    final dateOnlyFormat = DateFormat('MMM d, yyyy');
    final totalCost = _receiving.totalCost;
    final formattedCost =
        '₦${totalCost.toStringAsFixed(totalCost % 1 == 0 ? 0 : 2)}';
    final totalQuantity = _receiving.totalQuantity;
    final formattedQty =
        totalQuantity.toStringAsFixed(totalQuantity % 1 == 0 ? 0 : 2);

    return Scaffold(
      backgroundColor: TallyColors.lightCanvas,
      appBar: AppBar(
        title: Text(
          _receiving.referenceNumber,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: TallyColors.primaryNavy,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: TallyColors.primaryNavy),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: TallySpacing.md),
            child: Center(
              child: ReceivingStatusBadge(status: _receiving.status),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: TallyColors.lightBorder, height: 1),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(isPhone ? TallySpacing.md : TallySpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Voided Banner
            if (_receiving.isVoided) ...[
              Container(
                padding: const EdgeInsets.all(TallySpacing.md),
                decoration: BoxDecoration(
                  color: TallyColors.stockCritical.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(TallyRadii.md),
                  border: Border.all(
                    color: TallyColors.stockCritical.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      color: TallyColors.stockCritical,
                      size: 24,
                    ),
                    const SizedBox(width: TallySpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'This transaction has been voided',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: TallyColors.stockCritical,
                            ),
                          ),
                          Text(
                            _receiving.notes?.isNotEmpty == true
                                ? 'Note: ${_receiving.notes}'
                                : 'Stock additions were reversed. Historical acquisition details are preserved.',
                            style: const TextStyle(
                              fontSize: 12,
                              color: TallyColors.primaryNavy,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: TallySpacing.md),
            ],

            // 1. Transaction Summary Metrics Cards
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    title: 'Total Line Items',
                    value: '${_receiving.lines.length}',
                    icon: Icons.list_alt,
                  ),
                ),
                const SizedBox(width: TallySpacing.sm),
                Expanded(
                  child: _buildMetricCard(
                    title: 'Units Inbound',
                    value: formattedQty,
                    icon: Icons.inventory_2_outlined,
                  ),
                ),
                const SizedBox(width: TallySpacing.sm),
                Expanded(
                  child: _buildMetricCard(
                    title: 'Total Acquisition Value',
                    value: formattedCost,
                    icon: Icons.attach_money,
                    isHighlight: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: TallySpacing.md),

            // 2. Metadata / Information Card
            Container(
              padding: const EdgeInsets.all(TallySpacing.md),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(TallyRadii.md),
                border: Border.all(color: TallyColors.lightBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Transaction Details',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: TallyColors.primaryNavy,
                    ),
                  ),
                  const SizedBox(height: TallySpacing.md),
                  _buildMetaRow(
                    'Date Received',
                    dateOnlyFormat.format(_receiving.receivedAt),
                  ),
                  _buildMetaRow(
                    'Supplier',
                    _receiving.supplier?.isNotEmpty == true
                        ? _receiving.supplier!
                        : '—',
                  ),
                  _buildMetaRow(
                    'Notes',
                    _receiving.notes?.isNotEmpty == true
                        ? _receiving.notes!
                        : '—',
                  ),
                  _buildMetaRow(
                    'Recorded At',
                    dateFormat.format(_receiving.createdAt),
                  ),
                  if (_receiving.createdBy?.isNotEmpty == true)
                    _buildMetaRow('Created By', _receiving.createdBy!),
                ],
              ),
            ),
            const SizedBox(height: TallySpacing.lg),

            // 3. Line Items Snapshot Table
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Received Products',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: TallyColors.primaryNavy,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: TallyColors.iceFrost,
                    borderRadius: BorderRadius.circular(TallyRadii.full),
                  ),
                  child: const Text(
                    'Historical Immutable Snapshots',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: TallyColors.primaryNavy,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: TallySpacing.sm),

            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(TallyRadii.md),
                border: Border.all(color: TallyColors.lightBorder),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(TallyRadii.md),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    headingRowHeight: 40,
                    dataRowMinHeight: 48,
                    dataRowMaxHeight: 52,
                    headingRowColor: WidgetStateProperty.all(
                      TallyColors.iceFrost.withValues(alpha: 0.5),
                    ),
                    columns: const [
                      DataColumn(
                        label: Text(
                          'Product',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: TallyColors.slateMuted,
                          ),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'SKU',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: TallyColors.slateMuted,
                          ),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Quantity',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: TallyColors.slateMuted,
                          ),
                        ),
                      ),
                      DataColumn(
                        numeric: true,
                        label: Text(
                          'Unit Cost',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: TallyColors.slateMuted,
                          ),
                        ),
                      ),
                      DataColumn(
                        numeric: true,
                        label: Text(
                          'Selling Price',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: TallyColors.slateMuted,
                          ),
                        ),
                      ),
                      DataColumn(
                        numeric: true,
                        label: Text(
                          'Subtotal',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: TallyColors.slateMuted,
                          ),
                        ),
                      ),
                    ],
                    rows: _receiving.lines.map((l) {
                      final lineTotal = l.lineTotal;
                      final formattedSubtotal =
                          '₦${lineTotal.toStringAsFixed(lineTotal % 1 == 0 ? 0 : 2)}';
                      final formattedLineCost =
                          '₦${l.unitCost.toStringAsFixed(l.unitCost % 1 == 0 ? 0 : 2)}';
                      final formattedSelling = l.newBaseSellingPrice != null
                          ? '₦${l.newBaseSellingPrice!.toStringAsFixed(l.newBaseSellingPrice! % 1 == 0 ? 0 : 2)}'
                          : '—';
                      final qtyStr = l.quantity
                          .toStringAsFixed(l.quantity % 1 == 0 ? 0 : 2);

                      return DataRow(
                        cells: [
                          DataCell(
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  l.itemNameSnapshot,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                    color: TallyColors.primaryNavy,
                                  ),
                                ),
                                if (l.updateItemCost)
                                  const Text(
                                    'Catalog cost updated',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: TallyColors.varianceZeroLight,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          DataCell(
                            Text(
                              l.skuSnapshot?.isNotEmpty == true
                                  ? l.skuSnapshot!
                                  : '—',
                              style: const TextStyle(
                                fontSize: 12,
                                color: TallyColors.slateMuted,
                              ),
                            ),
                          ),
                          DataCell(
                            Text(
                              '$qtyStr ${l.unitSnapshot}',
                              style: const TextStyle(
                                fontSize: 13,
                                color: TallyColors.primaryNavy,
                              ),
                            ),
                          ),
                          DataCell(
                            Text(
                              formattedLineCost,
                              style: const TextStyle(
                                fontSize: 13,
                                color: TallyColors.primaryNavy,
                              ),
                            ),
                          ),
                          DataCell(
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  formattedSelling,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: TallyColors.primaryNavy,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                if (l.updateItemPrice)
                                  const Text(
                                    'Catalog price updated',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: TallyColors.primaryNavy,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          DataCell(
                            Text(
                              formattedSubtotal,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: TallyColors.primaryNavy,
                              ),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
            const SizedBox(height: TallySpacing.xl),

            // 4. Void Action (Only if completed)
            if (_receiving.isCompleted) ...[
              Center(
                child: OutlinedButton.icon(
                  onPressed: _isVoiding ? null : _handleVoid,
                  icon: const Icon(
                    Icons.cancel_outlined,
                    size: 18,
                    color: TallyColors.stockCritical,
                  ),
                  label: _isVoiding
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text(
                          'Void this Receiving Transaction',
                          style: TextStyle(
                            color: TallyColors.stockCritical,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: TallyColors.stockCritical),
                    shape: const StadiumBorder(),
                    padding: const EdgeInsets.symmetric(
                      horizontal: TallySpacing.xl,
                      vertical: TallySpacing.md,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: TallySpacing.xl),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    bool isHighlight = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(TallySpacing.md),
      decoration: BoxDecoration(
        color: isHighlight ? TallyColors.iceFrost : Colors.white,
        borderRadius: BorderRadius.circular(TallyRadii.md),
        border: Border.all(
          color: isHighlight
              ? TallyColors.primaryNavy.withValues(alpha: 0.2)
              : TallyColors.lightBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    color: TallyColors.slateMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                icon,
                size: 16,
                color: isHighlight
                    ? TallyColors.primaryNavy
                    : TallyColors.slateMuted,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: TallyColors.primaryNavy,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetaRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: TallyColors.slateMuted,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: TallyColors.primaryNavy,
            ),
          ),
        ],
      ),
    );
  }
}

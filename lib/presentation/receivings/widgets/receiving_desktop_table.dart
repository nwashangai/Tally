import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../app/providers/core_providers.dart';
import '../../../domain/receiving/receiving.dart';
import '../../../domain/receiving/receiving_query.dart';
import '../../../domain/receiving/receiving_status.dart';
import '../../design_system/tokens/colors.dart';
import '../../design_system/tokens/dimensions.dart';
import 'receiving_status_badge.dart';

/// Responsive data table for displaying Receivings on tablet and desktop surfaces.
class ReceivingDesktopTable extends ConsumerWidget {
  final List<Receiving> receivings;
  final ValueChanged<Receiving> onViewDetails;
  final ValueChanged<Receiving>? onVoid;

  const ReceivingDesktopTable({
    super.key,
    required this.receivings,
    required this.onViewDetails,
    this.onVoid,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = ref.watch(receivingQueryProvider);
    final queryNotifier = ref.read(receivingQueryProvider.notifier);
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm');

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(TallyRadii.md),
        border: Border.all(color: TallyColors.lightBorder),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(TallyRadii.md),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(minWidth: constraints.maxWidth),
                child: SingleChildScrollView(
                  child: DataTable(
                    headingRowHeight: 44,
                    dataRowMinHeight: 48,
                    dataRowMaxHeight: 56,
                    horizontalMargin: 16,
                    columnSpacing: 24,
                    headingRowColor: WidgetStateProperty.all(
                      TallyColors.iceFrost.withValues(alpha: 0.5),
                    ),
                    columns: [
                      // Reference Column (sortable)
                      DataColumn(
                        label: _buildSortableHeader(
                          label: 'Reference',
                          field: ReceivingSortField.reference,
                          currentSort: query.sortBy,
                          direction: query.sortDirection,
                          onTap: () => queryNotifier
                              .setSortField(ReceivingSortField.reference),
                        ),
                      ),
                      // Date Received (sortable)
                      DataColumn(
                        label: _buildSortableHeader(
                          label: 'Date Received',
                          field: ReceivingSortField.receivedAt,
                          currentSort: query.sortBy,
                          direction: query.sortDirection,
                          onTap: () => queryNotifier
                              .setSortField(ReceivingSortField.receivedAt),
                        ),
                      ),
                      // Supplier
                      const DataColumn(
                        label: Text(
                          'Supplier',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: TallyColors.slateMuted,
                          ),
                        ),
                      ),
                      // Items Count
                      const DataColumn(
                        label: Text(
                          'Items',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: TallyColors.slateMuted,
                          ),
                        ),
                      ),
                      // Total Units
                      const DataColumn(
                        label: Text(
                          'Units Received',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: TallyColors.slateMuted,
                          ),
                        ),
                      ),
                      // Total Cost (sortable)
                      DataColumn(
                        numeric: true,
                        label: _buildSortableHeader(
                          label: 'Total Cost',
                          field: ReceivingSortField.totalCost,
                          currentSort: query.sortBy,
                          direction: query.sortDirection,
                          onTap: () => queryNotifier
                              .setSortField(ReceivingSortField.totalCost),
                        ),
                      ),
                      // Status
                      const DataColumn(
                        label: Text(
                          'Status',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: TallyColors.slateMuted,
                          ),
                        ),
                      ),
                      // Actions
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
                    rows: receivings.map((rec) {
                      final totalCost = rec.totalCost;
                      final formattedCost =
                          '₦${totalCost.toStringAsFixed(totalCost % 1 == 0 ? 0 : 2)}';
                      final totalQuantity = rec.totalQuantity;
                      final formattedQty = totalQuantity
                          .toStringAsFixed(totalQuantity % 1 == 0 ? 0 : 2);

                      return DataRow(
                        cells: [
                          // Reference
                          DataCell(
                            InkWell(
                              onTap: () => onViewDetails(rec),
                              child: Text(
                                rec.referenceNumber,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: TallyColors.primaryNavy,
                                ),
                              ),
                            ),
                          ),
                          // Date Received
                          DataCell(
                            Text(
                              dateFormat.format(rec.receivedAt),
                              style: const TextStyle(
                                fontSize: 13,
                                color: TallyColors.primaryNavy,
                              ),
                            ),
                          ),
                          // Supplier
                          DataCell(
                            Text(
                              rec.supplier?.isNotEmpty == true
                                  ? rec.supplier!
                                  : '—',
                              style: TextStyle(
                                fontSize: 13,
                                color: rec.supplier?.isNotEmpty == true
                                    ? TallyColors.primaryNavy
                                    : TallyColors.slateMuted,
                              ),
                            ),
                          ),
                          // Items Count
                          DataCell(
                            Text(
                              '${rec.lines.length}',
                              style: const TextStyle(
                                fontSize: 13,
                                color: TallyColors.primaryNavy,
                              ),
                            ),
                          ),
                          // Units Received
                          DataCell(
                            Text(
                              formattedQty,
                              style: const TextStyle(
                                fontSize: 13,
                                color: TallyColors.primaryNavy,
                              ),
                            ),
                          ),
                          // Total Cost
                          DataCell(
                            Text(
                              formattedCost,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: TallyColors.primaryNavy,
                              ),
                            ),
                          ),
                          // Status
                          DataCell(
                            ReceivingStatusBadge(status: rec.status),
                          ),
                          // Actions
                          DataCell(
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Tooltip(
                                  message: 'View Details',
                                  child: IconButton(
                                    icon: const Icon(
                                      Icons.visibility_outlined,
                                      size: 18,
                                      color: TallyColors.primaryNavy,
                                    ),
                                    onPressed: () => onViewDetails(rec),
                                    splashRadius: 18,
                                  ),
                                ),
                                if (rec.status == ReceivingStatus.completed &&
                                    onVoid != null)
                                  Tooltip(
                                    message: 'Void Receiving',
                                    child: IconButton(
                                      icon: const Icon(
                                        Icons.cancel_outlined,
                                        size: 18,
                                        color: TallyColors.stockCritical,
                                      ),
                                      onPressed: () => onVoid!(rec),
                                      splashRadius: 18,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSortableHeader({
    required String label,
    required ReceivingSortField field,
    required ReceivingSortField currentSort,
    required ReceivingSortDirection direction,
    required VoidCallback onTap,
  }) {
    final isSorted = currentSort == field;

    return InkWell(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color:
                  isSorted ? TallyColors.primaryNavy : TallyColors.slateMuted,
            ),
          ),
          const SizedBox(width: 4),
          Icon(
            isSorted
                ? (direction.isAscending
                    ? Icons.arrow_upward
                    : Icons.arrow_downward)
                : Icons.unfold_more,
            size: 14,
            color: isSorted
                ? TallyColors.primaryNavy
                : TallyColors.slateMuted.withValues(alpha: 0.5),
          ),
        ],
      ),
    );
  }
}

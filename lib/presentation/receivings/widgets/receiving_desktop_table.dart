import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../app/providers/core_providers.dart';
import '../../../domain/receiving/receiving.dart';
import '../../../domain/receiving/receiving_query.dart';
import '../../../domain/receiving/receiving_status.dart';
import '../../design_system/tokens/colors.dart';
import '../../design_system/widgets/tally_sortable_header.dart';
import '../../design_system/widgets/tally_table_container.dart';
import 'receiving_status_badge.dart';

/// Responsive data table for displaying Receivings on tablet and desktop surfaces.
class ReceivingDesktopTable extends ConsumerWidget {
  final List<Receiving> receivings;
  final ValueChanged<Receiving> onViewDetails;
  final ValueChanged<Receiving>? onVoid;
  final ValueChanged<Receiving>? onEditDraft;
  final ValueChanged<Receiving>? onDeleteDraft;

  const ReceivingDesktopTable({
    super.key,
    required this.receivings,
    required this.onViewDetails,
    this.onVoid,
    this.onEditDraft,
    this.onDeleteDraft,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = ref.watch(receivingQueryProvider);
    final queryNotifier = ref.read(receivingQueryProvider.notifier);
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm');

    return TallyTableContainer(
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
            label: TallySortableHeader(
              label: 'Reference',
              isSorted: query.sortBy == ReceivingSortField.reference,
              isAscending: query.sortDirection.isAscending,
              onTap: () => queryNotifier
                  .setSortField(ReceivingSortField.reference),
            ),
          ),
          // Date Received (sortable)
          DataColumn(
            label: TallySortableHeader(
              label: 'Date Received',
              isSorted: query.sortBy == ReceivingSortField.receivedAt,
              isAscending: query.sortDirection.isAscending,
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
            label: TallySortableHeader(
              label: 'Total Cost',
              isSorted: query.sortBy == ReceivingSortField.totalCost,
              isAscending: query.sortDirection.isAscending,
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
                                if (rec.status == ReceivingStatus.draft) ...[
                                  if (onEditDraft != null)
                                    Tooltip(
                                      message: 'Edit Draft',
                                      child: IconButton(
                                        icon: const Icon(
                                          Icons.edit_outlined,
                                          size: 18,
                                          color: TallyColors.primaryNavy,
                                        ),
                                        onPressed: () => onEditDraft!(rec),
                                        splashRadius: 18,
                                      ),
                                    ),
                                  if (onDeleteDraft != null)
                                    Tooltip(
                                      message: 'Delete Draft',
                                      child: IconButton(
                                        icon: const Icon(
                                          Icons.delete_outline,
                                          size: 18,
                                          color: TallyColors.stockCritical,
                                        ),
                                        onPressed: () => onDeleteDraft!(rec),
                                        splashRadius: 18,
                                      ),
                                    ),
                                ],
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
    );
  }
}

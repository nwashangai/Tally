import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../domain/receiving/receiving.dart';
import '../../design_system/tokens/colors.dart';
import '../../design_system/tokens/dimensions.dart';
import 'receiving_status_badge.dart';

/// Card component representing a Receiving transaction on mobile screens.
class ReceivingMobileCard extends StatelessWidget {
  final Receiving receiving;
  final VoidCallback onTap;
  final VoidCallback? onVoid;

  const ReceivingMobileCard({
    super.key,
    required this.receiving,
    required this.onTap,
    this.onVoid,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d, yyyy');
    final formattedDate = dateFormat.format(receiving.receivedAt);
    final totalCost = receiving.totalCost;
    final formattedCost =
        '₦${totalCost.toStringAsFixed(totalCost % 1 == 0 ? 0 : 2)}';
    final totalQuantity = receiving.totalQuantity;
    final formattedQty =
        totalQuantity.toStringAsFixed(totalQuantity % 1 == 0 ? 0 : 2);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(TallyRadii.md),
        side: const BorderSide(color: TallyColors.lightBorder),
      ),
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: TallySpacing.sm),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(TallyRadii.md),
        child: Padding(
          padding: const EdgeInsets.all(TallySpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Reference Number & Status Badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: TallyColors.iceFrost,
                          borderRadius: BorderRadius.circular(TallyRadii.sm),
                        ),
                        child: const Icon(
                          Icons.local_shipping_outlined,
                          size: 16,
                          color: TallyColors.primaryNavy,
                        ),
                      ),
                      const SizedBox(width: TallySpacing.xs),
                      Text(
                        receiving.referenceNumber,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: TallyColors.primaryNavy,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                  ReceivingStatusBadge(status: receiving.status),
                ],
              ),
              const SizedBox(height: TallySpacing.sm),

              // Date & Supplier Info
              Row(
                children: [
                  const Icon(
                    Icons.calendar_today_outlined,
                    size: 13,
                    color: TallyColors.slateMuted,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    formattedDate,
                    style: const TextStyle(
                      fontSize: 12,
                      color: TallyColors.slateMuted,
                    ),
                  ),
                  if (receiving.supplier != null &&
                      receiving.supplier!.isNotEmpty) ...[
                    const SizedBox(width: TallySpacing.sm),
                    const Text('•',
                        style: TextStyle(color: TallyColors.lightBorderStrong)),
                    const SizedBox(width: TallySpacing.sm),
                    const Icon(
                      Icons.storefront_outlined,
                      size: 13,
                      color: TallyColors.slateMuted,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        receiving.supplier!,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: TallyColors.slateMuted,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: TallySpacing.sm),
              const Divider(height: 1, color: TallyColors.lightBorder),
              const SizedBox(height: TallySpacing.sm),

              // Summary Metrics Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Items & Qty',
                          style: TextStyle(
                            fontSize: 11,
                            color: TallyColors.slateMuted,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${receiving.lines.length} items ($formattedQty units)',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: TallyColors.primaryNavy,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: TallySpacing.sm),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        'Total Value',
                        style: TextStyle(
                          fontSize: 11,
                          color: TallyColors.slateMuted,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        formattedCost,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: TallyColors.primaryNavy,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../app/providers/core_providers.dart';
import '../../domain/item/item.dart';
import '../design_system/extensions/responsive.dart';
import '../design_system/tokens/colors.dart';
import '../design_system/tokens/dimensions.dart';
import 'item_form_screen.dart';
import 'widgets/item_delete_confirm_dialog.dart';

/// Dedicated screen/view for inspecting an individual item's current catalog and inventory state.
class ItemDetailsScreen extends ConsumerWidget {
  final Item item;

  const ItemDetailsScreen({
    super.key,
    required this.item,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm');
    final pricing = item.pricing;
    final inventory = item.inventory;
    final isPhone = context.isPhone;

    return Scaffold(
      backgroundColor: TallyColors.lightCanvas,
      appBar: AppBar(
        title: Text(
          item.name,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit Item',
            onPressed: () async {
              final updated = await Navigator.of(context).push<bool>(
                MaterialPageRoute(
                  builder: (_) => ItemFormScreen(existingItem: item),
                ),
              );
              if (updated == true && context.mounted) {
                Navigator.of(context).pop(true);
              }
            },
          ),
          IconButton(
            icon: Icon(
              item.isActive ? Icons.archive_outlined : Icons.unarchive_outlined,
            ),
            tooltip: item.isActive ? 'Archive Item' : 'Reactivate Item',
            onPressed: () async {
              if (item.isActive) {
                await ref.read(itemListProvider.notifier).archiveItem(item.id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Archived "${item.name}"')),
                  );
                  Navigator.of(context).pop(true);
                }
              } else {
                await ref.read(itemListProvider.notifier).activateItem(item.id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Reactivated "${item.name}"')),
                  );
                  Navigator.of(context).pop(true);
                }
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(TallySpacing.lg),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Identity Header Card
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(TallyRadii.lg),
                    side: const BorderSide(color: TallyColors.lightBorder),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(TallySpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.name,
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w800,
                                      color: TallyColors.primaryNavy,
                                    ),
                                  ),
                                  if (item.description != null &&
                                      item.description!.isNotEmpty) ...[
                                    const SizedBox(height: TallySpacing.xs),
                                    Text(
                                      item.description!,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: TallyColors.slateMuted,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: item.isActive
                                    ? TallyColors.varianceZeroLight
                                        .withValues(alpha: 0.12)
                                    : TallyColors.slateMuted
                                        .withValues(alpha: 0.12),
                                borderRadius:
                                    BorderRadius.circular(TallyRadii.sm),
                              ),
                              child: Text(
                                item.isActive ? 'Active' : 'Archived',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: item.isActive
                                      ? TallyColors.varianceZeroLight
                                      : TallyColors.slateMuted,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: TallySpacing.md),
                        const Divider(color: TallyColors.lightBorder),
                        const SizedBox(height: TallySpacing.sm),
                        Wrap(
                          spacing: TallySpacing.lg,
                          runSpacing: TallySpacing.sm,
                          children: [
                            _buildMetaPill('SKU', item.sku ?? 'Not set'),
                            _buildMetaPill(
                                'Barcode', item.barcode ?? 'Not set'),
                            _buildMetaPill(
                              'Category',
                              item.categoryId ?? 'Uncategorized',
                            ),
                            _buildMetaPill('Unit', item.unit.label),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: TallySpacing.md),

                // 2. Current Pricing Section
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(TallyRadii.lg),
                    side: const BorderSide(color: TallyColors.lightBorder),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(TallySpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(
                              Icons.sell_outlined,
                              size: 20,
                              color: TallyColors.primaryNavy,
                            ),
                            SizedBox(width: TallySpacing.xs),
                            Expanded(
                              child: Text(
                                'Current Pricing',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: TallyColors.primaryNavy,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: TallySpacing.md),
                        Row(
                          children: [
                            Expanded(
                              child: _buildMetricBox(
                                label: 'Cost Price',
                                value:
                                    '₦${pricing.costPrice.toStringAsFixed(pricing.costPrice % 1 == 0 ? 0 : 2)}',
                                subtitle: 'Current unit acquisition',
                              ),
                            ),
                            const SizedBox(width: TallySpacing.sm),
                            Expanded(
                              child: _buildMetricBox(
                                label: 'Base Selling Price',
                                value:
                                    '₦${pricing.baseSellingPrice.toStringAsFixed(pricing.baseSellingPrice % 1 == 0 ? 0 : 2)}',
                                subtitle: 'Retail standard',
                                isPrimary: true,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: TallySpacing.sm),
                        Row(
                          children: [
                            Expanded(
                              child: _buildMetricBox(
                                label: 'Minimum Selling Price',
                                value: pricing.minSellingPrice != null
                                    ? '₦${pricing.minSellingPrice!.toStringAsFixed(pricing.minSellingPrice! % 1 == 0 ? 0 : 2)}'
                                    : 'None',
                                subtitle: 'Negotiation floor',
                              ),
                            ),
                            const SizedBox(width: TallySpacing.sm),
                            Expanded(
                              child: _buildMetricBox(
                                label: 'Gross Margin',
                                value:
                                    '₦${pricing.margin.toStringAsFixed(pricing.margin % 1 == 0 ? 0 : 2)}',
                                subtitle:
                                    '${pricing.markupPercentage.toStringAsFixed(1)}% Markup',
                                textColor: pricing.margin >= 0
                                    ? TallyColors.varianceZeroLight
                                    : TallyColors.stockCritical,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: TallySpacing.md),

                // 3. Inventory Stock Section
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(TallyRadii.lg),
                    side: const BorderSide(color: TallyColors.lightBorder),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(TallySpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(
                              Icons.inventory_2_outlined,
                              size: 20,
                              color: TallyColors.primaryNavy,
                            ),
                            SizedBox(width: TallySpacing.xs),
                            Expanded(
                              child: Text(
                                'Inventory & Stock',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: TallyColors.primaryNavy,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: TallySpacing.md),
                        Row(
                          children: [
                            Expanded(
                              child: _buildMetricBox(
                                label: 'On-Hand Stock',
                                value:
                                    '${inventory.quantity.toStringAsFixed(inventory.quantity % 1 == 0 ? 0 : 2)} ${item.unit.abbreviation}',
                                subtitle: inventory.isLowStock
                                    ? 'Low stock warning'
                                    : (inventory.isOutOfStock
                                        ? 'Out of stock'
                                        : 'Healthy stock'),
                                textColor: inventory.isOutOfStock
                                    ? TallyColors.stockCritical
                                    : (inventory.isLowStock
                                        ? TallyColors.varianceDiscrepancy
                                        : TallyColors.primaryNavy),
                              ),
                            ),
                            const SizedBox(width: TallySpacing.sm),
                            Expanded(
                              child: _buildMetricBox(
                                label: 'Reorder Level',
                                value: inventory.reorderLevel != null
                                    ? '${inventory.reorderLevel!.toStringAsFixed(0)} ${item.unit.abbreviation}'
                                    : 'Not configured',
                                subtitle: 'Alert threshold',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: TallySpacing.md),

                // 4. Domain History Principle Notice
                Container(
                  padding: const EdgeInsets.all(TallySpacing.md),
                  decoration: BoxDecoration(
                    color: TallyColors.iceFrost.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(TallyRadii.md),
                    border: Border.all(color: TallyColors.lightBorderStrong),
                  ),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.history_edu_outlined,
                        size: 22,
                        color: TallyColors.primaryNavy,
                      ),
                      SizedBox(width: TallySpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Ledger Principle (ADR 0012)',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: TallyColors.primaryNavy,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Current values shown here belong to the item catalog. Past transaction costs and selling prices in Receivings and Sales are immutably preserved in the historical ledger.',
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

                // 5. Audit & Activity Metadata (Timestamps)
                _buildAuditCard(item, dateFormat),
                const SizedBox(height: TallySpacing.md),

                // 6. Danger Zone / Management Actions
                _buildDangerZoneCard(context, ref, item, isPhone),

                // Generous bottom spacing for safe scrolling and mobile gestures
                SizedBox(
                  height:
                      TallySpacing.xxl + MediaQuery.paddingOf(context).bottom,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAuditCard(Item item, DateFormat dateFormat) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(TallyRadii.lg),
        side: const BorderSide(color: TallyColors.lightBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.all(TallySpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.history_toggle_off_rounded,
                  size: 16,
                  color: TallyColors.slateMuted,
                ),
                const SizedBox(width: TallySpacing.xs),
                const Expanded(
                  child: Text(
                    'Record Audit',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                      color: TallyColors.slateMuted,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: TallyColors.iceFrost,
                    borderRadius: BorderRadius.circular(TallyRadii.full),
                    border: Border.all(color: TallyColors.lightBorder),
                  ),
                  child: Text(
                    'ID: ${item.id.value.length > 8 ? item.id.value.substring(0, 8) : item.id.value}',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: TallyColors.primaryNavy,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: TallySpacing.sm),
            const Divider(color: TallyColors.lightBorder, height: 1),
            const SizedBox(height: TallySpacing.md),
            Wrap(
              spacing: TallySpacing.xl,
              runSpacing: TallySpacing.md,
              children: [
                _buildTimestampTile(
                  icon: Icons.calendar_today_outlined,
                  label: 'Created on',
                  value: dateFormat.format(item.createdAt.toLocal()),
                ),
                _buildTimestampTile(
                  icon: Icons.edit_calendar_outlined,
                  label: 'Last updated',
                  value: dateFormat.format(item.updatedAt.toLocal()),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimestampTile({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: TallyColors.iceFrost.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(TallyRadii.sm),
          ),
          child: Icon(icon, size: 14, color: TallyColors.primaryNavy),
        ),
        const SizedBox(width: TallySpacing.sm),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: TallyColors.slateMuted,
              ),
            ),
            const SizedBox(height: 2),
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
      ],
    );
  }

  Widget _buildDangerZoneCard(
    BuildContext context,
    WidgetRef ref,
    Item item,
    bool isPhone,
  ) {
    final leadingInfo = [
      Container(
        padding: const EdgeInsets.all(TallySpacing.sm),
        decoration: BoxDecoration(
          color: TallyColors.stockCritical.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(TallyRadii.md),
        ),
        child: const Icon(
          Icons.delete_sweep_outlined,
          size: 22,
          color: TallyColors.stockCritical,
        ),
      ),
      const SizedBox(width: TallySpacing.md),
      const Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Item Removal & Danger Zone',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: TallyColors.primaryNavy,
              ),
            ),
            SizedBox(height: 2),
            Text(
              'Archive to hide from active catalog, or delete permanently if no transactions exist.',
              style: TextStyle(
                fontSize: 12,
                color: TallyColors.slateMuted,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    ];

    final actionButton = OutlinedButton.icon(
      key: const Key('item_details_delete_archive_button'),
      onPressed: () => _handleDeleteOrArchive(context, ref, item),
      icon: const Icon(Icons.delete_outline, size: 16),
      label: const Text('Archive or Delete'),
      style: OutlinedButton.styleFrom(
        foregroundColor: TallyColors.stockCritical,
        side: BorderSide(
          color: TallyColors.stockCritical.withValues(alpha: 0.4),
        ),
        backgroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(
          horizontal: TallySpacing.base,
          vertical: 12,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(TallyRadii.md),
        ),
      ),
    );

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(TallyRadii.lg),
        side: BorderSide(
          color: TallyColors.stockCritical.withValues(alpha: 0.25),
        ),
      ),
      color: TallyColors.stockCritical.withValues(alpha: 0.03),
      child: Padding(
        padding: const EdgeInsets.all(TallySpacing.md),
        child: isPhone
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: leadingInfo,
                  ),
                  const SizedBox(height: TallySpacing.md),
                  actionButton,
                ],
              )
            : Row(
                children: [
                  ...leadingInfo,
                  const SizedBox(width: TallySpacing.md),
                  actionButton,
                ],
              ),
      ),
    );
  }

  Future<void> _handleDeleteOrArchive(
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
          SnackBar(
            content: Text('Archived "${item.name}"'),
          ),
        );
        Navigator.of(context).pop(true);
      }
    } else if (action == ItemDeleteAction.delete) {
      final deleteRes =
          await ref.read(itemListProvider.notifier).deleteItem(item.id);
      if (!context.mounted) return;
      if (deleteRes.isSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Deleted "${item.name}" permanently'),
          ),
        );
        Navigator.of(context).pop(true);
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

  Widget _buildMetaPill(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: TallyColors.slateMuted,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: TallyColors.primaryNavy,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricBox({
    required String label,
    required String value,
    required String subtitle,
    bool isPrimary = false,
    Color? textColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(TallySpacing.md),
      decoration: BoxDecoration(
        color: isPrimary
            ? TallyColors.iceFrost.withValues(alpha: 0.5)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(TallyRadii.md),
        border: Border.all(
          color: isPrimary
              ? TallyColors.primaryNavy.withValues(alpha: 0.2)
              : TallyColors.lightBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: TallyColors.slateMuted,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: textColor ?? TallyColors.primaryNavy,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 11,
              color: TallyColors.slateMuted,
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../app/providers/core_providers.dart';
import '../../application/receiving/create_receiving_notifier.dart';
import '../../core/error/app_error.dart';
import '../../domain/item/item.dart';
import '../../domain/item/item_query.dart';
import '../../domain/item/item_repository.dart';
import '../../domain/receiving/receiving_line.dart';
import '../design_system/extensions/responsive.dart';
import '../design_system/tokens/colors.dart';
import '../design_system/tokens/dimensions.dart';
import '../design_system/widgets/tally_cancel_button.dart';
import '../items/widgets/barcode_scanner_sheet.dart';

/// Screen for creating and receiving stock into inventory from suppliers.
class NewReceivingScreen extends ConsumerStatefulWidget {
  const NewReceivingScreen({super.key});

  @override
  ConsumerState<NewReceivingScreen> createState() => _NewReceivingScreenState();
}

class _NewReceivingScreenState extends ConsumerState<NewReceivingScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _refCtrl;
  late final TextEditingController _supplierCtrl;
  late final TextEditingController _notesCtrl;

  @override
  void initState() {
    super.initState();
    final state = ref.read(createReceivingProvider);
    _refCtrl = TextEditingController(text: state.referenceNumber);
    _supplierCtrl = TextEditingController(text: state.supplier);
    _notesCtrl = TextEditingController(text: state.notes);
  }

  @override
  void dispose() {
    _refCtrl.dispose();
    _supplierCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate(BuildContext context) async {
    final state = ref.read(createReceivingProvider);
    final picked = await showDatePicker(
      context: context,
      initialDate: state.receivedAt,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      ref.read(createReceivingProvider.notifier).setReceivedAt(picked);
    }
  }

  Future<void> _showItemPickerDialog(BuildContext context) async {
    final itemRepo = ref.read(itemRepositoryProvider);
    final selectedItem = await showDialog<Item>(
      context: context,
      builder: (ctx) => _ItemPickerSearchDialog(itemRepository: itemRepo),
    );

    if (selectedItem != null && mounted) {
      ref.read(createReceivingProvider.notifier).addItem(
            selectedItem,
            quantity: 1,
            unitCost: selectedItem.pricing.costPrice,
            updateItemCost: false,
            newBaseSellingPrice: selectedItem.pricing.baseSellingPrice,
            newMinSellingPrice: selectedItem.pricing.minSellingPrice,
            updateItemPrice: false,
          );
    }
  }

  Future<void> _scanAndAddItem() async {
    final scannedBarcode = await BarcodeScannerSheet.scan(context);
    if (scannedBarcode == null || scannedBarcode.trim().isEmpty || !mounted) {
      return;
    }

    final barcode = scannedBarcode.trim();
    final itemRepo = ref.read(itemRepositoryProvider);
    final res = await itemRepo.query(
      ItemQuery(
        search: barcode,
        pageSize: 50,
      ),
    );

    if (!mounted) return;

    final items = res.valueOrNull?.items ?? [];
    // Prioritize exact match on barcode or SKU (case-insensitive)
    Item? exactMatch;
    for (final i in items) {
      final itemBarcode = i.barcode?.trim().toLowerCase();
      final itemSku = i.sku?.trim().toLowerCase();
      if (itemBarcode == barcode.toLowerCase() ||
          itemSku == barcode.toLowerCase()) {
        exactMatch = i;
        break;
      }
    }

    final matchedItem = exactMatch ?? (items.length == 1 ? items.first : null);

    if (matchedItem != null) {
      ref.read(createReceivingProvider.notifier).addItem(
            matchedItem,
            quantity: 1,
            unitCost: matchedItem.pricing.costPrice,
            updateItemCost: false,
            newBaseSellingPrice: matchedItem.pricing.baseSellingPrice,
            newMinSellingPrice: matchedItem.pricing.minSellingPrice,
            updateItemPrice: false,
          );

      if (!mounted) return;
      final skuSuffix = matchedItem.sku != null && matchedItem.sku!.isNotEmpty
          ? ' (${matchedItem.sku})'
          : '';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Added ${matchedItem.name}$skuSuffix',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          backgroundColor: TallyColors.varianceZeroLight,

          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else if (items.isNotEmpty) {
      if (!mounted) return;
      // Multiple partial matches, show picker pre-filled with the barcode
      final selected = await showDialog<Item>(
        context: context,
        builder: (ctx) => _ItemPickerSearchDialog(
          itemRepository: itemRepo,
          initialSearch: barcode,
        ),
      );
      if (selected != null && mounted) {
        ref.read(createReceivingProvider.notifier).addItem(
              selected,
              quantity: 1,
              unitCost: selected.pricing.costPrice,
              updateItemCost: false,
              newBaseSellingPrice: selected.pricing.baseSellingPrice,
              newMinSellingPrice: selected.pricing.minSellingPrice,
              updateItemPrice: false,
            );
      }
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.warning_amber_rounded,
                  color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'No product found for barcode "$barcode"',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          backgroundColor: TallyColors.stockCritical,
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }



  Future<void> _handleSave({required bool markCompleted}) async {
    final notifier = ref.read(createReceivingProvider.notifier);
    final state = ref.read(createReceivingProvider);

    notifier.setReference(_refCtrl.text);
    notifier.setSupplier(_supplierCtrl.text);
    notifier.setNotes(_notesCtrl.text);

    if (state.lines.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one line item.'),
          backgroundColor: TallyColors.stockCritical,
        ),
      );
      return;
    }

    if (markCompleted) {
      final shouldProceed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(TallyRadii.lg),
          ),
          title: const Row(
            children: [
              Icon(Icons.inventory, color: TallyColors.primaryNavy),
              SizedBox(width: TallySpacing.sm),
              Text(
                'Complete Receiving?',
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
                'Completing this transaction will immediately increase inventory stock levels for ${state.lines.length} items and record audited stock movements.',
                style: const TextStyle(
                  fontSize: 14,
                  color: TallyColors.primaryNavy,
                ),
              ),
              const SizedBox(height: TallySpacing.md),
              Container(
                padding: const EdgeInsets.all(TallySpacing.md),
                decoration: BoxDecoration(
                  color: TallyColors.iceFrost,
                  borderRadius: BorderRadius.circular(TallyRadii.md),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Reference:',
                            style: TextStyle(
                                fontSize: 12, color: TallyColors.slateMuted)),
                        Text(state.referenceNumber,
                            style: const TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w700)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total Units:',
                            style: TextStyle(
                                fontSize: 12, color: TallyColors.slateMuted)),
                        Text(
                          state.totalQuantity.toStringAsFixed(
                              state.totalQuantity % 1 == 0 ? 0 : 2),
                          style: const TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total Value:',
                            style: TextStyle(
                                fontSize: 12, color: TallyColors.slateMuted)),
                        Text(
                          '₦${state.totalCost.toStringAsFixed(state.totalCost % 1 == 0 ? 0 : 2)}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: TallyColors.primaryNavy,
                          ),
                        ),
                      ],
                    ),
                  ],
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
                backgroundColor: TallyColors.primaryNavy,
                foregroundColor: Colors.white,
                shape: const StadiumBorder(),
                padding: const EdgeInsets.symmetric(
                  horizontal: TallySpacing.xl,
                  vertical: TallySpacing.md,
                ),
              ),
              child: const Text('Confirm & Complete'),
            ),
          ],
        ),
      );

      if (shouldProceed != true) return;
    }

    final result = await notifier.submit(markCompleted: markCompleted);
    result.fold(
      onSuccess: (receiving) {
        // Refresh receiving list and item list
        ref.read(receivingListProvider.notifier).refresh();
        ref.read(itemListProvider.notifier).load();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                markCompleted
                    ? 'Receiving ${receiving.referenceNumber} completed successfully. Stock updated.'
                    : 'Receiving ${receiving.referenceNumber} saved as draft.',
              ),
              backgroundColor: TallyColors.varianceZeroLight,
            ),
          );
          Navigator.of(context).pop(true);
        }
      },
      onFailure: (err, _) {
        if (mounted) {
          final msg = err is AppError ? err.message : '$err';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed: $msg'),
              backgroundColor: TallyColors.stockCritical,
            ),
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(createReceivingProvider);
    final isPhone = context.isPhone;
    final dateFormat = DateFormat('MMM d, yyyy');

    // Keep controller in sync if auto-generated reference arrived
    if (_refCtrl.text.isEmpty && state.referenceNumber.isNotEmpty) {
      _refCtrl.text = state.referenceNumber;
    }

    return Scaffold(
      backgroundColor: TallyColors.lightCanvas,
      appBar: AppBar(
        title: const Text(
          'New Receiving',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: TallyColors.primaryNavy,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: TallyColors.primaryNavy),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: TallyColors.lightBorder, height: 1),
        ),
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(
                  isPhone ? TallySpacing.md : TallySpacing.lg,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Top Info Card: Reference, Date, Supplier, Notes
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
                            'Transaction Information',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: TallyColors.primaryNavy,
                            ),
                          ),
                          const SizedBox(height: TallySpacing.md),
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final useTwoCols = constraints.maxWidth > 500;
                              return Column(
                                children: [
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Reference Number
                                      Expanded(
                                        child: TextFormField(
                                          controller: _refCtrl,
                                          decoration: InputDecoration(
                                            labelText: 'Reference Number *',
                                            hintText: 'e.g. REC-000001',
                                            prefixIcon: const Icon(
                                              Icons.tag,
                                              size: 18,
                                              color: TallyColors.slateMuted,
                                            ),
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(
                                                      TallyRadii.md),
                                            ),
                                            contentPadding:
                                                const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 12,
                                            ),
                                          ),
                                          onChanged: (val) => ref
                                              .read(createReceivingProvider
                                                  .notifier)
                                              .setReference(val),
                                          validator: (val) {
                                            if (val == null ||
                                                val.trim().isEmpty) {
                                              return 'Reference number is required';
                                            }
                                            return null;
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: TallySpacing.md),
                                      // Date Received
                                      Expanded(
                                        child: InkWell(
                                          onTap: () => _pickDate(context),
                                          borderRadius: BorderRadius.circular(
                                              TallyRadii.md),
                                          child: InputDecorator(
                                            decoration: InputDecoration(
                                              labelText: 'Date Received',
                                              prefixIcon: const Icon(
                                                Icons.calendar_today,
                                                size: 18,
                                                color: TallyColors.slateMuted,
                                              ),
                                              border: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(
                                                        TallyRadii.md),
                                              ),
                                              contentPadding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 12,
                                                vertical: 12,
                                              ),
                                            ),
                                            child: Text(
                                              dateFormat
                                                  .format(state.receivedAt),
                                              style: const TextStyle(
                                                fontSize: 13,
                                                color: TallyColors.primaryNavy,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: TallySpacing.md),
                                  if (useTwoCols)
                                    Row(
                                      children: [
                                        Expanded(
                                          child: TextFormField(
                                            controller: _supplierCtrl,
                                            decoration: InputDecoration(
                                              labelText: 'Supplier (Optional)',
                                              hintText:
                                                  'e.g. Acme Distributors Ltd',
                                              prefixIcon: const Icon(
                                                Icons.storefront_outlined,
                                                size: 18,
                                                color: TallyColors.slateMuted,
                                              ),
                                              border: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(
                                                        TallyRadii.md),
                                              ),
                                              contentPadding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 12,
                                                vertical: 12,
                                              ),
                                            ),
                                            onChanged: (val) => ref
                                                .read(createReceivingProvider
                                                    .notifier)
                                                .setSupplier(val),
                                          ),
                                        ),
                                        const SizedBox(width: TallySpacing.md),
                                        Expanded(
                                          child: TextFormField(
                                            controller: _notesCtrl,
                                            decoration: InputDecoration(
                                              labelText: 'Notes (Optional)',
                                              hintText:
                                                  'e.g. Delivery note #9842',
                                              prefixIcon: const Icon(
                                                Icons.notes_outlined,
                                                size: 18,
                                                color: TallyColors.slateMuted,
                                              ),
                                              border: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(
                                                        TallyRadii.md),
                                              ),
                                              contentPadding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 12,
                                                vertical: 12,
                                              ),
                                            ),
                                            onChanged: (val) => ref
                                                .read(createReceivingProvider
                                                    .notifier)
                                                .setNotes(val),
                                          ),
                                        ),
                                      ],
                                    )
                                  else ...[
                                    TextFormField(
                                      controller: _supplierCtrl,
                                      decoration: InputDecoration(
                                        labelText: 'Supplier (Optional)',
                                        hintText: 'e.g. Acme Distributors Ltd',
                                        prefixIcon: const Icon(
                                          Icons.storefront_outlined,
                                          size: 18,
                                          color: TallyColors.slateMuted,
                                        ),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                              TallyRadii.md),
                                        ),
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 12,
                                        ),
                                      ),
                                      onChanged: (val) => ref
                                          .read(
                                              createReceivingProvider.notifier)
                                          .setSupplier(val),
                                    ),
                                    const SizedBox(height: TallySpacing.md),
                                    TextFormField(
                                      controller: _notesCtrl,
                                      decoration: InputDecoration(
                                        labelText: 'Notes (Optional)',
                                        hintText: 'e.g. Delivery note #9842',
                                        prefixIcon: const Icon(
                                          Icons.notes_outlined,
                                          size: 18,
                                          color: TallyColors.slateMuted,
                                        ),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                              TallyRadii.md),
                                        ),
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 12,
                                        ),
                                      ),
                                      onChanged: (val) => ref
                                          .read(
                                              createReceivingProvider.notifier)
                                          .setNotes(val),
                                    ),
                                  ],
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: TallySpacing.lg),

                    // Line Items Section Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Inbound Line Items',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: TallyColors.primaryNavy,
                                ),
                              ),
                              Text(
                                '${state.lines.length} items added',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: TallyColors.slateMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: TallySpacing.sm),
                        Wrap(
                          spacing: TallySpacing.xs,
                          runSpacing: TallySpacing.xs,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            OutlinedButton.icon(
                              onPressed: _scanAndAddItem,
                              icon: const Icon(Icons.qr_code_scanner, size: 16),
                              label: const Text('Scan'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: TallyColors.primaryNavy,
                                side: const BorderSide(
                                    color: TallyColors.primaryNavy),
                                shape: const StadiumBorder(),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                              ),
                            ),
                            ElevatedButton.icon(
                              onPressed: () => _showItemPickerDialog(context),
                              icon: const Icon(Icons.add_shopping_cart, size: 16),
                              label: const Text('Add Product'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: TallyColors.primaryNavy,
                                foregroundColor: Colors.white,
                                shape: const StadiumBorder(),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: TallySpacing.md,
                                  vertical: 10,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: TallySpacing.md),

                    // Line Items List
                    if (state.lines.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(TallySpacing.xxl),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(TallyRadii.md),
                          border: Border.all(
                            color: TallyColors.lightBorder,
                            style: BorderStyle.solid,
                          ),
                        ),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: const BoxDecoration(
                                color: TallyColors.iceFrost,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.add_box_outlined,
                                size: 40,
                                color: TallyColors.primaryNavy,
                              ),
                            ),
                            const SizedBox(height: TallySpacing.md),
                            const Text(
                              'No products added yet',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: TallyColors.primaryNavy,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Search and select products or scan barcodes to record inbound quantities and acquisition costs.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13,
                                color: TallyColors.slateMuted,
                              ),
                            ),
                            const SizedBox(height: TallySpacing.md),
                            Wrap(
                              spacing: TallySpacing.sm,
                              runSpacing: TallySpacing.sm,
                              alignment: WrapAlignment.center,
                              children: [
                                ElevatedButton.icon(
                                  onPressed: _scanAndAddItem,
                                  icon: const Icon(Icons.qr_code_scanner, size: 16),
                                  label: const Text('Scan Barcode'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: TallyColors.primaryNavy,
                                    foregroundColor: Colors.white,
                                    shape: const StadiumBorder(),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: TallySpacing.md,
                                      vertical: 10,
                                    ),
                                  ),
                                ),
                                OutlinedButton.icon(
                                  onPressed: () => _showItemPickerDialog(context),
                                  icon: const Icon(Icons.search, size: 16),
                                  label: const Text('Select from Catalog'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: TallyColors.primaryNavy,
                                    shape: const StadiumBorder(),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: TallySpacing.md,
                                      vertical: 10,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      )

                    else
                      ...state.lines.map((line) {
                        return _ReceivingLineCard(
                          key: ValueKey(line.id),
                          line: line,
                          onQuantityChanged: (qty) => ref
                              .read(createReceivingProvider.notifier)
                              .updateQuantity(line.id, qty),
                          onUnitCostChanged: (cost) => ref
                              .read(createReceivingProvider.notifier)
                              .updateUnitCost(line.id, cost),
                          onUpdateCostToggled: (val) => ref
                              .read(createReceivingProvider.notifier)
                              .toggleUpdateItemCost(line.id, val),
                          onBaseSellingPriceChanged: (price) => ref
                              .read(createReceivingProvider.notifier)
                              .updateBaseSellingPrice(line.id, price),
                          onMinSellingPriceChanged: (minPrice) => ref
                              .read(createReceivingProvider.notifier)
                              .updateMinSellingPrice(line.id, minPrice),
                          onUpdatePriceToggled: (val) => ref
                              .read(createReceivingProvider.notifier)
                              .toggleUpdateItemPrice(line.id, val),
                          onRemove: () => ref
                              .read(createReceivingProvider.notifier)
                              .removeLine(line.id),
                        );
                      }),
                  ],
                ),
              ),
            ),

            // Bottom Sticky Summary & Action Bar
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: isPhone ? TallySpacing.md : TallySpacing.xl,
                vertical: isPhone ? TallySpacing.sm : TallySpacing.md,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 12,
                    offset: const Offset(0, -4),
                  ),
                ],
                border: const Border(
                  top: BorderSide(color: TallyColors.lightBorder),
                ),
              ),
              child: SafeArea(
                top: false,
                child: isPhone
                    ? _buildMobileFooter(context, state)
                    : _buildDesktopFooter(context, state),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileFooter(BuildContext context, CreateReceivingState state) {
    final currencyFormat = NumberFormat('#,##0.00', 'en_US');
    final formattedCost = currencyFormat.format(state.totalCost);
    final itemsCount = state.lines.length;
    final totalQtyStr = state.totalQuantity
        .toStringAsFixed(state.totalQuantity % 1 == 0 ? 0 : 2);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Enterprise Metric Summary Strip (zero layout shift, clean horizontal layout)
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: TallySpacing.sm,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            color: TallyColors.iceFrost.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(TallyRadii.md),
            border: Border.all(color: TallyColors.lightBorder),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Left: Items & Units pills
              Expanded(
                child: Row(
                  children: [
                    const Icon(
                      Icons.inventory_2_outlined,
                      size: 14,
                      color: TallyColors.primaryNavy,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '$itemsCount ${itemsCount == 1 ? 'item' : 'items'}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: TallyColors.primaryNavy,
                              ),
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 4),
                              child: Text(
                                '•',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: TallyColors.slateMuted,
                                ),
                              ),
                            ),
                            Text(
                              '$totalQtyStr units',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: TallyColors.primaryNavy,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),

              // Right: Total Cost Value
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerRight,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Total: ',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: TallyColors.slateMuted,
                      ),
                    ),
                    Text(
                      '₦$formattedCost',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: TallyColors.primaryNavy,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: TallySpacing.sm),

        // 2. Action Buttons Row (proper enterprise proportions & touch targets)
        Row(
          children: [
            // Cancel
            TallyCancelButton(
              onPressed: () => Navigator.of(context).pop(),
              padding: const EdgeInsets.symmetric(
                horizontal: TallySpacing.md,
                vertical: 12,
              ),
            ),
            const SizedBox(width: 8),

            // Save Draft (secondary outlined)
            Expanded(
              flex: 2,
              child: OutlinedButton(
                onPressed: state.isSaving
                    ? null
                    : () => _handleSave(markCompleted: false),
                style: OutlinedButton.styleFrom(
                  foregroundColor: TallyColors.primaryNavy,
                  side: const BorderSide(color: TallyColors.lightBorderStrong),
                  shape: const StadiumBorder(),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    'Save Draft',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),

            // Complete Receiving (primary solid)
            Expanded(
              flex: 3,
              child: ElevatedButton.icon(
                onPressed: state.isSaving
                    ? null
                    : () => _handleSave(markCompleted: true),
                icon: state.isSaving
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.check_circle_outline, size: 16),
                label: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    state.isSaving ? 'Completing...' : 'Complete Receiving',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: TallyColors.primaryNavy,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: const StadiumBorder(),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDesktopFooter(BuildContext context, CreateReceivingState state) {
    final currencyFormat = NumberFormat('#,##0.00', 'en_US');
    final formattedCost = currencyFormat.format(state.totalCost);
    final itemsCount = state.lines.length;
    final totalQtyStr = state.totalQuantity
        .toStringAsFixed(state.totalQuantity % 1 == 0 ? 0 : 2);

    return Row(
      children: [
        // Summary Totals
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$itemsCount ${itemsCount == 1 ? 'item' : 'items'} • $totalQtyStr units',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: TallyColors.slateMuted,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Total: ₦$formattedCost',
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: TallyColors.primaryNavy,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
        ),

        // Actions
        TallyCancelButton(
          onPressed: () => Navigator.of(context).pop(),
        ),
        const SizedBox(width: TallySpacing.sm),
        OutlinedButton(
          onPressed:
              state.isSaving ? null : () => _handleSave(markCompleted: false),
          style: OutlinedButton.styleFrom(
            foregroundColor: TallyColors.primaryNavy,
            side: const BorderSide(color: TallyColors.lightBorderStrong),
            shape: const StadiumBorder(),
            padding: const EdgeInsets.symmetric(
              horizontal: TallySpacing.lg,
              vertical: 12,
            ),
          ),
          child: const Text(
            'Save Draft',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(width: TallySpacing.sm),
        ElevatedButton(
          onPressed:
              state.isSaving ? null : () => _handleSave(markCompleted: true),
          style: ElevatedButton.styleFrom(
            backgroundColor: TallyColors.primaryNavy,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: const StadiumBorder(),
            padding: const EdgeInsets.symmetric(
              horizontal: TallySpacing.xl,
              vertical: 12,
            ),
          ),
          child: state.isSaving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text(
                  'Complete Receiving',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
        ),
      ],
    );
  }
}

/// Card representing a single receiving line item with editable quantity, unit cost, base selling price, min selling price, and update toggles.
class _ReceivingLineCard extends StatefulWidget {
  final ReceivingLine line;
  final ValueChanged<double> onQuantityChanged;
  final ValueChanged<double> onUnitCostChanged;
  final ValueChanged<bool> onUpdateCostToggled;
  final ValueChanged<double?> onBaseSellingPriceChanged;
  final ValueChanged<double?> onMinSellingPriceChanged;
  final ValueChanged<bool> onUpdatePriceToggled;
  final VoidCallback onRemove;

  const _ReceivingLineCard({
    super.key,
    required this.line,
    required this.onQuantityChanged,
    required this.onUnitCostChanged,
    required this.onUpdateCostToggled,
    required this.onBaseSellingPriceChanged,
    required this.onMinSellingPriceChanged,
    required this.onUpdatePriceToggled,
    required this.onRemove,
  });

  @override
  State<_ReceivingLineCard> createState() => _ReceivingLineCardState();
}

class _ReceivingLineCardState extends State<_ReceivingLineCard> {
  late final TextEditingController _qtyCtrl;
  late final TextEditingController _costCtrl;
  late final TextEditingController _basePriceCtrl;
  late final TextEditingController _minPriceCtrl;

  @override
  void initState() {
    super.initState();
    _qtyCtrl = TextEditingController(
      text: widget.line.quantity
          .toStringAsFixed(widget.line.quantity % 1 == 0 ? 0 : 2),
    );
    _costCtrl = TextEditingController(
      text: widget.line.unitCost
          .toStringAsFixed(widget.line.unitCost % 1 == 0 ? 0 : 2),
    );
    _basePriceCtrl = TextEditingController(
      text: widget.line.newBaseSellingPrice != null
          ? widget.line.newBaseSellingPrice!.toStringAsFixed(
              widget.line.newBaseSellingPrice! % 1 == 0 ? 0 : 2)
          : '',
    );
    _minPriceCtrl = TextEditingController(
      text: widget.line.newMinSellingPrice != null
          ? widget.line.newMinSellingPrice!
              .toStringAsFixed(widget.line.newMinSellingPrice! % 1 == 0 ? 0 : 2)
          : '',
    );
  }

  @override
  void didUpdateWidget(covariant _ReceivingLineCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.line.quantity != widget.line.quantity) {
      final text = widget.line.quantity
          .toStringAsFixed(widget.line.quantity % 1 == 0 ? 0 : 2);
      if (_qtyCtrl.text != text) _qtyCtrl.text = text;
    }
    if (oldWidget.line.unitCost != widget.line.unitCost) {
      final text = widget.line.unitCost
          .toStringAsFixed(widget.line.unitCost % 1 == 0 ? 0 : 2);
      if (_costCtrl.text != text) _costCtrl.text = text;
    }
    if (oldWidget.line.newBaseSellingPrice != widget.line.newBaseSellingPrice) {
      final text = widget.line.newBaseSellingPrice != null
          ? widget.line.newBaseSellingPrice!.toStringAsFixed(
              widget.line.newBaseSellingPrice! % 1 == 0 ? 0 : 2)
          : '';
      if (_basePriceCtrl.text != text) _basePriceCtrl.text = text;
    }
    if (oldWidget.line.newMinSellingPrice != widget.line.newMinSellingPrice) {
      final text = widget.line.newMinSellingPrice != null
          ? widget.line.newMinSellingPrice!
              .toStringAsFixed(widget.line.newMinSellingPrice! % 1 == 0 ? 0 : 2)
          : '';
      if (_minPriceCtrl.text != text) _minPriceCtrl.text = text;
    }
  }

  @override
  void dispose() {
    _qtyCtrl.dispose();
    _costCtrl.dispose();
    _basePriceCtrl.dispose();
    _minPriceCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final line = widget.line;
    final lineTotal = line.lineTotal;
    final formattedTotal =
        '₦${lineTotal.toStringAsFixed(lineTotal % 1 == 0 ? 0 : 2)}';

    return Container(
      margin: const EdgeInsets.only(bottom: TallySpacing.sm),
      padding: const EdgeInsets.all(TallySpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(TallyRadii.md),
        border: Border.all(color: TallyColors.lightBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Item Name, SKU, Unit, Remove Button
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      line.itemNameSnapshot,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: TallyColors.primaryNavy,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        if (line.skuSnapshot != null &&
                            line.skuSnapshot!.isNotEmpty) ...[
                          Text(
                            'SKU: ${line.skuSnapshot}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: TallyColors.slateMuted,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text('•',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: TallyColors.lightBorderStrong)),
                          const SizedBox(width: 8),
                        ],
                        Text(
                          'Unit: ${line.unitSnapshot}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: TallyColors.slateMuted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.delete_outline,
                  size: 20,
                  color: TallyColors.stockCritical,
                ),
                onPressed: widget.onRemove,
                splashRadius: 18,
              ),
            ],
          ),
          const SizedBox(height: TallySpacing.sm),
          const Divider(height: 1, color: TallyColors.lightBorder),
          const SizedBox(height: TallySpacing.sm),

          // Inputs Row 1: Quantity, Unit Cost, and Line Total
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Quantity
              Expanded(
                flex: 2,
                child: TextFormField(
                  controller: _qtyCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                  ],
                  decoration: InputDecoration(
                    labelText: 'Quantity',
                    suffixText: line.unitSnapshot,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 10,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(TallyRadii.sm),
                    ),
                  ),
                  onChanged: (val) {
                    final d = double.tryParse(val);
                    if (d != null && d > 0) widget.onQuantityChanged(d);
                  },
                ),
              ),
              const SizedBox(width: TallySpacing.sm),

              // Unit Cost
              Expanded(
                flex: 2,
                child: TextFormField(
                  controller: _costCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                  ],
                  decoration: InputDecoration(
                    labelText: 'Unit Cost',
                    prefixText: '₦ ',
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 10,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(TallyRadii.sm),
                    ),
                  ),
                  onChanged: (val) {
                    final d = double.tryParse(val);
                    if (d != null && d >= 0) widget.onUnitCostChanged(d);
                  },
                ),
              ),
              const SizedBox(width: TallySpacing.sm),

              // Line Total
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'Subtotal',
                      style: TextStyle(
                        fontSize: 11,
                        color: TallyColors.slateMuted,
                      ),
                    ),
                    Text(
                      formattedTotal,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: TallyColors.primaryNavy,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: TallySpacing.sm),

          // Inputs Row 2: Base Selling Price and Min Selling Price
          Row(
            children: [
              // Base Selling Price
              Expanded(
                child: TextFormField(
                  controller: _basePriceCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                  ],
                  decoration: InputDecoration(
                    labelText: 'Base Selling Price',
                    prefixText: '₦ ',
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 10,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(TallyRadii.sm),
                    ),
                  ),
                  onChanged: (val) {
                    final d = double.tryParse(val);
                    widget.onBaseSellingPriceChanged(d);
                  },
                ),
              ),
              const SizedBox(width: TallySpacing.sm),

              // Min Selling Price
              Expanded(
                child: TextFormField(
                  controller: _minPriceCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                  ],
                  decoration: InputDecoration(
                    labelText: 'Min Selling Price',
                    prefixText: '₦ ',
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 10,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(TallyRadii.sm),
                    ),
                  ),
                  onChanged: (val) {
                    final d = double.tryParse(val);
                    widget.onMinSellingPriceChanged(d);
                  },
                ),
              ),
            ],
          ),

          // Margin & Markup Indicator
          if (line.newBaseSellingPrice != null) ...[
            const SizedBox(height: TallySpacing.xs),
            Builder(
              builder: (context) {
                final margin = line.margin ?? 0;
                final markup = line.markupPercentage;
                final isPositive = margin >= 0;
                final markupText = markup != null
                    ? '${markup >= 0 ? "+" : ""}${markup.toStringAsFixed(1)}% markup'
                    : '';
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: TallySpacing.sm,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isPositive
                        ? TallyColors.varianceZeroLight.withValues(alpha: 0.1)
                        : TallyColors.stockCritical.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(TallyRadii.sm),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isPositive ? Icons.trending_up : Icons.trending_down,
                        size: 14,
                        color: isPositive
                            ? TallyColors.varianceZeroLight
                            : TallyColors.stockCritical,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Margin: ₦${margin.toStringAsFixed(margin % 1 == 0 ? 0 : 2)} ($markupText)',
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
                );
              },
            ),
          ],

          const SizedBox(height: TallySpacing.xs),

          // Checkbox: Update Catalog Cost Price
          InkWell(
            onTap: () => widget.onUpdateCostToggled(!line.updateItemCost),
            borderRadius: BorderRadius.circular(TallyRadii.sm),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: Checkbox(
                      value: line.updateItemCost,
                      onChanged: (v) => widget.onUpdateCostToggled(v ?? false),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Expanded(
                    child: Text(
                      'Update catalog cost price to this unit cost',
                      style: TextStyle(
                        fontSize: 12,
                        color: TallyColors.primaryNavy,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Checkbox: Update Catalog Selling Prices
          InkWell(
            onTap: () => widget.onUpdatePriceToggled(!line.updateItemPrice),
            borderRadius: BorderRadius.circular(TallyRadii.sm),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: Checkbox(
                      value: line.updateItemPrice,
                      onChanged: (v) => widget.onUpdatePriceToggled(v ?? false),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Expanded(
                    child: Text(
                      'Update catalog selling prices (Base & Min)',
                      style: TextStyle(
                        fontSize: 12,
                        color: TallyColors.primaryNavy,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Dialog for searching and selecting active items from the catalog to add to receiving.
class _ItemPickerSearchDialog extends StatefulWidget {
  final ItemRepository itemRepository;
  final String? initialSearch;

  const _ItemPickerSearchDialog({
    required this.itemRepository,
    this.initialSearch,
  });

  @override
  State<_ItemPickerSearchDialog> createState() =>
      _ItemPickerSearchDialogState();
}

class _ItemPickerSearchDialogState extends State<_ItemPickerSearchDialog> {
  late final TextEditingController _searchCtrl;
  List<Item> _items = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _searchCtrl = TextEditingController(text: widget.initialSearch ?? '');
    _fetchItems(_searchCtrl.text);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchItems([String search = '']) async {
    setState(() => _isLoading = true);
    final res = await widget.itemRepository.query(
      ItemQuery(
        search: search.trim(),
        pageSize: 50,
      ),
    );
    if (mounted) {
      setState(() {
        _isLoading = false;
        _items = res.valueOrNull?.items ?? [];
      });
    }
  }

  Future<void> _scanBarcode() async {
    final barcode = await BarcodeScannerSheet.scan(context);
    if (barcode != null && barcode.trim().isNotEmpty && mounted) {
      final trimmed = barcode.trim();
      _searchCtrl.text = trimmed;
      await _fetchItems(trimmed);
      Item? exact;
      for (final i in _items) {
        final itemBarcode = i.barcode?.trim().toLowerCase();
        final itemSku = i.sku?.trim().toLowerCase();
        if (itemBarcode == trimmed.toLowerCase() ||
            itemSku == trimmed.toLowerCase()) {
          exact = i;
          break;
        }
      }
      final candidate = exact ?? (_items.length == 1 ? _items.first : null);
      if (candidate != null && mounted) {
        Navigator.of(context).pop(candidate);
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(TallyRadii.lg),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 550, maxHeight: 600),
        child: Padding(
          padding: const EdgeInsets.all(TallySpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Select Product',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: TallyColors.primaryNavy,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: TallySpacing.sm),
              TextField(
                controller: _searchCtrl,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Search by product name, SKU, or barcode...',
                  prefixIcon: const Icon(Icons.search, size: 18),
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_searchCtrl.text.isNotEmpty)
                        IconButton(
                          icon: const Icon(Icons.clear, size: 16),
                          onPressed: () {
                            _searchCtrl.clear();
                            _fetchItems('');
                          },
                        ),
                      IconButton(
                        icon: const Icon(
                          Icons.qr_code_scanner,
                          size: 20,
                          color: TallyColors.primaryNavy,
                        ),
                        tooltip: 'Scan Barcode',
                        onPressed: _scanBarcode,
                      ),
                    ],
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(TallyRadii.md),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                ),
                onChanged: (val) => _fetchItems(val),
              ),
              const SizedBox(height: TallySpacing.md),

              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: TallyColors.primaryNavy,
                        ),
                      )
                    : _items.isEmpty
                        ? const Center(
                            child: Text(
                              'No products found.',
                              style: TextStyle(color: TallyColors.slateMuted),
                            ),
                          )
                        : ListView.separated(
                            itemCount: _items.length,
                            separatorBuilder: (_, __) => const Divider(
                              height: 1,
                              color: TallyColors.lightBorder,
                            ),
                            itemBuilder: (ctx, idx) {
                              final item = _items[idx];
                              final cost = item.pricing.costPrice;
                              return ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                title: Text(
                                  item.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                    color: TallyColors.primaryNavy,
                                  ),
                                ),
                                subtitle: Text(
                                  'SKU: ${item.sku ?? '—'} • Current Stock: ${item.inventory.quantity.toStringAsFixed(item.inventory.quantity % 1 == 0 ? 0 : 2)} ${item.unit.abbreviation}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: TallyColors.slateMuted,
                                  ),
                                ),
                                trailing: Text(
                                  'Cost: ₦${cost.toStringAsFixed(cost % 1 == 0 ? 0 : 2)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                    color: TallyColors.primaryNavy,
                                  ),
                                ),
                                onTap: () => Navigator.of(context).pop(item),
                              );
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

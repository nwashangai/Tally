import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/providers/core_providers.dart';
import '../../application/store/current_store_state.dart';
import '../../domain/item/item.dart';
import '../../domain/item/item_id.dart';
import '../../domain/item/item_inventory.dart';
import '../../domain/item/item_pricing.dart';
import '../../domain/item/item_unit.dart';
import '../design_system/extensions/responsive.dart';
import '../design_system/tokens/colors.dart';
import '../design_system/tokens/dimensions.dart';
import '../design_system/widgets/tally_cancel_button.dart';
import 'widgets/barcode_scanner_sheet.dart';

/// Dedicated screen for creating or editing an Item in the store catalog.
/// Provides clear back navigation, form validation, and return-to-list confirmation.
class ItemFormScreen extends ConsumerStatefulWidget {
  final Item? existingItem;

  const ItemFormScreen({
    super.key,
    this.existingItem,
  });

  @override
  ConsumerState<ItemFormScreen> createState() => _ItemFormScreenState();
}

class _ItemFormScreenState extends ConsumerState<ItemFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameCtrl;
  late final TextEditingController _skuCtrl;
  late final TextEditingController _barcodeCtrl;
  late final TextEditingController _descriptionCtrl;
  late final TextEditingController _categoryCtrl;
  late final TextEditingController _costPriceCtrl;
  late final TextEditingController _baseSellingPriceCtrl;
  late final TextEditingController _minSellingPriceCtrl;
  late final TextEditingController _quantityCtrl;
  late final TextEditingController _reorderLevelCtrl;

  late ItemUnit _unit;
  late bool _isActive;
  bool _isSaving = false;
  String? _formError;

  bool get isEditing => widget.existingItem != null;

  @override
  void initState() {
    super.initState();
    final item = widget.existingItem;

    _nameCtrl = TextEditingController(text: item?.name ?? '');
    _skuCtrl = TextEditingController(text: item?.sku ?? '');
    _barcodeCtrl = TextEditingController(text: item?.barcode ?? '');
    _descriptionCtrl = TextEditingController(text: item?.description ?? '');
    _categoryCtrl = TextEditingController(text: item?.categoryId ?? '');
    _costPriceCtrl = TextEditingController(
      text: item != null
          ? item.pricing.costPrice.toStringAsFixed(
              item.pricing.costPrice % 1 == 0 ? 0 : 2,
            )
          : '',
    );
    _baseSellingPriceCtrl = TextEditingController(
      text: item != null
          ? item.pricing.baseSellingPrice.toStringAsFixed(
              item.pricing.baseSellingPrice % 1 == 0 ? 0 : 2,
            )
          : '',
    );
    _minSellingPriceCtrl = TextEditingController(
      text: item?.pricing.minSellingPrice != null
          ? item!.pricing.minSellingPrice!.toStringAsFixed(
              item.pricing.minSellingPrice! % 1 == 0 ? 0 : 2,
            )
          : '',
    );
    _quantityCtrl = TextEditingController(
      text: item != null
          ? item.inventory.quantity.toStringAsFixed(
              item.inventory.quantity % 1 == 0 ? 0 : 2,
            )
          : '0',
    );
    _reorderLevelCtrl = TextEditingController(
      text: item?.inventory.reorderLevel != null
          ? item!.inventory.reorderLevel!.toStringAsFixed(0)
          : '',
    );

    _unit = item?.unit ?? ItemUnit.piece;
    _isActive = item?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _skuCtrl.dispose();
    _barcodeCtrl.dispose();
    _descriptionCtrl.dispose();
    _categoryCtrl.dispose();
    _costPriceCtrl.dispose();
    _baseSellingPriceCtrl.dispose();
    _minSellingPriceCtrl.dispose();
    _quantityCtrl.dispose();
    _reorderLevelCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
      _formError = null;
    });

    try {
      final storeState = ref.read(currentStoreProvider);
      if (storeState is! StoreSelected) {
        setState(() {
          _isSaving = false;
          _formError = 'No active store selected.';
        });
        return;
      }

      final name = _nameCtrl.text.trim();
      final sku = _skuCtrl.text.trim().isEmpty ? null : _skuCtrl.text.trim();
      final barcode =
          _barcodeCtrl.text.trim().isEmpty ? null : _barcodeCtrl.text.trim();
      final description = _descriptionCtrl.text.trim().isEmpty
          ? null
          : _descriptionCtrl.text.trim();
      final category =
          _categoryCtrl.text.trim().isEmpty ? null : _categoryCtrl.text.trim();

      final costPrice = double.tryParse(_costPriceCtrl.text.trim()) ?? 0.0;
      final baseSellingPrice =
          double.tryParse(_baseSellingPriceCtrl.text.trim()) ?? 0.0;
      final minSellingRaw = _minSellingPriceCtrl.text.trim();
      final minSellingPrice =
          minSellingRaw.isNotEmpty ? double.tryParse(minSellingRaw) : null;

      final quantity = double.tryParse(_quantityCtrl.text.trim()) ?? 0.0;
      final reorderRaw = _reorderLevelCtrl.text.trim();
      final reorderLevel =
          reorderRaw.isNotEmpty ? double.tryParse(reorderRaw) : null;

      // Invariant check: minSellingPrice <= baseSellingPrice
      if (minSellingPrice != null && minSellingPrice > baseSellingPrice) {
        setState(() {
          _isSaving = false;
          _formError =
              'Minimum Selling Price (₦$minSellingPrice) cannot exceed Base Selling Price (₦$baseSellingPrice).';
        });
        return;
      }

      final idGen = ref.read(idGeneratorProvider);
      final now = DateTime.now().toUtc();

      final pricing = ItemPricing(
        costPrice: costPrice,
        baseSellingPrice: baseSellingPrice,
        minSellingPrice: minSellingPrice,
      );

      final inventory = ItemInventory(
        quantity: quantity,
        reorderLevel: reorderLevel,
      );

      final itemNotifier = ref.read(itemListProvider.notifier);

      if (isEditing) {
        final updatedItem = widget.existingItem!.copyWith(
          name: name,
          sku: sku,
          barcode: barcode,
          description: description,
          categoryId: category,
          unit: _unit,
          pricing: pricing,
          inventory: inventory,
          isActive: _isActive,
          updatedAt: now,
        );
        final result = await itemNotifier.updateItem(updatedItem);
        if (!mounted) return;

        if (result.isSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Item "$name" updated successfully.'),
              backgroundColor: TallyColors.varianceZeroLight,
            ),
          );
          Navigator.of(context).pop(true);
        } else {
          setState(() {
            _isSaving = false;
            _formError = result.errorMessageOrNull ?? 'Failed to update item.';
          });
        }
      } else {
        final newItem = Item(
          id: ItemId(idGen.generate()),
          storeId: storeState.store.id,
          name: name,
          sku: sku,
          barcode: barcode,
          description: description,
          categoryId: category,
          unit: _unit,
          pricing: pricing,
          inventory: inventory,
          isActive: _isActive,
          createdAt: now,
          updatedAt: now,
        );
        final result = await itemNotifier.createItem(newItem);
        if (!mounted) return;

        if (result.isSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Item "$name" added to catalog.'),
              backgroundColor: TallyColors.varianceZeroLight,
            ),
          );
          Navigator.of(context).pop(true);
        } else {
          setState(() {
            _isSaving = false;
            _formError = result.errorMessageOrNull ?? 'Failed to create item.';
          });
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _formError = e.toString();
      });
    }
  }

  Future<void> _scanBarcode() async {
    final scannedBarcode = await BarcodeScannerSheet.scan(context);
    if (scannedBarcode != null && mounted) {
      setState(() {
        _barcodeCtrl.text = scannedBarcode;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Scanned barcode: $scannedBarcode'),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPhone = context.isPhone;

    return Scaffold(
      backgroundColor: TallyColors.lightCanvas,
      appBar: AppBar(
        title: Text(
          isEditing ? 'Edit Item' : 'Add New Item',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: TallySpacing.base),
            child: ElevatedButton.icon(
              onPressed: _isSaving ? null : _handleSubmit,
              icon: _isSaving
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.check, size: 16),
              label: Text(isEditing ? 'Save Changes' : 'Save Item'),
              style: ElevatedButton.styleFrom(
                backgroundColor: TallyColors.primaryNavy,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(TallySpacing.lg),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_formError != null) ...[
                    Container(
                      padding: const EdgeInsets.all(TallySpacing.md),
                      decoration: BoxDecoration(
                        color: TallyColors.stockCritical.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(TallyRadii.md),
                        border: Border.all(
                          color:
                              TallyColors.stockCritical.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: TallyColors.stockCritical,
                            size: 20,
                          ),
                          const SizedBox(width: TallySpacing.sm),
                          Expanded(
                            child: Text(
                              _formError!,
                              style: const TextStyle(
                                fontSize: 13,
                                color: TallyColors.stockCritical,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: TallySpacing.md),
                  ],

                  // 1. Basic Identity Card
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
                          const Text(
                            'Item Details',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: TallyColors.primaryNavy,
                            ),
                          ),
                          const SizedBox(height: TallySpacing.md),

                          // Name
                          TextFormField(
                            controller: _nameCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Item Name *',
                              hintText: 'e.g. Coca-Cola 50cl, Peak Milk 400g',
                              border: OutlineInputBorder(),
                            ),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return 'Item name is required.';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: TallySpacing.md),

                          // SKU & Barcode
                          if (isPhone) ...[
                            TextFormField(
                              controller: _skuCtrl,
                              decoration: const InputDecoration(
                                labelText: 'SKU (Stock Keeping Unit)',
                                hintText: 'e.g. COKE-50CL',
                                border: OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: TallySpacing.md),
                            TextFormField(
                              controller: _barcodeCtrl,
                              decoration: InputDecoration(
                                labelText: 'Barcode',
                                hintText: 'e.g. 5449000000996',
                                border: const OutlineInputBorder(),
                                suffixIcon: IconButton(
                                  icon: const Icon(Icons.qr_code_scanner),
                                  tooltip: 'Scan Barcode with Camera',
                                  onPressed: _scanBarcode,
                                ),
                              ),
                            ),
                          ] else ...[
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _skuCtrl,
                                    decoration: const InputDecoration(
                                      labelText: 'SKU (Stock Keeping Unit)',
                                      hintText: 'e.g. COKE-50CL',
                                      border: OutlineInputBorder(),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: TallySpacing.md),
                                Expanded(
                                  child: TextFormField(
                                    controller: _barcodeCtrl,
                                    decoration: InputDecoration(
                                      labelText: 'Barcode',
                                      hintText: 'e.g. 5449000000996',
                                      border: const OutlineInputBorder(),
                                      suffixIcon: IconButton(
                                        icon: const Icon(Icons.qr_code_scanner),
                                        tooltip: 'Scan Barcode with Camera',
                                        onPressed: _scanBarcode,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                          const SizedBox(height: TallySpacing.md),

                          // Category & Unit
                          if (isPhone) ...[
                            TextFormField(
                              controller: _categoryCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Category',
                                hintText: 'e.g. Drinks, Food, Bakery',
                                border: OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: TallySpacing.md),
                            DropdownButtonFormField<ItemUnit>(
                              initialValue: _unit,
                              decoration: const InputDecoration(
                                labelText: 'Measurement Unit *',
                                border: OutlineInputBorder(),
                              ),
                              items: ItemUnit.values
                                  .map(
                                    (u) => DropdownMenuItem(
                                      value: u,
                                      child: Text(
                                        '${u.label} (${u.abbreviation})',
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() => _unit = val);
                                }
                              },
                            ),
                          ] else ...[
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _categoryCtrl,
                                    decoration: const InputDecoration(
                                      labelText: 'Category',
                                      hintText: 'e.g. Drinks, Food, Bakery',
                                      border: OutlineInputBorder(),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: TallySpacing.md),
                                Expanded(
                                  child: DropdownButtonFormField<ItemUnit>(
                                    initialValue: _unit,
                                    decoration: const InputDecoration(
                                      labelText: 'Measurement Unit *',
                                      border: OutlineInputBorder(),
                                    ),
                                    items: ItemUnit.values
                                        .map(
                                          (u) => DropdownMenuItem(
                                            value: u,
                                            child: Text(
                                              '${u.label} (${u.abbreviation})',
                                            ),
                                          ),
                                        )
                                        .toList(),
                                    onChanged: (val) {
                                      if (val != null) {
                                        setState(() => _unit = val);
                                      }
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                          const SizedBox(height: TallySpacing.md),

                          // Description
                          TextFormField(
                            controller: _descriptionCtrl,
                            maxLines: 2,
                            decoration: const InputDecoration(
                              labelText: 'Description (Optional)',
                              hintText: 'Notes, supplier details, or specs',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: TallySpacing.md),

                  // 2. Current Pricing Card
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
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Current Pricing',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: TallyColors.primaryNavy,
                                ),
                              ),
                              Text(
                                '₦ Nigerian Naira',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: TallyColors.slateMuted,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Represents current shelf pricing. Historical transaction prices in past Receivings and Sales are not altered when updating current prices.',
                            style: TextStyle(
                              fontSize: 12,
                              color: TallyColors.slateMuted,
                            ),
                          ),
                          const SizedBox(height: TallySpacing.md),

                          // Cost Price & Base Selling Price
                          if (isPhone) ...[
                            TextFormField(
                              controller: _costPriceCtrl,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                              decoration: const InputDecoration(
                                labelText: 'Cost Price (₦)',
                                hintText: '0.00',
                                border: OutlineInputBorder(),
                              ),
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) {
                                  return null;
                                }
                                final n = double.tryParse(val.trim());
                                if (n == null || n < 0) {
                                  return 'Invalid cost price.';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: TallySpacing.md),
                            TextFormField(
                              controller: _baseSellingPriceCtrl,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                              decoration: const InputDecoration(
                                labelText: 'Base Selling Price (₦) *',
                                hintText: '0.00',
                                border: OutlineInputBorder(),
                              ),
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) {
                                  return 'Selling price is required.';
                                }
                                final n = double.tryParse(val.trim());
                                if (n == null || n < 0) {
                                  return 'Invalid selling price.';
                                }
                                return null;
                              },
                            ),
                          ] else ...[
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _costPriceCtrl,
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                    decoration: const InputDecoration(
                                      labelText: 'Cost Price (₦)',
                                      hintText: '0.00',
                                      border: OutlineInputBorder(),
                                    ),
                                    validator: (val) {
                                      if (val == null || val.trim().isEmpty) {
                                        return null;
                                      }
                                      final n = double.tryParse(val.trim());
                                      if (n == null || n < 0) {
                                        return 'Invalid cost price.';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                const SizedBox(width: TallySpacing.md),
                                Expanded(
                                  child: TextFormField(
                                    controller: _baseSellingPriceCtrl,
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                    decoration: const InputDecoration(
                                      labelText: 'Base Selling Price (₦) *',
                                      hintText: '0.00',
                                      border: OutlineInputBorder(),
                                    ),
                                    validator: (val) {
                                      if (val == null || val.trim().isEmpty) {
                                        return 'Selling price is required.';
                                      }
                                      final n = double.tryParse(val.trim());
                                      if (n == null || n < 0) {
                                        return 'Invalid selling price.';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                          const SizedBox(height: TallySpacing.md),

                          // Minimum Selling Price
                          TextFormField(
                            controller: _minSellingPriceCtrl,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: const InputDecoration(
                              labelText:
                                  'Minimum Selling Price (₦ - Floor Price)',
                              hintText: 'Lowest allowable negotiated price',
                              helperText:
                                  'Must be less than or equal to Base Selling Price.',
                              border: OutlineInputBorder(),
                            ),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return null;
                              }
                              final minPrice = double.tryParse(val.trim());
                              if (minPrice == null || minPrice < 0) {
                                return 'Invalid minimum price.';
                              }
                              final basePrice = double.tryParse(
                                _baseSellingPriceCtrl.text.trim(),
                              );
                              if (basePrice != null && minPrice > basePrice) {
                                return 'Cannot exceed base price (₦$basePrice).';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: TallySpacing.md),

                  // 3. Inventory Stock Card
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
                          const Text(
                            'Inventory Quantities',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: TallyColors.primaryNavy,
                            ),
                          ),
                          const SizedBox(height: TallySpacing.md),
                          if (isPhone) ...[
                            TextFormField(
                              controller: _quantityCtrl,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                              decoration: InputDecoration(
                                labelText: 'Initial On-Hand Stock *',
                                suffixText: _unit.abbreviation,
                                helperText: 'Current physical quantity.',
                                border: const OutlineInputBorder(),
                              ),
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) {
                                  return 'Quantity is required.';
                                }
                                final n = double.tryParse(val.trim());
                                if (n == null || n < 0) {
                                  return 'Invalid quantity.';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: TallySpacing.md),
                            TextFormField(
                              controller: _reorderLevelCtrl,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                              decoration: InputDecoration(
                                labelText: 'Reorder Level Threshold',
                                suffixText: _unit.abbreviation,
                                hintText: 'e.g. 10',
                                helperText: 'Alerts when stock falls below.',
                                border: const OutlineInputBorder(),
                              ),
                            ),
                          ] else ...[
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _quantityCtrl,
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                    decoration: InputDecoration(
                                      labelText: 'Initial On-Hand Stock *',
                                      suffixText: _unit.abbreviation,
                                      helperText: 'Current physical quantity.',
                                      border: const OutlineInputBorder(),
                                    ),
                                    validator: (val) {
                                      if (val == null || val.trim().isEmpty) {
                                        return 'Quantity is required.';
                                      }
                                      final n = double.tryParse(val.trim());
                                      if (n == null || n < 0) {
                                        return 'Invalid quantity.';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                const SizedBox(width: TallySpacing.md),
                                Expanded(
                                  child: TextFormField(
                                    controller: _reorderLevelCtrl,
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                    decoration: InputDecoration(
                                      labelText: 'Reorder Level Threshold',
                                      suffixText: _unit.abbreviation,
                                      hintText: 'e.g. 10',
                                      helperText:
                                          'Alerts when stock falls below.',
                                      border: const OutlineInputBorder(),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: TallySpacing.md),

                  // 4. Status Card
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(TallyRadii.lg),
                      side: const BorderSide(color: TallyColors.lightBorder),
                    ),
                    child: SwitchListTile(
                      title: const Text(
                        'Active in Catalog',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      subtitle: const Text(
                        'Active items appear in point-of-sale registers and inventory tallies.',
                        style: TextStyle(
                            fontSize: 12, color: TallyColors.slateMuted),
                      ),
                      value: _isActive,
                      activeThumbColor: TallyColors.varianceZeroLight,
                      onChanged: (val) => setState(() => _isActive = val),
                    ),
                  ),
                  const SizedBox(height: TallySpacing.xl),

                  // Action Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TallyCancelButton(
                        onPressed: _isSaving
                            ? null
                            : () => Navigator.of(context).pop(),
                      ),
                      const SizedBox(width: TallySpacing.md),
                      ElevatedButton.icon(
                        onPressed: _isSaving ? null : _handleSubmit,
                        icon: _isSaving
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.check, size: 18),
                        label: Text(
                          isEditing ? 'Save Changes' : 'Create Item',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: TallyColors.primaryNavy,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: TallySpacing.xl,
                            vertical: TallySpacing.md,
                          ),
                          shape: const StadiumBorder(),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/providers/core_providers.dart';
import '../../../application/store/current_store_state.dart';
import '../../../domain/item/item_export.dart';
import '../../design_system/tokens/colors.dart';
import '../../design_system/tokens/dimensions.dart';
import '../../design_system/widgets/tally_cancel_button.dart';

/// Modal dialog for exporting catalog data to Excel (.xlsx) or CSV (.csv).
class ItemExportDialog extends ConsumerStatefulWidget {
  final int totalMatchingItems;

  const ItemExportDialog({
    super.key,
    required this.totalMatchingItems,
  });

  @override
  ConsumerState<ItemExportDialog> createState() => _ItemExportDialogState();
}

class _ItemExportDialogState extends ConsumerState<ItemExportDialog> {
  ItemExportScope _selectedScope = ItemExportScope.currentView;
  ItemExportFormat _selectedFormat = ItemExportFormat.excel;
  bool _isExporting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final selectedIds = ref.read(itemSelectionProvider);
    if (selectedIds.isNotEmpty) {
      _selectedScope = ItemExportScope.selectedItems;
    }
  }

  Future<void> _handleExport() async {
    setState(() {
      _isExporting = true;
      _errorMessage = null;
    });

    try {
      final query = ref.read(itemQueryProvider);
      final selectedIds = ref.read(itemSelectionProvider);
      final colState = ref.read(itemColumnPreferencesProvider);
      final storeState = ref.read(currentStoreProvider);
      final storeName =
          storeState is StoreSelected ? storeState.store.name : 'Tally Store';

      final request = ItemExportRequest(
        scope: _selectedScope,
        format: _selectedFormat,
        query: query,
        selectedItemIds: selectedIds,
        columns: colState.visibleColumns,
        storeName: storeName,
      );

      final exportService = ref.read(itemExportServiceProvider);
      final result = await exportService.export(request);

      if (result.isFailure) {
        setState(() {
          _isExporting = false;
          _errorMessage = result.errorMessageOrNull ?? 'Export failed.';
        });
        return;
      }

      final exportedFile = result.valueOrNull!;
      final shareResult = await exportService.shareOrSave(exportedFile);

      if (!mounted) return;

      if (shareResult.isSuccess) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Exported ${exportedFile.itemCount} items to ${exportedFile.fileName}',
            ),
            backgroundColor: TallyColors.varianceZeroLight,
          ),
        );
      } else {
        setState(() {
          _isExporting = false;
          _errorMessage =
              shareResult.errorMessageOrNull ?? 'Failed to save file.';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isExporting = false;
        _errorMessage = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedIds = ref.watch(itemSelectionProvider);

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(TallyRadii.lg),
      ),
      title: const Row(
        children: [
          Icon(Icons.file_download_outlined, color: TallyColors.primaryNavy),
          SizedBox(width: TallySpacing.sm),
          Text(
            'Export Items',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: TallyColors.primaryNavy,
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 440,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Export Scope',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: TallyColors.slateMuted,
              ),
            ),
            const SizedBox(height: TallySpacing.xs),
            RadioGroup<ItemExportScope>(
              groupValue: _selectedScope,
              onChanged: (v) {
                if (v != null && !_isExporting) {
                  setState(() => _selectedScope = v);
                }
              },
              child: Column(
                children: [
                  RadioListTile<ItemExportScope>(
                    value: ItemExportScope.currentView,
                    title: Text(
                      'Current View (${widget.totalMatchingItems} items)',
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    subtitle: const Text(
                      'Matches active search, filters, and column settings',
                      style: TextStyle(
                          fontSize: 12, color: TallyColors.slateMuted),
                    ),
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  RadioListTile<ItemExportScope>(
                    value: ItemExportScope.selectedItems,
                    title: Text(
                      'Selected Items (${selectedIds.length} selected)',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: selectedIds.isEmpty
                            ? TallyColors.slateMuted
                            : TallyColors.primaryNavy,
                      ),
                    ),
                    subtitle: Text(
                      selectedIds.isEmpty
                          ? 'Check items in list to enable this option'
                          : 'Only currently checked items',
                      style: const TextStyle(
                          fontSize: 12, color: TallyColors.slateMuted),
                    ),
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  const RadioListTile<ItemExportScope>(
                    value: ItemExportScope.allItems,
                    title: Text(
                      'All Items in Store',
                      style:
                          TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      'Complete store catalog regardless of search/filter',
                      style: TextStyle(
                          fontSize: 12, color: TallyColors.slateMuted),
                    ),
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),
            const SizedBox(height: TallySpacing.md),
            const Divider(color: TallyColors.lightBorder),
            const SizedBox(height: TallySpacing.xs),
            const Text(
              'Format',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: TallyColors.slateMuted,
              ),
            ),
            const SizedBox(height: TallySpacing.xs),
            Row(
              children: ItemExportFormat.values.map((format) {
                final isSelected = _selectedFormat == format;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: InkWell(
                      onTap: _isExporting
                          ? null
                          : () => setState(() => _selectedFormat = format),
                      borderRadius: BorderRadius.circular(TallyRadii.md),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: TallySpacing.sm,
                          horizontal: TallySpacing.sm,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? TallyColors.iceFrost
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(TallyRadii.md),
                          border: Border.all(
                            color: isSelected
                                ? TallyColors.primaryNavy
                                : TallyColors.lightBorder,
                            width: isSelected ? 1.5 : 1.0,
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              format == ItemExportFormat.excel
                                  ? Icons.table_chart_outlined
                                  : Icons.description_outlined,
                              color: isSelected
                                  ? TallyColors.primaryNavy
                                  : TallyColors.slateMuted,
                              size: 24,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              format == ItemExportFormat.excel
                                  ? 'Excel (.xlsx)'
                                  : 'CSV (.csv)',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: isSelected
                                    ? TallyColors.primaryNavy
                                    : TallyColors.slateMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: TallySpacing.md),
              Text(
                _errorMessage!,
                style: const TextStyle(
                  fontSize: 12,
                  color: TallyColors.stockCritical,
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TallyCancelButton(
          onPressed: _isExporting ? null : () => Navigator.of(context).pop(),
        ),
        ElevatedButton.icon(
          onPressed: _isExporting ? null : _handleExport,
          icon: _isExporting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.file_download, size: 18),
          label: Text(_isExporting ? 'Generating...' : 'Export File'),
          style: ElevatedButton.styleFrom(
            backgroundColor: TallyColors.primaryNavy,
            foregroundColor: Colors.white,
            shape: const StadiumBorder(),
          ),
        ),
      ],
    );
  }
}

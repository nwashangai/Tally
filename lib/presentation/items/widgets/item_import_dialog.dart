import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers/core_providers.dart';
import '../../../application/store/current_store_state.dart';
import '../../../domain/item/item_export.dart';
import '../../../domain/item/item_import.dart';
import '../../design_system/tokens/colors.dart';
import '../../design_system/tokens/dimensions.dart';
import '../../design_system/widgets/tally_cancel_button.dart';

/// Modal dialog for uploading, validating, previewing, and importing catalog items from Excel or CSV files.
class ItemImportDialog extends ConsumerStatefulWidget {
  const ItemImportDialog({super.key});

  @override
  ConsumerState<ItemImportDialog> createState() => _ItemImportDialogState();
}

class _ItemImportDialogState extends ConsumerState<ItemImportDialog> {
  bool _isPickingOrParsing = false;
  bool _isImporting = false;
  String? _generalError;
  ItemImportResult? _importResult;

  Future<void> _pickFile() async {
    setState(() {
      _isPickingOrParsing = true;
      _generalError = null;
    });

    try {
      final storeState = ref.read(currentStoreProvider);
      if (storeState is! StoreSelected) {
        setState(() {
          _generalError = 'No active store selected.';
          _isPickingOrParsing = false;
        });
        return;
      }

      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls', 'csv'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) {
        setState(() => _isPickingOrParsing = false);
        return;
      }

      final file = result.files.first;
      final bytes = file.bytes;

      if (bytes == null || bytes.isEmpty) {
        setState(() {
          _generalError = 'Could not read file data. Please try another file.';
          _isPickingOrParsing = false;
        });
        return;
      }

      final importer = ref.read(itemImporterProvider);
      final parseRes = await importer.parse(
        bytes: bytes,
        fileName: file.name,
        storeId: storeState.store.id,
      );

      if (parseRes.isSuccess) {
        setState(() {
          _importResult = parseRes.valueOrNull;
          _isPickingOrParsing = false;
        });
      } else {
        setState(() {
          _generalError =
              parseRes.errorMessageOrNull ?? 'Failed to parse file.';
          _isPickingOrParsing = false;
        });
      }
    } catch (e) {
      setState(() {
        _generalError = 'Error picking file: $e';
        _isPickingOrParsing = false;
      });
    }
  }

  Future<void> _downloadTemplate(ItemExportFormat format) async {
    try {
      final box = context.findRenderObject() as RenderBox?;
      final origin = box != null && box.hasSize
          ? box.localToGlobal(Offset.zero) & box.size
          : null;

      final importer = ref.read(itemImporterProvider);
      final res = await importer.generateSampleTemplate(format);
      if (res.isSuccess) {
        final exported = res.valueOrNull!;
        final exportService = ref.read(itemExportServiceProvider);
        await exportService.shareOrSave(
          exported,
          sharePositionOrigin: origin,
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              res.errorMessageOrNull ?? 'Failed to generate template.',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generating template: $e')),
        );
      }
    }
  }

  Future<void> _handleConfirmImport() async {
    final result = _importResult;
    if (result == null || !result.hasValidItems) return;

    setState(() {
      _isImporting = true;
      _generalError = null;
    });

    final importRes = await ref
        .read(itemListProvider.notifier)
        .importItems(result.validItems);

    if (importRes.isSuccess) {
      if (mounted) {
        Navigator.of(context).pop(result.validItems.length);
      }
    } else {
      if (mounted) {
        setState(() {
          _isImporting = false;
          _generalError = importRes.errorMessageOrNull ??
              'Failed to import items into database.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final result = _importResult;

    return AlertDialog(
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(TallySpacing.xs),
            decoration: BoxDecoration(
              color: TallyColors.iceFrost,
              borderRadius: BorderRadius.circular(TallyRadii.md),
            ),
            child: const Icon(
              Icons.file_upload_outlined,
              color: TallyColors.primaryNavy,
              size: 20,
            ),
          ),
          const SizedBox(width: TallySpacing.sm),
          const Text(
            'Import Items Catalog',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: TallyColors.primaryNavy,
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 540,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Upload an Excel (.xlsx) or CSV file with product names, selling prices, and quantities to batch-add to your catalog.',
                style: TextStyle(
                  fontSize: 13,
                  color: TallyColors.slateMuted,
                ),
              ),
              const SizedBox(height: TallySpacing.md),

              // File Selection Box
              InkWell(
                onTap: (_isPickingOrParsing || _isImporting) ? null : _pickFile,
                borderRadius: BorderRadius.circular(TallyRadii.lg),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: TallySpacing.xl,
                    horizontal: TallySpacing.lg,
                  ),
                  decoration: BoxDecoration(
                    color: TallyColors.iceFrost.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(TallyRadii.lg),
                    border: Border.all(
                      color: TallyColors.primaryNavy.withValues(alpha: 0.3),
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    children: [
                      if (_isPickingOrParsing) ...[
                        const SizedBox(
                          width: 28,
                          height: 28,
                          child: CircularProgressIndicator(strokeWidth: 2.5),
                        ),
                        const SizedBox(height: TallySpacing.sm),
                        const Text(
                          'Reading and validating spreadsheet...',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: TallyColors.primaryNavy,
                          ),
                        ),
                      ] else if (result != null) ...[
                        const Icon(
                          Icons.check_circle_outline,
                          size: 32,
                          color: TallyColors.varianceZeroLight,
                        ),
                        const SizedBox(height: TallySpacing.xs),
                        Text(
                          result.fileName,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: TallyColors.primaryNavy,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${(result.fileSizeBytes / 1024).toStringAsFixed(1)} KB • Tap to pick another file',
                          style: const TextStyle(
                            fontSize: 12,
                            color: TallyColors.slateMuted,
                          ),
                        ),
                      ] else ...[
                        const Icon(
                          Icons.cloud_upload_outlined,
                          size: 36,
                          color: TallyColors.primaryNavy,
                        ),
                        const SizedBox(height: TallySpacing.sm),
                        const Text(
                          'Tap to select Excel or CSV file',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: TallyColors.primaryNavy,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Supports .xlsx, .xls, and .csv files',
                          style: TextStyle(
                            fontSize: 12,
                            color: TallyColors.slateMuted,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: TallySpacing.sm),

              // Sample Templates Helper
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: TallySpacing.xs,
                runSpacing: TallySpacing.xs,
                children: [
                  const Text(
                    'Need a starting template?',
                    style:
                        TextStyle(fontSize: 12, color: TallyColors.slateMuted),
                  ),
                  Wrap(
                    spacing: TallySpacing.xs,
                    runSpacing: TallySpacing.xs,
                    children: [
                      TextButton.icon(
                        onPressed: () =>
                            _downloadTemplate(ItemExportFormat.excel),
                        icon: const Icon(Icons.table_chart_outlined, size: 14),
                        label: const Text('Excel Template',
                            style: TextStyle(fontSize: 11)),
                        style: TextButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () =>
                            _downloadTemplate(ItemExportFormat.csv),
                        icon: const Icon(Icons.description_outlined, size: 14),
                        label: const Text('CSV Template',
                            style: TextStyle(fontSize: 11)),
                        style: TextButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              if (_generalError != null) ...[
                const SizedBox(height: TallySpacing.sm),
                Container(
                  padding: const EdgeInsets.all(TallySpacing.sm),
                  decoration: BoxDecoration(
                    color: TallyColors.stockCritical.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(TallyRadii.md),
                    border: Border.all(
                        color:
                            TallyColors.stockCritical.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline,
                          size: 16, color: TallyColors.stockCritical),
                      const SizedBox(width: TallySpacing.xs),
                      Expanded(
                        child: Text(
                          _generalError!,
                          style: const TextStyle(
                              fontSize: 12, color: TallyColors.stockCritical),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // 2. Inspection / Validation Summary
              if (result != null) ...[
                const SizedBox(height: TallySpacing.md),
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.check_circle,
                                size: 16,
                                color: TallyColors.varianceZeroLight,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${result.validCount} valid items',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: TallyColors.primaryNavy,
                                ),
                              ),
                            ],
                          ),
                          if (result.hasErrors)
                            Row(
                              children: [
                                const Icon(
                                  Icons.warning_amber_rounded,
                                  size: 16,
                                  color: TallyColors.varianceDiscrepancy,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${result.errorCount} skipped rows',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: TallyColors.varianceDiscrepancy,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                      const SizedBox(height: TallySpacing.xs),
                      Text(
                        'Total spreadsheet rows: ${result.totalRows}',
                        style: const TextStyle(
                            fontSize: 12, color: TallyColors.slateMuted),
                      ),

                      // Errors expander if any
                      if (result.hasErrors) ...[
                        const SizedBox(height: TallySpacing.sm),
                        const Divider(color: TallyColors.lightBorder),
                        const Text(
                          'Skipped Row Issues:',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: TallyColors.slateMuted,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          constraints: const BoxConstraints(maxHeight: 120),
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: result.errors.length,
                            itemBuilder: (context, idx) {
                              final err = result.errors[idx];
                              return Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 2.0),
                                child: Text(
                                  '• ${err.toString()}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: TallyColors.stockCritical,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TallyCancelButton(
          onPressed: (_isPickingOrParsing || _isImporting)
              ? null
              : () => Navigator.of(context).pop(),
        ),
        ElevatedButton.icon(
          onPressed: (_isPickingOrParsing ||
                  _isImporting ||
                  result == null ||
                  !result.hasValidItems)
              ? null
              : _handleConfirmImport,
          icon: _isImporting
              ? const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.file_upload, size: 18),
          label: Text(
            _isImporting
                ? 'Importing...'
                : (result != null && result.hasValidItems
                    ? 'Import ${result.validCount} Items'
                    : 'Import Items'),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: TallyColors.primaryNavy,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(
              horizontal: TallySpacing.lg,
              vertical: TallySpacing.md,
            ),
            shape: const StadiumBorder(),
          ),
        ),
      ],
    );
  }
}

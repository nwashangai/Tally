import 'dart:io';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/error/app_error.dart';
import '../../core/result/result.dart';
import '../../domain/item/item_export.dart';
import '../../domain/item/item_export_service.dart';
import '../../domain/item/item_repository.dart';
import 'csv_item_exporter.dart';
import 'excel_item_exporter.dart';

/// Default implementation of [ItemExportService].
/// Orchestrates data query, format encoding (Excel / CSV), and platform share/download.
class DefaultItemExportService implements ItemExportService {
  final ItemRepository _repository;
  final ExcelItemExporter _excelExporter;
  final CsvItemExporter _csvExporter;

  DefaultItemExportService({
    required ItemRepository repository,
    ExcelItemExporter excelExporter = const ExcelItemExporter(),
    CsvItemExporter csvExporter = const CsvItemExporter(),
  })  : _repository = repository,
        _excelExporter = excelExporter,
        _csvExporter = csvExporter;

  @override
  Future<Result<ExportedFile>> export(ItemExportRequest request) async {
    try {
      final itemsResult = await _repository.getExportItems(request);
      if (itemsResult.isFailure) {
        return Failure(itemsResult.errorOrNull!);
      }
      final items = itemsResult.valueOrNull ?? [];

      final now = DateTime.now();
      final dateSlug = DateFormat('yyyy-MM-dd_HHmm').format(now);
      final sanitizedStore =
          request.storeName.replaceAll(RegExp(r'[^a-zA-Z0-9_\-]'), '_').trim();

      final List<int> bytes;
      final String extension;
      final String mimeType;

      switch (request.format) {
        case ItemExportFormat.excel:
          bytes = _excelExporter.exportWorkbook(
            items: items,
            columns: request.columns,
            storeName: request.storeName,
            currencyCode: request.currencyCode,
          );
          extension = 'xlsx';
          mimeType = request.format.mimeType;
          break;
        case ItemExportFormat.csv:
          bytes = _csvExporter.exportCsv(
            items: items,
            columns: request.columns,
            currencyCode: request.currencyCode,
          );
          extension = 'csv';
          mimeType = request.format.mimeType;
          break;
      }

      final fileName = 'Tally_${sanitizedStore}_Items_$dateSlug.$extension';

      return Success(
        ExportedFile(
          fileName: fileName,
          bytes: bytes,
          mimeType: mimeType,
          itemCount: items.length,
          exportedAt: now,
        ),
      );
    } catch (e, st) {
      return Failure(
        StorageError('Failed to generate export file: $e'),
        stackTrace: st,
      );
    }
  }

  @override
  Future<Result<void>> shareOrSave(ExportedFile file) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final targetFile = File('${tempDir.path}/${file.fileName}');
      await targetFile.writeAsBytes(file.bytes, flush: true);

      final xFile = XFile(
        targetFile.path,
        mimeType: file.mimeType,
        name: file.fileName,
      );

      // ignore: deprecated_member_use
      final shareResult = await Share.shareXFiles(
        [xFile],
        subject: file.fileName,
      );

      if (shareResult.status == ShareResultStatus.dismissed) {
        // User dismissed the share dialog - perfectly normal
      }

      return const Success(null);
    } catch (e, st) {
      return Failure(
        StorageError('Failed to share or save export file: $e'),
        stackTrace: st,
      );
    }
  }
}

import 'dart:typed_data';
import '../../core/result/result.dart';
import '../../domain/item/item_export.dart';
import '../../domain/item/item_import.dart';
import '../../domain/store/store_id.dart';

/// Contract for parsing and importing catalog files (Excel, CSV).
abstract interface class ItemImporter {
  /// Parses raw file bytes (Excel .xlsx or CSV) into domain items with row-by-row validation.
  Future<Result<ItemImportResult>> parse({
    required Uint8List bytes,
    required String fileName,
    required StoreId storeId,
  });

  /// Generates a sample template file with standard column headers and example rows.
  Future<Result<ExportedFile>> generateSampleTemplate(ItemExportFormat format);
}

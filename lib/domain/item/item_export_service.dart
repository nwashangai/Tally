import 'dart:ui';
import '../../core/result/result.dart';
import 'item_export.dart';

/// Service boundary for generating and exporting item catalog files.
abstract interface class ItemExportService {
  /// Generates a formatted file (Excel / CSV) based on the specified request.
  Future<Result<ExportedFile>> export(ItemExportRequest request);

  /// Shares or triggers download of the exported file on the host platform.
  Future<Result<void>> shareOrSave(
    ExportedFile file, {
    Rect? sharePositionOrigin,
  });
}

import 'item.dart';

/// Single validation or parsing error encountered during an import operation.
class ItemImportError {
  final int rowIndex; // 1-indexed (matching spreadsheet row numbers)
  final String? fieldName;
  final String rawValue;
  final String message;

  const ItemImportError({
    required this.rowIndex,
    this.fieldName,
    required this.rawValue,
    required this.message,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ItemImportError &&
          runtimeType == other.runtimeType &&
          rowIndex == other.rowIndex &&
          fieldName == other.fieldName &&
          rawValue == other.rawValue &&
          message == other.message;

  @override
  int get hashCode => Object.hash(rowIndex, fieldName, rawValue, message);

  @override
  String toString() =>
      'Row $rowIndex [${fieldName ?? "General"}]: $message (Value: "$rawValue")';
}

/// Parsed outcome of an import file containing validated domain items and row-level issues.
class ItemImportResult {
  final String fileName;
  final int fileSizeBytes;
  final int totalRows;
  final List<Item> validItems;
  final List<ItemImportError> errors;

  const ItemImportResult({
    required this.fileName,
    required this.fileSizeBytes,
    required this.totalRows,
    required this.validItems,
    required this.errors,
  });

  bool get hasErrors => errors.isNotEmpty;
  bool get hasValidItems => validItems.isNotEmpty;
  int get validCount => validItems.length;
  int get errorCount => errors.length;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ItemImportResult &&
          runtimeType == other.runtimeType &&
          fileName == other.fileName &&
          fileSizeBytes == other.fileSizeBytes &&
          totalRows == other.totalRows;

  @override
  int get hashCode => Object.hash(fileName, fileSizeBytes, totalRows);
}

import 'item_column.dart';
import 'item_id.dart';
import 'item_query.dart';

/// Scope of items included in an export operation.
enum ItemExportScope {
  currentView(
      'Current View', 'Items matching active search, filters, and sort order'),
  selectedItems('Selected Items', 'Only items currently checked in the list'),
  allItems('All Items', 'Complete item catalog for this store');

  final String label;
  final String description;
  const ItemExportScope(this.label, this.description);
}

/// Target file formats supported for item catalog exports.
enum ItemExportFormat {
  excel('Excel Workbook (.xlsx)', 'xlsx',
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'),
  csv('Comma-Separated Values (.csv)', 'csv', 'text/csv');

  final String label;
  final String extension;
  final String mimeType;
  const ItemExportFormat(this.label, this.extension, this.mimeType);
}

/// Specification for an item export request.
class ItemExportRequest {
  final ItemExportScope scope;
  final ItemExportFormat format;
  final ItemQuery query;
  final Set<ItemId> selectedItemIds;
  final Set<ItemColumn> columns;
  final String storeName;
  final String currencyCode;

  const ItemExportRequest({
    required this.scope,
    required this.format,
    required this.query,
    this.selectedItemIds = const {},
    required this.columns,
    this.storeName = 'Tally Store',
    this.currencyCode = '₦',
  });
}

/// Represents the generated binary export payload.
class ExportedFile {
  final String fileName;
  final List<int> bytes;
  final String mimeType;
  final int itemCount;
  final DateTime exportedAt;

  const ExportedFile({
    required this.fileName,
    required this.bytes,
    required this.mimeType,
    required this.itemCount,
    required this.exportedAt,
  });
}

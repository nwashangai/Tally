import 'dart:convert';
import 'package:intl/intl.dart';
import '../../domain/item/item.dart';
import '../../domain/item/item_column.dart';

/// Generates RFC 4180 compliant CSV files with UTF-8 encoding.
class CsvItemExporter {
  const CsvItemExporter();

  List<int> exportCsv({
    required List<Item> items,
    required Set<ItemColumn> columns,
    required String currencyCode,
  }) {
    final orderedColumns = ItemColumn.values.where(columns.contains).toList();
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm');

    final rows = <List<dynamic>>[];

    // 1. Header Row
    rows.add(orderedColumns.map((col) => col.label).toList());

    // 2. Data Rows
    for (final item in items) {
      final row = <dynamic>[];
      for (final col in orderedColumns) {
        row.add(_csvValueFor(item, col, currencyCode, dateFormat));
      }
      rows.add(row);
    }

    final buffer = StringBuffer();
    for (final row in rows) {
      final line = row.map((cell) {
        if (cell == null) return '';
        final str = cell.toString();
        if (str.contains(',') ||
            str.contains('"') ||
            str.contains('\n') ||
            str.contains('\r')) {
          return '"${str.replaceAll('"', '""')}"';
        }
        return str;
      }).join(',');
      buffer.writeln(line);
    }

    // Add UTF-8 Byte Order Mark (BOM) so Excel and third-party apps open Unicode characters (like ₦) correctly
    final bytes = <int>[0xEF, 0xBB, 0xBF, ...utf8.encode(buffer.toString())];
    return bytes;
  }

  dynamic _csvValueFor(
    Item item,
    ItemColumn column,
    String currencyCode,
    DateFormat dateFormat,
  ) {
    switch (column) {
      case ItemColumn.name:
        return item.name;
      case ItemColumn.sku:
        return item.sku ?? '';
      case ItemColumn.barcode:
        return item.barcode ?? '';
      case ItemColumn.category:
        return item.categoryId ?? '';
      case ItemColumn.unit:
        return item.unit.label;
      case ItemColumn.stock:
        return item.inventory.quantity;
      case ItemColumn.reorderLevel:
        return item.inventory.reorderLevel ?? '';
      case ItemColumn.costPrice:
        return item.pricing.costPrice;
      case ItemColumn.baseSellingPrice:
        return item.pricing.baseSellingPrice;
      case ItemColumn.minSellingPrice:
        return item.pricing.minSellingPrice ?? '';
      case ItemColumn.margin:
        return item.pricing.margin;
      case ItemColumn.status:
        return item.isActive ? 'Active' : 'Archived';
      case ItemColumn.updatedAt:
        return dateFormat.format(item.updatedAt.toLocal());
    }
  }
}

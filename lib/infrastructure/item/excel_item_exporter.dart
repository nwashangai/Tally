import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import '../../domain/item/item.dart';
import '../../domain/item/item_column.dart';

/// Generates real Microsoft Excel (.xlsx) workbooks from item catalog data.
class ExcelItemExporter {
  const ExcelItemExporter();

  List<int> exportWorkbook({
    required List<Item> items,
    required Set<ItemColumn> columns,
    required String storeName,
    required String currencyCode,
  }) {
    final excel = Excel.createExcel();
    const sheetName = 'Items';

    // Rename default sheet
    final defaultSheet = excel.getDefaultSheet();
    if (defaultSheet != null && defaultSheet != sheetName) {
      excel.rename(defaultSheet, sheetName);
    }
    final sheet = excel[sheetName];

    final orderedColumns = ItemColumn.values.where(columns.contains).toList();
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm');

    // 1. Header Row
    final headerCells = <CellValue>[];
    for (final col in orderedColumns) {
      headerCells.add(TextCellValue(col.label));
    }
    sheet.appendRow(headerCells);

    // Style header row cells
    for (var colIdx = 0; colIdx < orderedColumns.length; colIdx++) {
      final cell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: colIdx, rowIndex: 0),
      );
      cell.cellStyle = CellStyle(
        bold: true,
        fontSize: 11,
      );
    }

    // 2. Data Rows
    for (final item in items) {
      final rowCells = <CellValue>[];
      for (final col in orderedColumns) {
        rowCells.add(_cellValueFor(item, col, currencyCode, dateFormat));
      }
      sheet.appendRow(rowCells);
    }

    // Auto-fit column widths
    for (var colIdx = 0; colIdx < orderedColumns.length; colIdx++) {
      sheet.setColumnAutoFit(colIdx);
    }

    final bytes = excel.save();
    return bytes ?? [];
  }

  CellValue _cellValueFor(
    Item item,
    ItemColumn column,
    String currencyCode,
    DateFormat dateFormat,
  ) {
    switch (column) {
      case ItemColumn.name:
        return TextCellValue(item.name);
      case ItemColumn.sku:
        return TextCellValue(item.sku ?? '-');
      case ItemColumn.barcode:
        return TextCellValue(item.barcode ?? '-');
      case ItemColumn.category:
        return TextCellValue(item.categoryId ?? 'Uncategorized');
      case ItemColumn.unit:
        return TextCellValue(item.unit.label);
      case ItemColumn.stock:
        return DoubleCellValue(item.inventory.quantity);
      case ItemColumn.reorderLevel:
        return item.inventory.reorderLevel != null
            ? DoubleCellValue(item.inventory.reorderLevel!)
            : TextCellValue('-');
      case ItemColumn.costPrice:
        return DoubleCellValue(item.pricing.costPrice);
      case ItemColumn.baseSellingPrice:
        return DoubleCellValue(item.pricing.baseSellingPrice);
      case ItemColumn.minSellingPrice:
        return item.pricing.minSellingPrice != null
            ? DoubleCellValue(item.pricing.minSellingPrice!)
            : TextCellValue('-');
      case ItemColumn.margin:
        return DoubleCellValue(item.pricing.margin);
      case ItemColumn.status:
        return TextCellValue(item.isActive ? 'Active' : 'Archived');
      case ItemColumn.updatedAt:
        return TextCellValue(dateFormat.format(item.updatedAt.toLocal()));
    }
  }
}

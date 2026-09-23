import 'dart:convert';
import 'dart:typed_data';
import 'package:excel/excel.dart';
import 'package:uuid/uuid.dart';

import '../../core/error/app_error.dart';
import '../../core/result/result.dart';
import '../../domain/item/item.dart';
import '../../domain/item/item_export.dart';
import '../../domain/item/item_id.dart';
import '../../domain/item/item_import.dart';
import '../../domain/item/item_inventory.dart';
import '../../domain/item/item_pricing.dart';
import '../../domain/item/item_unit.dart';
import '../../domain/store/store_id.dart';
import 'item_importer.dart';

/// Production implementation of [ItemImporter] supporting .xlsx and .csv formats.
class DefaultItemImporter implements ItemImporter {
  static const _uuid = Uuid();

  const DefaultItemImporter();

  @override
  Future<Result<ItemImportResult>> parse({
    required Uint8List bytes,
    required String fileName,
    required StoreId storeId,
  }) async {
    try {
      if (bytes.isEmpty) {
        return const Failure(
          ValidationError(
            'The selected file is empty. Please select a valid CSV or Excel file.',
            field: 'file',
          ),
        );
      }

      final lowerName = fileName.toLowerCase();
      List<List<String>> rawRows;

      if (lowerName.endsWith('.xlsx') || lowerName.endsWith('.xls')) {
        rawRows = _parseExcel(bytes);
      } else {
        rawRows = _parseCsv(bytes);
      }

      if (rawRows.isEmpty) {
        return Failure(
          ValidationError(
            'No readable rows found in "$fileName".',
            field: 'file',
          ),
        );
      }

      // 1. Identify header row and map column indices
      final headerRow = rawRows.first;
      final headerMap = _mapHeaderIndices(headerRow);

      if (!headerMap.containsKey(_Field.name)) {
        return Failure(
          ValidationError(
            'Missing required column: "Item Name" or "Name". Found columns: ${headerRow.join(", ")}',
            field: 'headers',
          ),
        );
      }

      final validItems = <Item>[];
      final errors = <ItemImportError>[];
      final now = DateTime.now().toUtc();

      // 2. Parse and validate data rows (1-indexed for user display, starting at row 2)
      for (int i = 1; i < rawRows.length; i++) {
        final row = rawRows[i];
        final rowNumber = i + 1; // 1-indexed row number in spreadsheet

        // Skip completely blank rows
        if (row.every((cell) => cell.trim().isEmpty)) {
          continue;
        }

        final nameVal = _getCell(row, headerMap[_Field.name]);
        if (nameVal.isEmpty) {
          errors.add(
            ItemImportError(
              rowIndex: rowNumber,
              fieldName: 'Name',
              rawValue: nameVal,
              message: 'Item name cannot be empty.',
            ),
          );
          continue;
        }

        // Selling Price (Required)
        final basePriceVal = _getCell(row, headerMap[_Field.baseSellingPrice]);
        if (basePriceVal.isEmpty) {
          errors.add(
            ItemImportError(
              rowIndex: rowNumber,
              fieldName: 'Selling Price',
              rawValue: basePriceVal,
              message: 'Selling price is required.',
            ),
          );
          continue;
        }

        final basePrice = _parsePrice(basePriceVal);
        if (basePrice == null || basePrice < 0) {
          errors.add(
            ItemImportError(
              rowIndex: rowNumber,
              fieldName: 'Selling Price',
              rawValue: basePriceVal,
              message: 'Selling price must be a valid positive number.',
            ),
          );
          continue;
        }

        // Cost Price (Optional, defaults to 0.0)
        final costPriceVal = _getCell(row, headerMap[_Field.costPrice]);
        double costPrice = 0.0;
        if (costPriceVal.isNotEmpty) {
          final parsed = _parsePrice(costPriceVal);
          if (parsed == null || parsed < 0) {
            errors.add(
              ItemImportError(
                rowIndex: rowNumber,
                fieldName: 'Cost Price',
                rawValue: costPriceVal,
                message: 'Cost price must be a valid positive number.',
              ),
            );
            continue;
          }
          costPrice = parsed;
        }

        // Minimum Selling Price (Optional)
        final minPriceVal = _getCell(row, headerMap[_Field.minSellingPrice]);
        double? minPrice;
        if (minPriceVal.isNotEmpty) {
          minPrice = _parsePrice(minPriceVal);
          if (minPrice == null || minPrice < 0) {
            errors.add(
              ItemImportError(
                rowIndex: rowNumber,
                fieldName: 'Minimum Selling Price',
                rawValue: minPriceVal,
                message:
                    'Minimum selling price must be a valid positive number.',
              ),
            );
            continue;
          }
          if (minPrice > basePrice) {
            errors.add(
              ItemImportError(
                rowIndex: rowNumber,
                fieldName: 'Minimum Selling Price',
                rawValue: minPriceVal,
                message:
                    'Minimum selling price (₦$minPrice) cannot exceed base selling price (₦$basePrice).',
              ),
            );
            continue;
          }
        }

        // Quantity (Optional, defaults to 0)
        final qtyVal = _getCell(row, headerMap[_Field.quantity]);
        double quantity = 0;
        if (qtyVal.isNotEmpty) {
          final q = double.tryParse(qtyVal.replaceAll(',', '').trim());
          if (q == null || q < 0) {
            errors.add(
              ItemImportError(
                rowIndex: rowNumber,
                fieldName: 'Quantity',
                rawValue: qtyVal,
                message: 'Quantity must be a valid non-negative number.',
              ),
            );
            continue;
          }
          quantity = q;
        }

        // Reorder Level (Optional, defaults to 0)
        final reorderVal = _getCell(row, headerMap[_Field.reorderLevel]);
        double reorderLevel = 0;
        if (reorderVal.isNotEmpty) {
          final r = double.tryParse(reorderVal.replaceAll(',', '').trim());
          if (r == null || r < 0) {
            errors.add(
              ItemImportError(
                rowIndex: rowNumber,
                fieldName: 'Reorder Level',
                rawValue: reorderVal,
                message: 'Reorder level must be a valid non-negative number.',
              ),
            );
            continue;
          }
          reorderLevel = r;
        }

        // Unit
        final unitVal = _getCell(row, headerMap[_Field.unit]);
        final unit = _matchUnit(unitVal);

        // SKU, Barcode, Category, Description
        final skuVal = _getCell(row, headerMap[_Field.sku]);
        final barcodeVal = _getCell(row, headerMap[_Field.barcode]);
        final catVal = _getCell(row, headerMap[_Field.category]);
        final descVal = _getCell(row, headerMap[_Field.description]);

        final item = Item(
          id: ItemId(_uuid.v4()),
          storeId: storeId,
          name: nameVal,
          sku: skuVal.isEmpty ? null : skuVal,
          barcode: barcodeVal.isEmpty ? null : barcodeVal,
          categoryId: catVal.isEmpty ? null : catVal,
          description: descVal.isEmpty ? null : descVal,
          unit: unit,
          pricing: ItemPricing(
            costPrice: costPrice,
            baseSellingPrice: basePrice,
            minSellingPrice: minPrice,
          ),
          inventory: ItemInventory(
            quantity: quantity,
            reorderLevel: reorderLevel,
          ),
          isActive: true,
          createdAt: now,
          updatedAt: now,
        );

        validItems.add(item);
      }

      final result = ItemImportResult(
        fileName: fileName,
        fileSizeBytes: bytes.length,
        totalRows: rawRows.length - 1,
        validItems: validItems,
        errors: errors,
      );

      return Success(result);
    } catch (e, st) {
      return Failure(
        StorageError('Failed to parse import file: $e'),
        stackTrace: st,
      );
    }
  }

  @override
  Future<Result<ExportedFile>> generateSampleTemplate(
    ItemExportFormat format,
  ) async {
    try {
      final headers = [
        'Item Name',
        'SKU',
        'Barcode',
        'Category',
        'Unit',
        'Cost Price',
        'Selling Price',
        'Minimum Selling Price',
        'Initial Stock',
        'Reorder Level',
        'Description',
      ];

      final sampleRows = [
        [
          'Coca-Cola 50cl',
          'COKE-50',
          '5449000000996',
          'Drinks',
          'bottle',
          '200',
          '250',
          '240',
          '48',
          '12',
          'Chilled soft drink',
        ],
        [
          'Peak Milk 400g',
          'PEAK-400',
          '8712800045231',
          'Provisions',
          'can',
          '1500',
          '1800',
          '1750',
          '24',
          '6',
          'Instant full cream milk powder',
        ],
        [
          'Dangote Sugar 50kg',
          'SUG-50KG',
          '',
          'Groceries',
          'bag',
          '68000',
          '72000',
          '70000',
          '10',
          '2',
          'Refined white granulated sugar',
        ],
      ];

      final now = DateTime.now().toUtc();

      if (format == ItemExportFormat.excel) {
        final excel = Excel.createExcel();
        final sheetName = excel.getDefaultSheet() ?? 'Sheet1';
        final sheet = excel[sheetName];

        sheet.appendRow(headers.map((h) => TextCellValue(h)).toList());
        for (final r in sampleRows) {
          sheet.appendRow(r.map((c) => TextCellValue(c)).toList());
        }

        final encoded = excel.encode();
        if (encoded == null) {
          return const Failure(
            StorageError('Failed to encode sample template Excel workbook.'),
          );
        }

        return Success(
          ExportedFile(
            fileName: 'tally_items_sample_template.xlsx',
            bytes: Uint8List.fromList(encoded),
            mimeType:
                'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
            itemCount: sampleRows.length,
            exportedAt: now,
          ),
        );
      } else {
        final allData = [headers, ...sampleRows];
        final buffer = StringBuffer();
        for (final row in allData) {
          final line = row.map((cell) {
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

        final bytes = Uint8List.fromList(utf8.encode(buffer.toString()));

        return Success(
          ExportedFile(
            fileName: 'tally_items_sample_template.csv',
            bytes: bytes,
            mimeType: 'text/csv',
            itemCount: sampleRows.length,
            exportedAt: now,
          ),
        );
      }
    } catch (e, st) {
      return Failure(
        StorageError('Failed to generate template: $e'),
        stackTrace: st,
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Parsing Helpers
  // ---------------------------------------------------------------------------

  List<List<String>> _parseCsv(Uint8List bytes) {
    String content;
    try {
      content = utf8.decode(bytes);
    } catch (_) {
      content = latin1.decode(bytes);
    }

    if (content.startsWith('\uFEFF')) {
      content = content.substring(1);
    }

    final rows = <List<String>>[];
    final currentRow = <String>[];
    final currentField = StringBuffer();
    bool insideQuotes = false;

    for (int i = 0; i < content.length; i++) {
      final char = content[i];

      if (insideQuotes) {
        if (char == '"') {
          if (i + 1 < content.length && content[i + 1] == '"') {
            currentField.write('"');
            i++; // skip escaped quote
          } else {
            insideQuotes = false;
          }
        } else {
          currentField.write(char);
        }
      } else {
        if (char == '"') {
          insideQuotes = true;
        } else if (char == ',') {
          currentRow.add(currentField.toString().trim());
          currentField.clear();
        } else if (char == '\n' || char == '\r') {
          if (char == '\r' &&
              i + 1 < content.length &&
              content[i + 1] == '\n') {
            i++;
          }
          currentRow.add(currentField.toString().trim());
          currentField.clear();
          if (currentRow.any((c) => c.isNotEmpty)) {
            rows.add(List<String>.from(currentRow));
          }
          currentRow.clear();
        } else {
          currentField.write(char);
        }
      }
    }

    if (currentField.isNotEmpty || currentRow.isNotEmpty) {
      currentRow.add(currentField.toString().trim());
      if (currentRow.any((c) => c.isNotEmpty)) {
        rows.add(List<String>.from(currentRow));
      }
    }

    return rows;
  }

  List<List<String>> _parseExcel(Uint8List bytes) {
    final excel = Excel.decodeBytes(bytes);
    if (excel.tables.isEmpty) return [];

    final firstTable = excel.tables.values.first;
    final rows = <List<String>>[];

    for (final row in firstTable.rows) {
      final stringRow = row.map((cell) {
        if (cell == null || cell.value == null) return '';
        return cell.value.toString().trim();
      }).toList();

      if (stringRow.any((c) => c.isNotEmpty)) {
        rows.add(stringRow);
      }
    }

    return rows;
  }

  Map<_Field, int> _mapHeaderIndices(List<String> headers) {
    final map = <_Field, int>{};

    for (int i = 0; i < headers.length; i++) {
      final h = headers[i].toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');

      if (h.contains('name') || h == 'item' || h == 'product' || h == 'title') {
        map.putIfAbsent(_Field.name, () => i);
      } else if (h == 'sku' ||
          h.contains('itemcode') ||
          h.contains('productcode') ||
          h == 'code') {
        map.putIfAbsent(_Field.sku, () => i);
      } else if (h.contains('barcode') || h == 'upc' || h == 'ean') {
        map.putIfAbsent(_Field.barcode, () => i);
      } else if (h.contains('category') || h.contains('dept') || h == 'group') {
        map.putIfAbsent(_Field.category, () => i);
      } else if (h.contains('unit') || h == 'uom' || h.contains('measure')) {
        map.putIfAbsent(_Field.unit, () => i);
      } else if (h.contains('cost') ||
          h.contains('buy') ||
          h.contains('purchase')) {
        map.putIfAbsent(_Field.costPrice, () => i);
      } else if (h.contains('min') ||
          h.contains('floor') ||
          h.contains('bottom')) {
        map.putIfAbsent(_Field.minSellingPrice, () => i);
      } else if (h.contains('price') ||
          h.contains('selling') ||
          h.contains('retail') ||
          h.contains('sale')) {
        map.putIfAbsent(_Field.baseSellingPrice, () => i);
      } else if (h.contains('qty') ||
          h.contains('quantity') ||
          h.contains('stock') ||
          h.contains('count') ||
          h.contains('onhand')) {
        map.putIfAbsent(_Field.quantity, () => i);
      } else if (h.contains('reorder') ||
          h.contains('threshold') ||
          h.contains('minstock')) {
        map.putIfAbsent(_Field.reorderLevel, () => i);
      } else if (h.contains('desc') ||
          h.contains('note') ||
          h.contains('remark')) {
        map.putIfAbsent(_Field.description, () => i);
      }
    }

    return map;
  }

  String _getCell(List<String> row, int? index) {
    if (index == null || index < 0 || index >= row.length) return '';
    return row[index].trim();
  }

  double? _parsePrice(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;
    final isNegative = trimmed.startsWith('-');
    final cleaned = trimmed.replaceAll(RegExp(r'[^\d.]'), '');
    if (cleaned.isEmpty) return null;
    final val = double.tryParse(cleaned);
    if (val == null) return null;
    return isNegative ? -val : val;
  }

  ItemUnit _matchUnit(String raw) {
    return ItemUnit.fromString(raw);
  }
}

enum _Field {
  name,
  sku,
  barcode,
  category,
  unit,
  costPrice,
  baseSellingPrice,
  minSellingPrice,
  quantity,
  reorderLevel,
  description,
}

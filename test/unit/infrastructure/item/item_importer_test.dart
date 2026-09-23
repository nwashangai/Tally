import 'dart:convert';
import 'dart:typed_data';
import 'package:excel/excel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tally/domain/item/item_export.dart';
import 'package:tally/domain/item/item_unit.dart';
import 'package:tally/domain/store/store_id.dart';
import 'package:tally/infrastructure/item/default_item_importer.dart';

void main() {
  const importer = DefaultItemImporter();
  const storeId = StoreId('store-123');

  String toCsvString(List<List<String>> rows) {
    return rows.map((r) => r.map((c) => '"$c"').join(',')).join('\n');
  }

  group('DefaultItemImporter CSV Parsing', () {
    test('parses valid CSV data with standard headers', () async {
      final rows = [
        [
          'Item Name',
          'SKU',
          'Unit',
          'Cost Price',
          'Selling Price',
          'Initial Stock'
        ],
        ['Coca-Cola 50cl', 'COKE-50', 'bottle', '200', '250', '48'],
        ['Peak Milk 400g', 'PEAK-400', 'can', '1500', '1800', '24'],
      ];
      final csvString = toCsvString(rows);
      final bytes = Uint8List.fromList(utf8.encode(csvString));

      final result = await importer.parse(
        bytes: bytes,
        fileName: 'products.csv',
        storeId: storeId,
      );

      expect(result.isSuccess, isTrue);
      final data = result.valueOrNull!;
      expect(data.validCount, 2);
      expect(data.errorCount, 0);

      final coke = data.validItems.first;
      expect(coke.name, 'Coca-Cola 50cl');
      expect(coke.sku, 'COKE-50');
      expect(coke.unit, ItemUnit.bottle);
      expect(coke.pricing.costPrice, 200);
      expect(coke.pricing.baseSellingPrice, 250);
      expect(coke.inventory.quantity, 48);

      final milk = data.validItems.last;
      expect(milk.name, 'Peak Milk 400g');
      expect(milk.pricing.baseSellingPrice, 1800);
      expect(milk.unit, ItemUnit.can);
    });

    test('accumulates row-level errors for invalid data and pricing invariants',
        () async {
      final rows = [
        ['Item Name', 'Selling Price', 'Minimum Selling Price'],
        ['Valid Item', '500', '450'],
        ['', '300', '250'], // Missing name -> error
        ['Bad Price Item', '-100', '50'], // Negative selling price -> error
        ['Invalid Invariant', '200', '250'], // Min > Base -> error
      ];
      final csvString = toCsvString(rows);
      final bytes = Uint8List.fromList(utf8.encode(csvString));

      final result = await importer.parse(
        bytes: bytes,
        fileName: 'test.csv',
        storeId: storeId,
      );

      expect(result.isSuccess, isTrue);
      final data = result.valueOrNull!;
      expect(data.validCount, 1);
      expect(data.errorCount, 3);
      expect(data.validItems.first.name, 'Valid Item');

      expect(data.errors.any((e) => e.rowIndex == 3 && e.fieldName == 'Name'),
          isTrue);
      expect(
          data.errors
              .any((e) => e.rowIndex == 4 && e.fieldName == 'Selling Price'),
          isTrue);
      expect(
          data.errors.any(
              (e) => e.rowIndex == 5 && e.fieldName == 'Minimum Selling Price'),
          isTrue);
    });
  });

  group('DefaultItemImporter Excel (.xlsx) Parsing', () {
    test('parses valid Excel workbook', () async {
      final excel = Excel.createExcel();
      final sheetName = excel.getDefaultSheet() ?? 'Sheet1';
      final sheet = excel[sheetName];

      sheet.appendRow([
        TextCellValue('Item Name'),
        TextCellValue('Category'),
        TextCellValue('Base Selling Price'),
        TextCellValue('Quantity'),
      ]);
      sheet.appendRow([
        TextCellValue('Dangote Sugar 50kg'),
        TextCellValue('Groceries'),
        TextCellValue('72000'),
        TextCellValue('10'),
      ]);

      final bytes = Uint8List.fromList(excel.encode()!);
      final result = await importer.parse(
        bytes: bytes,
        fileName: 'catalog.xlsx',
        storeId: storeId,
      );

      expect(result.isSuccess, isTrue);
      final data = result.valueOrNull!;
      expect(data.validCount, 1);
      expect(data.errorCount, 0);

      final item = data.validItems.first;
      expect(item.name, 'Dangote Sugar 50kg');
      expect(item.categoryId, 'Groceries');
      expect(item.pricing.baseSellingPrice, 72000);
      expect(item.inventory.quantity, 10);
    });
  });

  group('DefaultItemImporter Sample Templates', () {
    test('generates sample CSV and Excel templates', () async {
      final csvRes =
          await importer.generateSampleTemplate(ItemExportFormat.csv);
      expect(csvRes.isSuccess, isTrue);
      expect(csvRes.valueOrNull!.fileName, 'tally_items_sample_template.csv');
      expect(csvRes.valueOrNull!.bytes.isNotEmpty, isTrue);

      final xlsxRes =
          await importer.generateSampleTemplate(ItemExportFormat.excel);
      expect(xlsxRes.isSuccess, isTrue);
      expect(xlsxRes.valueOrNull!.fileName, 'tally_items_sample_template.xlsx');
      expect(xlsxRes.valueOrNull!.bytes.isNotEmpty, isTrue);
    });
  });
}

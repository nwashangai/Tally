import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:tally/domain/item/item.dart';
import 'package:tally/domain/item/item_column.dart';
import 'package:tally/domain/item/item_id.dart';
import 'package:tally/domain/item/item_inventory.dart';
import 'package:tally/domain/item/item_pricing.dart';
import 'package:tally/domain/item/item_unit.dart';
import 'package:tally/domain/store/store_id.dart';
import 'package:tally/infrastructure/item/csv_item_exporter.dart';
import 'package:tally/infrastructure/item/excel_item_exporter.dart';

void main() {
  const storeId = StoreId('test-store-export');

  final sampleItems = [
    Item(
      id: const ItemId('item-1'),
      storeId: storeId,
      name: 'Coca-Cola 50cl',
      sku: 'COKE-50',
      barcode: '5449000000996',
      categoryId: 'Drinks',
      unit: ItemUnit.bottle,
      pricing: ItemPricing(
        costPrice: 200,
        baseSellingPrice: 250,
        minSellingPrice: 240,
      ),
      inventory: ItemInventory(quantity: 42, reorderLevel: 10),
      createdAt: DateTime.utc(2026, 9, 1),
      updatedAt: DateTime.utc(2026, 9, 23),
    ),
    Item(
      id: const ItemId('item-2'),
      storeId: storeId,
      name: 'Peak Milk 400g',
      sku: 'PEAK-400',
      categoryId: 'Provisions',
      unit: ItemUnit.can,
      pricing: ItemPricing(
        costPrice: 1500,
        baseSellingPrice: 1800,
      ),
      inventory: ItemInventory(quantity: 15, reorderLevel: 5),
      createdAt: DateTime.utc(2026, 9, 1),
      updatedAt: DateTime.utc(2026, 9, 23),
    ),
  ];

  group('ExcelItemExporter', () {
    test('generates valid non-empty .xlsx binary payload', () {
      const exporter = ExcelItemExporter();
      final bytes = exporter.exportWorkbook(
        items: sampleItems,
        columns: ColumnPreset.standard.columns,
        storeName: 'Downtown Supermarket',
        currencyCode: '₦',
      );

      expect(bytes, isNotEmpty);
      // PK zip header bytes for .xlsx
      expect(bytes[0], 0x50);
      expect(bytes[1], 0x4B);
    });
  });

  group('CsvItemExporter', () {
    test('generates formatted CSV with UTF-8 BOM', () {
      const exporter = CsvItemExporter();
      final bytes = exporter.exportCsv(
        items: sampleItems,
        columns: {
          ItemColumn.name,
          ItemColumn.sku,
          ItemColumn.costPrice,
          ItemColumn.baseSellingPrice,
        },
        currencyCode: '₦',
      );

      expect(bytes, isNotEmpty);
      // UTF-8 BOM
      expect(bytes[0], 0xEF);
      expect(bytes[1], 0xBB);
      expect(bytes[2], 0xBF);

      final text = utf8.decode(bytes.sublist(3));
      expect(text, contains('Item'));
      expect(text, contains('SKU'));
      expect(text, contains('Coca-Cola 50cl'));
      expect(text, contains('Peak Milk 400g'));
    });
  });
}

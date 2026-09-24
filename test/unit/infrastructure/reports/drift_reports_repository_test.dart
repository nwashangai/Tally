import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:tally/domain/item/item.dart';
import 'package:tally/domain/item/item_id.dart';
import 'package:tally/domain/item/item_inventory.dart';
import 'package:tally/domain/item/item_pricing.dart';
import 'package:tally/domain/item/item_unit.dart';
import 'package:tally/domain/store/store_id.dart';
import 'package:tally/infrastructure/database/store_database.dart';
import 'package:tally/infrastructure/item/drift_item_repository.dart';
import 'package:tally/infrastructure/reports/drift_reports_repository.dart';

void main() {
  late Directory tempDir;
  late StoreDatabase db;
  late DriftItemRepository itemRepo;
  late DriftReportsRepository reportsRepo;
  const storeId = StoreId('store-reports-test');

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('tally_reports_test_');
    final dbFile = File('${tempDir.path}/test_reports.db');
    db = StoreDatabase(
      storeId: storeId,
      databaseFile: dbFile,
      encryptionKey: 'test-passphrase-reports',
    );
    await db.open();
    itemRepo = DriftItemRepository(database: db, storeId: storeId);
    reportsRepo = DriftReportsRepository(database: db, storeId: storeId);
  });

  tearDown(() async {
    await db.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  Item createTestItem({
    required String id,
    required String name,
    double cost = 700,
    double base = 1000,
  }) {
    final now = DateTime.now().toUtc();
    return Item(
      id: ItemId(id),
      storeId: storeId,
      name: name,
      sku: 'SKU-$id',
      unit: ItemUnit.bottle,
      pricing: ItemPricing(
        costPrice: cost,
        baseSellingPrice: base,
      ),
      inventory: ItemInventory(quantity: 100),
      createdAt: now,
      updatedAt: now,
    );
  }

  Future<void> recordSale({
    required String txId,
    required String itemId,
    required double quantitySold,
    required double unitCost,
    required double unitPrice,
    required DateTime timestamp,
  }) async {
    await db.executor.runInsert(
      '''
      INSERT INTO item_transactions (
        id, store_id, item_id, type, quantity_delta,
        unit_cost, unit_price, reference_id, notes, created_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
      ''',
      [
        txId,
        storeId.value,
        itemId,
        'SALE',
        -quantitySold, // Negative for sales
        unitCost,
        unitPrice,
        'SALE-$txId',
        'Sale order $txId',
        timestamp.toUtc().toIso8601String(),
      ],
    );
  }

  group('DriftReportsRepository Multi-Era Sales & Profit Tests', () {
    test(
        'calculates sales, COGS, and profit factoring in different costs and prices at different times',
        () async {
      // Create catalog item: starts in January with cost=700, price=1000
      final item = createTestItem(
        id: 'whiskey-1',
        name: 'Jameson Whiskey 75cl',
        cost: 700.0,
        base: 1000.0,
      );
      await itemRepo.create(item);

      // Era 1 (January): 10 units sold @ price=1000, cost=700
      // Revenue = 10 * 1000 = 10,000 | COGS = 10 * 700 = 7,000 | Profit = 3,000
      final janTime = DateTime.utc(2026, 1, 15, 12, 0);
      await recordSale(
        txId: 'tx-jan-1',
        itemId: item.id.value,
        quantitySold: 10,
        unitCost: 700.0,
        unitPrice: 1000.0,
        timestamp: janTime,
      );

      // Era 2 (February): receiving increased unit cost to 900, selling price to 1500
      // 5 units sold @ price=1500, cost=900
      // Revenue = 5 * 1500 = 7,500 | COGS = 5 * 900 = 4,500 | Profit = 3,000
      final febTime = DateTime.utc(2026, 2, 20, 15, 30);
      await recordSale(
        txId: 'tx-feb-1',
        itemId: item.id.value,
        quantitySold: 5,
        unitCost: 900.0,
        unitPrice: 1500.0,
        timestamp: febTime,
      );

      // Catalog item price later changes to cost=1100, price=2000 in March
      await itemRepo.update(
        item.copyWith(
          pricing: ItemPricing(
            costPrice: 1100.0,
            baseSellingPrice: 2000.0,
          ),
        ),
      );

      // Run reports for entire period
      final reportRes = await reportsRepo.getSalesProfitReport();
      expect(reportRes.isSuccess, isTrue);

      final report = reportRes.valueOrNull!;
      expect(report.transactionCount, 2);
      expect(report.totalUnitsSold, 15.0);

      // Expected Totals:
      // Total Revenue = 10,000 + 7,500 = 17,500
      // Total COGS = 7,000 + 4,500 = 11,500
      // Total Gross Profit = 17,500 - 11,500 = 6,000
      // Overall Margin = (6,000 / 17,500) * 100 = 34.2857%
      expect(report.totalRevenue, 17500.0);
      expect(report.totalCogs, 11500.0);
      expect(report.totalGrossProfit, 6000.0);
      expect(
        report.overallMarginPercentage,
        closeTo(34.2857, 0.001),
      );

      // Inspect Item Breakdown & Distinct Price Eras
      expect(report.itemReports.length, 1);
      final itemReport = report.itemReports.first;
      expect(itemReport.itemName, 'Jameson Whiskey 75cl');
      expect(itemReport.totalQuantitySold, 15.0);
      expect(itemReport.totalRevenue, 17500.0);
      expect(itemReport.totalCogs, 11500.0);
      expect(itemReport.totalGrossProfit, 6000.0);

      // 2 Distinct Price Eras
      expect(itemReport.priceEras.length, 2);

      final era1 = itemReport.priceEras[0];
      expect(era1.unitPrice, 1000.0);
      expect(era1.unitCost, 700.0);
      expect(era1.quantitySold, 10.0);
      expect(era1.revenue, 10000.0);
      expect(era1.cogs, 7000.0);
      expect(era1.grossProfit, 3000.0);
      expect(era1.marginPercentage, 30.0); // (3000 / 10000) * 100

      final era2 = itemReport.priceEras[1];
      expect(era2.unitPrice, 1500.0);
      expect(era2.unitCost, 900.0);
      expect(era2.quantitySold, 5.0);
      expect(era2.revenue, 7500.0);
      expect(era2.cogs, 4500.0);
      expect(era2.grossProfit, 3000.0);
      expect(era2.marginPercentage, 40.0); // (3000 / 7500) * 100
    });

    test('date range filters correctly bound transactions', () async {
      final item = createTestItem(id: 'water-1', name: 'Bottled Water 75cl');
      await itemRepo.create(item);

      final d1 = DateTime.utc(2026, 3, 1);
      final d2 = DateTime.utc(2026, 3, 15);
      final d3 = DateTime.utc(2026, 4, 1);

      await recordSale(
        txId: 's1',
        itemId: item.id.value,
        quantitySold: 20,
        unitCost: 50.0,
        unitPrice: 100.0,
        timestamp: d1,
      );

      await recordSale(
        txId: 's2',
        itemId: item.id.value,
        quantitySold: 30,
        unitCost: 50.0,
        unitPrice: 100.0,
        timestamp: d2,
      );

      await recordSale(
        txId: 's3',
        itemId: item.id.value,
        quantitySold: 50,
        unitCost: 60.0,
        unitPrice: 120.0,
        timestamp: d3,
      );

      // Query only March
      final marchReport = await reportsRepo.getSalesProfitReport(
        startDate: DateTime.utc(2026, 3, 1),
        endDate: DateTime.utc(2026, 3, 31, 23, 59, 59),
      );

      final r = marchReport.valueOrNull!;
      expect(r.transactionCount, 2);
      expect(r.totalUnitsSold, 50.0);
      expect(r.totalRevenue, 5000.0); // (20 + 30) * 100
      expect(r.totalCogs, 2500.0);
      expect(r.totalGrossProfit, 2500.0);
    });
  });
}

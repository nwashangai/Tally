import '../../core/error/app_error.dart';
import '../../core/result/result.dart';
import '../../domain/item/item_id.dart';
import '../../domain/reports/reports_repository.dart';
import '../../domain/reports/sales_profit_report.dart';
import '../../domain/store/store_id.dart';
import '../database/store_database.dart';

/// Drift/SQLite implementation of [ReportsRepository].
///
/// Ensures historical accuracy by calculating sales revenue, Cost of Goods Sold (COGS),
/// and profit strictly from transaction records in `item_transactions`. Past sales
/// are NEVER retroactively altered when item catalog prices or costs change later.
class DriftReportsRepository implements ReportsRepository {
  final StoreDatabase _database;
  final StoreId _storeId;

  DriftReportsRepository({
    required StoreDatabase database,
    required StoreId storeId,
  })  : _database = database,
        _storeId = storeId;

  Future<void> _ensureOpen() async {
    if (!_database.isOpen) {
      await _database.open();
    }
  }

  @override
  Future<Result<SalesProfitReport>> getSalesProfitReport({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      await _ensureOpen();

      final conditions = <String>["t.store_id = ?", "t.type = 'SALE'"];
      final params = <Object?>[_storeId.value];

      if (startDate != null) {
        conditions.add("t.created_at >= ?");
        params.add(startDate.toUtc().toIso8601String());
      }

      if (endDate != null) {
        conditions.add("t.created_at <= ?");
        params.add(endDate.toUtc().toIso8601String());
      }

      final sql = '''
        SELECT
          t.id as tx_id,
          t.item_id,
          COALESCE(i.name, t.notes, 'Unknown Item') as item_name,
          i.sku as sku,
          COALESCE(i.unit, 'unit') as unit,
          t.quantity_delta,
          t.unit_cost,
          t.unit_price,
          t.created_at
        FROM item_transactions t
        LEFT JOIN items i ON t.item_id = i.id
        WHERE ${conditions.join(' AND ')}
        ORDER BY t.created_at ASC;
      ''';

      final rows = await _database.executor.runSelect(sql, params);

      // Group rows by item_id
      final itemMap = <String, List<Map<String, Object?>>>{};
      for (final r in rows) {
        final itemId = r['item_id'] as String;
        itemMap.putIfAbsent(itemId, () => []).add(r);
      }

      final itemReports = <ItemProfitReport>[];

      for (final entry in itemMap.entries) {
        final itemId = entry.key;
        final itemRows = entry.value;

        final firstRow = itemRows.first;
        final itemName = firstRow['item_name'] as String;
        final sku = firstRow['sku'] as String?;
        final unit = firstRow['unit'] as String;

        // Group by pricing era: (unit_cost, unit_price)
        final eraMap = <String, _EraAccumulator>{};

        for (final row in itemRows) {
          final rawDelta = (row['quantity_delta'] as num).toDouble();
          final qtySold = rawDelta.abs();
          final cost = (row['unit_cost'] as num?)?.toDouble() ?? 0.0;
          final price = (row['unit_price'] as num?)?.toDouble() ?? 0.0;
          final txDate = DateTime.parse(row['created_at'] as String);

          // Unique era key based on cost and price
          final eraKey =
              '${cost.toStringAsFixed(4)}_${price.toStringAsFixed(4)}';

          if (eraMap.containsKey(eraKey)) {
            final acc = eraMap[eraKey]!;
            acc.quantitySold += qtySold;
            if (txDate.isBefore(acc.firstSoldAt)) acc.firstSoldAt = txDate;
            if (txDate.isAfter(acc.lastSoldAt)) acc.lastSoldAt = txDate;
          } else {
            eraMap[eraKey] = _EraAccumulator(
              unitCost: cost,
              unitPrice: price,
              quantitySold: qtySold,
              firstSoldAt: txDate,
              lastSoldAt: txDate,
            );
          }
        }

        final priceEras = eraMap.values.map((acc) {
          return SalePriceEra(
            unitCost: acc.unitCost,
            unitPrice: acc.unitPrice,
            quantitySold: acc.quantitySold,
            firstSoldAt: acc.firstSoldAt,
            lastSoldAt: acc.lastSoldAt,
          );
        }).toList();

        // Sort eras chronologically by firstSoldAt
        priceEras.sort((a, b) => a.firstSoldAt.compareTo(b.firstSoldAt));

        itemReports.add(
          ItemProfitReport(
            itemId: ItemId(itemId),
            itemName: itemName,
            sku: sku,
            unit: unit,
            priceEras: priceEras,
          ),
        );
      }

      // Sort items by total revenue descending
      itemReports.sort((a, b) => b.totalRevenue.compareTo(a.totalRevenue));

      return Success(
        SalesProfitReport(
          startDate: startDate,
          endDate: endDate,
          itemReports: itemReports,
          transactionCount: rows.length,
        ),
      );
    } catch (e, st) {
      return Failure(
        StorageError('Failed to generate sales profit report: $e'),
        stackTrace: st,
      );
    }
  }
}

class _EraAccumulator {
  final double unitCost;
  final double unitPrice;
  double quantitySold;
  DateTime firstSoldAt;
  DateTime lastSoldAt;

  _EraAccumulator({
    required this.unitCost,
    required this.unitPrice,
    required this.quantitySold,
    required this.firstSoldAt,
    required this.lastSoldAt,
  });
}

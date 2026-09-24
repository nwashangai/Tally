import 'package:equatable/equatable.dart';
import '../item/item_id.dart';

/// Represents a distinct pricing era where an item was sold at a specific
/// unit cost and selling price.
class SalePriceEra extends Equatable {
  final double unitCost;
  final double unitPrice;
  final double quantitySold;
  final DateTime firstSoldAt;
  final DateTime lastSoldAt;

  const SalePriceEra({
    required this.unitCost,
    required this.unitPrice,
    required this.quantitySold,
    required this.firstSoldAt,
    required this.lastSoldAt,
  });

  /// Total revenue earned during this price era.
  double get revenue => quantitySold * unitPrice;

  /// Total Cost of Goods Sold (COGS) during this price era.
  double get cogs => quantitySold * unitCost;

  /// Total gross profit during this price era.
  double get grossProfit => revenue - cogs;

  /// Profit margin percentage: (Gross Profit / Revenue) * 100.
  double get marginPercentage =>
      revenue > 0 ? (grossProfit / revenue) * 100 : 0.0;

  /// Markup percentage: (Gross Profit / COGS) * 100.
  double get markupPercentage => cogs > 0 ? (grossProfit / cogs) * 100 : 0.0;

  SalePriceEra copyWith({
    double? unitCost,
    double? unitPrice,
    double? quantitySold,
    DateTime? firstSoldAt,
    DateTime? lastSoldAt,
  }) {
    return SalePriceEra(
      unitCost: unitCost ?? this.unitCost,
      unitPrice: unitPrice ?? this.unitPrice,
      quantitySold: quantitySold ?? this.quantitySold,
      firstSoldAt: firstSoldAt ?? this.firstSoldAt,
      lastSoldAt: lastSoldAt ?? this.lastSoldAt,
    );
  }

  @override
  List<Object?> get props => [
        unitCost,
        unitPrice,
        quantitySold,
        firstSoldAt,
        lastSoldAt,
      ];
}

/// Item-level profit breakdown across all historical pricing eras.
class ItemProfitReport extends Equatable {
  final ItemId itemId;
  final String itemName;
  final String? sku;
  final String unit;
  final List<SalePriceEra> priceEras;

  const ItemProfitReport({
    required this.itemId,
    required this.itemName,
    this.sku,
    required this.unit,
    required this.priceEras,
  });

  /// Aggregate quantity sold across all eras.
  double get totalQuantitySold =>
      priceEras.fold(0.0, (sum, era) => sum + era.quantitySold);

  /// Aggregate revenue across all eras.
  double get totalRevenue =>
      priceEras.fold(0.0, (sum, era) => sum + era.revenue);

  /// Aggregate Cost of Goods Sold across all eras.
  double get totalCogs => priceEras.fold(0.0, (sum, era) => sum + era.cogs);

  /// Aggregate Gross Profit across all eras.
  double get totalGrossProfit => totalRevenue - totalCogs;

  /// Aggregate margin percentage.
  double get marginPercentage =>
      totalRevenue > 0 ? (totalGrossProfit / totalRevenue) * 100 : 0.0;

  @override
  List<Object?> get props => [
        itemId,
        itemName,
        sku,
        unit,
        priceEras,
      ];
}

/// Store-level sales and profit report spanning a defined period.
class SalesProfitReport extends Equatable {
  final DateTime? startDate;
  final DateTime? endDate;
  final List<ItemProfitReport> itemReports;
  final int transactionCount;

  const SalesProfitReport({
    this.startDate,
    this.endDate,
    required this.itemReports,
    this.transactionCount = 0,
  });

  /// Total revenue across all items.
  double get totalRevenue =>
      itemReports.fold(0.0, (sum, item) => sum + item.totalRevenue);

  /// Total COGS across all items.
  double get totalCogs =>
      itemReports.fold(0.0, (sum, item) => sum + item.totalCogs);

  /// Total gross profit across all items.
  double get totalGrossProfit => totalRevenue - totalCogs;

  /// Overall gross margin percentage.
  double get overallMarginPercentage =>
      totalRevenue > 0 ? (totalGrossProfit / totalRevenue) * 100 : 0.0;

  /// Total quantity of all units sold.
  double get totalUnitsSold =>
      itemReports.fold(0.0, (sum, item) => sum + item.totalQuantitySold);

  @override
  List<Object?> get props => [
        startDate,
        endDate,
        itemReports,
        transactionCount,
      ];
}

import '../../core/result/result.dart';
import 'sales_profit_report.dart';

/// Repository port for analytics and profitability reports.
abstract class ReportsRepository {
  /// Calculates historical sales, cost of goods sold (COGS), and gross profit
  /// strictly using the historical transaction records stamped at the time of each sale.
  Future<Result<SalesProfitReport>> getSalesProfitReport({
    DateTime? startDate,
    DateTime? endDate,
  });
}

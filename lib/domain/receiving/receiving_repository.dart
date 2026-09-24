import '../../core/result/result.dart';
import '../item/item_id.dart';
import '../item/item_query.dart';
import 'receiving.dart';
import 'receiving_id.dart';
import 'receiving_line_history.dart';
import 'receiving_query.dart';

/// Contract for managing and persisting Receiving transactions.
abstract class ReceivingRepository {
  /// Queries receivings using the specified filters, pagination, and sorting.
  Future<Result<PaginatedResult<Receiving>>> query(ReceivingQuery query);

  /// Retrieves a receiving transaction by its unique identifier, including all lines.
  Future<Result<Receiving?>> getById(ReceivingId id);

  /// Persists a new receiving transaction (in draft or completed status).
  Future<Result<Receiving>> create(Receiving receiving);

  /// Atomically completes a receiving:
  /// 1. Updates receiving status to `completed`
  /// 2. Records stock movements in `item_transactions` (`+quantity`)
  /// 3. Increments item inventory quantity
  /// 4. Optionally updates item catalog cost_price if requested on the line
  /// Must be idempotent and executed within a single database transaction.
  Future<Result<Receiving>> complete(ReceivingId id);

  /// Atomically voids a completed receiving:
  /// 1. Updates receiving status to `voided`
  /// 2. Records compensating reversal stock movements in `item_transactions` (`-quantity`)
  /// 3. Decrements item inventory quantity
  /// Preserves historical receiving record for auditability.
  Future<Result<Receiving>> voidReceiving(ReceivingId id, {String? reason});

  /// Retrieves chronological inbound receiving history for an item.
  Future<Result<List<ReceivingLineHistory>>> getItemReceivingHistory(
    ItemId itemId, {
    int limit = 10,
  });

  /// Generates the next sequential, human-readable reference number (e.g. REC-000001).
  Future<Result<String>> getNextReferenceNumber();
}

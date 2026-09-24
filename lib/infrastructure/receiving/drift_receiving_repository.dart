import 'package:uuid/uuid.dart';
import '../../core/error/app_error.dart';
import '../../core/result/result.dart';
import '../../domain/item/item_id.dart';
import '../../domain/item/item_query.dart';
import '../../domain/receiving/receiving.dart';
import '../../domain/receiving/receiving_id.dart';
import '../../domain/receiving/receiving_line.dart';
import '../../domain/receiving/receiving_line_history.dart';
import '../../domain/receiving/receiving_query.dart';
import '../../domain/receiving/receiving_repository.dart';
import '../../domain/receiving/receiving_status.dart';
import '../../domain/store/store_id.dart';
import '../database/store_database.dart';

/// SQLite and Drift implementation of [ReceivingRepository].
/// Provides transactional atomicity, idempotency, and historical snapshot preservation.
class DriftReceivingRepository implements ReceivingRepository {
  final StoreDatabase _database;
  final StoreId _storeId;

  DriftReceivingRepository({
    required StoreDatabase database,
    required StoreId storeId,
  })  : _database = database,
        _storeId = storeId;

  Future<void> _ensureOpen() async {
    if (!_database.isOpen) {
      final openRes = await _database.open();
      if (openRes.isFailure) {
        throw openRes.errorOrNull!;
      }
    }
  }

  @override
  Future<Result<PaginatedResult<Receiving>>> query(ReceivingQuery query) async {
    try {
      await _ensureOpen();

      final whereClauses = <String>['store_id = ?'];
      final whereParams = <Object?>[_storeId.value];

      // Search across referenceNumber, supplier, notes
      if (query.search.trim().isNotEmpty) {
        final term = '%${query.search.trim().toLowerCase()}%';
        whereClauses.add(
          '(LOWER(reference_number) LIKE ? OR LOWER(supplier) LIKE ? OR LOWER(notes) LIKE ?)',
        );
        whereParams.addAll([term, term, term]);
      }

      // Filter: Status
      if (query.status != null) {
        whereClauses.add('status = ?');
        whereParams.add(query.status!.value);
      }

      // Filter: Supplier
      if (query.supplier != null && query.supplier!.trim().isNotEmpty) {
        whereClauses.add('LOWER(supplier) = ?');
        whereParams.add(query.supplier!.trim().toLowerCase());
      }

      // Filter: Date range
      if (query.startDate != null) {
        whereClauses.add('received_at >= ?');
        whereParams.add(query.startDate!.toUtc().toIso8601String());
      }
      if (query.endDate != null) {
        whereClauses.add('received_at <= ?');
        whereParams.add(query.endDate!.toUtc().toIso8601String());
      }

      final whereSql = whereClauses.join(' AND ');

      // Total count
      final countRows = await _database.executor.runSelect(
        'SELECT COUNT(*) as count FROM receivings WHERE $whereSql;',
        whereParams,
      );
      final totalItems = (countRows.first['count'] as num?)?.toInt() ?? 0;

      // Ordering
      final sortCol = query.sortBy.dbColumn;
      final sortDir = query.sortDirection.sql;

      final selectParams = List<Object?>.from(whereParams)
        ..addAll([query.pageSize, query.offset]);

      final rows = await _database.executor.runSelect(
        '''
        SELECT * FROM receivings
        WHERE $whereSql
        ORDER BY $sortCol $sortDir
        LIMIT ? OFFSET ?;
        ''',
        selectParams,
      );

      final receivings = <Receiving>[];
      for (final row in rows) {
        final receivingId = row['id'] as String;
        final lines = await _fetchLinesForReceiving(receivingId);

        receivings.add(
          Receiving(
            id: ReceivingId(receivingId),
            storeId: StoreId(row['store_id'] as String),
            referenceNumber: row['reference_number'] as String,
            receivedAt: DateTime.parse(row['received_at'] as String),
            supplier: row['supplier'] as String?,
            notes: row['notes'] as String?,
            status: ReceivingStatus.fromValue(row['status'] as String),
            totalCost: (row['total_cost'] as num).toDouble(),
            createdBy: row['created_by'] as String?,
            createdAt: DateTime.parse(row['created_at'] as String),
            updatedAt: DateTime.parse(row['updated_at'] as String),
            lines: lines,
          ),
        );
      }

      return Success(
        PaginatedResult<Receiving>(
          items: receivings,
          page: query.page,
          pageSize: query.pageSize,
          totalItems: totalItems,
        ),
      );
    } catch (e, st) {
      return Failure(
        StorageError('Failed to query receivings: $e'),
        stackTrace: st,
      );
    }
  }

  @override
  Future<Result<Receiving?>> getById(ReceivingId id) async {
    try {
      await _ensureOpen();

      final rows = await _database.executor.runSelect(
        'SELECT * FROM receivings WHERE id = ? AND store_id = ?;',
        [id.value, _storeId.value],
      );

      if (rows.isEmpty) return const Success(null);

      final row = rows.first;
      final lines = await _fetchLinesForReceiving(id.value);

      return Success(
        Receiving(
          id: id,
          storeId: StoreId(row['store_id'] as String),
          referenceNumber: row['reference_number'] as String,
          receivedAt: DateTime.parse(row['received_at'] as String),
          supplier: row['supplier'] as String?,
          notes: row['notes'] as String?,
          status: ReceivingStatus.fromValue(row['status'] as String),
          totalCost: (row['total_cost'] as num).toDouble(),
          createdBy: row['created_by'] as String?,
          createdAt: DateTime.parse(row['created_at'] as String),
          updatedAt: DateTime.parse(row['updated_at'] as String),
          lines: lines,
        ),
      );
    } catch (e, st) {
      return Failure(
        StorageError('Failed to get receiving ${id.value}: $e'),
        stackTrace: st,
      );
    }
  }

  @override
  Future<Result<Receiving>> create(Receiving receiving) async {
    try {
      await _ensureOpen();

      await _database.executor.runCustom('BEGIN TRANSACTION;');
      try {
        await _database.executor.runInsert(
          '''
          INSERT INTO receivings (
            id, store_id, reference_number, received_at, supplier,
            notes, status, total_cost, created_by, created_at, updated_at
          ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
          ''',
          [
            receiving.id.value,
            _storeId.value,
            receiving.referenceNumber,
            receiving.receivedAt.toUtc().toIso8601String(),
            receiving.supplier,
            receiving.notes,
            receiving.status.value,
            receiving.totalCost,
            receiving.createdBy,
            receiving.createdAt.toUtc().toIso8601String(),
            receiving.updatedAt.toUtc().toIso8601String(),
          ],
        );

        for (final line in receiving.lines) {
          await _database.executor.runInsert(
            '''
            INSERT INTO receiving_lines (
              id, receiving_id, store_id, item_id, item_name_snapshot,
              sku_snapshot, unit_snapshot, quantity, unit_cost, line_total,
              update_item_cost, new_base_selling_price, new_min_selling_price, update_item_price
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
            ''',
            [
              line.id,
              receiving.id.value,
              _storeId.value,
              line.itemId.value,
              line.itemNameSnapshot,
              line.skuSnapshot,
              line.unitSnapshot,
              line.quantity,
              line.unitCost,
              line.lineTotal,
              line.updateItemCost ? 1 : 0,
              line.newBaseSellingPrice,
              line.newMinSellingPrice,
              line.updateItemPrice ? 1 : 0,
            ],
          );
        }

        // If created directly in completed status, apply inventory mutations
        if (receiving.status == ReceivingStatus.completed) {
          await _applyCompletedReceivingMutations(receiving);
        }

        await _database.executor.runCustom('COMMIT;');
        return Success(receiving);
      } catch (e) {
        await _database.executor.runCustom('ROLLBACK;');
        rethrow;
      }
    } catch (e, st) {
      return Failure(
        StorageError('Failed to create receiving: $e'),
        stackTrace: st,
      );
    }
  }

  @override
  Future<Result<Receiving>> complete(ReceivingId id) async {
    try {
      await _ensureOpen();

      await _database.executor.runCustom('BEGIN TRANSACTION;');
      try {
        final rows = await _database.executor.runSelect(
          'SELECT * FROM receivings WHERE id = ? AND store_id = ?;',
          [id.value, _storeId.value],
        );

        if (rows.isEmpty) {
          throw NotFoundError('Receiving ${id.value} not found.');
        }

        final currentStatus =
            ReceivingStatus.fromValue(rows.first['status'] as String);

        // Idempotency guard: if already completed, do not re-apply stock
        if (currentStatus == ReceivingStatus.completed) {
          await _database.executor.runCustom('COMMIT;');
          final existing = await getById(id);
          return Success(existing.valueOrNull!);
        }

        if (currentStatus == ReceivingStatus.voided) {
          throw const DomainError('Cannot complete a voided receiving.');
        }

        final lines = await _fetchLinesForReceiving(id.value);
        if (lines.isEmpty) {
          throw const DomainError(
            'Cannot complete a receiving with no line items.',
          );
        }

        final now = DateTime.now().toUtc();

        await _database.executor.runUpdate(
          'UPDATE receivings SET status = ?, updated_at = ? WHERE id = ? AND store_id = ?;',
          [
            ReceivingStatus.completed.value,
            now.toIso8601String(),
            id.value,
            _storeId.value,
          ],
        );

        final completedReceiving = Receiving(
          id: id,
          storeId: _storeId,
          referenceNumber: rows.first['reference_number'] as String,
          receivedAt: DateTime.parse(rows.first['received_at'] as String),
          supplier: rows.first['supplier'] as String?,
          notes: rows.first['notes'] as String?,
          status: ReceivingStatus.completed,
          totalCost: (rows.first['total_cost'] as num).toDouble(),
          createdBy: rows.first['created_by'] as String?,
          createdAt: DateTime.parse(rows.first['created_at'] as String),
          updatedAt: now,
          lines: lines,
        );

        await _applyCompletedReceivingMutations(completedReceiving);

        await _database.executor.runCustom('COMMIT;');
        return Success(completedReceiving);
      } catch (e) {
        await _database.executor.runCustom('ROLLBACK;');
        rethrow;
      }
    } catch (e, st) {
      return Failure(
        StorageError('Failed to complete receiving ${id.value}: $e'),
        stackTrace: st,
      );
    }
  }

  @override
  Future<Result<Receiving>> voidReceiving(
    ReceivingId id, {
    String? reason,
  }) async {
    try {
      await _ensureOpen();

      await _database.executor.runCustom('BEGIN TRANSACTION;');
      try {
        final rows = await _database.executor.runSelect(
          'SELECT * FROM receivings WHERE id = ? AND store_id = ?;',
          [id.value, _storeId.value],
        );

        if (rows.isEmpty) {
          throw NotFoundError('Receiving ${id.value} not found.');
        }

        final currentStatus =
            ReceivingStatus.fromValue(rows.first['status'] as String);

        // Idempotency: if already voided, no-op
        if (currentStatus == ReceivingStatus.voided) {
          await _database.executor.runCustom('COMMIT;');
          final existing = await getById(id);
          return Success(existing.valueOrNull!);
        }

        final now = DateTime.now().toUtc();
        final lines = await _fetchLinesForReceiving(id.value);

        final existingNotes = rows.first['notes'] as String?;
        final updatedNotes = reason != null && reason.trim().isNotEmpty
            ? '${existingNotes ?? ""}\n[Voided: ${reason.trim()}]'.trim()
            : existingNotes;

        await _database.executor.runUpdate(
          'UPDATE receivings SET status = ?, notes = ?, updated_at = ? WHERE id = ? AND store_id = ?;',
          [
            ReceivingStatus.voided.value,
            updatedNotes,
            now.toIso8601String(),
            id.value,
            _storeId.value,
          ],
        );

        // If the receiving was previously completed, record compensatory reversal stock movements
        if (currentStatus == ReceivingStatus.completed) {
          for (final line in lines) {
            final txId = const Uuid().v4();
            await _database.executor.runInsert(
              '''
              INSERT INTO item_transactions (
                id, store_id, item_id, type, quantity_delta,
                unit_cost, unit_price, reference_id, notes, created_at
              ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
              ''',
              [
                txId,
                _storeId.value,
                line.itemId.value,
                'RECEIVING_VOID',
                -line.quantity,
                line.unitCost,
                null,
                id.value,
                'Voided receiving ${rows.first['reference_number']}',
                now.toIso8601String(),
              ],
            );

            // Revert item inventory quantity
            await _database.executor.runUpdate(
              '''
              UPDATE items SET
                quantity = quantity - ?,
                updated_at = ?
              WHERE id = ? AND store_id = ?;
              ''',
              [
                line.quantity,
                now.toIso8601String(),
                line.itemId.value,
                _storeId.value,
              ],
            );
          }
        }

        await _database.executor.runCustom('COMMIT;');

        final voidedReceiving = Receiving(
          id: id,
          storeId: _storeId,
          referenceNumber: rows.first['reference_number'] as String,
          receivedAt: DateTime.parse(rows.first['received_at'] as String),
          supplier: rows.first['supplier'] as String?,
          notes: updatedNotes,
          status: ReceivingStatus.voided,
          totalCost: (rows.first['total_cost'] as num).toDouble(),
          createdBy: rows.first['created_by'] as String?,
          createdAt: DateTime.parse(rows.first['created_at'] as String),
          updatedAt: now,
          lines: lines,
        );

        return Success(voidedReceiving);
      } catch (e) {
        await _database.executor.runCustom('ROLLBACK;');
        rethrow;
      }
    } catch (e, st) {
      return Failure(
        StorageError('Failed to void receiving ${id.value}: $e'),
        stackTrace: st,
      );
    }
  }

  @override
  Future<Result<List<ReceivingLineHistory>>> getItemReceivingHistory(
    ItemId itemId, {
    int limit = 10,
  }) async {
    try {
      await _ensureOpen();

      final rows = await _database.executor.runSelect(
        '''
        SELECT
          r.id as receiving_id,
          r.reference_number,
          r.received_at,
          r.supplier,
          l.quantity,
          l.unit_cost,
          l.line_total,
          l.unit_snapshot,
          l.new_base_selling_price
        FROM receiving_lines l
        INNER JOIN receivings r ON l.receiving_id = r.id
        WHERE l.store_id = ? AND l.item_id = ? AND r.status = 'completed'
        ORDER BY r.received_at DESC
        LIMIT ?;
        ''',
        [_storeId.value, itemId.value, limit],
      );

      final history = rows.map((r) {
        return ReceivingLineHistory(
          receivingId: ReceivingId(r['receiving_id'] as String),
          referenceNumber: r['reference_number'] as String,
          receivedAt: DateTime.parse(r['received_at'] as String),
          supplier: r['supplier'] as String?,
          quantity: (r['quantity'] as num).toDouble(),
          unitCost: (r['unit_cost'] as num).toDouble(),
          lineTotal: (r['line_total'] as num).toDouble(),
          unitSnapshot: r['unit_snapshot'] as String,
          newBaseSellingPrice:
              (r['new_base_selling_price'] as num?)?.toDouble(),
        );
      }).toList();

      return Success(history);
    } catch (e, st) {
      return Failure(
        StorageError(
          'Failed to get receiving history for item ${itemId.value}: $e',
        ),
        stackTrace: st,
      );
    }
  }

  @override
  Future<Result<String>> getNextReferenceNumber() async {
    try {
      await _ensureOpen();

      final rows = await _database.executor.runSelect(
        '''
        SELECT reference_number FROM receivings
        WHERE store_id = ?
        ORDER BY rowid DESC
        LIMIT 1;
        ''',
        [_storeId.value],
      );

      if (rows.isEmpty) {
        return const Success('REC-000001');
      }

      final lastRef = rows.first['reference_number'] as String;
      final numericPart = RegExp(r'\d+').firstMatch(lastRef)?.group(0);
      if (numericPart != null) {
        final nextNum = (int.tryParse(numericPart) ?? 0) + 1;
        final padded = nextNum.toString().padLeft(numericPart.length, '0');
        return Success('REC-$padded');
      }

      return const Success('REC-000001');
    } catch (e, st) {
      return Failure(
        StorageError('Failed to generate next reference number: $e'),
        stackTrace: st,
      );
    }
  }

  Future<List<ReceivingLine>> _fetchLinesForReceiving(
      String receivingId) async {
    final lineRows = await _database.executor.runSelect(
      '''
      SELECT * FROM receiving_lines
      WHERE receiving_id = ? AND store_id = ?
      ORDER BY rowid ASC;
      ''',
      [receivingId, _storeId.value],
    );

    return lineRows.map((lr) {
      return ReceivingLine(
        id: lr['id'] as String,
        receivingId: ReceivingId(lr['receiving_id'] as String),
        itemId: ItemId(lr['item_id'] as String),
        itemNameSnapshot: lr['item_name_snapshot'] as String,
        skuSnapshot: lr['sku_snapshot'] as String?,
        unitSnapshot: lr['unit_snapshot'] as String,
        quantity: (lr['quantity'] as num).toDouble(),
        unitCost: (lr['unit_cost'] as num).toDouble(),
        lineTotal: (lr['line_total'] as num).toDouble(),
        updateItemCost: (lr['update_item_cost'] as int) == 1,
        newBaseSellingPrice: (lr['new_base_selling_price'] as num?)?.toDouble(),
        newMinSellingPrice: (lr['new_min_selling_price'] as num?)?.toDouble(),
        updateItemPrice: (lr['update_item_price'] as int? ?? 0) == 1,
      );
    }).toList();
  }

  Future<void> _applyCompletedReceivingMutations(Receiving receiving) async {
    final now = DateTime.now().toUtc().toIso8601String();

    for (final line in receiving.lines) {
      // 1. Record stock movement audit entry in item_transactions
      final txId = const Uuid().v4();
      await _database.executor.runInsert(
        '''
        INSERT INTO item_transactions (
          id, store_id, item_id, type, quantity_delta,
          unit_cost, unit_price, reference_id, notes, created_at
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
        ''',
        [
          txId,
          _storeId.value,
          line.itemId.value,
          'RECEIVING',
          line.quantity,
          line.unitCost,
          line.newBaseSellingPrice,
          receiving.id.value,
          receiving.referenceNumber,
          receiving.receivedAt.toUtc().toIso8601String(),
        ],
      );

      // 2. Mutate item current inventory quantity and optionally cost price & selling price
      final updateFields = <String>['quantity = quantity + ?'];
      final updateParams = <Object?>[line.quantity];

      if (line.updateItemCost) {
        updateFields.add('cost_price = ?');
        updateParams.add(line.unitCost);
      }

      if (line.updateItemPrice && line.newBaseSellingPrice != null) {
        updateFields.add('base_selling_price = ?');
        updateParams.add(line.newBaseSellingPrice);
        if (line.newMinSellingPrice != null) {
          updateFields.add('min_selling_price = ?');
          updateParams.add(line.newMinSellingPrice);
        }
      }

      updateFields.add('updated_at = ?');
      updateParams.add(now);

      updateParams.add(line.itemId.value);
      updateParams.add(_storeId.value);

      await _database.executor.runUpdate(
        '''
        UPDATE items SET
          ${updateFields.join(', ')}
        WHERE id = ? AND store_id = ?;
        ''',
        updateParams,
      );
    }
  }
}

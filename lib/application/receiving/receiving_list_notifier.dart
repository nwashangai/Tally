import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/result/result.dart';
import '../../domain/item/item_query.dart';
import '../../domain/receiving/receiving.dart';
import '../../domain/receiving/receiving_id.dart';
import '../../domain/receiving/receiving_query.dart';
import '../../domain/receiving/receiving_repository.dart';

/// State notifier for querying, filtering, and managing the Receivings list.
class ReceivingListNotifier
    extends StateNotifier<AsyncValue<PaginatedResult<Receiving>>> {
  final ReceivingRepository _repository;
  ReceivingQuery _query;

  ReceivingListNotifier({
    required ReceivingRepository repository,
    ReceivingQuery initialQuery = const ReceivingQuery(),
  })  : _repository = repository,
        _query = initialQuery,
        super(const AsyncValue.loading()) {
    load();
  }

  ReceivingQuery get currentQuery => _query;

  Future<void> load() async {
    state = const AsyncValue.loading();
    final result = await _repository.query(_query);
    result.fold(
      onSuccess: (data) {
        state = AsyncValue.data(data);
      },
      onFailure: (err, st) {
        state = AsyncValue.error(err, st ?? StackTrace.current);
      },
    );
  }

  Future<void> updateQuery(ReceivingQuery query) async {
    _query = query;
    await load();
  }

  Future<void> refresh() async {
    await load();
  }

  Future<Result<Receiving>> voidReceiving(
    ReceivingId id, {
    String? reason,
  }) async {
    final result = await _repository.voidReceiving(id, reason: reason);
    if (result.isSuccess) {
      await refresh();
    }
    return result;
  }
}

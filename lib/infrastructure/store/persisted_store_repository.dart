import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../../core/error/app_error.dart';
import '../../core/result/result.dart';
import '../../domain/store/store.dart';
import '../../domain/store/store_id.dart';
import '../../domain/store/store_repository.dart';

/// Key used to persist the store catalog in SharedPreferences.
const String kPrefKeyStoresCatalog = 'tally_stores_catalog_v1';

/// Persistent implementation of [StoreRepository].
/// Persists the store metadata catalog to local persistent storage (SharedPreferences JSON)
/// and synchronizes with the physical `<docs>/tally/stores/` file directory.
class PersistedStoreRepository implements StoreRepository {
  final SharedPreferences _prefs;
  final String? _storesDirectoryPath;
  final Uuid _uuid;

  PersistedStoreRepository({
    required SharedPreferences prefs,
    String? storesDirectoryPath,
    Uuid? uuid,
  })  : _prefs = prefs,
        _storesDirectoryPath = storesDirectoryPath,
        _uuid = uuid ?? const Uuid();

  /// Loads all stored store entities from persistent storage.
  Map<StoreId, Store> _loadStoresFromPrefs() {
    final rawJson = _prefs.getString(kPrefKeyStoresCatalog);
    if (rawJson == null || rawJson.isEmpty) {
      return {};
    }

    try {
      final List<dynamic> decoded = jsonDecode(rawJson) as List<dynamic>;
      final Map<StoreId, Store> map = {};
      for (final item in decoded) {
        if (item is Map<String, dynamic>) {
          final store = Store.fromJson(item);
          map[store.id] = store;
        }
      }
      return map;
    } catch (_) {
      return {};
    }
  }

  /// Saves all store entities to persistent storage.
  Future<void> _saveStoresToPrefs(Map<StoreId, Store> stores) async {
    final list = stores.values.map((s) => s.toJson()).toList();
    final jsonString = jsonEncode(list);
    await _prefs.setString(kPrefKeyStoresCatalog, jsonString);
  }

  @override
  Future<Result<List<Store>>> getAccessibleStores(String userId) async {
    try {
      final stores = _loadStoresFromPrefs();

      // If stores directory path is provided, discover any orphan database files
      if (_storesDirectoryPath != null) {
        final dir = Directory(_storesDirectoryPath);
        if (await dir.exists()) {
          final entities = await dir.list().toList();
          for (final entity in entities) {
            if (entity is File && entity.path.endsWith('.db')) {
              final fileName = entity.uri.pathSegments.last;
              final storeIdValue = fileName.replaceAll('.db', '');
              final id = StoreId(storeIdValue);

              // If database exists on disk but not in catalog, register a recovered store
              if (!stores.containsKey(id)) {
                final recoveredStore = Store(
                  id: id,
                  name: 'Recovered Store ($storeIdValue)',
                  ownerId: userId,
                  createdAt: await entity.lastModified(),
                  updatedAt: await entity.lastModified(),
                );
                stores[id] = recoveredStore;
              }
            }
          }
          await _saveStoresToPrefs(stores);
        }
      }

      final accessible = stores.values
          .where((store) => store.ownerId == userId)
          .toList()
        ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

      return Success(accessible);
    } catch (e, st) {
      return Failure(
        StorageError('Failed to retrieve accessible stores: $e'),
        stackTrace: st,
      );
    }
  }

  @override
  Future<Result<Store?>> getStore(StoreId storeId) async {
    try {
      final stores = _loadStoresFromPrefs();
      return Success(stores[storeId]);
    } catch (e, st) {
      return Failure(
        StorageError('Failed to get store: $e'),
        stackTrace: st,
      );
    }
  }

  @override
  Future<Result<Store>> createStore({
    required String name,
    required String userId,
  }) async {
    try {
      final trimmedName = name.trim();
      if (trimmedName.isEmpty) {
        return const Failure(
          ValidationError('Store name cannot be empty.', field: 'name'),
        );
      }

      final stores = _loadStoresFromPrefs();
      final now = DateTime.now().toUtc();
      final store = Store(
        id: StoreId(_uuid.v4()),
        name: trimmedName,
        ownerId: userId,
        createdAt: now,
        updatedAt: now,
      );

      stores[store.id] = store;
      await _saveStoresToPrefs(stores);

      return Success(store);
    } catch (e, st) {
      return Failure(
        StorageError('Failed to create store: $e'),
        stackTrace: st,
      );
    }
  }

  @override
  Future<Result<Store>> updateStore(Store store) async {
    try {
      final stores = _loadStoresFromPrefs();
      if (!stores.containsKey(store.id)) {
        return Failure(
          NotFoundError('Store ${store.id.value} does not exist.'),
        );
      }

      final updated = store.copyWith(updatedAt: DateTime.now().toUtc());
      stores[store.id] = updated;
      await _saveStoresToPrefs(stores);

      return Success(updated);
    } catch (e, st) {
      return Failure(
        StorageError('Failed to update store: $e'),
        stackTrace: st,
      );
    }
  }

  @override
  Future<Result<void>> deleteStore(StoreId storeId) async {
    try {
      final stores = _loadStoresFromPrefs();
      stores.remove(storeId);
      await _saveStoresToPrefs(stores);
      return const Success(null);
    } catch (e, st) {
      return Failure(
        StorageError('Failed to delete store: $e'),
        stackTrace: st,
      );
    }
  }
}

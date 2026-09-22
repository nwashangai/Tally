import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../../core/error/app_error.dart';
import '../../core/result/result.dart';
import '../../domain/store/store_id.dart';
import '../../domain/store/store_snapshot.dart';
import '../../domain/store/store_storage.dart';

/// File-per-store local persistence adapter.
/// Each store is stored as a JSON file: `<documents>/tally/stores/<storeId>.json`.
/// Uses atomic write (write to temp → rename) to prevent corruption.
class FileStoreStorage implements StoreStorage {
  final String _baseDirectory;

  FileStoreStorage({required String baseDirectory})
      : _baseDirectory = baseDirectory;

  /// Convenience factory that resolves the application documents directory.
  static Future<FileStoreStorage> create() async {
    final dir = await getApplicationDocumentsDirectory();
    final storesDir = Directory('${dir.path}/tally/stores');
    await storesDir.create(recursive: true);
    return FileStoreStorage(baseDirectory: storesDir.path);
  }

  File _fileFor(StoreId storeId) =>
      File('$_baseDirectory/${storeId.value}.json');

  @override
  Future<Result<StoreSnapshot?>> readStore(StoreId storeId) async {
    try {
      final file = _fileFor(storeId);
      if (!await file.exists()) return const Success(null);
      final content = await file.readAsString();
      final json = jsonDecode(content) as Map<String, Object?>;
      final snapshot = StoreSnapshot.fromJson(json);
      if (!snapshot.verifyIntegrity()) {
        return Failure(
          CorruptDataError(
            'Checksum mismatch for store ${storeId.value}. File may be corrupt.',
          ),
        );
      }
      return Success(snapshot);
    } catch (e, st) {
      return Failure(StorageError('Failed to read store: $e'), stackTrace: st);
    }
  }

  @override
  Future<Result<void>> writeStore(StoreSnapshot snapshot) async {
    try {
      final file = _fileFor(snapshot.storeId);
      final content = jsonEncode(snapshot.toJson());
      // Atomic write: write to temp file then rename.
      final tempFile = File('${file.path}.tmp');
      await tempFile.writeAsString(content, flush: true);
      await tempFile.rename(file.path);
      return const Success(null);
    } catch (e, st) {
      return Failure(StorageError('Failed to write store: $e'), stackTrace: st);
    }
  }

  @override
  Future<Result<void>> deleteStore(StoreId storeId) async {
    try {
      final file = _fileFor(storeId);
      if (await file.exists()) await file.delete();
      return const Success(null);
    } catch (e, st) {
      return Failure(
        StorageError('Failed to delete store: $e'),
        stackTrace: st,
      );
    }
  }

  @override
  Future<Result<bool>> exists(StoreId storeId) async {
    try {
      return Success(await _fileFor(storeId).exists());
    } catch (e, st) {
      return Failure(
        StorageError('Failed to check store existence: $e'),
        stackTrace: st,
      );
    }
  }

  @override
  Future<Result<List<StoreId>>> listStoreIds() async {
    try {
      final dir = Directory(_baseDirectory);
      if (!await dir.exists()) return const Success([]);
      final ids = await dir
          .list()
          .where(
            (e) => e is File && e.path.endsWith('.json'),
          )
          .map((e) {
        final fileName = e.path.split(Platform.pathSeparator).last;
        return StoreId(fileName.replaceFirst('.json', ''));
      }).toList();
      return Success(ids);
    } catch (e, st) {
      return Failure(
        StorageError('Failed to list stores: $e'),
        stackTrace: st,
      );
    }
  }
}

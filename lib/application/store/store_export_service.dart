import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../../core/error/app_error.dart';
import '../../core/result/result.dart';
import '../../domain/store/store_database_manager.dart';
import '../../domain/store/store_id.dart';

/// Handles safe database checkpointing and physical `.db` file export.
class StoreExportService {
  final StoreDatabaseManager _dbManager;

  StoreExportService({required StoreDatabaseManager dbManager})
      : _dbManager = dbManager;

  /// Ensures WAL pages are safely flushed to disk, then creates a clean copy of the `.db` file.
  Future<Result<String>> exportStoreDatabase(StoreId storeId) async {
    try {
      // 1. Flush WAL checkpoint
      final checkpointResult = await _dbManager.checkpoint(storeId);
      if (checkpointResult.isFailure) {
        return Failure(checkpointResult.errorOrNull!);
      }

      // 2. Locate source database file
      final pathResult = await _dbManager.getDatabaseFilePath(storeId);
      if (pathResult.isFailure) {
        return Failure(pathResult.errorOrNull!);
      }
      final sourcePath = pathResult.valueOrNull!;
      final sourceFile = File(sourcePath);

      if (!await sourceFile.exists()) {
        return Failure(
          NotFoundError('Store database file does not exist at $sourcePath'),
        );
      }

      // 3. Create clean export copy in temp directory
      String exportBasePath;
      try {
        final temp = await getTemporaryDirectory();
        exportBasePath = temp.path;
      } catch (_) {
        exportBasePath = Directory.systemTemp.path;
      }

      final exportDir = Directory('$exportBasePath/tally_exports');
      if (!await exportDir.exists()) {
        await exportDir.create(recursive: true);
      }

      final exportFile = File(
        '${exportDir.path}/${storeId.value}_export_${DateTime.now().millisecondsSinceEpoch}.db',
      );
      await sourceFile.copy(exportFile.path);

      return Success(exportFile.path);
    } catch (e, st) {
      return Failure(
        StorageError('Failed to export store database: $e'),
        stackTrace: st,
      );
    }
  }
}

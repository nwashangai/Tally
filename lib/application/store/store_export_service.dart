import 'dart:io';
import 'dart:ui';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/error/app_error.dart';
import '../../core/result/result.dart';
import '../../domain/store/store_database_manager.dart';
import '../../domain/store/store_id.dart';
import '../../infrastructure/store/drift_store_database_manager.dart';

/// Handles safe database checkpointing, physical `.db` file export, and device backup sharing.
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

      // 4. If DriftStoreDatabaseManager, export portable database; otherwise copy file
      if (_dbManager is DriftStoreDatabaseManager) {
        final dbRes = await _dbManager.getOrOpenStoreDatabase(storeId);
        if (dbRes.isSuccess) {
          final db = dbRes.valueOrNull!;
          final exportRes = await db.exportToPlaintext(exportFile);
          if (exportRes.isSuccess) {
            return Success(exportFile.path);
          }
        }
      }

      await sourceFile.copy(exportFile.path);

      return Success(exportFile.path);
    } catch (e, st) {
      return Failure(
        StorageError('Failed to export store database: $e'),
        stackTrace: st,
      );
    }
  }

  /// Exports the store database to a safe file and opens the platform share/save sheet
  /// to back up the database locally to the user's device or preferred storage location.
  Future<Result<String>> backupStoreToDevice({
    required StoreId storeId,
    required String storeName,
    Rect? sharePositionOrigin,
  }) async {
    try {
      final exportResult = await exportStoreDatabase(storeId);
      if (exportResult.isFailure) {
        return exportResult;
      }

      final exportPath = exportResult.valueOrNull!;
      final now = DateTime.now();
      final dateSlug = DateFormat('yyyy-MM-dd_HHmm').format(now);
      final sanitizedName =
          storeName.replaceAll(RegExp(r'[^a-zA-Z0-9_\-]'), '_').trim();
      final backupFileName =
          'Tally_${sanitizedName.isEmpty ? "Store" : sanitizedName}_Backup_$dateSlug.db';

      // Copy to clean named backup file for sharing
      final sourceFile = File(exportPath);
      final namedBackupFile =
          File('${sourceFile.parent.path}/$backupFileName');
      if (namedBackupFile.path != exportPath) {
        await sourceFile.copy(namedBackupFile.path);
      }

      final xFile = XFile(
        namedBackupFile.path,
        mimeType: 'application/x-sqlite3',
        name: backupFileName,
      );

      final safeOrigin =
          (sharePositionOrigin != null && !sharePositionOrigin.isEmpty)
              ? sharePositionOrigin
              : const Rect.fromLTWH(0, 0, 300, 300);

      // ignore: deprecated_member_use
      await Share.shareXFiles(
        [xFile],
        subject: 'Tally Store Backup - $storeName',
        text: 'Tally SQLite database backup for $storeName ($dateSlug).',
        sharePositionOrigin: safeOrigin,
      );

      return Success(namedBackupFile.path);
    } catch (e, st) {
      return Failure(
        StorageError('Failed to backup store to device: $e'),
        stackTrace: st,
      );
    }
  }
}

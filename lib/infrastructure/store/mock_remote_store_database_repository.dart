import 'dart:io';
import 'package:crypto/crypto.dart';
import '../../core/error/app_error.dart';
import '../../core/result/result.dart';
import '../../domain/store/remote_store_database_metadata.dart';
import '../../domain/store/remote_store_database_repository.dart';
import '../../domain/store/store_id.dart';

/// Mock implementation of [RemoteStoreDatabaseRepository] for offline testing & development.
/// Simulates serverless cloud object storage for store database files.
class MockRemoteStoreDatabaseRepository
    implements RemoteStoreDatabaseRepository {
  final Map<StoreId, RemoteStoreDatabaseMetadata> _remoteMetadata = {};
  final Map<StoreId, List<int>> _remoteFiles = {};

  @override
  Future<Result<RemoteStoreDatabaseMetadata?>> getMetadata(
    StoreId storeId,
  ) async {
    return Success(_remoteMetadata[storeId]);
  }

  @override
  Future<Result<void>> upload({
    required StoreId storeId,
    required String localFilePath,
    required int revision,
  }) async {
    try {
      final file = File(localFilePath);
      if (!await file.exists()) {
        return Failure(
          NotFoundError('Local database file does not exist: $localFilePath'),
        );
      }

      final bytes = await file.readAsBytes();
      final checksum = sha256.convert(bytes).toString();

      _remoteFiles[storeId] = bytes;
      _remoteMetadata[storeId] = RemoteStoreDatabaseMetadata(
        storeId: storeId,
        revision: revision,
        fileSize: bytes.length,
        checksum: checksum,
        uploadedAt: DateTime.now().toUtc(),
        uploadedBy: 'authenticated_user',
      );

      return const Success(null);
    } catch (e, st) {
      return Failure(
        StorageError('Failed to upload store database: $e'),
        stackTrace: st,
      );
    }
  }

  @override
  Future<Result<void>> download({
    required StoreId storeId,
    required String destinationFilePath,
  }) async {
    try {
      final bytes = _remoteFiles[storeId];
      if (bytes == null) {
        return Failure(
          NotFoundError(
            'Remote database file not found for store ${storeId.value}',
          ),
        );
      }

      final destFile = File(destinationFilePath);
      if (!await destFile.parent.exists()) {
        await destFile.parent.create(recursive: true);
      }

      await destFile.writeAsBytes(bytes, flush: true);
      return const Success(null);
    } catch (e, st) {
      return Failure(
        StorageError('Failed to download store database: $e'),
        stackTrace: st,
      );
    }
  }
}

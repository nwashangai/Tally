import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:tally/domain/store/store_id.dart';
import 'package:tally/infrastructure/store/mock_remote_store_database_repository.dart';

void main() {
  group('MockRemoteStoreDatabaseRepository', () {
    late MockRemoteStoreDatabaseRepository remoteRepo;
    late Directory tempDir;
    const storeId = StoreId('store_remote_test');

    setUp(() async {
      remoteRepo = MockRemoteStoreDatabaseRepository();
      tempDir = await Directory.systemTemp.createTemp('tally_remote_test_');
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('upload and download roundtrip preserves file content', () async {
      final localFile = File('${tempDir.path}/original.db');
      await localFile.writeAsString('SQLITE_MOCK_CONTENT_ABC_123');

      final uploadResult = await remoteRepo.upload(
        storeId: storeId,
        localFilePath: localFile.path,
        revision: 1,
      );
      expect(uploadResult.isSuccess, isTrue);

      final metadata = await remoteRepo.getMetadata(storeId);
      expect(metadata.valueOrNull, isNotNull);
      expect(metadata.valueOrNull?.storeId, storeId);
      expect(metadata.valueOrNull?.revision, 1);

      final downloadDest = File('${tempDir.path}/downloaded.db');
      final downloadResult = await remoteRepo.download(
        storeId: storeId,
        destinationFilePath: downloadDest.path,
      );
      expect(downloadResult.isSuccess, isTrue);
      expect(await downloadDest.exists(), isTrue);
      expect(await downloadDest.readAsString(), 'SQLITE_MOCK_CONTENT_ABC_123');
    });

    test('downloading non-existent store returns failure', () async {
      final dest = '${tempDir.path}/missing.db';
      final result = await remoteRepo.download(
        storeId: const StoreId('non_existent'),
        destinationFilePath: dest,
      );
      expect(result.isFailure, isTrue);
    });
  });
}

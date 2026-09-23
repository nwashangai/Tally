import 'dart:io';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tally/application/store/store_export_service.dart';
import 'package:tally/domain/store/store_id.dart';
import 'package:tally/infrastructure/store/drift_store_database_manager.dart';
import 'package:tally/infrastructure/store/secure_storage_store_key_manager.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  FlutterSecureStorage.setMockInitialValues({});

  group('StoreExportService', () {
    late Directory tempDir;
    late DriftStoreDatabaseManager dbManager;
    late StoreExportService exportService;
    const storeId = StoreId('store_export_test');

    setUp(() async {
      FlutterSecureStorage.setMockInitialValues({});
      tempDir = await Directory.systemTemp.createTemp('tally_export_test_');
      final keyManager = SecureStorageStoreKeyManager();
      dbManager = DriftStoreDatabaseManager(
        baseDirectory: tempDir.path,
        keyManager: keyManager,
      );
      exportService = StoreExportService(dbManager: dbManager);
    });

    tearDown(() async {
      await dbManager.close(storeId);
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('exportStoreDatabase flushes checkpoint and creates verified copy',
        () async {
      await dbManager.create(storeId);

      final exportResult = await exportService.exportStoreDatabase(storeId);
      expect(exportResult.isSuccess, isTrue);

      final exportPath = exportResult.valueOrNull!;
      expect(File(exportPath).existsSync(), isTrue);
      expect(exportPath, contains('.db'));
    });
  });
}

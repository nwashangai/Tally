import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqlcipher_flutter_libs/sqlcipher_flutter_libs.dart';
import 'package:sqlite3/open.dart';
import '../app/providers/core_providers.dart';

/// Bootstraps the application before the root widget is inflated.

/// Keeps platform initialization, orientation locks, and service startup
/// out of [main.dart].
Future<ProviderContainer> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Configure SQLite FFI to load SQLCipher binaries on Android
  open.overrideFor(OperatingSystem.android, openCipherOnAndroid);

  // Lock mobile to portrait during scaffold phase (revisit in UX slice).
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  // Initialize SharedPreferences
  final prefs = await SharedPreferences.getInstance();

  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
    ],
  );

  // Kick off session restoration eagerly so the auth redirect resolves fast.
  final authRepo = container.read(authRepositoryProvider);
  final sessionResult = await authRepo.restoreSession();

  // If user is authenticated, discover accessible stores and restore active store
  if (sessionResult.isSuccess && sessionResult.valueOrNull != null) {
    final session = sessionResult.valueOrNull!;
    final storeRepo = container.read(storeRepositoryProvider);
    final storesResult = await storeRepo.getAccessibleStores(session.user.id);
    if (storesResult.isSuccess) {
      final accessibleStores = storesResult.valueOrNull ?? [];
      await container
          .read(currentStoreProvider.notifier)
          .restoreActiveStore(accessibleStores);
    }
  }

  return container;
}

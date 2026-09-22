import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../app/providers/core_providers.dart';

/// Bootstraps the application before the root widget is inflated.
/// Keeps platform initialization, orientation locks, and service startup
/// out of [main.dart].
Future<ProviderContainer> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock mobile to portrait during scaffold phase (revisit in UX slice).
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  final container = ProviderContainer();

  // Kick off session restoration eagerly so the auth redirect resolves fast.
  final authRepo = container.read(authRepositoryProvider);
  await authRepo.restoreSession();

  return container;
}

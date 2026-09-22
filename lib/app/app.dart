import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../app/router/app_router.dart';
import '../presentation/design_system/theme/tally_theme.dart';

/// Root Tally application widget.
/// Wires together the Riverpod container, GoRouter, and design themes.
class TallyApp extends ConsumerWidget {
  const TallyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'Tally',
      debugShowCheckedModeBanner: false,
      theme: TallyTheme.light,
      darkTheme: TallyTheme.dark,
      routerConfig: router,
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/providers/core_providers.dart';
import '../../application/navigation/store_module_registry.dart';
import '../../application/store/current_store_state.dart';
import '../design_system/tokens/colors.dart';
import '../design_system/tokens/dimensions.dart';
import '../settings/store_config_screen.dart';

/// Authenticated application shell for the active store.
/// Hosts responsive navigation (Bottom Navigation on mobile, Navigation Rail on desktop/tablet)
/// and dynamically mounts the active StoreModule.
class TallyShell extends ConsumerWidget {
  const TallyShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentStoreState = ref.watch(currentStoreProvider);
    final authRepo = ref.watch(authRepositoryProvider);
    final modules = ref.watch(storeModulesProvider);
    final selectedModuleId = ref.watch(selectedModuleIdProvider);

    if (currentStoreState is! StoreSelected) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: TallyColors.primaryNavy),
        ),
      );
    }

    final store = currentStoreState.store;

    // Find active module, fallback to first module if not found
    final activeModule = modules.firstWhere(
      (m) => m.id == selectedModuleId,
      orElse: () => modules.first,
    );

    final bottomNavModules = modules.where((m) => m.showInBottomNav).toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWideScreen = constraints.maxWidth >= 720;

        return Scaffold(
          backgroundColor: TallyColors.lightCanvas,
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  store.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  activeModule.label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: TallyColors.slateMuted,
                  ),
                ),
              ],
            ),
            actions: [
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                onSelected: (action) async {
                  switch (action) {
                    case 'switch_store':
                      await ref
                          .read(currentStoreProvider.notifier)
                          .clearStore();
                      break;
                    case 'config':
                      await Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const StoreConfigScreen(),
                        ),
                      );
                      break;
                    case 'backup_cloud':
                      await ref
                          .read(currentStoreProvider.notifier)
                          .triggerManualBackup();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Manual backup snapshot created.'),
                          ),
                        );
                      }
                      break;
                    case 'logout':
                      await ref
                          .read(currentStoreProvider.notifier)
                          .clearStore();
                      await authRepo.signOut();
                      break;
                  }
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: 'config',
                    child: Row(
                      children: [
                        Icon(Icons.tune,
                            size: 20, color: TallyColors.primaryNavy),
                        SizedBox(width: TallySpacing.sm),
                        Text('Database & Config'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'switch_store',
                    child: Row(
                      children: [
                        Icon(Icons.swap_horiz,
                            size: 20, color: TallyColors.primaryNavy),
                        SizedBox(width: TallySpacing.sm),
                        Text('Switch Store'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'backup_cloud',
                    child: Row(
                      children: [
                        Icon(Icons.cloud_upload_outlined,
                            size: 20, color: TallyColors.primaryNavy),
                        SizedBox(width: TallySpacing.sm),
                        Text('Manual Cloud Backup'),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                  const PopupMenuItem(
                    value: 'logout',
                    child: Row(
                      children: [
                        Icon(Icons.logout,
                            size: 20, color: TallyColors.stockCritical),
                        SizedBox(width: TallySpacing.sm),
                        Text(
                          'Sign Out',
                          style: TextStyle(color: TallyColors.stockCritical),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          body: isWideScreen
              ? Row(
                  children: [
                    NavigationRail(
                      selectedIndex: bottomNavModules
                          .indexWhere((m) => m.id == selectedModuleId)
                          .clamp(0, bottomNavModules.length - 1),
                      onDestinationSelected: (index) {
                        ref.read(selectedModuleIdProvider.notifier).state =
                            bottomNavModules[index].id;
                      },
                      labelType: NavigationRailLabelType.all,
                      destinations: [
                        for (final module in bottomNavModules)
                          NavigationRailDestination(
                            icon: Icon(module.icon),
                            selectedIcon:
                                Icon(module.selectedIcon ?? module.icon),
                            label: Text(module.label),
                          ),
                      ],
                    ),
                    const VerticalDivider(thickness: 1, width: 1),
                    Expanded(
                      child: activeModule.builder(context),
                    ),
                  ],
                )
              : activeModule.builder(context),
          bottomNavigationBar: isWideScreen
              ? null
              : NavigationBar(
                  selectedIndex: bottomNavModules
                      .indexWhere((m) => m.id == selectedModuleId)
                      .clamp(0, bottomNavModules.length - 1),
                  onDestinationSelected: (index) {
                    ref.read(selectedModuleIdProvider.notifier).state =
                        bottomNavModules[index].id;
                  },
                  backgroundColor: TallyColors.canvasWhite,
                  indicatorColor:
                      TallyColors.primaryNavy.withValues(alpha: 0.12),
                  destinations: [
                    for (final module in bottomNavModules)
                      NavigationDestination(
                        icon: Icon(module.icon),
                        selectedIcon: Icon(module.selectedIcon ?? module.icon),
                        label: module.label,
                      ),
                  ],
                ),
        );
      },
    );
  }
}

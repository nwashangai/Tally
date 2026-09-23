import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/providers/core_providers.dart';
import '../../application/store/current_store_state.dart';
import '../design_system/tokens/colors.dart';
import '../design_system/tokens/dimensions.dart';
import 'store_config_screen.dart';

/// Settings hub for the active store.
class StoreSettingsScreen extends ConsumerWidget {
  const StoreSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentStoreState = ref.watch(currentStoreProvider);
    final authRepo = ref.watch(authRepositoryProvider);

    if (currentStoreState is! StoreSelected) {
      return const Scaffold(
        body: Center(child: Text('No store selected')),
      );
    }

    final store = currentStoreState.store;

    return Scaffold(
      backgroundColor: TallyColors.lightCanvas,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(TallySpacing.xl),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header / Profile card
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(TallyRadii.lg),
                    side: const BorderSide(color: TallyColors.lightBorder),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(TallySpacing.lg),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: const BoxDecoration(
                            color: TallyColors.primaryNavy,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              store.name.isNotEmpty
                                  ? store.name[0].toUpperCase()
                                  : 'T',
                              style: const TextStyle(
                                color: TallyColors.canvasWhite,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: TallySpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                store.name,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: TallyColors.primaryNavy,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Store ID: ${store.id.value}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: TallyColors.slateMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: TallySpacing.xl),

                // Settings Navigation List
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(TallyRadii.lg),
                    side: const BorderSide(color: TallyColors.lightBorder),
                  ),
                  child: Column(
                    children: [
                      ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(TallySpacing.xs),
                          decoration: BoxDecoration(
                            color:
                                TallyColors.primaryNavy.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(TallyRadii.sm),
                          ),
                          child: const Icon(
                            Icons.storage_rounded,
                            color: TallyColors.primaryNavy,
                            size: 22,
                          ),
                        ),
                        title: const Text(
                          'Database & Storage Config',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: const Text(
                          'Inspect SQLite database path, encryption, WAL checkpoints & export',
                          style: TextStyle(fontSize: 12),
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => const StoreConfigScreen(),
                            ),
                          );
                        },
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(TallySpacing.xs),
                          decoration: BoxDecoration(
                            color:
                                const Color(0xFF0284C7).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(TallyRadii.sm),
                          ),
                          child: const Icon(
                            Icons.cloud_sync_outlined,
                            color: Color(0xFF0284C7),
                            size: 22,
                          ),
                        ),
                        title: const Text(
                          'Cloud Sync & Remote Backup',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: const Text(
                          'Trigger manual backup snapshot to remote storage',
                          style: TextStyle(fontSize: 12),
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () async {
                          final scaffoldMessenger =
                              ScaffoldMessenger.of(context);
                          await ref
                              .read(currentStoreProvider.notifier)
                              .triggerManualBackup();
                          scaffoldMessenger.showSnackBar(
                            const SnackBar(
                              content: Text('Backup snapshot created.'),
                            ),
                          );
                        },
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(TallySpacing.xs),
                          decoration: BoxDecoration(
                            color:
                                TallyColors.slateMuted.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(TallyRadii.sm),
                          ),
                          child: const Icon(
                            Icons.swap_horiz_rounded,
                            color: TallyColors.slateMuted,
                            size: 22,
                          ),
                        ),
                        title: const Text(
                          'Switch Store',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: const Text(
                          'Close current database and pick another store',
                          style: TextStyle(fontSize: 12),
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () async {
                          await ref
                              .read(currentStoreProvider.notifier)
                              .clearStore();
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: TallySpacing.xl),

                // Sign Out Button
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: TallyColors.stockCritical,
                    side: const BorderSide(color: TallyColors.stockCritical),
                    padding: const EdgeInsets.symmetric(
                      vertical: TallySpacing.md,
                      horizontal: TallySpacing.lg,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(TallyRadii.md),
                    ),
                  ),
                  icon: const Icon(Icons.logout),
                  label: const Text('Sign Out of Account'),
                  onPressed: () async {
                    await ref.read(currentStoreProvider.notifier).clearStore();
                    await authRepo.signOut();
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

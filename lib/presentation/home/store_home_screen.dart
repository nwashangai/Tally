import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/providers/core_providers.dart';
import '../../application/navigation/store_module_registry.dart';
import '../../application/store/current_store_state.dart';
import '../../domain/navigation/store_module.dart';
import '../design_system/tokens/colors.dart';
import '../design_system/tokens/dimensions.dart';
import '../settings/store_config_screen.dart';

/// Store Overview & Menu Dashboard.
/// Renders dynamic modular menu cards for all registered features.
class StoreHomeScreen extends ConsumerWidget {
  const StoreHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentStoreState = ref.watch(currentStoreProvider);
    final modules = ref.watch(storeModulesProvider);

    if (currentStoreState is! StoreSelected) {
      return const Scaffold(
        body: Center(child: Text('No store selected')),
      );
    }

    final store = currentStoreState.store;
    // Filter out 'home' itself from the menu card grid
    final menuModules =
        modules.where((m) => m.id != StoreModuleId.home).toList();

    return Scaffold(
      backgroundColor: TallyColors.lightCanvas,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(TallySpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Store Header Greeting Banner
              Container(
                padding: const EdgeInsets.all(TallySpacing.xl),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      TallyColors.primaryNavy,
                      Color(0xFF1E293B),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(TallyRadii.lg),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: TallySpacing.sm,
                            vertical: TallySpacing.xs,
                          ),
                          decoration: BoxDecoration(
                            color: TallyColors.varianceZeroLight
                                .withValues(alpha: 0.2),
                            borderRadius:
                                BorderRadius.circular(TallyRadii.full),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.lock_outline,
                                size: 12,
                                color: TallyColors.varianceZeroLight,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Encrypted Local DB',
                                style: TextStyle(
                                  color: TallyColors.varianceZeroLight,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        InkWell(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => const StoreConfigScreen(),
                              ),
                            );
                          },
                          borderRadius: BorderRadius.circular(TallyRadii.sm),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: TallySpacing.sm,
                              vertical: TallySpacing.xs,
                            ),
                            decoration: BoxDecoration(
                              color: TallyColors.canvasWhite
                                  .withValues(alpha: 0.12),
                              borderRadius:
                                  BorderRadius.circular(TallyRadii.sm),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.tune,
                                  size: 14,
                                  color: TallyColors.canvasWhite,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Config',
                                  style: TextStyle(
                                    color: TallyColors.canvasWhite,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: TallySpacing.md),
                    Text(
                      store.name,
                      style: const TextStyle(
                        color: TallyColors.canvasWhite,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Ready for inventory, sales, and ledger updates.',
                      style: TextStyle(
                        color: TallyColors.slateMuted,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: TallySpacing.xl),

              // Section Heading
              const Text(
                'Store Modules',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: TallyColors.primaryNavy,
                ),
              ),
              const SizedBox(height: TallySpacing.sm),
              const Text(
                'Select a module to manage sales, inventory, receivings, or reports.',
                style: TextStyle(
                  fontSize: 13,
                  color: TallyColors.slateMuted,
                ),
              ),
              const SizedBox(height: TallySpacing.lg),

              // Responsive Menu Grid
              LayoutBuilder(
                builder: (context, constraints) {
                  final crossAxisCount = constraints.maxWidth > 600 ? 3 : 2;
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: TallySpacing.md,
                      mainAxisSpacing: TallySpacing.md,
                      childAspectRatio: constraints.maxWidth > 600 ? 1.4 : 1.15,
                    ),
                    itemCount: menuModules.length,
                    itemBuilder: (context, index) {
                      final module = menuModules[index];
                      return _ModuleCard(
                        module: module,
                        onTap: () {
                          ref.read(selectedModuleIdProvider.notifier).state =
                              module.id;
                        },
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModuleCard extends StatelessWidget {
  final StoreModule module;
  final VoidCallback onTap;

  const _ModuleCard({
    required this.module,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final (accentColor, bgColor) = switch (module.id) {
      StoreModuleId.sales => (
          TallyColors.primaryNavy,
          TallyColors.primaryNavy.withValues(alpha: 0.08)
        ),
      StoreModuleId.items => (
          TallyColors.varianceZeroLight,
          TallyColors.varianceZeroLight.withValues(alpha: 0.1)
        ),
      StoreModuleId.receivings => (
          const Color(0xFF0284C7),
          const Color(0xFF0284C7).withValues(alpha: 0.1)
        ),
      StoreModuleId.reports => (
          const Color(0xFF8B5CF6),
          const Color(0xFF8B5CF6).withValues(alpha: 0.1)
        ),
      StoreModuleId.settings => (
          TallyColors.slateMuted,
          TallyColors.slateMuted.withValues(alpha: 0.1)
        ),
      _ => (
          TallyColors.primaryNavy,
          TallyColors.primaryNavy.withValues(alpha: 0.08)
        ),
    };

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(TallyRadii.lg),
        side: const BorderSide(color: TallyColors.lightBorder),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(TallyRadii.lg),
        child: Padding(
          padding: const EdgeInsets.all(TallySpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(TallySpacing.sm),
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: BorderRadius.circular(TallyRadii.md),
                    ),
                    child: Icon(module.icon, color: accentColor, size: 24),
                  ),
                  const Spacer(),
                  const Icon(
                    Icons.arrow_forward_rounded,
                    size: 16,
                    color: TallyColors.slateMuted,
                  ),
                ],
              ),
              const Spacer(),
              Text(
                module.label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: TallyColors.primaryNavy,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                module.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11,
                  color: TallyColors.slateMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

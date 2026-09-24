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
                  final isDesktopOrTablet = constraints.maxWidth >= 600;
                  final crossAxisCount = constraints.maxWidth >= 1024
                      ? 3
                      : (constraints.maxWidth >= 600 ? 3 : 2);
                  final childAspectRatio = constraints.maxWidth >= 1024
                      ? 1.25
                      : (constraints.maxWidth >= 600 ? 1.05 : 1.15);

                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: TallySpacing.lg,
                      mainAxisSpacing: TallySpacing.lg,
                      childAspectRatio: childAspectRatio,
                    ),
                    itemCount: menuModules.length,
                    itemBuilder: (context, index) {
                      final module = menuModules[index];
                      return _ModuleCard(
                        module: module,
                        isDesktopOrTablet: isDesktopOrTablet,
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

class _ModuleCardTheme {
  final Color cardBg;
  final Color borderColor;
  final Color iconBg;
  final Color iconColor;
  final Color titleColor;
  final Color descColor;

  const _ModuleCardTheme({
    required this.cardBg,
    required this.borderColor,
    required this.iconBg,
    required this.iconColor,
    required this.titleColor,
    required this.descColor,
  });

  static _ModuleCardTheme forModule(StoreModuleId id) {
    switch (id) {
      case StoreModuleId.sales:
        return const _ModuleCardTheme(
          cardBg: Color(0xFFEFF6FF), // Soft Azure/Blue tint
          borderColor: Color(0xFFBFDBFE),
          iconBg: Color(0xFFDBEAFE),
          iconColor: Color(0xFF1D4ED8),
          titleColor: TallyColors.primaryNavy,
          descColor: Color(0xFF475569),
        );
      case StoreModuleId.items:
        return const _ModuleCardTheme(
          cardBg: Color(0xFFECFDF5), // Soft Emerald/Mint tint
          borderColor: Color(0xFFA7F3D0),
          iconBg: Color(0xFFD1FAE5),
          iconColor: Color(0xFF059669),
          titleColor: TallyColors.primaryNavy,
          descColor: Color(0xFF475569),
        );
      case StoreModuleId.receivings:
        return const _ModuleCardTheme(
          cardBg: Color(0xFFFFFBEB), // Soft Amber tint
          borderColor: Color(0xFFFDE68A),
          iconBg: Color(0xFFFEF3C7),
          iconColor: Color(0xFFD97706),
          titleColor: TallyColors.primaryNavy,
          descColor: Color(0xFF475569),
        );
      case StoreModuleId.reports:
        return const _ModuleCardTheme(
          cardBg: Color(0xFFFAF5FF), // Soft Purple/Violet tint
          borderColor: Color(0xFFE9D5FF),
          iconBg: Color(0xFFF3E8FF),
          iconColor: Color(0xFF7C3AED),
          titleColor: TallyColors.primaryNavy,
          descColor: Color(0xFF475569),
        );
      case StoreModuleId.settings:
        return const _ModuleCardTheme(
          cardBg: Color(0xFFF8FAFC), // Soft Slate tint
          borderColor: Color(0xFFE2E8F0),
          iconBg: Color(0xFFF1F5F9),
          iconColor: Color(0xFF334155),
          titleColor: TallyColors.primaryNavy,
          descColor: Color(0xFF475569),
        );
      case StoreModuleId.home:
      case StoreModuleId.custom:
        return const _ModuleCardTheme(
          cardBg: Color(0xFFF0FDFA), // Soft Teal tint
          borderColor: Color(0xFF99F6E4),
          iconBg: Color(0xFFCCFBF1),
          iconColor: Color(0xFF0D9488),
          titleColor: TallyColors.primaryNavy,
          descColor: Color(0xFF475569),
        );
    }
  }
}

class _ModuleCard extends StatelessWidget {
  final StoreModule module;
  final bool isDesktopOrTablet;
  final VoidCallback onTap;

  const _ModuleCard({
    required this.module,
    required this.isDesktopOrTablet,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = _ModuleCardTheme.forModule(module.id);

    return Card(
      elevation: 0,
      color: theme.cardBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(TallyRadii.lg),
        side: BorderSide(color: theme.borderColor, width: 1.2),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(TallyRadii.lg),
        child: Padding(
          padding: EdgeInsets.all(
            isDesktopOrTablet ? TallySpacing.lg : TallySpacing.md,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: isDesktopOrTablet ? 64 : 48,
                height: isDesktopOrTablet ? 64 : 48,
                decoration: BoxDecoration(
                  color: theme.iconBg,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: theme.borderColor.withValues(alpha: 0.8),
                    width: 1.5,
                  ),
                ),
                child: Center(
                  child: Icon(
                    module.icon,
                    color: theme.iconColor,
                    size: isDesktopOrTablet ? 32 : 24,
                  ),
                ),
              ),
              SizedBox(
                height: isDesktopOrTablet ? TallySpacing.md : TallySpacing.sm,
              ),
              Text(
                module.label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: isDesktopOrTablet ? 17 : 15,
                  fontWeight: FontWeight.w700,
                  color: theme.titleColor,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                module.description,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: isDesktopOrTablet ? 12 : 11,
                  color: theme.descColor,
                  height: 1.25,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

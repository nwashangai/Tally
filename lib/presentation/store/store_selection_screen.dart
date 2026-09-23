import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/providers/core_providers.dart';
import '../../application/auth/auth_state_provider.dart';
import '../../application/store/current_store_state.dart';
import '../../application/store/store_list_notifier.dart';
import '../../domain/auth/auth_state.dart';
import '../design_system/tokens/colors.dart';
import '../design_system/tokens/dimensions.dart';

/// Store selection screen displayed after authentication.
/// Lists all stores accessible to the user and manages store activation.
class StoreSelectionScreen extends ConsumerStatefulWidget {
  const StoreSelectionScreen({super.key});

  @override
  ConsumerState<StoreSelectionScreen> createState() =>
      _StoreSelectionScreenState();
}

class _StoreSelectionScreenState extends ConsumerState<StoreSelectionScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadStores();
    });
  }

  void _loadStores() {
    final authState = ref.read(authStateProvider).valueOrNull;
    if (authState is AuthStateAuthenticated) {
      ref
          .read(storeListProvider.notifier)
          .loadStores(authState.session.user.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider).valueOrNull;
    final storesAsync = ref.watch(storeListProvider);
    final currentStoreState = ref.watch(currentStoreProvider);
    final authRepo = ref.watch(authRepositoryProvider);

    final user =
        authState is AuthStateAuthenticated ? authState.session.user : null;

    return Scaffold(
      backgroundColor: TallyColors.lightCanvas,
      appBar: AppBar(
        title: const Text(
          'Your Stores',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          if (user != null)
            Padding(
              padding: const EdgeInsets.only(right: TallySpacing.sm),
              child: PopupMenuButton<String>(
                icon: const Icon(Icons.account_circle_outlined),
                onSelected: (value) {
                  if (value == 'logout') {
                    authRepo.signOut();
                  }
                },
                itemBuilder: (_) => [
                  PopupMenuItem(
                    enabled: false,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.displayName ?? 'Merchant',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: TallyColors.primaryNavy,
                          ),
                        ),
                        Text(
                          user.email,
                          style: const TextStyle(
                            fontSize: 12,
                            color: TallyColors.slateMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                  const PopupMenuItem(
                    value: 'logout',
                    child: Row(
                      children: [
                        Icon(Icons.logout,
                            size: 18, color: TallyColors.stockCritical),
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
            ),
        ],
      ),
      body: SafeArea(
        child: storesAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: TallyColors.primaryNavy),
          ),
          error: (err, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(TallySpacing.xl),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 48,
                    color: TallyColors.stockCritical,
                  ),
                  const SizedBox(height: TallySpacing.md),
                  Text(
                    'Failed to load stores: $err',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: TallyColors.slateMuted),
                  ),
                  const SizedBox(height: TallySpacing.lg),
                  ElevatedButton(
                    onPressed: _loadStores,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
          data: (items) {
            if (items.isEmpty) {
              return _EmptyStoresView(
                onCreateTap: () => context.push('/stores/create'),
              );
            }

            return RefreshIndicator(
              onRefresh: () async => _loadStores(),
              child: ListView(
                padding: const EdgeInsets.all(TallySpacing.lg),
                children: [
                  const Text(
                    'Select a store to open its local encrypted database:',
                    style: TextStyle(
                      color: TallyColors.slateMuted,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: TallySpacing.lg),
                  ...items.map(
                    (item) => _StoreCard(
                      item: item,
                      isLoading: currentStoreState is SelectingStore &&
                          currentStoreState.store.id == item.store.id,
                      onTap: () {
                        if (item.localDbExists) {
                          ref
                              .read(currentStoreProvider.notifier)
                              .selectStore(item.store);
                        } else {
                          ref
                              .read(currentStoreProvider.notifier)
                              .downloadAndInstallStore(item.store);
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: TallySpacing.xxl),
                ],
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: TallyColors.primaryNavy,
        foregroundColor: TallyColors.iceFrost,
        icon: const Icon(Icons.add),
        label: const Text('New Store'),
        onPressed: () => context.push('/stores/create'),
      ),
    );
  }
}

class _EmptyStoresView extends StatelessWidget {
  final VoidCallback onCreateTap;

  const _EmptyStoresView({required this.onCreateTap});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(TallySpacing.xxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(TallySpacing.xl),
              decoration: const BoxDecoration(
                color: TallyColors.iceFrost,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.storefront_outlined,
                size: 64,
                color: TallyColors.primaryNavy,
              ),
            ),
            const SizedBox(height: TallySpacing.xl),
            const Text(
              "You don't have a store yet",
              style: TextStyle(
                color: TallyColors.primaryNavy,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: TallySpacing.sm),
            const Text(
              'Create your first store to set up its local encrypted database.',
              textAlign: TextAlign.center,
              style: TextStyle(color: TallyColors.slateMuted, fontSize: 14),
            ),
            const SizedBox(height: TallySpacing.xl),
            SizedBox(
              height: 48,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: TallyColors.primaryNavy,
                  foregroundColor: TallyColors.iceFrost,
                  padding: const EdgeInsets.symmetric(
                    horizontal: TallySpacing.xl,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(TallyRadii.md),
                  ),
                ),
                icon: const Icon(Icons.add),
                label: const Text(
                  'Create Store',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                onPressed: onCreateTap,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StoreCard extends StatelessWidget {
  final StoreItemState item;
  final bool isLoading;
  final VoidCallback onTap;

  const _StoreCard({
    required this.item,
    required this.isLoading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: TallySpacing.md),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(TallyRadii.lg),
        side: const BorderSide(color: TallyColors.lightBorder),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(TallyRadii.lg),
        onTap: isLoading ? null : onTap,
        child: Padding(
          padding: const EdgeInsets.all(TallySpacing.lg),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(TallySpacing.md),
                decoration: BoxDecoration(
                  color: TallyColors.iceFrost,
                  borderRadius: BorderRadius.circular(TallyRadii.md),
                ),
                child: const Icon(
                  Icons.store,
                  color: TallyColors.primaryNavy,
                  size: 28,
                ),
              ),
              const SizedBox(width: TallySpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.store.name,
                      style: const TextStyle(
                        color: TallyColors.primaryNavy,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: TallySpacing.xs),
                    Row(
                      children: [
                        if (item.localDbExists) ...[
                          const Icon(
                            Icons.lock_outline,
                            size: 14,
                            color: TallyColors.varianceZeroLight,
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            'Encrypted DB Ready',
                            style: TextStyle(
                              color: TallyColors.varianceZeroLight,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ] else ...[
                          const Icon(
                            Icons.cloud_download_outlined,
                            size: 14,
                            color: TallyColors.varianceDiscrepancy,
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            'Remote Only (Download Required)',
                            style: TextStyle(
                              color: TallyColors.varianceDiscrepancy,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              if (isLoading)
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: TallyColors.primaryNavy,
                  ),
                )
              else
                const Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: TallyColors.slateMuted,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

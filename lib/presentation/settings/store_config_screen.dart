import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/providers/core_providers.dart';
import '../../application/store/current_store_state.dart';
import '../../domain/sync/store_sync_state.dart';
import '../design_system/tokens/colors.dart';
import '../design_system/tokens/dimensions.dart';

/// Store Configuration & Database Details screen.
/// Moved from the store home page to provide dedicated database lifecycle controls.
class StoreConfigScreen extends ConsumerStatefulWidget {
  const StoreConfigScreen({super.key});

  @override
  ConsumerState<StoreConfigScreen> createState() => _StoreConfigScreenState();
}

class _StoreConfigScreenState extends ConsumerState<StoreConfigScreen> {
  bool _isCheckpointing = false;
  bool _isValidating = false;

  Future<void> _handleExport(StoreSelected storeState) async {
    final exportService = ref.read(storeExportServiceProvider);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    scaffoldMessenger.showSnackBar(
      const SnackBar(
        content: Text('Flushing WAL checkpoint and exporting database...'),
        duration: Duration(seconds: 1),
      ),
    );

    final result = await exportService.exportStoreDatabase(storeState.store.id);

    if (!mounted) return;

    if (result.isSuccess) {
      final exportPath = result.valueOrNull!;
      scaffoldMessenger.showSnackBar(
        SnackBar(
          backgroundColor: TallyColors.varianceZeroLight,
          content: Text('Database exported successfully to:\n$exportPath'),
          duration: const Duration(seconds: 4),
        ),
      );
    } else {
      final error = result.errorOrNull;
      scaffoldMessenger.showSnackBar(
        SnackBar(
          backgroundColor: TallyColors.stockCritical,
          content: Text('Export failed: ${error?.toString()}'),
        ),
      );
    }
  }

  Future<void> _handleCheckpoint(StoreSelected storeState) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    setState(() => _isCheckpointing = true);
    final dbManager = await ref.read(storeDatabaseManagerProvider.future);

    final result = await dbManager.checkpoint(storeState.store.id);
    if (!mounted) return;
    setState(() => _isCheckpointing = false);

    if (result.isSuccess) {
      scaffoldMessenger.showSnackBar(
        const SnackBar(
          backgroundColor: TallyColors.varianceZeroLight,
          content: Text('WAL Checkpoint completed successfully.'),
        ),
      );
    } else {
      scaffoldMessenger.showSnackBar(
        SnackBar(
          backgroundColor: TallyColors.stockCritical,
          content: Text('Checkpoint failed: ${result.errorOrNull}'),
        ),
      );
    }
  }

  Future<void> _handleValidateIntegrity(StoreSelected storeState) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    setState(() => _isValidating = true);
    final dbManager = await ref.read(storeDatabaseManagerProvider.future);

    final result = await dbManager.validateIntegrity(storeState.store.id);
    if (!mounted) return;
    setState(() => _isValidating = false);

    final isValid = result.valueOrNull ?? false;
    scaffoldMessenger.showSnackBar(
      SnackBar(
        backgroundColor:
            isValid ? TallyColors.varianceZeroLight : TallyColors.stockCritical,
        content: Text(
          isValid
              ? '✓ Database integrity verified. Encryption & SQLite tables intact.'
              : '✗ Database integrity check failed.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentStoreState = ref.watch(currentStoreProvider);

    if (currentStoreState is! StoreSelected) {
      return Scaffold(
        appBar: AppBar(title: const Text('Store Database & Config')),
        body: const Center(child: Text('No store selected')),
      );
    }

    final store = currentStoreState.store;
    final syncStatus = currentStoreState.syncStatus;

    return Scaffold(
      backgroundColor: TallyColors.lightCanvas,
      appBar: AppBar(
        title: const Text('Store Database & Config'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(TallySpacing.xl),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Active Store Database Card
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(TallyRadii.lg),
                    side: const BorderSide(color: TallyColors.lightBorder),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(TallySpacing.xl),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(TallySpacing.sm),
                              decoration: BoxDecoration(
                                color: TallyColors.varianceZeroLight
                                    .withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.lock,
                                color: TallyColors.varianceZeroLight,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: TallySpacing.sm),
                            const Text(
                              'Active Store Database',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: TallyColors.primaryNavy,
                              ),
                            ),
                            const Spacer(),
                            _SyncBadge(status: syncStatus),
                          ],
                        ),
                        const Divider(height: TallySpacing.xl),
                        _InfoRow(label: 'Store Name', value: store.name),
                        const SizedBox(height: TallySpacing.sm),
                        _InfoRow(label: 'Store ID', value: store.id.value),
                        const SizedBox(height: TallySpacing.sm),
                        _InfoRow(
                          label: 'Database File',
                          value: currentStoreState.dbPath,
                        ),
                        const SizedBox(height: TallySpacing.sm),
                        const _InfoRow(
                          label: 'Encryption',
                          value: 'SQLCipher AES-256 (Key in Secure Storage)',
                        ),
                        const SizedBox(height: TallySpacing.sm),
                        _InfoRow(
                          label: 'Created',
                          value: store.createdAt
                              .toLocal()
                              .toString()
                              .split('.')
                              .first,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: TallySpacing.xl),

                // Database Lifecycle & Health Actions Card
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(TallyRadii.lg),
                    side: const BorderSide(color: TallyColors.lightBorder),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(TallySpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Database Maintenance & Lifecycle',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: TallyColors.primaryNavy,
                          ),
                        ),
                        const SizedBox(height: TallySpacing.md),
                        ListTile(
                          leading: const Icon(Icons.verified_outlined,
                              color: TallyColors.primaryNavy),
                          title: const Text('Verify Database Integrity'),
                          subtitle: const Text(
                              'Tests decryption and query execution on local tables'),
                          trailing: _isValidating
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.chevron_right),
                          onTap: _isValidating
                              ? null
                              : () =>
                                  _handleValidateIntegrity(currentStoreState),
                        ),
                        const Divider(),
                        ListTile(
                          leading: const Icon(Icons.sync_outlined,
                              color: TallyColors.primaryNavy),
                          title: const Text('Run WAL Checkpoint'),
                          subtitle: const Text(
                              'Flushes memory WAL pages directly into main SQLite store'),
                          trailing: _isCheckpointing
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.chevron_right),
                          onTap: _isCheckpointing
                              ? null
                              : () => _handleCheckpoint(currentStoreState),
                        ),
                        const Divider(),
                        ListTile(
                          leading: const Icon(Icons.download_rounded,
                              color: TallyColors.primaryNavy),
                          title: const Text('Export Store Database (.db)'),
                          subtitle: const Text(
                              'Flushes WAL pages and creates a safe backup copy'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => _handleExport(currentStoreState),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: TallyColors.slateMuted,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: TallyColors.primaryNavy,
            ),
          ),
        ),
      ],
    );
  }
}

class _SyncBadge extends StatelessWidget {
  final SyncStatus status;

  const _SyncBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (color, label) = switch (status) {
      SyncStatus.local => (TallyColors.slateMuted, 'Local Only'),
      SyncStatus.pending => (TallyColors.varianceDiscrepancy, 'Pending Sync'),
      SyncStatus.syncing => (TallyColors.varianceDiscrepancy, 'Syncing...'),
      SyncStatus.synced => (TallyColors.varianceZeroLight, 'Synced'),
      SyncStatus.offline => (TallyColors.slateMuted, 'Offline'),
      SyncStatus.conflict => (TallyColors.stockCritical, 'Conflict'),
      SyncStatus.error => (TallyColors.stockCritical, 'Error'),
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: TallySpacing.sm,
        vertical: TallySpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(TallyRadii.full),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

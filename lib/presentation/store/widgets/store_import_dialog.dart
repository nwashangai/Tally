import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/providers/core_providers.dart';
import '../../../application/auth/auth_state_provider.dart';
import '../../../domain/auth/auth_state.dart';
import '../../design_system/tokens/colors.dart';
import '../../design_system/tokens/dimensions.dart';
import '../../design_system/widgets/tally_cancel_button.dart';

/// Modal dialog for importing a store from local backup files (.db, .tally)
/// or reviewing online / cloud backup capabilities.
class StoreImportDialog extends ConsumerStatefulWidget {
  const StoreImportDialog({super.key});

  @override
  ConsumerState<StoreImportDialog> createState() => _StoreImportDialogState();
}

class _StoreImportDialogState extends ConsumerState<StoreImportDialog> {
  int _selectedTabIndex = 0; // 0 = Local Backup, 1 = Online / Cloud Backup

  // Local backup state
  PlatformFile? _pickedFile;
  List<int>? _fileBytes;
  late final TextEditingController _nameController;
  bool _isPicking = false;
  bool _isImporting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickBackupFile() async {
    setState(() {
      _isPicking = true;
      _errorMessage = null;
    });

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        withData: true,
      );

      if (result == null || result.files.isEmpty) {
        setState(() => _isPicking = false);
        return;
      }

      final file = result.files.first;
      List<int>? bytes = file.bytes;

      if ((bytes == null || bytes.isEmpty) && file.path != null) {
        try {
          bytes = await File(file.path!).readAsBytes();
        } catch (_) {}
      }

      if (bytes == null || bytes.isEmpty) {
        setState(() {
          _errorMessage =
              'Could not read backup file data. Please try selecting the file again.';
          _isPicking = false;
        });
        return;
      }

      final ext = file.extension?.toLowerCase() ??
          (file.name.contains('.') ? file.name.split('.').last.toLowerCase() : '');
      const validExtensions = ['db', 'sqlite', 'tally', 'sqlite3', ''];
      if (!validExtensions.contains(ext)) {
        setState(() {
          _errorMessage =
              'Selected file ".$ext" is not a supported database backup. Please select a .db, .sqlite, or .tally file.';
          _isPicking = false;
        });
        return;
      }

      // Pre-fill store name from file name if name input is empty
      final derivedName = file.name
          .replaceAll(
              RegExp(r'\.(db|sqlite|tally|sqlite3)$', caseSensitive: false), '')
          .replaceAll(RegExp(r'^(Tally|Backup)_', caseSensitive: false), '')
          .replaceAll(RegExp(r'_export_\d+$'), '')
          .replaceAll('_', ' ')
          .trim();

      if (_nameController.text.trim().isEmpty && derivedName.isNotEmpty) {
        _nameController.text = derivedName;
      }

      setState(() {
        _pickedFile = file;
        _fileBytes = bytes;
        _isPicking = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error picking file: $e';
        _isPicking = false;
      });
    }
  }

  Future<void> _handleImport() async {
    final bytes = _fileBytes;
    final file = _pickedFile;
    if (bytes == null || file == null) return;

    final storeName = _nameController.text.trim();
    if (storeName.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter a name for the imported store.';
      });
      return;
    }

    final authState = ref.read(authStateProvider).valueOrNull;
    if (authState is! AuthStateAuthenticated) {
      setState(() {
        _errorMessage = 'User session expired. Please sign in again.';
      });
      return;
    }

    setState(() {
      _isImporting = true;
      _errorMessage = null;
    });

    final result = await ref.read(storeListProvider.notifier).importStoreFromBackup(
          fileBytes: bytes,
          fileName: file.name,
          userId: authState.session.user.id,
          storeName: storeName,
        );

    if (!mounted) return;

    if (result.isSuccess) {
      final store = result.valueOrNull!;
      Navigator.of(context).pop(store);
    } else {
      setState(() {
        _isImporting = false;
        _errorMessage = result.errorMessageOrNull ??
            'Failed to import store. Please ensure the file is a valid Tally backup.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      titlePadding: const EdgeInsets.fromLTRB(
        TallySpacing.xl,
        TallySpacing.xl,
        TallySpacing.xl,
        TallySpacing.md,
      ),
      contentPadding: const EdgeInsets.fromLTRB(
        TallySpacing.xl,
        0,
        TallySpacing.xl,
        TallySpacing.md,
      ),
      actionsPadding: const EdgeInsets.all(TallySpacing.lg),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(TallySpacing.xs),
            decoration: BoxDecoration(
              color: TallyColors.iceFrost,
              borderRadius: BorderRadius.circular(TallyRadii.md),
            ),
            child: const Icon(
              Icons.file_download_outlined,
              color: TallyColors.primaryNavy,
              size: 22,
            ),
          ),
          const SizedBox(width: TallySpacing.sm),
          const Expanded(
            child: Text(
              'Import Store Backup',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: TallyColors.primaryNavy,
              ),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Tab Selector
              Container(
                decoration: BoxDecoration(
                  color: TallyColors.slateMuted.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(TallyRadii.md),
                ),
                padding: const EdgeInsets.all(3),
                child: Row(
                  children: [
                    Expanded(
                      child: _TabButton(
                        title: 'Local Backup File',
                        icon: Icons.folder_open_outlined,
                        isSelected: _selectedTabIndex == 0,
                        onTap: () => setState(() => _selectedTabIndex = 0),
                      ),
                    ),
                    Expanded(
                      child: _TabButton(
                        title: 'Online / Cloud Backup',
                        icon: Icons.cloud_sync_outlined,
                        isSelected: _selectedTabIndex == 1,
                        onTap: () => setState(() => _selectedTabIndex = 1),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: TallySpacing.lg),

              // Tab Content
              if (_selectedTabIndex == 0)
                _buildLocalBackupView()
              else
                _buildOnlineBackupView(),
            ],
          ),
        ),
      ),
      actions: _selectedTabIndex == 0
          ? [
              TallyCancelButton(
                onPressed: (_isPicking || _isImporting)
                    ? null
                    : () => Navigator.of(context).pop(),
              ),
              ElevatedButton.icon(
                onPressed: (_isPicking ||
                        _isImporting ||
                        _fileBytes == null ||
                        _nameController.text.trim().isEmpty)
                    ? null
                    : _handleImport,
                icon: _isImporting
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.file_download, size: 18),
                label: Text(_isImporting ? 'Importing...' : 'Import Store'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: TallyColors.primaryNavy,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: TallySpacing.lg,
                    vertical: TallySpacing.md,
                  ),
                  shape: const StadiumBorder(),
                ),
              ),
            ]
          : [
              TallyCancelButton(
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
    );
  }

  Widget _buildLocalBackupView() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Select a Tally database backup file (.db or .tally) to restore it as a store on this device.',
          style: TextStyle(
            fontSize: 13,
            color: TallyColors.slateMuted,
          ),
        ),
        const SizedBox(height: TallySpacing.md),

        // File dropzone
        InkWell(
          onTap: (_isPicking || _isImporting) ? null : _pickBackupFile,
          borderRadius: BorderRadius.circular(TallyRadii.lg),
          child: Container(
            padding: const EdgeInsets.all(TallySpacing.lg),
            decoration: BoxDecoration(
              color: TallyColors.iceFrost.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(TallyRadii.lg),
              border: Border.all(
                color: _pickedFile != null
                    ? TallyColors.varianceZeroLight
                    : TallyColors.primaryNavy.withValues(alpha: 0.3),
                width: 1.5,
              ),
            ),
            child: Column(
              children: [
                if (_isPicking) ...[
                  const SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  ),
                  const SizedBox(height: TallySpacing.sm),
                  const Text(
                    'Reading backup file...',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: TallyColors.primaryNavy,
                    ),
                  ),
                ] else if (_pickedFile != null) ...[
                  const Icon(
                    Icons.check_circle_outline,
                    size: 36,
                    color: TallyColors.varianceZeroLight,
                  ),
                  const SizedBox(height: TallySpacing.xs),
                  Text(
                    _pickedFile!.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: TallyColors.primaryNavy,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${(_pickedFile!.size / 1024).toStringAsFixed(1)} KB • Tap to choose another file',
                    style: const TextStyle(
                      fontSize: 12,
                      color: TallyColors.slateMuted,
                    ),
                  ),
                ] else ...[
                  const Icon(
                    Icons.upload_file_outlined,
                    size: 36,
                    color: TallyColors.primaryNavy,
                  ),
                  const SizedBox(height: TallySpacing.sm),
                  const Text(
                    'Tap to select backup file',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: TallyColors.primaryNavy,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Supports .db, .sqlite, and .tally database files',
                    style: TextStyle(
                      fontSize: 12,
                      color: TallyColors.slateMuted,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),

        const SizedBox(height: TallySpacing.md),

        // Store Name input field
        TextField(
          controller: _nameController,
          enabled: !_isImporting,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            labelText: 'Store Name',
            hintText: 'e.g. Downtown Grocery',
            prefixIcon: const Icon(Icons.storefront_outlined, size: 20),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(TallyRadii.md),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: TallySpacing.md,
              vertical: TallySpacing.md,
            ),
          ),
        ),

        if (_errorMessage != null) ...[
          const SizedBox(height: TallySpacing.sm),
          Container(
            padding: const EdgeInsets.all(TallySpacing.sm),
            decoration: BoxDecoration(
              color: TallyColors.stockCritical.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(TallyRadii.md),
              border: Border.all(
                color: TallyColors.stockCritical.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 16,
                  color: TallyColors.stockCritical,
                ),
                const SizedBox(width: TallySpacing.xs),
                Expanded(
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: TallyColors.stockCritical,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildOnlineBackupView() {
    return Container(
      padding: const EdgeInsets.all(TallySpacing.lg),
      decoration: BoxDecoration(
        color: const Color(0xFF0284C7).withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(TallyRadii.lg),
        border: Border.all(
          color: const Color(0xFF0284C7).withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(TallySpacing.xs),
                decoration: BoxDecoration(
                  color: const Color(0xFF0284C7).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.cloud_sync,
                  color: Color(0xFF0284C7),
                  size: 24,
                ),
              ),
              const SizedBox(width: TallySpacing.sm),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cloud Backup & Sync',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: TallyColors.primaryNavy,
                      ),
                    ),
                    Text(
                      'Coming Soon in next update',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0284C7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: TallySpacing.md),
          const Text(
            'Remote backup and automatic multi-device synchronization will be available once the remote backup service is activated. In the meantime, you can easily transfer stores across devices using the Local Backup (.db) file option.',
            style: TextStyle(
              fontSize: 13,
              color: TallyColors.slateMuted,
              height: 1.4,
            ),
          ),
          const SizedBox(height: TallySpacing.md),
          const _FeaturePill(text: 'End-to-End Encrypted Snapshots'),
          const SizedBox(height: 4),
          const _FeaturePill(text: 'Multi-Device Instant Sync'),
          const SizedBox(height: 4),
          const _FeaturePill(text: 'Automated Daily Cloud Backups'),
        ],
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _TabButton({
    required this.title,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(TallyRadii.sm),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: TallySpacing.sm),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(TallyRadii.sm),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected
                  ? TallyColors.primaryNavy
                  : TallyColors.slateMuted,
            ),
            const SizedBox(width: TallySpacing.xs),
            Flexible(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected
                      ? TallyColors.primaryNavy
                      : TallyColors.slateMuted,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeaturePill extends StatelessWidget {
  final String text;

  const _FeaturePill({required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(
          Icons.check_circle_rounded,
          size: 14,
          color: Color(0xFF0284C7),
        ),
        const SizedBox(width: TallySpacing.xs),
        Text(
          text,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: TallyColors.primaryNavy,
          ),
        ),
      ],
    );
  }
}

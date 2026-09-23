import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/providers/core_providers.dart';
import '../../application/auth/auth_state_provider.dart';
import '../../domain/auth/auth_state.dart';
import '../design_system/tokens/colors.dart';
import '../design_system/tokens/dimensions.dart';

/// Screen allowing the authenticated merchant to create a new store
/// and initialize its local encrypted database file.
class CreateStoreScreen extends ConsumerStatefulWidget {
  const CreateStoreScreen({super.key});

  @override
  ConsumerState<CreateStoreScreen> createState() => _CreateStoreScreenState();
}

class _CreateStoreScreenState extends ConsumerState<CreateStoreScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final authState = ref.read(authStateProvider).valueOrNull;
    if (authState is! AuthStateAuthenticated) {
      setState(
          () => _errorMessage = 'Authentication session lost. Please log in.');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final userId = authState.session.user.id;
    final storeName = _nameController.text.trim();

    final createResult = await ref
        .read(storeListProvider.notifier)
        .createStore(name: storeName, userId: userId);

    if (!mounted) return;

    if (createResult.isSuccess) {
      final newStore = createResult.valueOrNull!;
      // Immediately open and activate the newly created store database
      await ref.read(currentStoreProvider.notifier).selectStore(newStore);
      if (mounted) {
        context.go('/home');
      }
    } else {
      final error = createResult.errorOrNull;
      setState(() {
        _isSubmitting = false;
        _errorMessage = error != null
            ? error.toString()
            : 'Failed to create store and initialize database.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(authStateProvider);
    return Scaffold(
      backgroundColor: TallyColors.lightCanvas,
      appBar: AppBar(
        title: const Text('Create New Store'),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(TallySpacing.xl),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Icon Header
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(TallySpacing.lg),
                        decoration: const BoxDecoration(
                          color: TallyColors.iceFrost,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.add_business_outlined,
                          size: 48,
                          color: TallyColors.primaryNavy,
                        ),
                      ),
                    ),
                    const SizedBox(height: TallySpacing.lg),
                    const Center(
                      child: Text(
                        'Set Up Your Store',
                        style: TextStyle(
                          color: TallyColors.primaryNavy,
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: TallySpacing.sm),
                    const Center(
                      child: Text(
                        'Each store owns an isolated, encrypted database file on this device.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: TallyColors.slateMuted, fontSize: 13),
                      ),
                    ),
                    const SizedBox(height: TallySpacing.xl),

                    if (_errorMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.all(TallySpacing.md),
                        decoration: BoxDecoration(
                          color:
                              TallyColors.stockCritical.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(TallyRadii.md),
                          border: Border.all(
                            color: TallyColors.stockCritical
                                .withValues(alpha: 0.4),
                          ),
                        ),
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(
                            color: TallyColors.stockCritical,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      const SizedBox(height: TallySpacing.lg),
                    ],

                    // Store Name Field
                    TextFormField(
                      controller: _nameController,
                      enabled: !_isSubmitting,
                      autofocus: true,
                      decoration: InputDecoration(
                        labelText: 'Store Name',
                        hintText: 'e.g. Main Street Warehouse, Downtown Kiosk',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(TallyRadii.md),
                        ),
                        prefixIcon: const Icon(Icons.storefront),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Please enter a store name';
                        }
                        if (val.trim().length < 2) {
                          return 'Store name must be at least 2 characters';
                        }
                        return null;
                      },
                      onFieldSubmitted: (_) => _handleSubmit(),
                    ),
                    const SizedBox(height: TallySpacing.lg),

                    // Security / Offline explanation card
                    Container(
                      padding: const EdgeInsets.all(TallySpacing.md),
                      decoration: BoxDecoration(
                        color: TallyColors.canvasWhite,
                        borderRadius: BorderRadius.circular(TallyRadii.md),
                        border: Border.all(color: TallyColors.lightBorder),
                      ),
                      child: const Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.shield_outlined,
                            size: 20,
                            color: TallyColors.varianceZeroLight,
                          ),
                          SizedBox(width: TallySpacing.sm),
                          Expanded(
                            child: Text(
                              'Your database is encrypted with SQLCipher (256-bit AES). '
                              'It works 100% offline and can be exported at any time.',
                              style: TextStyle(
                                color: TallyColors.slateMuted,
                                fontSize: 12,
                                height: 1.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: TallySpacing.xl),

                    // Submit Button
                    SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: TallyColors.primaryNavy,
                          foregroundColor: TallyColors.iceFrost,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(TallyRadii.md),
                          ),
                        ),
                        onPressed: _isSubmitting ? null : _handleSubmit,
                        child: _isSubmitting
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: TallyColors.iceFrost,
                                ),
                              )
                            : const Text(
                                'Create & Open Store',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

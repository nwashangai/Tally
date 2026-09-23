import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/providers/core_providers.dart';
import '../../core/result/result.dart';
import '../../domain/auth/auth_session.dart';
import '../design_system/tokens/colors.dart';
import '../design_system/tokens/dimensions.dart';
import '../design_system/widgets/tally_logo.dart';

/// Full branded sign-in screen supporting Google, Apple, and Facebook authentication.
class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _handleSignIn(
      Future<Result<AuthSession>> Function() action) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await action();
    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (result.isFailure) {
      final error = result.errorOrNull;
      setState(() {
        _errorMessage = error != null ? error.toString() : 'Sign in failed.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authRepo = ref.watch(authRepositoryProvider);

    return Scaffold(
      backgroundColor: TallyColors.primaryNavy,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: TallySpacing.xl,
              vertical: TallySpacing.xxl,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo / Header
                  const Center(
                    child: TallyLogo(
                      size: 52,
                      variant: TallyLogoVariant.fullWordmark,
                      showGlow: true,
                    ),
                  ),
                  const SizedBox(height: TallySpacing.md),
                  const Center(
                    child: Text(
                      'Small-Business Inventory & Stock Balancing',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: TallyColors.slateMuted,
                        fontSize: 14,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                  const SizedBox(height: TallySpacing.xxl),

                  if (_errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(TallySpacing.md),
                      decoration: BoxDecoration(
                        color:
                            TallyColors.stockCritical.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(TallyRadii.md),
                        border: Border.all(
                          color:
                              TallyColors.stockCritical.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(
                          color: TallyColors.stockCritical,
                          fontSize: 13,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: TallySpacing.lg),
                  ],

                  if (_isLoading)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(TallySpacing.lg),
                        child: CircularProgressIndicator(
                          color: TallyColors.iceFrost,
                        ),
                      ),
                    )
                  else ...[
                    // Google Sign-In Button
                    _SocialSignInButton(
                      icon: Icons.g_mobiledata_rounded,
                      iconSize: 32,
                      label: 'Continue with Google',
                      backgroundColor: TallyColors.canvasWhite,
                      foregroundColor: TallyColors.primaryNavy,
                      onPressed: () => _handleSignIn(authRepo.signInWithGoogle),
                    ),
                    const SizedBox(height: TallySpacing.md),

                    // Apple Sign-In Button
                    _SocialSignInButton(
                      icon: Icons.apple,
                      iconSize: 26,
                      label: 'Continue with Apple',
                      backgroundColor: Colors.black,
                      foregroundColor: TallyColors.canvasWhite,
                      onPressed: () => _handleSignIn(authRepo.signInWithApple),
                    ),
                    const SizedBox(height: TallySpacing.md),

                    // Facebook Sign-In Button
                    _SocialSignInButton(
                      icon: Icons.facebook,
                      iconSize: 26,
                      label: 'Continue with Facebook',
                      backgroundColor: const Color(0xFF1877F2),
                      foregroundColor: TallyColors.canvasWhite,
                      onPressed: () =>
                          _handleSignIn(authRepo.signInWithFacebook),
                    ),
                  ],

                  const SizedBox(height: TallySpacing.xxl),
                  const Center(
                    child: Text(
                      'Your stores & data are stored locally in an encrypted database.\nOnline accounts are used only for cloud sync.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: TallyColors.slateMuted,
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SocialSignInButton extends StatelessWidget {
  final IconData icon;
  final double iconSize;
  final String label;
  final Color backgroundColor;
  final Color foregroundColor;
  final VoidCallback onPressed;

  const _SocialSignInButton({
    required this.icon,
    required this.iconSize,
    required this.label,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52, // Compliance with >= 48dp touch target
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(TallyRadii.md),
          ),
          padding: const EdgeInsets.symmetric(horizontal: TallySpacing.lg),
        ),
        onPressed: onPressed,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: iconSize, color: foregroundColor),
            const SizedBox(width: TallySpacing.sm),
            Text(
              label,
              style: TextStyle(
                color: foregroundColor,
                fontSize: 15,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

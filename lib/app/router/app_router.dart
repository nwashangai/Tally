import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/auth/auth_state_provider.dart';
import '../../domain/auth/auth_state.dart';
import '../../presentation/shell/tally_shell.dart';
import '../../presentation/shell/splash_screen.dart';
import '../../presentation/auth/sign_in_screen.dart';

/// Route names as string constants to avoid hardcoded path strings in the UI.
abstract final class TallyRoutes {
  static const splash = '/';
  static const signIn = '/sign-in';
  static const home = '/home';
}

/// Tally router provider — observes auth state to drive redirects.
final appRouterProvider = Provider<GoRouter>((ref) {
  final authNotifier = _AuthChangeNotifier(ref);
  ref.onDispose(authNotifier.dispose);

  return GoRouter(
    debugLogDiagnostics: true,
    initialLocation: TallyRoutes.splash,
    refreshListenable: authNotifier,
    redirect: (context, state) {
      final authState = ref.read(authStateProvider).valueOrNull;
      final isAuthenticated = authState is AuthStateAuthenticated;
      final isLoading = authState == null ||
          authState is AuthStateLoading ||
          authState is AuthStateInitial;
      final isSignIn = state.matchedLocation == TallyRoutes.signIn;
      final isSplash = state.matchedLocation == TallyRoutes.splash;

      if (isLoading) return isSplash ? null : TallyRoutes.splash;
      if (!isAuthenticated && !isSignIn) return TallyRoutes.signIn;
      if (isAuthenticated && (isSignIn || isSplash)) return TallyRoutes.home;
      return null;
    },
    routes: [
      GoRoute(
        path: TallyRoutes.splash,
        builder: (_, __) => const SplashScreen(),
      ),
      GoRoute(
        path: TallyRoutes.signIn,
        builder: (_, __) => const SignInScreen(),
      ),
      GoRoute(
        path: TallyRoutes.home,
        builder: (_, __) => const TallyShell(),
      ),
    ],
  );
});

/// A [ChangeNotifier] that triggers GoRouter refresh whenever auth state changes.
class _AuthChangeNotifier extends ChangeNotifier {
  late final ProviderSubscription<AsyncValue<AuthState>> _subscription;

  _AuthChangeNotifier(Ref ref) {
    _subscription = ref.listen(authStateProvider, (_, __) => notifyListeners());
  }

  @override
  void dispose() {
    _subscription.close();
    super.dispose();
  }
}

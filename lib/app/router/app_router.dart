import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../application/auth/auth_state_provider.dart';
import '../../application/splash/splash_state_provider.dart';
import '../../application/store/current_store_state.dart';
import '../../domain/auth/auth_state.dart';
import '../../presentation/auth/sign_in_screen.dart';
import '../../presentation/shell/splash_screen.dart';
import '../../presentation/shell/tally_shell.dart';
import '../../presentation/store/create_store_screen.dart';
import '../../presentation/store/store_selection_screen.dart';
import '../providers/core_providers.dart';

/// Centralized route constants.
abstract final class TallyRoutes {
  static const splash = '/';
  static const signIn = '/sign-in';
  static const stores = '/stores';
  static const createStore = '/stores/create';
  static const home = '/home';
}

/// Tally router provider — observes auth state and active store context.
final appRouterProvider = Provider<GoRouter>((ref) {
  final navNotifier = _NavigationChangeNotifier(ref);
  ref.onDispose(navNotifier.dispose);

  return GoRouter(
    debugLogDiagnostics: false,
    initialLocation: TallyRoutes.splash,
    refreshListenable: navNotifier,
    redirect: (context, state) {
      final isSplashFinished = ref.read(splashCompletedProvider);
      final authState = ref.read(authStateProvider).valueOrNull;
      final currentStoreState = ref.read(currentStoreProvider);

      final isAuthenticated = authState is AuthStateAuthenticated;
      final isLoading = authState == null ||
          authState is AuthStateLoading ||
          authState is AuthStateInitial;

      final loc = state.matchedLocation;
      final isSplash = loc == TallyRoutes.splash;
      final isSignIn = loc == TallyRoutes.signIn;
      final isStores = loc == TallyRoutes.stores;
      final isCreateStore = loc == TallyRoutes.createStore;
      final isHome = loc == TallyRoutes.home;

      if (!isSplashFinished || isLoading) {
        return isSplash ? null : TallyRoutes.splash;
      }

      if (!isAuthenticated) {
        return isSignIn ? null : TallyRoutes.signIn;
      }

      // User is Authenticated
      final hasStoreSelected = currentStoreState is StoreSelected;

      if (hasStoreSelected) {
        if (isSignIn || isSplash || isStores) {
          return TallyRoutes.home;
        }
        return null;
      } else {
        // No store selected yet
        if (isHome || isSignIn || isSplash) {
          return TallyRoutes.stores;
        }
        if (isStores || isCreateStore) {
          return null;
        }
        return TallyRoutes.stores;
      }
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
        path: TallyRoutes.stores,
        builder: (_, __) => const StoreSelectionScreen(),
      ),
      GoRoute(
        path: TallyRoutes.createStore,
        builder: (_, __) => const CreateStoreScreen(),
      ),
      GoRoute(
        path: TallyRoutes.home,
        builder: (_, __) => const TallyShell(),
      ),
    ],
  );
});

/// A [ChangeNotifier] that triggers GoRouter refresh whenever auth or store context changes.
class _NavigationChangeNotifier extends ChangeNotifier {
  late final ProviderSubscription<AsyncValue<AuthState>> _authSub;
  late final ProviderSubscription<CurrentStoreState> _storeSub;
  late final ProviderSubscription<bool> _splashSub;

  _NavigationChangeNotifier(Ref ref) {
    _authSub = ref.listen(authStateProvider, (_, __) => notifyListeners());
    _storeSub = ref.listen(currentStoreProvider, (_, __) => notifyListeners());
    _splashSub =
        ref.listen(splashCompletedProvider, (_, __) => notifyListeners());
  }

  @override
  void dispose() {
    _authSub.close();
    _storeSub.close();
    _splashSub.close();
    super.dispose();
  }
}

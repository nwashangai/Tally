import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/auth/auth_state.dart';
import '../../app/providers/core_providers.dart';

/// Exposes the live authentication state stream as a [StreamProvider].
final authStateProvider = StreamProvider<AuthState>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  return repo.watchAuthState();
});

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import '../core/providers/role_provider.dart';
import '../features/auth/presentation/login_placeholder.dart';
import '../features/auth/presentation/register_placeholder.dart';
import '../features/auth/presentation/welcome_screen.dart';
import '../features/customer/placeholder_home.dart';
import '../features/provider/placeholder_home.dart';

/// Role-aware router. Redirect logic reads tokens + role directly from
/// `FlutterSecureStorage` (authoritative source), so we don't race against
/// the async hydration of `roleProvider` on cold start. The `roleProvider`
/// is still subscribed so that changes from `setRole(...)` / `clear()` pulse
/// a rebuild of the redirect.
final routerProvider = Provider<GoRouter>((ref) {
  final storage = ref.watch(secureStorageProvider);
  final refreshTick = ValueNotifier<int>(0);

  ref.listen<UserRole?>(roleProvider, (_, __) {
    refreshTick.value++;
  });

  final router = GoRouter(
    initialLocation: '/welcome',
    refreshListenable: refreshTick,
    redirect: (context, state) async {
      final token = await storage.read(key: 'access_token');
      final hasToken = token != null && token.isNotEmpty;
      final role = await _readRole(storage);
      final goingTo = state.matchedLocation;

      if (!hasToken) {
        if (goingTo == '/welcome') return null;
        if (goingTo == '/login' && role != null) return null;
        if (goingTo == '/register' && role != null) return null;
        return '/welcome';
      }

      if (role == UserRole.customer && !goingTo.startsWith('/customer')) {
        return '/customer/home';
      }
      if (role == UserRole.provider && !goingTo.startsWith('/provider')) {
        return '/provider/home';
      }
      if (role == null) return '/welcome';
      return null;
    },
    routes: [
      GoRoute(
        path: '/welcome',
        builder: (_, __) => const WelcomeScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (_, __) => const LoginPlaceholder(),
      ),
      GoRoute(
        path: '/register',
        builder: (_, __) => const RegisterPlaceholder(),
      ),
      GoRoute(
        path: '/customer/home',
        builder: (_, __) => const CustomerPlaceholderHome(),
      ),
      GoRoute(
        path: '/provider/home',
        builder: (_, __) => const ProviderPlaceholderHome(),
      ),
    ],
  );

  ref.onDispose(refreshTick.dispose);
  return router;
});

Future<UserRole?> _readRole(FlutterSecureStorage storage) async {
  final raw = await storage.read(key: 'user_role');
  if (raw == 'customer') return UserRole.customer;
  if (raw == 'provider') return UserRole.provider;
  return null;
}

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/presentation/auth_provider.dart';
import '../features/auth/presentation/welcome_screen.dart';
import '../features/auth/presentation/login_page.dart';
import '../features/auth/presentation/register_screen.dart';
import '../features/auth/presentation/otp_screen.dart';
import '../features/jobs/presentation/job_feed_screen.dart';
import '../features/jobs/presentation/job_detail_screen.dart';
import '../features/jobs/presentation/active_job_detail_screen.dart';
import '../features/jobs/presentation/upload_after_photos_screen.dart';
import '../features/navigation/presentation/navigation_page.dart';
import '../features/earnings/presentation/earnings_page.dart';
import '../features/earnings/presentation/payout_status_screen.dart';
import '../features/profile/presentation/profile_page.dart';
import '../features/chat/presentation/chat_screen.dart';
import '../features/notifications/presentation/notifications_screen.dart';

/// Routes accessible without authentication.
const _authRoutes = {'/welcome', '/login', '/register'};

bool _isAuthRoute(String location) {
  if (_authRoutes.contains(location)) return true;
  if (location.startsWith('/otp')) return true;
  return false;
}

class _AuthChangeNotifier extends ChangeNotifier {
  _AuthChangeNotifier(Ref ref) {
    ref.listen(authNotifierProvider, (_, __) => notifyListeners());
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final authListenable = _AuthChangeNotifier(ref);

  return GoRouter(
    initialLocation: '/welcome',
    refreshListenable: authListenable,
    redirect: (context, state) {
      final authAsync = ref.read(authNotifierProvider);
      if (authAsync.isLoading) return null;

      final isAuthenticated = authAsync.valueOrNull is AuthAuthenticated;
      final location = state.uri.toString();
      final onAuthRoute = _isAuthRoute(location);

      if (isAuthenticated && onAuthRoute) return '/jobs';
      if (!isAuthenticated && !onAuthRoute) return '/welcome';
      return null;
    },
    routes: [
      GoRoute(path: '/welcome', builder: (_, __) => const WelcomeScreen()),
      GoRoute(path: '/login', builder: (_, __) => const LoginPage()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
      GoRoute(
        path: '/otp',
        builder: (_, state) {
          final phone =
              Uri.decodeComponent(state.uri.queryParameters['phone'] ?? '');
          return OtpScreen(phone: phone);
        },
      ),
      GoRoute(
        path: '/jobs',
        builder: (_, __) => const JobFeedScreen(),
      ),
      GoRoute(
        path: '/job-detail/:jobId',
        builder: (_, state) =>
            JobDetailScreen(jobId: state.pathParameters['jobId']!),
      ),
      GoRoute(
        path: '/active-job/:jobId',
        builder: (_, state) =>
            ActiveJobDetailScreen(jobId: state.pathParameters['jobId']!),
      ),
      GoRoute(
        path: '/active-job/:jobId/after-photos',
        builder: (_, state) =>
            UploadAfterPhotosScreen(jobId: state.pathParameters['jobId']!),
      ),
      GoRoute(
        path: '/navigation/:jobId',
        builder: (_, state) =>
            NavigationPage(jobId: state.pathParameters['jobId']!),
      ),
      GoRoute(path: '/earnings', builder: (_, __) => const EarningsPage()),
      GoRoute(path: '/payout-status', builder: (_, __) => const PayoutStatusScreen()),
      GoRoute(path: '/profile', builder: (_, __) => const ProfilePage()),
      GoRoute(
        path: '/chat/:jobId',
        builder: (_, state) => ProviderChatScreen(
          jobId: state.pathParameters['jobId']!,
          otherPartyName: (state.extra as String?) ?? '',
        ),
      ),
      GoRoute(
        path: '/notifications',
        builder: (_, __) => const NotificationsScreen(),
      ),
    ],
  );
});

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/presentation/auth_provider.dart';
import '../features/auth/presentation/welcome_screen.dart';
import '../features/auth/presentation/login_page.dart';
import '../features/auth/presentation/register_screen.dart';
import '../features/auth/presentation/otp_screen.dart';
import '../features/home/presentation/home_page.dart';
import '../features/booking/presentation/category_screen.dart';
import '../features/booking/presentation/job_description_screen.dart';
import '../features/booking/presentation/location_screen.dart';
import '../features/booking/presentation/booking_summary_screen.dart';
import '../features/booking/presentation/booking_confirmation_screen.dart';
import '../features/tracking/presentation/tracking_page.dart';
import '../features/history/presentation/history_page.dart';
import '../features/history/presentation/job_detail_page.dart';
import '../features/dispute/presentation/raise_dispute_screen.dart';
import '../features/profile/presentation/profile_page.dart';
import '../features/payments/presentation/payment_receipt_screen.dart';
import '../features/payments/presentation/payment_status_screen.dart';
import '../features/chat/presentation/chat_screen.dart';
import '../features/notifications/presentation/notifications_screen.dart';
import '../features/referral/presentation/referral_screen.dart';
import '../features/reminders/presentation/reminders_screen.dart';
import '../features/profile/presentation/edit_profile_screen.dart';
import '../widgets/main_scaffold.dart';

/// Routes accessible without authentication.
const _authRoutes = {'/welcome', '/login', '/register'};

bool _isAuthRoute(String location) {
  if (_authRoutes.contains(location)) return true;
  if (location.startsWith('/otp')) return true;
  return false;
}

/// A simple [ChangeNotifier] that fires whenever the Riverpod auth state
/// changes, giving [GoRouter.refreshListenable] a proper [Listenable].
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

      // While initializing, stay put.
      if (authAsync.isLoading) return null;

      final isAuthenticated = authAsync.valueOrNull is AuthAuthenticated;
      final location = state.uri.toString();
      final onAuthRoute = _isAuthRoute(location);

      if (isAuthenticated && onAuthRoute) return '/home';
      if (!isAuthenticated && !onAuthRoute) return '/welcome';
      return null;
    },
    routes: [
      // Auth routes
      GoRoute(
        path: '/welcome',
        builder: (_, __) => const WelcomeScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (_, __) => const LoginPage(),
      ),
      GoRoute(
        path: '/register',
        builder: (_, __) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/otp',
        builder: (_, state) {
          final phone =
              Uri.decodeComponent(state.uri.queryParameters['phone'] ?? '');
          return OtpScreen(phone: phone);
        },
      ),

      // Main shell — persistent bottom nav across Home, Bookings, Notifications, Profile
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) =>
            MainScaffold(navigationShell: shell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(path: '/home', builder: (_, __) => const HomePage()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/history', builder: (_, __) => const HistoryPage()),
            GoRoute(
              path: '/history/:jobId',
              builder: (_, s) =>
                  JobDetailPage(jobId: s.pathParameters['jobId']!),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
                path: '/notifications',
                builder: (_, __) => const NotificationsScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/profile', builder: (_, __) => const ProfilePage()),
          ]),
        ],
      ),

      // Booking flow (sub-routes share BookingNotifier state)
      GoRoute(
        path: '/booking/category',
        builder: (_, __) => const CategoryScreen(),
      ),
      GoRoute(
        path: '/booking/description',
        builder: (_, __) => const JobDescriptionScreen(),
      ),
      GoRoute(
        path: '/booking/location',
        builder: (_, __) => const LocationScreen(),
      ),
      GoRoute(
        path: '/booking/summary',
        builder: (_, __) => const BookingSummaryScreen(),
      ),
      GoRoute(
        path: '/booking/confirmation',
        builder: (_, __) => const BookingConfirmationScreen(),
      ),

      GoRoute(
        path: '/tracking/:jobId',
        builder: (_, state) =>
            TrackingPage(jobId: state.pathParameters['jobId']!),
      ),
      GoRoute(
        path: '/history',
        builder: (_, __) => const HistoryPage(),
      ),
      GoRoute(
        path: '/history/:jobId',
        builder: (_, state) =>
            JobDetailPage(jobId: state.pathParameters['jobId']!),
      ),
      GoRoute(
        path: '/dispute/raise',
        builder: (_, state) {
          final extra = state.extra as Map<String, String>? ?? {};
          return RaiseDisputeScreen(
            jobId: extra['jobId'] ?? '',
            referenceNumber: extra['referenceNumber'] ?? '',
          );
        },
      ),
      GoRoute(
        path: '/profile',
        builder: (_, __) => const ProfilePage(),
      ),
      GoRoute(
        path: '/payment/receipt',
        builder: (_, __) => const PaymentReceiptScreen(),
      ),
      GoRoute(
        path: '/payment/status/:jobId',
        builder: (_, state) =>
            PaymentStatusScreen(jobId: state.pathParameters['jobId']!),
      ),
      GoRoute(
        path: '/chat/:jobId',
        builder: (_, state) => CustomerChatScreen(
          jobId: state.pathParameters['jobId']!,
          otherPartyName: (state.extra as String?) ?? '',
        ),
      ),
      GoRoute(
        path: '/notifications',
        builder: (_, __) => const NotificationsScreen(),
      ),
      GoRoute(
        path: '/referral',
        builder: (_, state) {
          final code = state.uri.queryParameters['ref'];
          return ReferralScreen(prefilledCode: code);
        },
      ),
      GoRoute(
        path: '/reminders',
        builder: (_, __) => const RemindersScreen(),
      ),
      GoRoute(
        path: '/profile/edit',
        builder: (_, __) => const EditProfileScreen(),
      ),
    ],
  );
});

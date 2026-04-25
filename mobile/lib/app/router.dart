import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:talker_flutter/talker_flutter.dart';
import '../core/logging/app_logger.dart';
import '../core/logging/log_viewer_screen.dart';
import '../core/providers/role_provider.dart';
import '../features/auth/presentation/forgot_password_screen.dart';
import '../features/auth/presentation/login_page.dart';
import '../features/auth/presentation/otp_screen.dart';
import '../features/auth/presentation/register_screen.dart';
import '../features/auth/presentation/reset_password_screen.dart';
import '../features/auth/presentation/welcome_screen.dart';
import '../features/customer/booking/presentation/booking_confirmation_screen.dart';
import '../features/customer/booking/presentation/booking_summary_screen.dart';
import '../features/customer/booking/presentation/category_screen.dart';
import '../features/customer/booking/presentation/job_description_screen.dart';
import '../features/customer/booking/presentation/location_screen.dart';
import '../features/customer/dispute/presentation/raise_dispute_screen.dart';
import '../features/customer/history/presentation/history_page.dart';
import '../features/customer/history/presentation/job_detail_page.dart';
import '../features/customer/home/home_page.dart';
import '../features/customer/payments/presentation/payment_receipt_screen.dart';
import '../features/customer/payments/presentation/payment_status_screen.dart';
import '../features/customer/referral/presentation/referral_screen.dart';
import '../features/customer/reminders/presentation/reminders_screen.dart';
import '../features/customer/tracking/presentation/tracking_page.dart';
import '../features/provider/analytics/presentation/analytics_screen.dart';
import '../features/provider/earnings/presentation/earnings_page.dart';
import '../features/provider/earnings/presentation/payout_status_screen.dart';
import '../features/provider/jobs/presentation/active_job_detail_screen.dart';
import '../features/provider/jobs/presentation/job_detail_screen.dart';
import '../features/provider/jobs/presentation/job_feed_screen.dart';
import '../features/provider/jobs/presentation/upload_after_photos_screen.dart';
import '../features/provider/navigation/presentation/navigation_page.dart';
import '../features/provider/onboarding/presentation/id_upload_screen.dart';
import '../features/provider/onboarding/presentation/onboarding_hub_screen.dart';
import '../features/provider/onboarding/presentation/skill_test_screen.dart';
import '../features/provider/subscription/presentation/subscription_screen.dart';
import '../features/shared/chat/presentation/chat_screen.dart';
import '../features/shared/notifications/presentation/notifications_screen.dart';
import '../features/shared/profile/presentation/edit_profile_screen.dart';
import '../features/shared/profile/presentation/profile_page.dart';
import '../widgets/main_scaffold_customer.dart';
import '../widgets/main_scaffold_provider.dart';

/// Root navigator key — exposed so the deep-link / FCM handler in
/// `notification_handler.dart` can push onto the root navigator even from
/// background isolates.
final rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

/// Storage key for the last-known provider verification tier. Written by
/// `onboardingStatusProvider` after a successful fetch so that the router can
/// gate the provider shell on cold start. `null` means "unknown" — the router
/// lets the provider through and the in-app screens handle the fetch.
const kProviderTierStorageKey = 'provider_tier';

/// Role-aware router. Redirect logic reads tokens + role directly from
/// `FlutterSecureStorage` (authoritative source), so we don't race against
/// the async hydration of `roleProvider` on cold start. The `roleProvider`
/// is still subscribed so that changes from `setRole(...)` / `clear()` pulse
/// a rebuild of the redirect.
final routerProvider = Provider<GoRouter>((ref) {
  final storage = ref.watch(secureStorageProvider);
  final refreshTick = ValueNotifier<int>(0);

  ref.listen<UserRole?>(roleProvider, (prev, next) {
    log.d('Router.redirect', 'refresh pulse', data: {
      'reason': 'role_change',
      'prev': prev?.name,
      'next': next?.name,
    });
    refreshTick.value++;
  });

  final router = GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/welcome',
    refreshListenable: refreshTick,
    redirect: (context, state) => _topLevelRedirect(storage, state),
    observers: [TalkerRouteObserver(log.talker)],
    routes: _routes,
  );

  ref.onDispose(refreshTick.dispose);
  return router;
});

const _publicPaths = {
  '/welcome',
  '/login',
  '/register',
  '/otp',
  '/forgot-password',
  '/reset-password',
};

/// Provider-tree routes that remain reachable even when the provider's tier
/// is not `Active` — so they can finish onboarding, check profile/logout,
/// read notifications, and use chat on any accepted job.
const _providerTierExemptPrefixes = {
  '/provider/onboarding',
  '/provider/profile',
  '/provider/notifications',
  '/provider/chat',
};

Future<String?> _topLevelRedirect(
  FlutterSecureStorage storage,
  GoRouterState state,
) async {
  final goingTo = state.matchedLocation;

  // Debug-only log viewer is reachable regardless of auth state — useful when
  // logs are needed precisely because auth is broken. Compiled out of release
  // builds because the route itself is only registered under `kDebugMode`.
  if (kDebugMode && goingTo.startsWith('/debug/')) return null;

  final token = await storage.read(key: 'access_token');
  final hasToken = token != null && token.isNotEmpty;
  final role = await _readRole(storage);
  final tier = await storage.read(key: kProviderTierStorageKey);

  log.v('Router.redirect', 'redirect', data: {
    'path': goingTo,
    'hasToken': hasToken,
    'role': role?.name,
    'tier': tier,
  });

  String? decide(String? to, String reason) {
    log.d('Router.redirect', 'decision', data: {
      'from': goingTo,
      'to': to ?? '<stay>',
      'reason': reason,
    });
    return to;
  }

  // Unauthenticated ------------------------------------------------------------
  if (!hasToken) {
    if (_publicPaths.any(goingTo.startsWith)) {
      // Provider role has no forgot/reset password flow — bounce back to login.
      if (role == UserRole.provider &&
          (goingTo.startsWith('/forgot-password') ||
              goingTo.startsWith('/reset-password'))) {
        return decide('/login', 'provider_no_password_recovery');
      }
      return decide(null, 'public');
    }
    return decide('/welcome', 'no_token');
  }

  // Authenticated with no role (corrupted state) → clear token + bounce.
  if (role == null) {
    log.w('Router.redirect', 'corrupt state, clearing tokens');
    await storage.delete(key: 'access_token');
    await storage.delete(key: 'refresh_token');
    return decide('/welcome', 'corrupt_state');
  }

  // Authenticated on a public route → send to role's home.
  if (_publicPaths.any(goingTo.startsWith)) {
    return decide(
      role == UserRole.customer ? '/customer/home' : '/provider/jobs',
      'authed_on_public',
    );
  }

  // Wrong-role namespace guard.
  if (role == UserRole.customer && goingTo.startsWith('/provider/')) {
    return decide('/customer/home', 'wrong_role');
  }
  if (role == UserRole.provider && goingTo.startsWith('/customer/')) {
    return decide('/provider/jobs', 'wrong_role');
  }

  // Provider-tier gate: un-verified providers may only navigate to
  // onboarding + profile + notifications + chat until they reach `Active`.
  if (role == UserRole.provider && goingTo.startsWith('/provider/')) {
    // `VerificationTier.active.name` serialises to `"active"` (camelCase).
    final needsOnboarding =
        tier != null && tier.isNotEmpty && tier != 'active';
    if (needsOnboarding &&
        !_providerTierExemptPrefixes.any(goingTo.startsWith)) {
      return decide('/provider/onboarding', 'tier_gate');
    }
  }

  return decide(null, 'allow');
}

Future<UserRole?> _readRole(FlutterSecureStorage storage) async {
  final raw = await storage.read(key: 'user_role');
  if (raw == 'customer') return UserRole.customer;
  if (raw == 'provider') return UserRole.provider;
  return null;
}

final List<RouteBase> _routes = [
  GoRoute(path: '/welcome', builder: (_, __) => const WelcomeScreen()),
  GoRoute(path: '/login', builder: (_, __) => const LoginPage()),
  GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
  GoRoute(
    path: '/otp',
    builder: (_, state) {
      final phone = state.uri.queryParameters['phone'] ?? '';
      return OtpScreen(phone: phone);
    },
  ),
  GoRoute(
    path: '/forgot-password',
    builder: (_, __) => const ForgotPasswordScreen(),
  ),
  GoRoute(
    path: '/reset-password',
    builder: (_, state) {
      final phone = state.uri.queryParameters['phone'] ?? '';
      return ResetPasswordScreen(phone: phone);
    },
  ),

  // Customer shell — persistent bottom nav across Home / History /
  // Notifications / Profile with the amber FAB opening the booking flow.
  StatefulShellRoute.indexedStack(
    builder: (context, state, shell) =>
        MainScaffoldCustomer(navigationShell: shell),
    branches: [
      StatefulShellBranch(routes: [
        GoRoute(
          path: '/customer/home',
          builder: (_, __) => const HomePage(),
        ),
      ]),
      StatefulShellBranch(routes: [
        GoRoute(
          path: '/customer/history',
          builder: (_, __) => const HistoryPage(),
          routes: [
            GoRoute(
              path: ':jobId',
              builder: (_, s) =>
                  JobDetailPage(jobId: s.pathParameters['jobId']!),
            ),
          ],
        ),
      ]),
      StatefulShellBranch(routes: [
        GoRoute(
          path: '/customer/notifications',
          builder: (_, __) => const NotificationsScreen(),
        ),
      ]),
      StatefulShellBranch(routes: [
        GoRoute(
          path: '/customer/profile',
          builder: (_, __) => const ProfilePage(),
          routes: [
            GoRoute(
              path: 'edit',
              builder: (_, __) => const EditProfileScreen(),
            ),
          ],
        ),
      ]),
    ],
  ),

  // Customer flows outside the shell.
  GoRoute(
    path: '/customer/booking/category',
    builder: (_, __) => const CategoryScreen(),
  ),
  GoRoute(
    path: '/customer/booking/description',
    builder: (_, __) => const JobDescriptionScreen(),
  ),
  GoRoute(
    path: '/customer/booking/location',
    builder: (_, __) => const LocationScreen(),
  ),
  GoRoute(
    path: '/customer/booking/summary',
    builder: (_, __) => const BookingSummaryScreen(),
  ),
  GoRoute(
    path: '/customer/booking/confirmation',
    builder: (_, __) => const BookingConfirmationScreen(),
  ),
  GoRoute(
    path: '/customer/tracking/:jobId',
    builder: (_, state) => TrackingPage(jobId: state.pathParameters['jobId']!),
  ),
  GoRoute(
    path: '/customer/payment/receipt',
    builder: (_, __) => const PaymentReceiptScreen(),
  ),
  GoRoute(
    path: '/customer/payment/status/:jobId',
    builder: (_, state) =>
        PaymentStatusScreen(jobId: state.pathParameters['jobId']!),
  ),
  GoRoute(
    path: '/customer/referral',
    builder: (_, state) {
      final code = state.uri.queryParameters['ref'];
      return ReferralScreen(prefilledCode: code);
    },
  ),
  GoRoute(
    path: '/customer/reminders',
    builder: (_, __) => const RemindersScreen(),
  ),
  GoRoute(
    path: '/customer/dispute/raise',
    builder: (_, state) {
      final extra = state.extra as Map<String, String>? ?? const {};
      return RaiseDisputeScreen(
        jobId: extra['jobId'] ?? '',
        referenceNumber: extra['referenceNumber'] ?? '',
      );
    },
  ),
  GoRoute(
    path: '/customer/chat/:jobId',
    builder: (_, state) => ChatScreen(
      jobId: state.pathParameters['jobId']!,
      otherPartyName: state.uri.queryParameters['name'] ?? '',
    ),
  ),

  // Provider shell — 4 tabs: Jobs / Earnings / Notifications / Profile.
  StatefulShellRoute.indexedStack(
    builder: (context, state, shell) =>
        MainScaffoldProvider(navigationShell: shell),
    branches: [
      StatefulShellBranch(routes: [
        GoRoute(
          path: '/provider/jobs',
          builder: (_, __) => const JobFeedScreen(),
        ),
      ]),
      StatefulShellBranch(routes: [
        GoRoute(
          path: '/provider/earnings',
          builder: (_, __) => const EarningsPage(),
        ),
      ]),
      StatefulShellBranch(routes: [
        GoRoute(
          path: '/provider/notifications',
          builder: (_, __) => const NotificationsScreen(),
        ),
      ]),
      StatefulShellBranch(routes: [
        GoRoute(
          path: '/provider/profile',
          builder: (_, __) => const ProfilePage(),
          routes: [
            GoRoute(
              path: 'edit',
              builder: (_, __) => const EditProfileScreen(),
            ),
          ],
        ),
      ]),
    ],
  ),

  // Provider flows outside the shell.
  GoRoute(
    path: '/provider/job-detail/:jobId',
    builder: (_, state) =>
        JobDetailScreen(jobId: state.pathParameters['jobId']!),
  ),
  GoRoute(
    path: '/provider/active-job/:jobId',
    builder: (_, state) =>
        ActiveJobDetailScreen(jobId: state.pathParameters['jobId']!),
    routes: [
      GoRoute(
        path: 'after-photos',
        builder: (_, state) =>
            UploadAfterPhotosScreen(jobId: state.pathParameters['jobId']!),
      ),
    ],
  ),
  GoRoute(
    path: '/provider/navigation/:jobId',
    builder: (_, state) =>
        NavigationPage(jobId: state.pathParameters['jobId']!),
  ),
  GoRoute(
    path: '/provider/payout-status',
    builder: (_, __) => const PayoutStatusScreen(),
  ),
  GoRoute(
    path: '/provider/onboarding',
    builder: (_, __) => const OnboardingHubScreen(),
    routes: [
      GoRoute(
        path: 'id-upload',
        builder: (_, __) => const IdUploadScreen(),
      ),
      GoRoute(
        path: 'skill-test',
        builder: (_, __) => const SkillTestScreen(),
      ),
    ],
  ),
  GoRoute(
    path: '/provider/subscription',
    builder: (_, __) => const SubscriptionScreen(),
  ),
  GoRoute(
    path: '/provider/analytics',
    builder: (_, __) => const AnalyticsScreen(),
  ),
  GoRoute(
    path: '/provider/chat/:jobId',
    builder: (_, state) => ChatScreen(
      jobId: state.pathParameters['jobId']!,
      otherPartyName: state.uri.queryParameters['name'] ?? '',
    ),
  ),

  // Debug-only log viewer. Reachable from a long-press on the profile-page
  // version label — and only when `kDebugMode` is true. Not redirect-guarded
  // so it works even if auth state is broken.
  if (kDebugMode)
    GoRoute(
      path: '/debug/logs',
      builder: (_, __) => const LogViewerScreen(),
    ),
];

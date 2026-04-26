import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:talker_riverpod_logger/talker_riverpod_logger.dart';
import 'app/app.dart';
import 'app/router.dart';
import 'core/api/api_client.dart';
import 'core/logging/app_logger.dart';
import 'core/logging/crashlytics_sink.dart';
import 'core/network/connectivity_provider.dart';
import 'core/providers/locale_provider.dart';
import 'core/services/fcm_service.dart';
import 'core/services/notification_handler.dart';
import 'features/migration/data/migration_analytics.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
  } catch (_) {}
}

void main() async {
  AppLogger.bootstrap();
  WidgetsFlutterBinding.ensureInitialized();
  log.i('Boot', 'app start');

  // Phase 06 — route uncaught Flutter / platform errors through `log.e` /
  // `log.c` so Crashlytics receives them once the sink is attached below.
  // Installed before any other init so a Stripe / Firebase init throw lands
  // in the same pipeline as runtime errors.
  FlutterError.onError = (details) {
    log.e(
      'FlutterError',
      details.exceptionAsString(),
      error: details.exception,
      stack: details.stack,
    );
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    log.c('PlatformError', error.toString(), error: error, stack: stack);
    return true;
  };

  bool firebaseReady = false;
  try {
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    await FirebaseMessaging.instance.requestPermission();
    await initLocalNotifications();
    firebaseReady = true;
  } catch (e) {
    // Firebase not yet configured — push notifications unavailable.
    // Phase 9 drops in `firebase_options.dart` + platform config.
    log.w('Boot', 'firebase init skipped', error: e);
  }

  // Phase 06 — once Firebase is up, mirror `error` + `critical` log lines to
  // Crashlytics. Skipped when Firebase init failed (placeholder config) and
  // also off in debug builds so local crashes don't pollute the dashboard.
  if (firebaseReady && kReleaseMode) {
    try {
      log.attachCrashlytics(CrashlyticsSink.fromFirebase());
      log.i('Boot', 'crashlytics attached');
    } catch (e) {
      log.w('Boot', 'crashlytics attach skipped', error: e);
    }
  }

  try {
    // Gated via --dart-define=STRIPE_PUBLISHABLE_KEY=<pk_live_…> for release.
    // Debug/profile builds fall back to a test-mode placeholder; callers to
    // PaymentSheet will fail gracefully (StripeException) if the placeholder
    // reaches production.
    const stripePublishableKey = String.fromEnvironment(
      'STRIPE_PUBLISHABLE_KEY',
      defaultValue: 'pk_test_REPLACE_WITH_YOUR_TEST_KEY',
    );
    Stripe.publishableKey = stripePublishableKey;
    await Stripe.instance.applySettings();
  } catch (e) {
    log.w('Boot', 'stripe init skipped', error: e);
  }

  final persistedLocale = await LocaleNotifier.loadPersisted();

  // Single ProviderContainer used by both (a) the FCM / deep-link handlers
  // (which run outside the widget tree) and (b) UncontrolledProviderScope so
  // the widget tree shares state with those handlers.
  //
  // `TalkerRiverpodObserver` lands here so provider build / dispose / state
  // changes / errors all flow through the same Talker history as Dio,
  // SignalR, FCM, and router events.
  final container = ProviderContainer(
    overrides: [
      localeProvider.overrideWith((_) => LocaleNotifier(persistedLocale)),
    ],
    // Defaults already log added / updated / disposed / failed for every
    // provider — no need to configure further. Settings can be tightened if
    // log volume becomes noisy.
    observers: [TalkerRiverpodObserver(talker: log.talker)],
  );

  // Start the connectivity listener before the first frame so the
  // `noInternetProvider` already reflects the device's online state when
  // `KhudmatiApp.builder` runs.
  container.read(connectivityServiceProvider);

  final router = container.read(routerProvider);
  final handler = NotificationHandler(router: router, container: container);

  if (firebaseReady) {
    final apiClient = container.read(apiClientProvider);
    setupFcmListeners(
      apiClient: apiClient,
      handler: handler,
      container: container,
    );
    registerFcmToken(apiClient, container);
  }

  // Phase 10 — fire `migration_opened_new_app` once per install so we can
  // track legacy → unified conversion in Firebase. Fire-and-forget; must
  // never block app startup.
  unawaited(
    MigrationAnalytics().logFirstLaunchIfNeeded(firebaseReady: firebaseReady),
  );

  // Custom-scheme deep links (khudmati://…). Covers cold-start (the intent
  // that launched the app) and warm events while the app is running.
  try {
    final appLinks = AppLinks();
    appLinks.getInitialLink().then((uri) {
      if (uri != null) handler.handleDeepLink(uri);
    });
    appLinks.uriLinkStream.listen(handler.handleDeepLink);
  } catch (e) {
    log.w('Boot', 'deep-link init skipped', error: e);
  }

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const KhudmatiApp(),
    ),
  );
}

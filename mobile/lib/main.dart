import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'app/app.dart';
import 'app/router.dart';
import 'core/api/api_client.dart';
import 'core/providers/locale_provider.dart';
import 'core/services/fcm_service.dart';
import 'core/services/notification_handler.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
  } catch (_) {}
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

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
    debugPrint('Firebase init skipped: $e');
  }

  try {
    // Env-gated in Phase 9 via --dart-define=STRIPE_PUBLISHABLE_KEY=...
    Stripe.publishableKey = 'pk_test_REPLACE_WITH_YOUR_TEST_KEY';
    await Stripe.instance.applySettings();
  } catch (e) {
    debugPrint('Stripe init skipped: $e');
  }

  final persistedLocale = await LocaleNotifier.loadPersisted();

  // Single ProviderContainer used by both (a) the FCM / deep-link handlers
  // (which run outside the widget tree) and (b) UncontrolledProviderScope so
  // the widget tree shares state with those handlers.
  final container = ProviderContainer(
    overrides: [
      localeProvider.overrideWith((_) => LocaleNotifier(persistedLocale)),
    ],
  );

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

  // Custom-scheme deep links (khudmati://…). Covers cold-start (the intent
  // that launched the app) and warm events while the app is running.
  try {
    final appLinks = AppLinks();
    appLinks.getInitialLink().then((uri) {
      if (uri != null) handler.handleDeepLink(uri);
    });
    appLinks.uriLinkStream.listen(handler.handleDeepLink);
  } catch (e) {
    debugPrint('Deep-link init skipped: $e');
  }

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const KhudmatiApp(),
    ),
  );
}

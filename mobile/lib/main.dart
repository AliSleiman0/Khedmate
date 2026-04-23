import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'app/app.dart';
import 'core/providers/locale_provider.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
  } catch (_) {}
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    await FirebaseMessaging.instance.requestPermission();
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

  runApp(
    ProviderScope(
      overrides: [
        localeProvider.overrideWith((_) => LocaleNotifier(persistedLocale)),
      ],
      child: const KhudmatiApp(),
    ),
  );
}

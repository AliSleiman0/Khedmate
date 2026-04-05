import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import '../core/api/api_client.dart';
import '../core/services/fcm_service.dart';
import 'router.dart';
import 'theme.dart';

class KhudmatiCustomerApp extends ConsumerStatefulWidget {
  const KhudmatiCustomerApp({super.key});

  @override
  ConsumerState<KhudmatiCustomerApp> createState() =>
      _KhudmatiCustomerAppState();
}

class _KhudmatiCustomerAppState extends ConsumerState<KhudmatiCustomerApp> {
  bool _fcmInitialized = false;

  @override
  void initState() {
    super.initState();
    initLocalNotifications();
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);

    if (!_fcmInitialized) {
      _fcmInitialized = true;
      final apiClient = ApiClient();
      registerFcmToken(apiClient);
      setupFcmListeners(apiClient: apiClient, router: router);
    }

    return MaterialApp.router(
      title: 'خدمتي',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      routerConfig: router,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('ar'), Locale('en')],
      locale: const Locale('ar'),
      builder: (context, child) => Directionality(
        textDirection: TextDirection.rtl,
        child: child!,
      ),
    );
  }
}

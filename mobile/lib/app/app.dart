import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/api/api_client.dart';
import '../core/network/connectivity_provider.dart';
import '../core/providers/locale_provider.dart';
import '../core/widgets/no_internet_screen.dart';
import '../features/migration/presentation/upgrade_required_screen.dart';
import 'router.dart';
import 'theme.dart';

class KhudmatiApp extends ConsumerWidget {
  const KhudmatiApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    final isRtl = locale.languageCode == 'ar';
    final router = ref.watch(routerProvider);
    final upgrade = ref.watch(upgradeRequiredProvider);
    final noInternet = ref.watch(noInternetProvider);

    return MaterialApp.router(
      title: 'Khudmati',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      routerConfig: router,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en'), Locale('ar')],
      locale: locale,
      builder: (context, child) => Directionality(
        textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
        child: upgrade != null
            ? UpgradeRequiredScreen(storeUrl: upgrade.storeUrl)
            : noInternet
                ? const NoInternetScreen()
                : child!,
      ),
    );
  }
}

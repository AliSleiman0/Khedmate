import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/providers/locale_provider.dart';
import 'theme.dart';

/// Minimal router — Phase 3 replaces this with the full auth-aware routing
/// graph that respects the current `roleProvider` value.
final _placeholderRouter = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (_, __) => const Scaffold(body: SizedBox.shrink()),
    ),
  ],
);

class KhudmatiApp extends ConsumerWidget {
  const KhudmatiApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    final isRtl = locale.languageCode == 'ar';

    return MaterialApp.router(
      title: 'Khudmati',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      routerConfig: _placeholderRouter,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en'), Locale('ar')],
      locale: locale,
      builder: (context, child) => Directionality(
        textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
        child: child!,
      ),
    );
  }
}

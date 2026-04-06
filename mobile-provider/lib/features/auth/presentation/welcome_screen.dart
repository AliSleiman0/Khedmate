import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/colors.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/providers/locale_provider.dart';

class WelcomeScreen extends ConsumerWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(ref);
    return Scaffold(
      backgroundColor: AppColors.brandBlue,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Language toggle
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    final current = ref.read(localeProvider);
                    ref.read(localeProvider.notifier).state =
                        current.languageCode == 'ar'
                            ? const Locale('en')
                            : const Locale('ar');
                  },
                  child: Text(
                    s.langToggle,
                    style: const TextStyle(
                      color: Color(0xFFD6EAF8),
                      fontSize: 15,
                      fontFamily: 'Cairo',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const Spacer(),
              // Logo
              Text(
                s.appName,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 64,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontFamily: 'Cairo',
                ),
              ),
              const SizedBox(height: 12),
              // Tagline
              Text(
                s.tagline,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 20,
                  color: Color(0xFFD6EAF8),
                  fontFamily: 'Cairo',
                ),
              ),
              const Spacer(),
              // Provider CTA
              ElevatedButton(
                onPressed: () => context.go('/register'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.amber,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Cairo',
                  ),
                ),
                child: Text(s.joinAsProvider),
              ),
              const SizedBox(height: 32),
              // Sign In link
              TextButton(
                onPressed: () => context.go('/login'),
                child: Text(
                  s.signIn,
                  style: const TextStyle(
                    color: Color(0xFFD6EAF8),
                    fontSize: 16,
                    fontFamily: 'Cairo',
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}



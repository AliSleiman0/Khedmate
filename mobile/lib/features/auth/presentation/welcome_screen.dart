import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/colors.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/providers/locale_provider.dart';
import '../../../core/providers/role_provider.dart';

class WelcomeScreen extends ConsumerWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(ref);
    return Scaffold(
      backgroundColor: AppColors.brandBlue,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    final current = ref.read(localeProvider);
                    ref.read(localeProvider.notifier).setLocale(
                          current.languageCode == 'ar'
                              ? const Locale('en')
                              : const Locale('ar'),
                        );
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
              const SizedBox(height: 8),
              Image.asset(
                'assets/images/logo.png',
                height: 110,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 12),
              Text(
                s.appName,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontFamily: 'Cairo',
                ),
              ),
              const SizedBox(height: 8),
              Text(
                s.tagline,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  color: Color(0xFFD6EAF8),
                  fontFamily: 'Cairo',
                ),
              ),
              const SizedBox(height: 32),
              Text(
                s.welcomeRoleQuestion,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  fontFamily: 'Cairo',
                ),
              ),
              const SizedBox(height: 20),
              _RoleTile(
                background: Colors.white,
                foreground: AppColors.brandBlue,
                icon: Icons.home_outlined,
                title: s.welcomeRoleCustomer,
                subtitle: s.welcomeRoleCustomerSub,
                onTap: () async {
                  await ref
                      .read(roleProvider.notifier)
                      .setRole(UserRole.customer);
                  if (context.mounted) context.go('/login');
                },
              ),
              const SizedBox(height: 16),
              _RoleTile(
                background: AppColors.amber,
                foreground: Colors.white,
                icon: Icons.handyman_outlined,
                title: s.welcomeRoleProvider,
                subtitle: s.welcomeRoleProviderSub,
                onTap: () async {
                  await ref
                      .read(roleProvider.notifier)
                      .setRole(UserRole.provider);
                  if (context.mounted) context.go('/login');
                },
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleTile extends StatelessWidget {
  final Color background;
  final Color foreground;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _RoleTile({
    required this.background,
    required this.foreground,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: background,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Row(
            children: [
              Icon(icon, size: 40, color: foreground),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: foreground,
                        fontFamily: 'Cairo',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: foreground.withValues(alpha: 0.85),
                        fontFamily: 'Cairo',
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: foreground.withValues(alpha: 0.7),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

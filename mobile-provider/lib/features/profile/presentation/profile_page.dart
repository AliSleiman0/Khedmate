import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/colors.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/providers/locale_provider.dart';
import '../../auth/presentation/auth_provider.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(ref);
    final locale = ref.watch(localeProvider);
    final authState = ref.watch(authNotifierProvider);
    final user = authState.valueOrNull is AuthAuthenticated
        ? (authState.valueOrNull as AuthAuthenticated).provider
        : null;

    return Scaffold(
      appBar: AppBar(title: Text(s.profileTitle)),
      body: ListView(
        children: [
          Container(
            color: AppColors.brandBlue,
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const CircleAvatar(
                  radius: 44,
                  backgroundColor: Colors.white24,
                  child: Icon(Icons.person, size: 52, color: Colors.white),
                ),
                const SizedBox(height: 12),
                Text(user?.fullName ?? '—',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                // Verification tier badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.success,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    s.profileVerification,
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
          const SizedBox(height: 8),
          _tile(Icons.edit, s.profileEdit, () => context.push('/profile/edit')),
          _tile(Icons.verified_user, s.profileVerification, () => context.push('/onboarding')),
          _tile(Icons.account_balance, s.profilePayment, () => context.push('/payout-status')),
          _tile(Icons.workspace_premium, s.subTitle, () => context.push('/subscription')),
          _tile(Icons.bar_chart_rounded, s.analyticsTitle, () => context.push('/analytics')),
          _tile(Icons.schedule, s.profileWorkHours, () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(s.profileComingSoon,
                  style: const TextStyle(fontFamily: 'Cairo'))),
            );
          }),
          _tile(Icons.language, locale.languageCode == 'ar' ? 'English' : 'عربي', () {
            ref.read(localeProvider.notifier).state =
                locale.languageCode == 'ar' ? const Locale('en') : const Locale('ar');
          }),
          _tile(Icons.notifications, s.profileNotifications, () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(s.profileComingSoon,
                  style: const TextStyle(fontFamily: 'Cairo'))),
            );
          }),
          _tile(Icons.help_outline, s.profileHelp, () async {
            final uri = Uri.parse('https://khudmati.app/#contact');
            if (await canLaunchUrl(uri)) {
              launchUrl(uri, mode: LaunchMode.externalApplication);
            }
          }),
          const Divider(),
          ListTile(
            leading:
                const Icon(Icons.logout, color: AppColors.danger),
            title: Text(s.profileLogout,
                style: const TextStyle(color: AppColors.danger)),
            onTap: () async {
              await ref.read(authNotifierProvider.notifier).logout();
              if (context.mounted) context.go('/welcome');
            },
          ),
        ],
      ),
    );
  }

  static ListTile _tile(IconData icon, String label, VoidCallback onTap) =>
      ListTile(
        leading: Icon(icon, color: AppColors.brandBlue),
        title: Text(label),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      );
}

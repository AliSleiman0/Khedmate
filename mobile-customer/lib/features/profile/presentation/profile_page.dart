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
    final authState = ref.watch(authNotifierProvider).valueOrNull;
    final user = authState is AuthAuthenticated ? (authState as AuthAuthenticated).customer : null;

    return Scaffold(
      appBar: AppBar(title: Text(s.profileTitle,
          style: const TextStyle(fontFamily: 'Cairo'))),
      body: ListView(
        children: [
          Container(
            color: AppColors.brandBlue,
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 36,
                  backgroundColor: Colors.white24,
                  child: Icon(Icons.person, size: 44, color: Colors.white),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user?.fullName ?? '—',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(
                      user?.phone ?? '—',
                      style: const TextStyle(color: Colors.white70)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          _tile(Icons.edit, s.profileEdit, () => context.push('/profile/edit')),
          _tile(Icons.location_on, s.profileAddresses,
              () => _comingSoon(context, s)),
          _tile(Icons.payment, s.profilePayment,
              () => _comingSoon(context, s)),
          _tile(Icons.card_giftcard, s.profileReferral,
              () => context.push('/referral')),
          _tile(Icons.language, s.langToggle, () {
            ref.read(localeProvider.notifier).state =
                locale.languageCode == 'ar'
                    ? const Locale('en')
                    : const Locale('ar');
          }),
          _tile(Icons.notifications, s.profileNotifs,
              () => context.push('/notifications')),
          _tile(Icons.help_outline, s.profileHelp, () async {
            final uri = Uri.parse('https://khudmati.app/#contact');
            if (await canLaunchUrl(uri)) {
              launchUrl(uri, mode: LaunchMode.externalApplication);
            }
          }),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: AppColors.danger),
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

  static void _comingSoon(BuildContext context, S s) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(s.comingSoon,
            style: const TextStyle(fontFamily: 'Cairo')),
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


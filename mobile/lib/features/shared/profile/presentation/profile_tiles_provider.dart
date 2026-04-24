import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/colors.dart';
import '../../../../core/l10n/app_strings.dart';
import '../../../../core/providers/locale_provider.dart';
import 'delete_account_action.dart';

class ProviderProfileTiles extends ConsumerWidget {
  const ProviderProfileTiles({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(ref);
    final locale = ref.watch(localeProvider);

    return Column(
      children: [
        _tile(Icons.edit, s.profileEdit,
            () => context.push('/provider/profile/edit')),
        _tile(Icons.verified_user, s.profileVerification,
            () => context.push('/provider/onboarding')),
        _tile(Icons.account_balance, s.profilePayment,
            () => context.push('/provider/payout-status')),
        _tile(Icons.workspace_premium, s.subTitle,
            () => context.push('/provider/subscription')),
        _tile(Icons.bar_chart_rounded, s.analyticsTitle,
            () => context.push('/provider/analytics')),
        _tile(Icons.schedule, s.profileWorkHours,
            () => _comingSoon(context, s)),
        _tile(Icons.language, s.langToggle, () {
          ref.read(localeProvider.notifier).setLocale(
                locale.languageCode == 'ar'
                    ? const Locale('en')
                    : const Locale('ar'),
              );
        }),
        _tile(Icons.notifications, s.profileNotifications,
            () => _comingSoon(context, s)),
        _tile(Icons.help_outline, s.providerProfileHelp, () async {
          final uri = Uri.parse('https://khudmati.app/#contact');
          if (await canLaunchUrl(uri)) {
            launchUrl(uri, mode: LaunchMode.externalApplication);
          }
        }),
        _destructiveTile(
          Icons.delete_forever,
          s.profileDeleteAccount,
          () => showDeleteAccountDialog(context, ref),
        ),
      ],
    );
  }

  static void _comingSoon(BuildContext context, S s) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          s.profileComingSoon,
          style: const TextStyle(fontFamily: 'Cairo'),
        ),
      ),
    );
  }

  static ListTile _tile(IconData icon, String label, VoidCallback onTap) =>
      ListTile(
        leading: Icon(icon, color: AppColors.brandBlue),
        title: Text(label, style: const TextStyle(fontFamily: 'Cairo')),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      );

  static ListTile _destructiveTile(
          IconData icon, String label, VoidCallback onTap) =>
      ListTile(
        leading: Icon(icon, color: Colors.red.shade700),
        title: Text(label,
            style: TextStyle(
                fontFamily: 'Cairo', color: Colors.red.shade700)),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      );
}

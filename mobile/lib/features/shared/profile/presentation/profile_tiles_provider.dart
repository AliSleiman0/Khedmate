import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/colors.dart';
import '../../../../core/l10n/app_strings.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../core/providers/locale_provider.dart';
import 'delete_account_action.dart';

const _tag = 'ProfileTilesP';

class ProviderProfileTiles extends ConsumerWidget {
  const ProviderProfileTiles({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(ref);
    final locale = ref.watch(localeProvider);

    return Column(
      children: [
        _tile(Icons.edit, s.profileEdit, () {
          log.d(_tag, 'tile tap', data: {'tile': 'edit'});
          context.push('/provider/profile/edit');
        }),
        _tile(Icons.verified_user, s.profileVerification, () {
          log.d(_tag, 'tile tap', data: {'tile': 'verification'});
          context.push('/provider/onboarding');
        }),
        _tile(Icons.account_balance, s.profilePayment, () {
          log.d(_tag, 'tile tap', data: {'tile': 'payout'});
          context.push('/provider/payout-status');
        }),
        _tile(Icons.workspace_premium, s.subTitle, () {
          log.d(_tag, 'tile tap', data: {'tile': 'subscription'});
          context.push('/provider/subscription');
        }),
        _tile(Icons.bar_chart_rounded, s.analyticsTitle, () {
          log.d(_tag, 'tile tap', data: {'tile': 'analytics'});
          context.push('/provider/analytics');
        }),
        _tile(Icons.schedule, s.profileWorkHours,
            () => _comingSoon(context, s, 'work_hours')),
        _tile(Icons.language, s.langToggle, () {
          log.d(_tag, 'tile tap', data: {'tile': 'language'});
          ref.read(localeProvider.notifier).setLocale(
                locale.languageCode == 'ar'
                    ? const Locale('en')
                    : const Locale('ar'),
              );
        }),
        _tile(Icons.notifications, s.profileNotifications,
            () => _comingSoon(context, s, 'notifications')),
        _tile(Icons.help_outline, s.providerProfileHelp, () async {
          log.d(_tag, 'tile tap', data: {'tile': 'help'});
          final uri = Uri.parse('https://khudmati.app/#contact');
          if (await canLaunchUrl(uri)) {
            launchUrl(uri, mode: LaunchMode.externalApplication);
          }
        }),
        _destructiveTile(
          Icons.delete_forever,
          s.profileDeleteAccount,
          () {
            log.d(_tag, 'tile tap', data: {'tile': 'delete_account'});
            showDeleteAccountDialog(context, ref);
          },
        ),
      ],
    );
  }

  static void _comingSoon(BuildContext context, S s, String tile) {
    log.d(_tag, 'tile tap (coming soon)', data: {'tile': tile});
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

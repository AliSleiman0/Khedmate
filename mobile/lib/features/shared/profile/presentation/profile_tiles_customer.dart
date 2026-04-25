import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/colors.dart';
import '../../../../core/l10n/app_strings.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../core/providers/locale_provider.dart';
import 'delete_account_action.dart';

const _tag = 'ProfileTilesC';

class CustomerProfileTiles extends ConsumerWidget {
  const CustomerProfileTiles({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(ref);
    final locale = ref.watch(localeProvider);

    return Column(
      children: [
        _tile(Icons.edit, s.profileEdit, () {
          log.d(_tag, 'tile tap', data: {'tile': 'edit'});
          context.push('/customer/profile/edit');
        }),
        _tile(Icons.location_on, s.profileAddresses,
            () => _comingSoon(context, s, 'addresses')),
        _tile(Icons.payment, s.profilePayment,
            () => _comingSoon(context, s, 'payment')),
        _tile(Icons.card_giftcard, s.profileReferral, () {
          log.d(_tag, 'tile tap', data: {'tile': 'referral'});
          context.push('/customer/referral');
        }),
        _tile(Icons.language, s.langToggle, () {
          log.d(_tag, 'tile tap', data: {'tile': 'language'});
          ref.read(localeProvider.notifier).setLocale(
                locale.languageCode == 'ar'
                    ? const Locale('en')
                    : const Locale('ar'),
              );
        }),
        _tile(Icons.notifications, s.profileNotifs, () {
          log.d(_tag, 'tile tap', data: {'tile': 'notifications'});
          context.push('/customer/notifications');
        }),
        _tile(Icons.help_outline, s.profileHelp, () async {
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
          s.comingSoon,
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

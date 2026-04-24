import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/colors.dart';
import '../../../../core/l10n/app_strings.dart';
import '../../../../core/providers/locale_provider.dart';
import 'delete_account_action.dart';

class CustomerProfileTiles extends ConsumerWidget {
  const CustomerProfileTiles({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(ref);
    final locale = ref.watch(localeProvider);

    return Column(
      children: [
        _tile(Icons.edit, s.profileEdit,
            () => context.push('/customer/profile/edit')),
        _tile(Icons.location_on, s.profileAddresses,
            () => _comingSoon(context, s)),
        _tile(Icons.payment, s.profilePayment,
            () => _comingSoon(context, s)),
        _tile(Icons.card_giftcard, s.profileReferral,
            () => context.push('/customer/referral')),
        _tile(Icons.language, s.langToggle, () {
          ref.read(localeProvider.notifier).setLocale(
                locale.languageCode == 'ar'
                    ? const Locale('en')
                    : const Locale('ar'),
              );
        }),
        _tile(Icons.notifications, s.profileNotifs,
            () => context.push('/customer/notifications')),
        _tile(Icons.help_outline, s.profileHelp, () async {
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

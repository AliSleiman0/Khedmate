import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/colors.dart';
import '../../../core/providers/locale_provider.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('الملف الشخصي')),
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
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('أحمد محمد',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold)),
                    SizedBox(height: 4),
                    Text('+966 50 000 0000',
                        style: TextStyle(color: Colors.white70)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          _tile(Icons.edit, 'تعديل البيانات', () {}),
          _tile(Icons.location_on, 'عناويني المحفوظة', () {}),
          _tile(Icons.payment, 'طرق الدفع', () {}),
          _tile(Icons.card_giftcard, 'دعوة الأصدقاء', () => context.push('/referral')),
          _tile(Icons.language, locale.languageCode == 'ar' ? 'English' : 'عربي', () {
            ref.read(localeProvider.notifier).state =
                locale.languageCode == 'ar' ? const Locale('en') : const Locale('ar');
          }),
          _tile(Icons.notifications, 'الإشعارات', () {}),
          _tile(Icons.help_outline, 'المساعدة والدعم', () {}),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: AppColors.danger),
            title: const Text('تسجيل الخروج',
                style: TextStyle(color: AppColors.danger)),
            onTap: () => context.go('/login'),
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

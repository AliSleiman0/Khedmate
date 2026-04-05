import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/colors.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الملف الشخصي')),
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
                const Text('خالد أحمد',
                    style: TextStyle(
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
                  child: const Text(
                    'موثق — المستوى 3 (اختبار المهارة)',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.star, color: AppColors.amber, size: 18),
                    const Text('4.8', style: TextStyle(color: Colors.white)),
                    const SizedBox(width: 16),
                    const Icon(Icons.work, color: Colors.white70, size: 18),
                    const Text('142 طلب', style: TextStyle(color: Colors.white)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          _tile(Icons.edit, 'تعديل البيانات', () {}),
          _tile(Icons.verified_user, 'مستوى التوثيق', () {}),
          _tile(Icons.account_balance, 'بيانات الدفع', () {}),
          _tile(Icons.schedule, 'ساعات العمل', () {}),
          _tile(Icons.notifications, 'الإشعارات', () {}),
          _tile(Icons.help_outline, 'المساعدة', () {}),
          const Divider(),
          ListTile(
            leading:
                const Icon(Icons.logout, color: AppColors.danger),
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

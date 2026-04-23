import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/colors.dart';
import '../../core/providers/role_provider.dart';

/// PLACEHOLDER — Phase 07 replaces this with the real provider home
/// (job feed, onboarding gate, earnings, etc.).
class ProviderPlaceholderHome extends ConsumerWidget {
  const ProviderPlaceholderHome({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Provider Home (PLACEHOLDER)')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.handyman_outlined,
              size: 72,
              color: AppColors.amber,
            ),
            const SizedBox(height: 16),
            const Text(
              'Provider home (placeholder)',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.amber,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => _logout(context, ref),
              icon: const Icon(Icons.logout),
              label: const Text('Logout'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    const storage = FlutterSecureStorage();
    await storage.delete(key: 'access_token');
    await storage.delete(key: 'refresh_token');
    await ref.read(roleProvider.notifier).clear();
    if (context.mounted) context.go('/welcome');
  }
}

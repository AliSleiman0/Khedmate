import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/colors.dart';
import '../../../core/providers/role_provider.dart';

/// PLACEHOLDER — Phase 04 replaces this with real phone+password login that
/// hits `/auth/customers/login` or `/auth/providers/login` based on roleProvider.
class LoginPlaceholder extends ConsumerWidget {
  const LoginPlaceholder({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(roleProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login (PLACEHOLDER)'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/welcome'),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 24),
            const Text(
              'PLACEHOLDER LOGIN',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.danger,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Role: ${role?.name ?? '(none)'}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () async {
                const storage = FlutterSecureStorage();
                await storage.write(key: 'access_token', value: 'mock-access');
                await storage.write(
                    key: 'refresh_token', value: 'mock-refresh');
                if (!context.mounted) return;
                final target = role == UserRole.provider
                    ? '/provider/home'
                    : '/customer/home';
                context.go(target);
              },
              child: const Text('Log in as mock user'),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => context.go('/register'),
              child: const Text('Go to register (placeholder)'),
            ),
          ],
        ),
      ),
    );
  }
}

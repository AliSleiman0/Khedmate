import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/colors.dart';
import '../../../core/providers/role_provider.dart';

/// PLACEHOLDER — Phase 04 replaces this with real signup (phone + OTP for
/// customers; phone + password + categories for providers).
class RegisterPlaceholder extends ConsumerWidget {
  const RegisterPlaceholder({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(roleProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Register (PLACEHOLDER)'),
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
              'PLACEHOLDER REGISTER',
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
              onPressed: () => context.go('/welcome'),
              child: const Text('Go back to welcome'),
            ),
          ],
        ),
      ),
    );
  }
}

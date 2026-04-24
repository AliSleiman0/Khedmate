import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/l10n/app_strings.dart';
import '../../../auth/presentation/auth_provider.dart';

/// Required for Apple App Store guideline 5.1.1(v) and Google Play Data
/// Safety: in-app account deletion that removes the account server-side.
/// Shows a destructive confirmation dialog, calls
/// `AuthNotifier.deleteAccount()`, then routes back to `/welcome`.
Future<void> showDeleteAccountDialog(BuildContext context, WidgetRef ref) async {
  final s = S.of(ref);
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(s.deleteAccountDialogTitle,
          style: const TextStyle(fontFamily: 'Cairo')),
      content: Text(s.deleteAccountDialogBody,
          style: const TextStyle(fontFamily: 'Cairo')),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: Text(s.deleteAccountCancel,
              style: const TextStyle(fontFamily: 'Cairo')),
        ),
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          style: TextButton.styleFrom(foregroundColor: Colors.red),
          child: Text(s.deleteAccountConfirm,
              style: const TextStyle(fontFamily: 'Cairo')),
        ),
      ],
    ),
  );

  if (confirmed != true) return;
  if (!context.mounted) return;

  final messenger = ScaffoldMessenger.of(context);
  try {
    await ref.read(authNotifierProvider.notifier).deleteAccount();
    if (!context.mounted) return;
    messenger.showSnackBar(SnackBar(
      content: Text(s.deleteAccountSuccess,
          style: const TextStyle(fontFamily: 'Cairo')),
    ));
    context.go('/welcome');
  } on DioException catch (e) {
    if (!context.mounted) return;
    final code = _extractErrorCode(e);
    final message = switch (code) {
      'HAS_ACTIVE_JOBS' => s.deleteAccountHasActiveJobs,
      'HAS_ACTIVE_SUBSCRIPTION' => s.deleteAccountHasActiveSubscription,
      _ => s.deleteAccountError,
    };
    messenger.showSnackBar(SnackBar(
      content: Text(message, style: const TextStyle(fontFamily: 'Cairo')),
      backgroundColor: Colors.red,
      duration: const Duration(seconds: 5),
    ));
  } catch (_) {
    if (!context.mounted) return;
    messenger.showSnackBar(SnackBar(
      content: Text(s.deleteAccountError,
          style: const TextStyle(fontFamily: 'Cairo')),
      backgroundColor: Colors.red,
    ));
  }
}

String? _extractErrorCode(DioException e) {
  final data = e.response?.data;
  if (data is Map && data['error'] is String) {
    return data['error'] as String;
  }
  return null;
}

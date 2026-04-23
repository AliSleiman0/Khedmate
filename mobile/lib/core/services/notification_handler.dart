import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/role_provider.dart';

/// Single source of truth for mapping FCM/local-notification payloads and
/// `khudmati://` deep links to GoRouter destinations. Route selection is
/// role-aware (customer vs provider) so a single payload can land in the
/// right tree for either app surface.
class NotificationHandler {
  final GoRouter router;
  final ProviderContainer container;

  NotificationHandler({required this.router, required this.container});

  UserRole? get _role => container.read(roleProvider);

  /// FCM tap → route. Safe to call before the first frame; navigation is
  /// deferred to post-frame.
  void handleFcmTap(RemoteMessage message) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _routeFromData(message.data);
    });
  }

  /// Custom-scheme deep link → route. Supports `khudmati://<host>/<path>`.
  void handleDeepLink(Uri uri) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _routeFromUri(uri);
    });
  }

  void _routeFromData(Map<String, dynamic> data) {
    final role = _role;
    final type = data['type']?.toString();
    final jobId = data['jobId']?.toString();

    switch (type) {
      case 'JOB_ACCEPTED':
      case 'PROVIDER_EN_ROUTE':
      case 'PROVIDER_ARRIVED':
      case 'JOB_COMPLETED':
        if (jobId == null) return;
        if (role == UserRole.customer) {
          router.push('/customer/tracking/$jobId');
        } else if (role == UserRole.provider) {
          router.push('/provider/active-job/$jobId');
        }
        break;
      case 'NEW_JOB_AVAILABLE':
        if (role == UserRole.provider) {
          router.push(jobId != null
              ? '/provider/job-detail/$jobId'
              : '/provider/jobs');
        }
        break;
      case 'PAYMENT_HELD':
        if (jobId == null) return;
        if (role == UserRole.customer) {
          router.push('/customer/payment/status/$jobId');
        }
        break;
      case 'PAYMENT_RELEASED':
        if (role == UserRole.customer && jobId != null) {
          router.push('/customer/payment/status/$jobId');
        } else if (role == UserRole.provider) {
          router.push('/provider/payout-status');
        }
        break;
      case 'DISPUTE_OPENED':
      case 'DISPUTE_RESOLVED':
        if (jobId == null) return;
        if (role == UserRole.customer) {
          router.push('/customer/history/$jobId');
        } else if (role == UserRole.provider) {
          router.push('/provider/job-detail/$jobId');
        }
        break;
      case 'MAINTENANCE_REMINDER':
        if (role == UserRole.customer) router.push('/customer/reminders');
        break;
      case 'VERIFICATION_APPROVED':
      case 'VERIFICATION_REJECTED':
        if (role == UserRole.provider) router.push('/provider/onboarding');
        break;
      case 'SUBSCRIPTION_ACTIVATED':
      case 'SUBSCRIPTION_CANCELLED':
      case 'SUBSCRIPTION_PAYMENT_FAILED':
        if (role == UserRole.provider) router.push('/provider/subscription');
        break;
      case 'NEW_CHAT_MESSAGE':
      case 'CHAT_MESSAGE':
        if (jobId == null) return;
        router.push(role == UserRole.provider
            ? '/provider/chat/$jobId'
            : '/customer/chat/$jobId');
        break;
      case 'ACCOUNT_SUSPENDED':
      case 'ACCOUNT_REINSTATED':
        if (role == UserRole.provider) router.push('/provider/profile');
        break;
      default:
        // Unknown — leave user wherever they are.
        if (kDebugMode) {
          debugPrint('NotificationHandler: unhandled type="$type"');
        }
        break;
    }
  }

  void _routeFromUri(Uri uri) {
    if (uri.scheme != 'khudmati') return;
    final role = _role;
    final host = uri.host;
    final segments = uri.pathSegments;

    switch (host) {
      case 'job':
        // khudmati://job/<jobId>
        final jobId = segments.isNotEmpty ? segments.first : null;
        if (jobId == null || jobId.isEmpty) return;
        if (role == UserRole.customer) {
          router.push('/customer/tracking/$jobId');
        } else if (role == UserRole.provider) {
          router.push('/provider/job-detail/$jobId');
        }
        break;
      case 'reminders':
        if (role == UserRole.customer) router.push('/customer/reminders');
        break;
      case 'onboarding':
        if (role == UserRole.provider) router.push('/provider/onboarding');
        break;
      case 'referral':
        // khudmati://referral?ref=CODE — also alias for /join?ref=CODE
        final code = uri.queryParameters['ref'];
        if (role == UserRole.customer) {
          router.push(code != null && code.isNotEmpty
              ? '/customer/referral?ref=$code'
              : '/customer/referral');
        }
        break;
      default:
        if (kDebugMode) debugPrint('NotificationHandler: unknown host "$host"');
        break;
    }
  }
}


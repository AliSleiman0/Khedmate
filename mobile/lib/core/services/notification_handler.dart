import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../logging/app_logger.dart';
import '../logging/redact.dart';
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
    log.d('NotifHandler', 'fcm tap', data: {
      'type': message.data['type'],
      'jobId': message.data['jobId'],
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _routeFromData(message.data);
    });
  }

  /// Custom-scheme deep link → route. Supports `khudmati://<host>/<path>`.
  void handleDeepLink(Uri uri) {
    log.d('NotifHandler', 'deep link', data: {
      'scheme': uri.scheme,
      'host': uri.host,
      'url': redactUrl(uri),
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _routeFromUri(uri);
    });
  }

  void _push(String target, {required String source}) {
    log.i('NotifHandler', 'route', data: {
      'target': target,
      'source': source,
    });
    router.push(target);
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
          _push('/customer/tracking/$jobId', source: 'fcm:$type');
        } else if (role == UserRole.provider) {
          _push('/provider/active-job/$jobId', source: 'fcm:$type');
        }
        break;
      case 'NEW_JOB_AVAILABLE':
        if (role == UserRole.provider) {
          _push(
            jobId != null ? '/provider/job-detail/$jobId' : '/provider/jobs',
            source: 'fcm:$type',
          );
        }
        break;
      case 'PAYMENT_HELD':
        if (jobId == null) return;
        if (role == UserRole.customer) {
          _push('/customer/payment/status/$jobId', source: 'fcm:$type');
        }
        break;
      case 'PAYMENT_RELEASED':
        if (role == UserRole.customer && jobId != null) {
          _push('/customer/payment/status/$jobId', source: 'fcm:$type');
        } else if (role == UserRole.provider) {
          _push('/provider/payout-status', source: 'fcm:$type');
        }
        break;
      case 'DISPUTE_OPENED':
      case 'DISPUTE_RESOLVED':
        if (jobId == null) return;
        if (role == UserRole.customer) {
          _push('/customer/history/$jobId', source: 'fcm:$type');
        } else if (role == UserRole.provider) {
          _push('/provider/job-detail/$jobId', source: 'fcm:$type');
        }
        break;
      case 'MAINTENANCE_REMINDER':
        if (role == UserRole.customer) {
          _push('/customer/reminders', source: 'fcm:$type');
        }
        break;
      case 'VERIFICATION_APPROVED':
      case 'VERIFICATION_REJECTED':
        if (role == UserRole.provider) {
          _push('/provider/onboarding', source: 'fcm:$type');
        }
        break;
      case 'SUBSCRIPTION_ACTIVATED':
      case 'SUBSCRIPTION_CANCELLED':
      case 'SUBSCRIPTION_PAYMENT_FAILED':
        if (role == UserRole.provider) {
          _push('/provider/subscription', source: 'fcm:$type');
        }
        break;
      case 'NEW_CHAT_MESSAGE':
      case 'CHAT_MESSAGE':
        if (jobId == null) return;
        _push(
          role == UserRole.provider
              ? '/provider/chat/$jobId'
              : '/customer/chat/$jobId',
          source: 'fcm:$type',
        );
        break;
      case 'ACCOUNT_SUSPENDED':
      case 'ACCOUNT_REINSTATED':
        if (role == UserRole.provider) {
          _push('/provider/profile', source: 'fcm:$type');
        }
        break;
      default:
        // Unknown — leave user wherever they are.
        log.w('NotifHandler', 'unhandled type', data: {'type': type});
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
          _push('/customer/tracking/$jobId', source: 'deeplink:job');
        } else if (role == UserRole.provider) {
          _push('/provider/job-detail/$jobId', source: 'deeplink:job');
        }
        break;
      case 'reminders':
        if (role == UserRole.customer) {
          _push('/customer/reminders', source: 'deeplink:reminders');
        }
        break;
      case 'onboarding':
        if (role == UserRole.provider) {
          _push('/provider/onboarding', source: 'deeplink:onboarding');
        }
        break;
      case 'referral':
        // khudmati://referral?ref=CODE — also alias for /join?ref=CODE
        final code = uri.queryParameters['ref'];
        if (role == UserRole.customer) {
          _push(
            code != null && code.isNotEmpty
                ? '/customer/referral?ref=$code'
                : '/customer/referral',
            source: 'deeplink:referral',
          );
        }
        break;
      default:
        log.w('NotifHandler', 'unknown host', data: {'host': host});
        break;
    }
  }
}

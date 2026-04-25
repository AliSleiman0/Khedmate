import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../logging/app_logger.dart';
import '../providers/role_provider.dart';

const _tag = 'SmartBack';

/// Single source of truth for "go back" behaviour across every screen.
///
/// Rules:
/// 1. If the navigation stack has a previous entry, pop it.
/// 2. Otherwise, route to the role-aware home (`/customer/home`,
///    `/provider/jobs`, or `/welcome` when there's no role).
/// 3. When the caller is already on that home (or on `/welcome` itself),
///    fall back to `SystemNavigator.pop()` — closes the app on Android,
///    no-op on iOS per Apple HIG.
void smartBack(BuildContext context, WidgetRef ref) {
  final canPop = context.canPop();
  final location = GoRouterState.of(context).uri.path;
  final role = ref.read(roleProvider);

  if (canPop) {
    log.d(_tag, 'pop',
        data: {'from': location, 'role': role?.name ?? 'none'});
    context.pop();
    return;
  }

  final home = role == UserRole.customer
      ? '/customer/home'
      : role == UserRole.provider
          ? '/provider/jobs'
          : '/welcome';

  if (location == home || location == '/welcome') {
    log.d(_tag, 'system pop',
        data: {'from': location, 'role': role?.name ?? 'none'});
    SystemNavigator.pop();
    return;
  }

  log.d(_tag, 'go home',
      data: {'from': location, 'to': home, 'role': role?.name ?? 'none'});
  context.go(home);
}

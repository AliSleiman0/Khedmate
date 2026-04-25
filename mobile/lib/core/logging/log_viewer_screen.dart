import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:talker_flutter/talker_flutter.dart';
import 'app_logger_providers.dart';

/// Debug-only log viewer. Wraps `TalkerScreen` so testers can scroll the
/// in-memory log history and share a capture from the Help & Support tile.
///
/// Only registered on the router when `kDebugMode` is true — the route is
/// not reachable in release builds.
class LogViewerScreen extends ConsumerWidget {
  const LogViewerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!kDebugMode) {
      return const Scaffold(
        body: Center(child: Text('Log viewer disabled in release builds')),
      );
    }
    final talker = ref.watch(talkerProvider);
    return TalkerScreen(
      talker: talker,
      appBarTitle: 'Khudmati logs',
    );
  }
}

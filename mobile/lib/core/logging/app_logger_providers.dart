import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:talker_flutter/talker_flutter.dart';
import 'app_logger.dart';

/// Riverpod handle for the [AppLogger] singleton. Override in tests with a
/// fresh `AppLogger` if you want to assert on log output.
final loggerProvider = Provider<AppLogger>((_) => AppLogger.instance);

/// Direct access to the underlying [Talker] instance — used by Phase 02
/// adapters (`TalkerDioLogger`, `TalkerRouteObserver`, etc.) that need the
/// raw type rather than the wrapper.
final talkerProvider = Provider<Talker>(
  (ref) => ref.watch(loggerProvider).talker,
);

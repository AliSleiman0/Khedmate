import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../logging/app_logger.dart';

/// App-wide flag flipped whenever the device loses (or regains) connectivity.
/// `KhudmatiApp.build` watches this and swaps a full-screen `NoInternetScreen`
/// over the rest of the app while it is `true`.
///
/// Two writers feed it:
///  * [ConnectivityService] — listens to platform connectivity changes
///    (interface up/down).
///  * `ApiClient.onError` — flips it on a `DioExceptionType.connectionError`
///    so we still catch captive portals where the interface is "up" but
///    real reachability is broken.
final noInternetProvider = StateProvider<bool>((_) => false);

/// Subscribes to [Connectivity.onConnectivityChanged] and reflects each
/// transition into [noInternetProvider]. Reading this provider once at
/// bootstrap is enough — the subscription stays alive as long as the
/// container does.
class ConnectivityService {
  ConnectivityService(this._ref) {
    _start();
  }

  final Ref _ref;
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _sub;

  Future<void> _start() async {
    try {
      final initial = await _connectivity.checkConnectivity();
      _apply(initial);
    } catch (e) {
      log.w('Connectivity', 'initial check failed', error: e);
    }

    _sub = _connectivity.onConnectivityChanged.listen(
      _apply,
      onError: (Object e) => log.w('Connectivity', 'stream error', error: e),
    );

    _ref.onDispose(() {
      _sub?.cancel();
      _sub = null;
    });
  }

  void _apply(List<ConnectivityResult> results) {
    final offline = results.isEmpty ||
        results.every((r) => r == ConnectivityResult.none);
    final notifier = _ref.read(noInternetProvider.notifier);
    if (notifier.state != offline) {
      log.i('Connectivity', 'state', data: {'online': !offline});
      notifier.state = offline;
    }
  }

  /// Re-checks connectivity on demand (used by the Retry button on
  /// [NoInternetScreen]). Returns `true` when online.
  Future<bool> recheck() async {
    try {
      final results = await _connectivity.checkConnectivity();
      _apply(results);
      return !_ref.read(noInternetProvider);
    } catch (e) {
      log.w('Connectivity', 'recheck failed', error: e);
      return false;
    }
  }
}

final connectivityServiceProvider = Provider<ConnectivityService>((ref) {
  return ConnectivityService(ref);
});

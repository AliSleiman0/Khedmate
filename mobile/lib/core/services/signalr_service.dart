import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:signalr_netcore/signalr_client.dart';
import '../constants/app_config.dart';

class SignalRService {
  static const _hubUrl = AppConfig.hubUrl;

  HubConnection? _connection;
  final _storage = const FlutterSecureStorage();

  HubConnection? get connection => _connection;

  Future<void> connect() async {
    if (_connection?.state == HubConnectionState.Connected) return;

    final token = await _storage.read(key: 'access_token');

    _connection = HubConnectionBuilder()
        .withUrl(
          _hubUrl,
          options: HttpConnectionOptions(
            accessTokenFactory: () async => token ?? '',
          ),
        )
        .withAutomaticReconnect()
        .build();

    await _connection!.start();
  }

  void on(String methodName, Function(List<Object?>?) handler) {
    _connection?.on(methodName, handler);
  }

  Future<void> invoke(String methodName, [List<Object>? args]) async {
    if (_connection?.state == HubConnectionState.Connected) {
      await _connection!.invoke(methodName, args: args);
    }
  }

  /// Join provider-side SignalR groups. `provider-{providerId}` is always
  /// joined server-side based on the JWT audience claim; the other two
  /// groups (`providers-available`, `providers-power`) are conditional:
  /// - Active tier providers see live job broadcasts → `providers-available`
  /// - Active Power subscribers get a 30-second head start → `providers-power`
  ///
  /// The method invocations are best-effort; if the server hasn't defined
  /// a given RPC, the invoke silently fails (matches the `if Connected`
  /// guard above).
  Future<void> joinProviderGroups({
    required bool isActive,
    required bool hasActiveSubscription,
  }) async {
    if (_connection?.state != HubConnectionState.Connected) return;
    if (isActive) {
      try {
        await _connection!.invoke('JoinProvidersAvailable');
      } catch (_) {
        // Non-fatal — server-side auto-join already covers the primary case.
      }
    }
    if (hasActiveSubscription) {
      try {
        await _connection!.invoke('JoinProvidersPower');
      } catch (_) {}
    }
  }

  Future<void> disconnect() async {
    await _connection?.stop();
    _connection = null;
  }
}

final signalRServiceProvider = Provider<SignalRService>((ref) {
  final service = SignalRService();
  ref.onDispose(service.disconnect);
  return service;
});

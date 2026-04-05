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

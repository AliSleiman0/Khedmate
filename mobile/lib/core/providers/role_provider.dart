import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

enum UserRole { customer, provider }

const _kRoleStorageKey = 'user_role';

class RoleNotifier extends StateNotifier<UserRole?> {
  final FlutterSecureStorage _storage;
  RoleNotifier(this._storage) : super(null) {
    _hydrate();
  }

  Future<void> _hydrate() async {
    final raw = await _storage.read(key: _kRoleStorageKey);
    if (raw == 'customer') state = UserRole.customer;
    if (raw == 'provider') state = UserRole.provider;
  }

  Future<void> setRole(UserRole role) async {
    state = role;
    await _storage.write(key: _kRoleStorageKey, value: role.name);
  }

  Future<void> clear() async {
    state = null;
    await _storage.delete(key: _kRoleStorageKey);
  }
}

final secureStorageProvider = Provider<FlutterSecureStorage>(
  (_) => const FlutterSecureStorage(),
);

final roleProvider = StateNotifierProvider<RoleNotifier, UserRole?>((ref) {
  return RoleNotifier(ref.read(secureStorageProvider));
});

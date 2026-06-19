// ============================================================
// TO Best Management — features/auth/providers/mgmt_auth_provider.dart
// ============================================================

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared/config/app_config.dart';
import 'package:shared/domain/entities/user.dart';
import 'package:shared/infrastructure/gas_client.dart';
import 'package:shared/infrastructure/isar_service.dart';
import 'package:shared/data/models/user_model.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

part 'mgmt_auth_provider.g.dart';

@riverpod
GasClient mgmtGasClient(MgmtGasClientRef ref) => GasClient();

@riverpod
IsarService mgmtIsarService(MgmtIsarServiceRef ref) => IsarService();

@riverpod
class MgmtAuthState extends _$MgmtAuthState {
  static const _deviceIdKey = 'mgmt_device_id';
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  @override
  Future<UserEntity?> build() async {
    final isar = ref.read(mgmtIsarServiceProvider);
    final db = await isar.db;
    final models = await db.userIsarModels.where().findAll();
    final model = models.isEmpty ? null : models.first;
    if (model == null) return null;

    // فحص أن الدور إداري
    if (!AppConfig.management_allowedRoles.contains(model.role)) {
      await isar.clearAll();
      return null;
    }

    return model.toEntity();
  }

  Future<void> login({
    required String email,
    required String password,
  }) async {
    state = const AsyncLoading();

    final deviceId = await _getOrCreateDeviceId();
    final deviceInfo = await _getDeviceInfo();

    state = await AsyncValue.guard(() async {
      final gasClient = ref.read(mgmtGasClientProvider);
      final result = await gasClient.post(
        action: 'LOGIN',
        data: {
          'email': email,
          'password': password,
          'deviceId': deviceId,
          'deviceName': deviceInfo,
          'platform': defaultTargetPlatform == TargetPlatform.android
              ? 'android'
              : 'ios',
        },
      );

      final userData = result['user'] as Map<String, dynamic>?;
      if (userData == null) throw Exception('invalid_response');

      final model = UserIsarModel.fromJson(userData);

      if (!AppConfig.management_allowedRoles.contains(model.role)) {
        throw Exception('unauthorized_role');
      }

      final isar = ref.read(mgmtIsarServiceProvider);
      final db = await isar.db;
      await db.writeTxn(() async {
        await db.userIsarModels.put(model);
      });

      return model.toEntity();
    });
  }

  Future<void> logout() async {
    try {
      final user = state.valueOrNull;
      if (user != null) {
        final gasClient = ref.read(mgmtGasClientProvider);
        await gasClient.post(action: 'LOGOUT', data: {'uid': user.uid});
      }
    } catch (_) {}

    final isar = ref.read(mgmtIsarServiceProvider);
    await isar.clearAll();
    state = const AsyncData(null);
  }

  Future<String> _getOrCreateDeviceId() async {
    var id = await _storage.read(key: _deviceIdKey);
    if (id == null || id.isEmpty) {
      id = const Uuid().v4();
      await _storage.write(key: _deviceIdKey, value: id);
    }
    return id;
  }

  Future<String> _getDeviceInfo() async {
    final plugin = DeviceInfoPlugin();
    if (defaultTargetPlatform == TargetPlatform.android) {
      final info = await plugin.androidInfo;
      return '${info.brand} ${info.model} [Management]';
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      final info = await plugin.iosInfo;
      return '${info.name ?? info.model} [Management]';
    }
    return 'Management Device';
  }
}

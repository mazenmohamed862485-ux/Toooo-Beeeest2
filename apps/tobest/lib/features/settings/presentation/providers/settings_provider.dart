// ============================================================
// TO Best — features/settings/presentation/providers/settings_provider.dart
// إعدادات التطبيق: ثيم، لغة، لون، حجم خط
// ============================================================

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared/design/themes.dart';
import 'package:shared/design/tokens.dart';
import 'package:shared/infrastructure/isar_service.dart';
import 'package:shared/infrastructure/background_service.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

part 'settings_provider.g.dart';

/// إعدادات التطبيق المحلية
class AppSettings {
  const AppSettings({
    this.theme = AppTheme.auto,
    this.accentColor = const Color(0xFF4F46E5), // accent1
    this.locale = const Locale('ar', 'SA'),
    this.fontSize = 1.0,
    this.notificationsEnabled = true,
    this.backgroundSyncEnabled = true,
  });

  final AppTheme theme;
  final Color accentColor;
  final Locale locale;

  /// مضاعِف حجم الخط (0.9 / 1.0 / 1.1 / 1.2)
  final double fontSize;

  final bool notificationsEnabled;
  final bool backgroundSyncEnabled;

  AppSettings copyWith({
    AppTheme? theme,
    Color? accentColor,
    Locale? locale,
    double? fontSize,
    bool? notificationsEnabled,
    bool? backgroundSyncEnabled,
  }) {
    return AppSettings(
      theme: theme ?? this.theme,
      accentColor: accentColor ?? this.accentColor,
      locale: locale ?? this.locale,
      fontSize: fontSize ?? this.fontSize,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      backgroundSyncEnabled:
          backgroundSyncEnabled ?? this.backgroundSyncEnabled,
    );
  }

  /// تحويل لـ JSON للتخزين
  String toJson() {
    return jsonEncode({
      'theme': theme.name,
      'accentColor': accentColor.value,
      'locale': locale.languageCode,
      'fontSize': fontSize,
      'notificationsEnabled': notificationsEnabled,
      'backgroundSyncEnabled': backgroundSyncEnabled,
    });
  }

  /// بناء من JSON
  factory AppSettings.fromJson(String json) {
    try {
      final map = jsonDecode(json) as Map<String, dynamic>;
      return AppSettings(
        theme: AppTheme.values.firstWhere(
          (t) => t.name == map['theme'],
          orElse: () => AppTheme.auto,
        ),
        accentColor: Color(map['accentColor'] as int? ?? 0xFF4F46E5),
        locale: Locale(map['locale'] as String? ?? 'ar'),
        fontSize: (map['fontSize'] as num?)?.toDouble() ?? 1.0,
        notificationsEnabled: map['notificationsEnabled'] as bool? ?? true,
        backgroundSyncEnabled: map['backgroundSyncEnabled'] as bool? ?? true,
      );
    } catch (_) {
      return const AppSettings();
    }
  }
}

// ── Isar Keys للإعدادات ───────────────────────────────────────
class _SettingsKeys {
  static const String settings = 'app_settings';
}

@riverpod
class Settings extends _$Settings {
  @override
  AppSettings build() {
    // تحميل الإعدادات من Isar بشكل async
    _loadFromIsar();
    return const AppSettings(); // القيم الافتراضية
  }

  Future<void> _loadFromIsar() async {
    final isar = ref.read(isarServiceProvider);
    final db = await isar.db;

    final stored = await db.appSettingsIsarModels
        .filter()
        .keyEqualTo(_SettingsKeys.settings)
        .findFirst();

    if (stored != null) {
      state = AppSettings.fromJson(stored.value);
    }
  }

  Future<void> _saveToIsar(AppSettings settings) async {
    final isar = ref.read(isarServiceProvider);
    final db = await isar.db;

    final existing = await db.appSettingsIsarModels
        .filter()
        .keyEqualTo(_SettingsKeys.settings)
        .findFirst();

    await db.writeTxn(() async {
      final model = AppSettingsIsarModel(
        key: _SettingsKeys.settings,
        value: settings.toJson(),
        updatedAt: DateTime.now(),
      );
      if (existing != null) {
        model.id = existing.id;
      }
      await db.appSettingsIsarModels.put(model);
    });
  }

  // ── دوال التحديث ──────────────────────────────────────────

  Future<void> setTheme(AppTheme theme) async {
    state = state.copyWith(theme: theme);
    await _saveToIsar(state);
  }

  Future<void> setAccentColor(Color color) async {
    state = state.copyWith(accentColor: color);
    await _saveToIsar(state);
  }

  Future<void> setLocale(Locale locale) async {
    state = state.copyWith(locale: locale);
    await _saveToIsar(state);
  }

  Future<void> setFontSize(double size) async {
    state = state.copyWith(fontSize: size.clamp(0.9, 1.2));
    await _saveToIsar(state);
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    state = state.copyWith(notificationsEnabled: enabled);
    await _saveToIsar(state);
  }

  Future<void> setBackgroundSyncEnabled(bool enabled) async {
    state = state.copyWith(backgroundSyncEnabled: enabled);
    await _saveToIsar(state);
    await BackgroundService().setEnabled(enabled);
  }
}

// shorthand
typedef AppSettingsNotifier = Settings;

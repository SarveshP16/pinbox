import 'package:flutter/material.dart' show ThemeMode;
import 'package:shared_preferences/shared_preferences.dart';

import 'app_settings.dart';

class SettingsRepository {
  const SettingsRepository(this._prefs);

  final SharedPreferences _prefs;

  static const _biometric = 'biometric_enabled';
  static const _autoLock = 'auto_lock_seconds';
  static const _screenshots = 'block_screenshots';
  static const _hideAfter = 'hide_after_seconds';
  static const _clearClipboard = 'clear_clipboard_seconds';
  static const _themeMode = 'theme_mode';

  AppSettings read() {
    const d = AppSettings();
    return AppSettings(
      biometricEnabled: _prefs.getBool(_biometric) ?? d.biometricEnabled,
      autoLockSeconds: _prefs.getInt(_autoLock) ?? d.autoLockSeconds,
      blockScreenshots: _prefs.getBool(_screenshots) ?? d.blockScreenshots,
      hideAfterSeconds: _prefs.getInt(_hideAfter) ?? d.hideAfterSeconds,
      clearClipboardSeconds:
          _prefs.getInt(_clearClipboard) ?? d.clearClipboardSeconds,
      // An unrecognised stored value falls back to following the system.
      themeMode:
          ThemeMode.values.asNameMap()[_prefs.getString(_themeMode)] ??
          d.themeMode,
    );
  }

  Future<void> write(AppSettings s) async {
    await _prefs.setBool(_biometric, s.biometricEnabled);
    await _prefs.setInt(_autoLock, s.autoLockSeconds);
    await _prefs.setBool(_screenshots, s.blockScreenshots);
    await _prefs.setInt(_hideAfter, s.hideAfterSeconds);
    await _prefs.setInt(_clearClipboard, s.clearClipboardSeconds);
    await _prefs.setString(_themeMode, s.themeMode.name);
  }
}

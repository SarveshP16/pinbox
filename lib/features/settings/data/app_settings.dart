import 'package:flutter/material.dart' show ThemeMode;

import '../../vault/domain/entry_sort.dart';

/// User-tunable behaviour. None of this is secret, so it lives in plain preferences.
class AppSettings {
  const AppSettings({
    this.biometricEnabled = false,
    this.autoLockSeconds = 60,
    this.blockScreenshots = true,
    this.hideAfterSeconds = 10,
    this.clearClipboardSeconds = 30,
    this.themeMode = ThemeMode.system,
    this.entrySort = EntrySort.alphabetical,
  });

  final bool biometricEnabled;

  /// Time in the background before the app re-locks. 0 = immediately.
  final int autoLockSeconds;
  final bool blockScreenshots;

  /// How long a revealed PIN stays visible.
  final int hideAfterSeconds;

  /// How long a copied PIN stays on the clipboard. 0 = never clear.
  final int clearClipboardSeconds;

  /// Light, dark, or follow the phone's setting.
  final ThemeMode themeMode;

  /// How the My PINs list is ordered.
  final EntrySort entrySort;

  AppSettings copyWith({
    bool? biometricEnabled,
    int? autoLockSeconds,
    bool? blockScreenshots,
    int? hideAfterSeconds,
    int? clearClipboardSeconds,
    ThemeMode? themeMode,
    EntrySort? entrySort,
  }) => AppSettings(
    biometricEnabled: biometricEnabled ?? this.biometricEnabled,
    autoLockSeconds: autoLockSeconds ?? this.autoLockSeconds,
    blockScreenshots: blockScreenshots ?? this.blockScreenshots,
    hideAfterSeconds: hideAfterSeconds ?? this.hideAfterSeconds,
    clearClipboardSeconds: clearClipboardSeconds ?? this.clearClipboardSeconds,
    themeMode: themeMode ?? this.themeMode,
    entrySort: entrySort ?? this.entrySort,
  );
}

import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../vault/domain/entry_sort.dart';
import '../data/app_settings.dart';

final settingsProvider = NotifierProvider<SettingsController, AppSettings>(
  SettingsController.new,
);

class SettingsController extends Notifier<AppSettings> {
  @override
  AppSettings build() => ref.watch(settingsRepositoryProvider).read();

  Future<void> _update(AppSettings next) async {
    state = next;
    await ref.read(settingsRepositoryProvider).write(next);
  }

  Future<void> setBiometric(bool value) =>
      _update(state.copyWith(biometricEnabled: value));
  Future<void> setAutoLockSeconds(int value) =>
      _update(state.copyWith(autoLockSeconds: value));
  Future<void> setBlockScreenshots(bool value) =>
      _update(state.copyWith(blockScreenshots: value));
  Future<void> setHideAfterSeconds(int value) =>
      _update(state.copyWith(hideAfterSeconds: value));
  Future<void> setClearClipboardSeconds(int value) =>
      _update(state.copyWith(clearClipboardSeconds: value));
  Future<void> setThemeMode(ThemeMode value) =>
      _update(state.copyWith(themeMode: value));
  Future<void> setEntrySort(EntrySort value) =>
      _update(state.copyWith(entrySort: value));
}

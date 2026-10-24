import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/routes.dart';
import '../../../core/app_info.dart';
import '../../../core/providers.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../core/widgets/page_header.dart';
import '../../backup/application/snapshot_controller.dart';
import '../../backup/domain/snapshot_labels.dart';
import '../../backup/presentation/backup_actions.dart';
import '../../backup/presentation/restore_snapshot_sheet.dart';
import '../../lock/application/lock_controller.dart';
import '../application/settings_controller.dart';
import '../domain/duration_labels.dart';
import 'widgets/option_sheet.dart';
import 'widgets/settings_group.dart';
import 'widgets/settings_tiles.dart';

const _autoLockChoices = [0, 30, 60, 300, 900];
const _hideAfterChoices = [5, 10, 15, 30];
const _clipboardChoices = [10, 30, 60, 0];

const _themeChoices = [
  (label: 'System default', value: ThemeMode.system),
  (label: 'Light', value: ThemeMode.light),
  (label: 'Dark', value: ThemeMode.dark),
];

String _themeLabel(ThemeMode mode) =>
    _themeChoices.firstWhere((c) => c.value == mode).label;

/// "3 kept · newest just now" for the Automatic backups row.
String _snapshotSubtitle(AsyncValue<List<SnapshotSummary>> snapshots) =>
    switch (snapshots) {
      AsyncLoading() => 'Checking this device',
      AsyncError() => 'Couldn’t be read on this device',
      AsyncValue(value: final list) when (list ?? const []).isEmpty =>
        'None yet · taken before each change',
      AsyncValue(value: final list) =>
        '${list!.length} kept · newest '
            '${describeSnapshotTime(list.first.snapshot.takenAt).toLowerCase()}',
    };

/// Screen 5: unlock, privacy, appearance and backup preferences.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final controller = ref.read(settingsProvider.notifier);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const PageHeader(title: 'Settings'),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 22, 24, 32),
                children: [
                  const SectionLabel('UNLOCK'),
                  SettingsGroup(
                    children: [
                      SwitchTile(
                        title: 'Biometric unlock',
                        subtitle: 'Fingerprint or face',
                        value: settings.biometricEnabled,
                        onChanged: (on) => _toggleBiometric(context, ref, on),
                      ),
                      NavTile(
                        title: 'Change master PIN',
                        onTap: () => context.push(AppRoutes.changePin),
                      ),
                      NavTile(
                        title: 'Auto-lock',
                        value: describeSeconds(
                          settings.autoLockSeconds,
                          zero: 'Immediately',
                        ),
                        onTap: () async {
                          final picked = await showOptionSheet<int>(
                            context,
                            title: 'Auto-lock',
                            selected: settings.autoLockSeconds,
                            options: [
                              for (final s in _autoLockChoices)
                                (
                                  label: describeSeconds(
                                    s,
                                    zero: 'Immediately',
                                  ),
                                  value: s,
                                ),
                            ],
                          );
                          if (picked != null) {
                            controller.setAutoLockSeconds(picked);
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  const SectionLabel('PRIVACY'),
                  SettingsGroup(
                    children: [
                      SwitchTile(
                        title: 'Block screenshots',
                        subtitle: 'Also hides the app in recent apps',
                        value: settings.blockScreenshots,
                        onChanged: controller.setBlockScreenshots,
                      ),
                      NavTile(
                        title: 'Hide revealed PINs after',
                        value: describeSeconds(settings.hideAfterSeconds),
                        onTap: () async {
                          final picked = await showOptionSheet<int>(
                            context,
                            title: 'Hide revealed PINs after',
                            selected: settings.hideAfterSeconds,
                            options: [
                              for (final s in _hideAfterChoices)
                                (label: describeSeconds(s), value: s),
                            ],
                          );
                          if (picked != null) {
                            controller.setHideAfterSeconds(picked);
                          }
                        },
                      ),
                      NavTile(
                        title: 'Clear clipboard',
                        value: describeSeconds(settings.clearClipboardSeconds),
                        onTap: () async {
                          final picked = await showOptionSheet<int>(
                            context,
                            title: 'Clear clipboard',
                            selected: settings.clearClipboardSeconds,
                            options: [
                              for (final s in _clipboardChoices)
                                (label: describeSeconds(s), value: s),
                            ],
                          );
                          if (picked != null) {
                            controller.setClearClipboardSeconds(picked);
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  const SectionLabel('APPEARANCE'),
                  SettingsGroup(
                    children: [
                      NavTile(
                        title: 'Theme',
                        value: _themeLabel(settings.themeMode),
                        onTap: () async {
                          final picked = await showOptionSheet<ThemeMode>(
                            context,
                            title: 'Theme',
                            selected: settings.themeMode,
                            options: _themeChoices,
                          );
                          if (picked != null) controller.setThemeMode(picked);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  const SectionLabel('BACKUP'),
                  SettingsGroup(
                    children: [
                      ActionTile(
                        title: 'Export encrypted backup',
                        subtitle: 'Protected by a password you choose',
                        icon: LucideIcons.download,
                        onTap: () => exportBackup(context, ref),
                      ),
                      ActionTile(
                        title: 'Restore from backup',
                        subtitle: 'Add PINs from an exported file',
                        icon: LucideIcons.upload,
                        onTap: () => importBackup(context, ref),
                      ),
                      ActionTile(
                        title: 'Automatic backups',
                        subtitle: _snapshotSubtitle(
                          ref.watch(snapshotsProvider),
                        ),
                        icon: LucideIcons.history,
                        onTap: () => showRestoreSnapshotSheet(context, ref),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  const SectionLabel('SUPPORT'),
                  SettingsGroup(
                    children: [
                      ActionTile(
                        title: 'Support Pinbox',
                        subtitle: 'Buy me a coffee on Ko-fi',
                        icon: LucideIcons.coffee,
                        onTap: () => _openKofi(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      'Everything is encrypted and stored on this device only.',
                      textAlign: TextAlign.center,
                      style: AppText.body(
                        14,
                        color: context.colors.muted,
                        height: 1.4,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      _versionLabel(ref.watch(packageInfoProvider)),
                      textAlign: TextAlign.center,
                      style: AppText.body(12.5, color: context.colors.muted),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleBiometric(
    BuildContext context,
    WidgetRef ref,
    bool on,
  ) async {
    final settings = ref.read(settingsProvider.notifier);
    if (!on) {
      await settings.setBiometric(false);
      return;
    }
    final lock = ref.read(lockProvider.notifier);
    if (!await lock.biometricsAvailable()) {
      if (context.mounted) {
        showAppSnackBar(
          context,
          'Set up a fingerprint or face unlock in your phone’s settings first',
        );
      }
      return;
    }
    // Prove it works before relying on it.
    if (await lock.authenticateBiometrically('Turn on biometric unlock')) {
      await settings.setBiometric(true);
    }
  }
}

/// "Pinbox 1.0.0 (Beta) · Build 1", or just "Pinbox" while the version is loading
/// (package_info's platform channel is effectively instant, but never blocks first paint).
String _versionLabel(AsyncValue<PackageInfo> info) {
  final loaded = info.value;
  if (loaded == null) return 'Pinbox';
  final beta = kIsBetaRelease ? ' (Beta)' : '';
  return 'Pinbox ${loaded.version}$beta · Build ${loaded.buildNumber}';
}

Future<void> _openKofi(BuildContext context) async {
  final uri = Uri.parse(kKoFiUrl);
  var opened = false;
  try {
    opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
  } on Object {
    opened = false;
  }
  if (!opened && context.mounted) {
    showAppSnackBar(context, 'Couldn’t open the link. Visit $kKoFiUrl');
  }
}

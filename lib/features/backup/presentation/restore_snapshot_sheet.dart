import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../vault/application/vault_controller.dart';
import '../application/snapshot_controller.dart';
import '../domain/snapshot_labels.dart';

/// Lists the automatic snapshots and restores the one the user picks.
///
/// Restoring replaces the whole vault, so it asks first — and because the save
/// path snapshots the pre-restore state, picking the wrong one is recoverable.
Future<void> showRestoreSnapshotSheet(BuildContext context, WidgetRef ref) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: context.colors.background,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (_) => const SafeArea(child: _SnapshotList()),
  );
}

class _SnapshotList extends ConsumerWidget {
  const _SnapshotList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshots = ref.watch(snapshotsProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 22, 24, 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Automatic backups',
            style: AppText.display(18, weight: 800, letterSpacing: -0.3),
          ),
          const SizedBox(height: 6),
          Text(
            'Taken on this device before each change. They stay on this phone and '
            'cannot be read after the app is uninstalled.',
            style: AppText.body(13, weight: 500, color: context.colors.muted),
          ),
          const SizedBox(height: 14),
          switch (snapshots) {
            AsyncLoading() => const Padding(
              padding: EdgeInsets.symmetric(vertical: 28),
              child: Center(child: CircularProgressIndicator()),
            ),
            AsyncError() => Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Text(
                'Couldn’t read the automatic backups on this device.',
                style: AppText.body(
                  15,
                  weight: 500,
                  color: context.colors.danger,
                ),
              ),
            ),
            AsyncValue(value: final list) when (list ?? const []).isEmpty =>
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Text(
                  'No automatic backups yet. The first one is taken the next time '
                  'you add or change an entry.',
                  style: AppText.body(
                    15,
                    weight: 500,
                    color: context.colors.muted,
                  ),
                ),
              ),
            AsyncValue(value: final list) => Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final summary in list!)
                    _SnapshotRow(
                      summary: summary,
                      onTap: () => _restore(context, ref, summary),
                    ),
                ],
              ),
            ),
          },
        ],
      ),
    );
  }

  Future<void> _restore(
    BuildContext context,
    WidgetRef ref,
    SnapshotSummary summary,
  ) async {
    final when = describeSnapshotTime(summary.snapshot.takenAt);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restore this backup?'),
        content: Text(
          'Your entries will be replaced by the $when backup '
          '(${describeSnapshotSize(summary.entryCount)}). The current state is '
          'kept as a backup of its own, so you can change your mind.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: AppText.body(16, weight: 600, color: context.colors.muted),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Restore',
              style: AppText.body(
                16,
                weight: 700,
                color: context.colors.primary,
              ),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final count = await ref
        .read(vaultProvider.notifier)
        .restoreSnapshot(summary.snapshot);
    ref.invalidate(snapshotsProvider);
    if (!context.mounted) return;
    Navigator.pop(context);
    showAppSnackBar(context, 'Restored ${describeSnapshotSize(count)}');
  }
}

class _SnapshotRow extends StatelessWidget {
  const _SnapshotRow({required this.summary, required this.onTap});

  final SnapshotSummary summary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
        child: Row(
          children: [
            Icon(
              LucideIcons.history,
              size: 20,
              color: context.colors.muted,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    describeSnapshotTime(summary.snapshot.takenAt),
                    style: AppText.body(16, weight: 600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    describeSnapshotSize(summary.entryCount),
                    style: AppText.body(
                      13,
                      weight: 500,
                      color: context.colors.muted,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              LucideIcons.chevronRight,
              size: 20,
              color: context.colors.muted,
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/crypto/packed_cipher.dart';
import '../../../core/providers.dart';
import '../../lock/application/lock_controller.dart';
import '../data/snapshot_store.dart';

/// A snapshot plus how many entries it holds, so the restore list can describe
/// each one without the caller decrypting it again.
class SnapshotSummary {
  const SnapshotSummary({required this.snapshot, required this.entryCount});

  final VaultSnapshot snapshot;
  final int entryCount;
}

/// Readable snapshots, newest first.
///
/// Auto-disposing and gated on the lock state for the same reason as the vault
/// itself: locking drops the listeners, and nothing decrypted is kept around.
final snapshotsProvider = FutureProvider.autoDispose<List<SnapshotSummary>>((
  ref,
) async {
  if (ref.watch(lockProvider) != LockStatus.unlocked) return const [];

  final repository = ref.read(vaultRepositoryProvider);
  final summaries = <SnapshotSummary>[];
  for (final snapshot in await ref.read(snapshotStoreProvider).list()) {
    try {
      final entries = await repository.readSnapshot(snapshot);
      summaries.add(
        SnapshotSummary(snapshot: snapshot, entryCount: entries.length),
      );
    } on DecryptionFailure {
      // Left over from an install whose key is gone. Unreadable, so don't offer it.
    }
  }
  return summaries;
});

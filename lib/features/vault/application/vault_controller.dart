import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../backup/data/snapshot_store.dart';
import '../../lock/application/lock_controller.dart';
import '../data/vault_repository.dart';
import '../domain/vault_entry.dart';

final vaultProvider =
    AsyncNotifierProvider.autoDispose<VaultController, List<VaultEntry>>(
      VaultController.new,
    );

/// The decrypted entries — held in memory only while the app is unlocked.
///
/// Auto-disposing is what makes locking real: locking replaces the screens that
/// watch this, so nothing is listening any more and the decrypted list is released
/// immediately. (A plain provider would keep the stale list until next read.)
class VaultController extends AsyncNotifier<List<VaultEntry>> {
  @override
  Future<List<VaultEntry>> build() async {
    final status = ref.watch(lockProvider);
    if (status != LockStatus.unlocked) return const [];
    return ref.read(vaultRepositoryProvider).load();
  }

  List<VaultEntry> get _current => state.value ?? const [];

  Future<void> _commit(List<VaultEntry> next, {bool snapshot = true}) async {
    await ref.read(vaultRepositoryProvider).save(next, snapshot: snapshot);
    state = AsyncData(next);
  }

  /// Opening an entry or copying its secret within this long of the last time
  /// doesn't write again — it wouldn't change its place in "Recently used".
  static const usageThrottle = Duration(minutes: 1);

  /// Pins an entry above the bank groups, or unpins it.
  ///
  /// Counts as an edit for backup merging ([merge] keeps the newer copy), but
  /// isn't snapshotted: undoing it is one more tap.
  Future<void> togglePin(String id) => _commit([
    for (final e in _current)
      if (e.id == id)
        e.copyWith(pinned: !e.pinned, updatedAt: DateTime.now())
      else
        e,
  ], snapshot: false);

  /// Records that an entry was just used, for the "Recently used" sort.
  /// Not an edit, so [VaultEntry.updatedAt] is untouched and nothing is
  /// snapshotted.
  ///
  /// Best-effort: callers don't wait on it, so a failed write is dropped rather
  /// than surfacing as an error. The worst outcome is a stale sort position.
  Future<void> markUsed(String id, {DateTime? now}) async {
    final at = now ?? DateTime.now();
    final entry = _current.where((e) => e.id == id).firstOrNull;
    if (entry == null) return;
    final last = entry.lastUsedAt;
    if (last != null && at.difference(last) < usageThrottle) return;
    try {
      await _commit([
        for (final e in _current)
          if (e.id == id) e.copyWith(lastUsedAt: at) else e,
      ], snapshot: false);
    } on Object {
      // See above: usage tracking must never break opening or copying.
    }
  }

  Future<void> addAll(List<VaultEntry> entries) =>
      _commit([..._current, ...entries]);

  Future<void> updateEntry(VaultEntry entry) =>
      _commit([for (final e in _current) e.id == entry.id ? entry : e]);

  Future<void> remove(String id) => _commit([
    for (final e in _current)
      if (e.id != id) e,
  ]);

  /// Replaces the vault with the contents of an automatic snapshot.
  ///
  /// The pre-restore state is itself copied aside by [VaultRepository.save], so
  /// restoring the wrong snapshot is recoverable too. Returns the entry count.
  Future<int> restoreSnapshot(VaultSnapshot snapshot) async {
    final entries = await ref
        .read(vaultRepositoryProvider)
        .readSnapshot(snapshot);
    await _commit(entries);
    return entries.length;
  }

  /// Adds entries from a backup that aren't already here; where an id exists in
  /// both, the more recently edited copy wins. Returns how many entries changed.
  Future<int> merge(List<VaultEntry> incoming) async {
    final byId = {for (final e in _current) e.id: e};
    var changed = 0;
    for (final entry in incoming) {
      final existing = byId[entry.id];
      if (existing == null || entry.updatedAt.isAfter(existing.updatedAt)) {
        byId[entry.id] = entry;
        changed++;
      }
    }
    if (changed > 0) await _commit(byId.values.toList());
    return changed;
  }
}

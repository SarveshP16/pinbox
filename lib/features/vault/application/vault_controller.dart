import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../lock/application/lock_controller.dart';
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

  Future<void> _commit(List<VaultEntry> next) async {
    await ref.read(vaultRepositoryProvider).save(next);
    state = AsyncData(next);
  }

  Future<void> addAll(List<VaultEntry> entries) =>
      _commit([..._current, ...entries]);

  Future<void> updateEntry(VaultEntry entry) =>
      _commit([for (final e in _current) e.id == entry.id ? entry : e]);

  Future<void> remove(String id) => _commit([
    for (final e in _current)
      if (e.id != id) e,
  ]);

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

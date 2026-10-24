import 'dart:io';

/// One automatic snapshot of the vault, taken just before a change was written.
class VaultSnapshot {
  const VaultSnapshot({required this.file, required this.takenAt});

  final File file;
  final DateTime takenAt;
}

/// Keeps the last few copies of `vault.bin` in app-private storage.
///
/// A snapshot is a byte-for-byte copy of the encrypted vault, so it is protected
/// by the same OS-keystore key and never exists in plaintext — nothing new is
/// written in the clear, and no second password is involved.
///
/// The flip side is that a snapshot cannot outlive the install: uninstalling the
/// app or resetting the keystore destroys the key, and the snapshots become
/// undecryptable bytes. They are here to undo a deletion or a bad edit, not to
/// survive losing the phone. The password-protected export is what covers that.
class SnapshotStore {
  SnapshotStore({required this.directory, this.keep = 10});

  static const _prefix = 'vault-';
  static const _suffix = '.bin';

  final Future<Directory> Function() directory;

  /// How many snapshots to retain. Older ones are pruned after each capture.
  final int keep;

  /// Copies the current vault aside, unless it is unchanged since the newest
  /// snapshot. Does nothing before the first save, when there is no vault yet.
  Future<void> capture(File vault) async {
    if (!await vault.exists()) return;
    final bytes = await vault.readAsBytes();

    final existing = await list();
    if (existing.isNotEmpty) {
      final newest = await existing.first.file.readAsBytes();
      // Saves that change nothing shouldn't push a real snapshot out of the window.
      if (_sameBytes(newest, bytes)) return;
    }

    final dir = await directory();
    await dir.create(recursive: true);
    final stamp = DateTime.now().millisecondsSinceEpoch;
    final target = File('${dir.path}${Platform.pathSeparator}$_prefix$stamp$_suffix');
    await target.writeAsBytes(bytes, flush: true);

    // Newest first, so skipping `keep` leaves exactly the stale ones.
    final retained = [
      VaultSnapshot(file: target, takenAt: DateTime.now()),
      ...existing,
    ];
    for (final stale in retained.skip(keep)) {
      if (await stale.file.exists()) await stale.file.delete();
    }
  }

  /// Newest first. Files whose names don't carry a timestamp are ignored.
  Future<List<VaultSnapshot>> list() async {
    final dir = await directory();
    if (!await dir.exists()) return const [];
    final found = <VaultSnapshot>[];
    await for (final entity in dir.list()) {
      if (entity is! File) continue;
      final name = entity.uri.pathSegments.last;
      if (!name.startsWith(_prefix) || !name.endsWith(_suffix)) continue;
      final stamp = int.tryParse(
        name.substring(_prefix.length, name.length - _suffix.length),
      );
      if (stamp == null) continue;
      found.add(
        VaultSnapshot(
          file: entity,
          takenAt: DateTime.fromMillisecondsSinceEpoch(stamp),
        ),
      );
    }
    found.sort((a, b) => b.takenAt.compareTo(a.takenAt));
    return found;
  }

  /// Removes every snapshot. Called when the vault itself is wiped, so that
  /// "delete everything" doesn't leave older copies of the data behind.
  Future<void> wipe() async {
    final dir = await directory();
    if (await dir.exists()) await dir.delete(recursive: true);
  }

  static bool _sameBytes(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pinbox/features/backup/data/snapshot_store.dart';

void main() {
  late Directory root;
  late File vault;
  late SnapshotStore store;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('pinbox_snapshot_test');
    vault = File('${root.path}/vault.bin');
    store = SnapshotStore(
      directory: () async => Directory('${root.path}/snapshots'),
      keep: 3,
    );
  });

  tearDown(() => root.delete(recursive: true));

  test('there is nothing to capture before the first save', () async {
    await store.capture(vault);
    expect(await store.list(), isEmpty);
  });

  test('capture copies the encrypted vault byte for byte', () async {
    final bytes = [1, 2, 3, 4, 5];
    await vault.writeAsBytes(bytes);
    await store.capture(vault);

    final snapshots = await store.list();
    expect(snapshots, hasLength(1));
    expect(await snapshots.single.file.readAsBytes(), bytes);
  });

  test('a save that changed nothing does not push out a real snapshot', () async {
    await vault.writeAsBytes([1, 1, 1]);
    await store.capture(vault);
    await store.capture(vault);
    await store.capture(vault);

    expect(await store.list(), hasLength(1));
  });

  test('each distinct state gets its own snapshot, newest first', () async {
    for (final n in [1, 2, 3]) {
      await vault.writeAsBytes([n]);
      await store.capture(vault);
      // Snapshot names carry a millisecond stamp, so separate the writes.
      await Future<void>.delayed(const Duration(milliseconds: 5));
    }

    final snapshots = await store.list();
    expect(snapshots, hasLength(3));
    final contents = [
      for (final s in snapshots) (await s.file.readAsBytes()).single,
    ];
    expect(contents, [3, 2, 1]);
  });

  test('only the newest `keep` snapshots are retained', () async {
    for (final n in [1, 2, 3, 4, 5]) {
      await vault.writeAsBytes([n]);
      await store.capture(vault);
      await Future<void>.delayed(const Duration(milliseconds: 5));
    }

    final snapshots = await store.list();
    expect(snapshots, hasLength(3));
    final contents = [
      for (final s in snapshots) (await s.file.readAsBytes()).single,
    ];
    expect(contents, [5, 4, 3], reason: 'the two oldest should be pruned');
  });

  test('takenAt comes from the file name', () async {
    final before = DateTime.now().subtract(const Duration(seconds: 2));
    await vault.writeAsBytes([9]);
    await store.capture(vault);

    final taken = (await store.list()).single.takenAt;
    expect(taken.isAfter(before), isTrue);
    expect(taken.isBefore(DateTime.now().add(const Duration(seconds: 2))), isTrue);
  });

  test('foreign files in the directory are ignored', () async {
    await vault.writeAsBytes([1]);
    await store.capture(vault);
    await File('${root.path}/snapshots/notes.txt').writeAsString('hello');
    await File('${root.path}/snapshots/vault-nonsense.bin').writeAsString('x');

    expect(await store.list(), hasLength(1));
  });

  test('wipe removes every snapshot', () async {
    await vault.writeAsBytes([1]);
    await store.capture(vault);
    await store.wipe();

    expect(await store.list(), isEmpty);
    expect(Directory('${root.path}/snapshots').existsSync(), isFalse);
  });

  test('listing a directory that was never created is empty, not an error', () async {
    expect(await store.list(), isEmpty);
  });
}

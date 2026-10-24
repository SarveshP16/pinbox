import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pinbox/core/crypto/secret_hasher.dart';
import 'package:pinbox/core/providers.dart';
import 'package:pinbox/features/backup/data/backup_codec.dart';
import 'package:pinbox/features/backup/data/snapshot_store.dart';
import 'package:pinbox/features/lock/application/lock_controller.dart';
import 'package:pinbox/features/lock/data/credentials_store.dart';
import 'package:pinbox/features/vault/application/vault_controller.dart';
import 'package:pinbox/features/vault/data/vault_repository.dart';
import 'package:pinbox/features/vault/domain/vault_entry.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/entries.dart';
import '../../support/memory_secure_store.dart';

/// The real controller over a real encrypted vault and snapshot store on disk.
void main() {
  late Directory dir;
  late SnapshotStore snapshots;
  late VaultRepository repo;
  late ProviderContainer container;

  VaultController vault() => container.read(vaultProvider.notifier);
  VaultEntry current(String id) =>
      container.read(vaultProvider).value!.firstWhere((e) => e.id == id);

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('pinbox_pin_usage_test');
    final keys = MemorySecureStore();
    final hasher = SecretHasher(iterations: 1000);
    snapshots = SnapshotStore(
      directory: () async => Directory('${dir.path}/snapshots'),
    );
    repo = VaultRepository(
      keyStore: keys,
      file: () async => File('${dir.path}/vault.bin'),
      snapshots: snapshots,
    );
    await repo.save([
      entry(id: 'a', bank: 'Harbour Bank', created: DateTime.utc(2026, 1, 1)),
      entry(id: 'b', bank: 'Meridian CU', created: DateTime.utc(2026, 1, 2)),
    ]);
    await CredentialsStore(keys, hasher).save(pin: '123456', password: 'pw12345678');

    SharedPreferences.setMockInitialValues({});
    container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(
          await SharedPreferences.getInstance(),
        ),
        secureStoreProvider.overrideWithValue(keys),
        secretHasherProvider.overrideWithValue(hasher),
        vaultRepositoryProvider.overrideWithValue(repo),
        snapshotStoreProvider.overrideWithValue(snapshots),
      ],
    );
    addTearDown(container.dispose);

    // Unlock, and keep the auto-disposing vault alive for the test.
    container.listen(vaultProvider, (_, _) {});
    while (container.read(lockProvider) == LockStatus.loading) {
      await Future<void>.delayed(const Duration(milliseconds: 5));
    }
    await container.read(lockProvider.notifier).unlockWithPin('123456');
    await container.read(vaultProvider.future);
  });

  tearDown(() => dir.delete(recursive: true));

  group('togglePin', () {
    test('pins, persists to the encrypted file, and unpins again', () async {
      await vault().togglePin('a');
      expect(current('a').pinned, isTrue);
      expect((await repo.load()).firstWhere((e) => e.id == 'a').pinned, isTrue);

      await vault().togglePin('a');
      expect(current('a').pinned, isFalse);
    });

    test('counts as an edit, so a backup merge keeps the newer pin', () async {
      final before = current('a').updatedAt;
      await vault().togglePin('a');
      expect(current('a').updatedAt.isAfter(before), isTrue);

      // An older export of the same entry must not unpin it.
      final changed = await vault().merge([entry(id: 'a', bank: 'Harbour Bank')]);
      expect(changed, 0);
      expect(current('a').pinned, isTrue);
    });

    test('doesn’t spend an automatic backup', () async {
      await vault().togglePin('a');
      await vault().togglePin('b');
      expect(await snapshots.list(), isEmpty);
    });
  });

  group('markUsed', () {
    final t0 = DateTime(2026, 10, 25, 9);

    test('records the time without counting as an edit', () async {
      final edited = current('a').updatedAt;
      await vault().markUsed('a', now: t0);
      expect(current('a').lastUsedAt, t0);
      expect(current('a').updatedAt, edited);
      expect(
        (await repo.load()).firstWhere((e) => e.id == 'a').lastUsedAt,
        t0.toUtc(),
      );
    });

    test('doesn’t spend an automatic backup', () async {
      await vault().markUsed('a', now: t0);
      await vault().markUsed('b', now: t0);
      expect(await snapshots.list(), isEmpty);
    });

    test('a second use within a minute doesn’t write again', () async {
      await vault().markUsed('a', now: t0);
      await vault().markUsed('a', now: t0.add(const Duration(seconds: 30)));
      expect(current('a').lastUsedAt, t0);

      await vault().markUsed('a', now: t0.add(const Duration(minutes: 2)));
      expect(current('a').lastUsedAt, t0.add(const Duration(minutes: 2)));
    });

    test('an unknown id is ignored', () async {
      await vault().markUsed('nope', now: t0);
      expect(container.read(vaultProvider).value, hasLength(2));
    });
  });

  test('real edits still take an automatic backup', () async {
    await vault().togglePin('a');
    await vault().markUsed('a', now: DateTime(2026, 10, 25));
    await vault().remove('b');
    expect(await snapshots.list(), hasLength(1));
  });

  test('pins and usage travel in an exported backup', () async {
    await vault().togglePin('a');
    await vault().markUsed('a', now: DateTime(2026, 10, 25, 9));
    final codec = BackupCodec(iterations: 1000, minIterations: 1);
    final file = await codec.encode(container.read(vaultProvider).value!, 'pw');
    final back = (await codec.decode(file, 'pw')).firstWhere((e) => e.id == 'a');
    expect(back.pinned, isTrue);
    expect(back.lastUsedAt, isNotNull);
  });
}

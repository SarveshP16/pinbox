import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pinbox/core/crypto/packed_cipher.dart';
import 'package:pinbox/features/vault/data/vault_repository.dart';

import '../../support/entries.dart';
import '../../support/memory_secure_store.dart';

void main() {
  late Directory dir;
  late MemorySecureStore keys;
  late VaultRepository repo;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('pinbox_vault_test');
    keys = MemorySecureStore();
    repo = VaultRepository(
      keyStore: keys,
      file: () async => File('${dir.path}/vault.bin'),
    );
  });

  tearDown(() => dir.delete(recursive: true));

  test('an empty vault loads as empty', () async {
    expect(await repo.load(), isEmpty);
  });

  test('saves and reloads entries', () async {
    await repo.save([
      entry(id: '1', secret: '4829'),
      entry(id: '2', secret: 'pa55'),
    ]);
    final loaded = await repo.load();
    expect(loaded.map((e) => e.id), ['1', '2']);
    expect(loaded.first.secret, '4829');
  });

  test('the file on disk contains no readable secrets or bank names', () async {
    await repo.save([
      entry(bank: 'Harbour Bank', secret: '4829', notes: 'top secret note'),
    ]);
    final raw = String.fromCharCodes(
      await File('${dir.path}/vault.bin').readAsBytes(),
    );
    for (final leak in ['Harbour', '4829', 'top secret', 'secret']) {
      expect(raw, isNot(contains(leak)));
    }
  });

  test('the key is kept in the keystore, not next to the file', () async {
    await repo.save([entry()]);
    expect(keys.values.keys, contains('vault_data_key'));
    final names = dir.listSync().whereType<File>().map(
      (f) => f.path.split(RegExp(r'[\\/]')).last,
    );
    expect(names, ['vault.bin']);
  });

  test('a tampered file is refused rather than misread', () async {
    await repo.save([entry()]);
    final file = File('${dir.path}/vault.bin');
    final bytes = await file.readAsBytes();
    bytes[bytes.length ~/ 2] ^= 0xff;
    await file.writeAsBytes(bytes);
    expect(repo.load(), throwsA(isA<DecryptionFailure>()));
  });

  test('a vault whose key was lost is reported, not shown as empty', () async {
    await repo.save([entry()]);
    keys.values.clear();
    expect(repo.load(), throwsA(isA<DecryptionFailure>()));
  });

  test('wipe removes both the file and the key', () async {
    await repo.save([entry()]);
    await repo.wipe();
    expect(File('${dir.path}/vault.bin').existsSync(), isFalse);
    expect(keys.values, isEmpty);
  });
}

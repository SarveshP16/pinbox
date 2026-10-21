import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:pinbox/core/crypto/packed_cipher.dart';
import 'package:pinbox/features/backup/data/backup_codec.dart';
import 'package:pinbox/features/vault/domain/entry_type.dart';

import '../../support/entries.dart';

void main() {
  final codec = BackupCodec(iterations: 1000, minIterations: 1);
  final entries = [
    entry(id: '1', secret: '4829', last4: '4417'),
    entry(
      id: '2',
      type: EntryType.password,
      secret: 'päss w0rd',
      notes: 'note',
    ),
  ];

  test('round-trips with the right password', () async {
    final file = await codec.encode(entries, 'correct horse');
    final back = await codec.decode(file, 'correct horse');
    expect(back.map((e) => e.toJson()), entries.map((e) => e.toJson()));
  });

  test('a wrong password is rejected', () async {
    final file = await codec.encode(entries, 'correct horse');
    expect(
      codec.decode(file, 'wrong horse'),
      throwsA(isA<DecryptionFailure>()),
    );
  });

  test('the backup file leaks nothing readable', () async {
    final text = utf8.decode(await codec.encode(entries, 'pw'));
    for (final leak in ['Harbour', '4829', '4417', 'w0rd', 'note']) {
      expect(text, isNot(contains(leak)));
    }
  });

  test('a modified file is rejected', () async {
    final file = await codec.encode(entries, 'pw');
    final json = jsonDecode(utf8.decode(file)) as Map<String, Object?>;
    final data = base64.decode(json['data'] as String);
    data[data.length ~/ 2] ^= 1;
    json['data'] = base64.encode(data);
    expect(
      codec.decode(utf8.encode(jsonEncode(json)), 'pw'),
      throwsA(isA<DecryptionFailure>()),
    );
  });

  test(
    'random bytes and foreign JSON are "not a backup", not a crash',
    () async {
      expect(codec.decode([1, 2, 3, 4], 'pw'), throwsA(isA<NotABackupFile>()));
      expect(
        codec.decode(utf8.encode('{"hello":1}'), 'pw'),
        throwsA(isA<NotABackupFile>()),
      );
    },
  );

  test(
    'refuses absurd iteration counts (DoS guard) and too-weak ones',
    () async {
      final file = await codec.encode(entries, 'pw');
      final tampered = (jsonDecode(utf8.decode(file)) as Map<String, Object?>)
        ..['iterations'] = 2000000000;
      expect(
        codec.decode(utf8.encode(jsonEncode(tampered)), 'pw'),
        throwsA(isA<NotABackupFile>()),
      );
      final strict = BackupCodec(iterations: 1000);
      expect(strict.decode(file, 'pw'), throwsA(isA<NotABackupFile>()));
    },
  );

  test('two exports of the same data differ (fresh salt and nonce)', () async {
    expect(
      await codec.encode(entries, 'pw'),
      isNot(await codec.encode(entries, 'pw')),
    );
  });
}

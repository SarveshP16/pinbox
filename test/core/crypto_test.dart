import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:pinbox/core/crypto/packed_cipher.dart';
import 'package:pinbox/core/crypto/secret_hasher.dart';

void main() {
  group('PackedCipher', () {
    final cipher = PackedCipher();

    test('round-trips data', () async {
      final key = await cipher.newKey();
      final packed = await cipher.encrypt(utf8.encode('4829 secret'), key);
      expect(utf8.decode(await cipher.decrypt(packed, key)), '4829 secret');
    });

    test('never stores the plaintext', () async {
      final key = await cipher.newKey();
      final packed = await cipher.encrypt(
        utf8.encode('correct horse battery'),
        key,
      );
      expect(
        utf8.decode(packed, allowMalformed: true),
        isNot(contains('correct horse')),
      );
    });

    test('uses a fresh nonce every time', () async {
      final key = await cipher.newKey();
      final a = await cipher.encrypt(utf8.encode('same'), key);
      final b = await cipher.encrypt(utf8.encode('same'), key);
      expect(a, isNot(equals(b)));
    });

    test('rejects the wrong key', () async {
      final packed = await cipher.encrypt(
        utf8.encode('x'),
        await cipher.newKey(),
      );
      expect(
        cipher.decrypt(packed, await cipher.newKey()),
        throwsA(isA<DecryptionFailure>()),
      );
    });

    test('rejects tampered data', () async {
      final key = await cipher.newKey();
      final packed = await cipher.encrypt(utf8.encode('hello world'), key);
      packed[packed.length ~/ 2] ^= 0x01;
      expect(cipher.decrypt(packed, key), throwsA(isA<DecryptionFailure>()));
    });

    test('rejects truncated or foreign data', () async {
      final key = await cipher.newKey();
      expect(cipher.decrypt([1, 2, 3], key), throwsA(isA<DecryptionFailure>()));
      expect(
        cipher.decrypt(List.filled(64, 9), key),
        throwsA(isA<DecryptionFailure>()),
      );
    });
  });

  group('SecretHasher', () {
    final hasher = SecretHasher(iterations: 1000);

    test('verifies the right secret and rejects the wrong one', () async {
      final stored = await hasher.hash('123456');
      expect(await hasher.verify('123456', stored), isTrue);
      expect(await hasher.verify('123457', stored), isFalse);
    });

    test('salts, so equal secrets hash differently', () async {
      expect(await hasher.hash('123456'), isNot(await hasher.hash('123456')));
    });

    test('keeps working if the iteration setting changes later', () async {
      final stored = await SecretHasher(iterations: 1000).hash('pw');
      expect(await SecretHasher(iterations: 2000).verify('pw', stored), isTrue);
    });

    test('treats malformed stored values as a mismatch, not a crash', () async {
      expect(await hasher.verify('x', 'garbage'), isFalse);
      expect(await hasher.verify('x', r'pbkdf2$abc$aaaa$bbbb'), isFalse);
    });
  });

  test('constantTimeEquals', () {
    expect(constantTimeEquals([1, 2, 3], [1, 2, 3]), isTrue);
    expect(constantTimeEquals([1, 2, 3], [1, 2, 4]), isFalse);
    expect(constantTimeEquals([1, 2], [1, 2, 3]), isFalse);
  });
}

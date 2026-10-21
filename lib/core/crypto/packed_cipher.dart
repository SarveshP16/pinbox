import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

/// Thrown when data can't be decrypted: wrong key, or the bytes were tampered with.
class DecryptionFailure implements Exception {
  const DecryptionFailure([this.message = 'Could not decrypt data']);
  final String message;
  @override
  String toString() => message;
}

/// AES-256-GCM over a single byte blob, packed as
/// `[version:1][nonce:12][ciphertext:n][tag:16]`.
///
/// GCM is authenticated, so a wrong key and a modified file both surface as the
/// same [DecryptionFailure] rather than as garbage plaintext.
class PackedCipher {
  PackedCipher({AesGcm? algorithm}) : _aes = algorithm ?? AesGcm.with256bits();

  static const version = 1;
  static const _nonceLength = 12;
  static const _tagLength = 16;

  final AesGcm _aes;

  Future<Uint8List> encrypt(List<int> plain, SecretKey key) async {
    final box = await _aes.encrypt(plain, secretKey: key);
    final out = BytesBuilder(copy: false)
      ..addByte(version)
      ..add(box.nonce)
      ..add(box.cipherText)
      ..add(box.mac.bytes);
    return out.toBytes();
  }

  Future<Uint8List> decrypt(List<int> packed, SecretKey key) async {
    if (packed.length < 1 + _nonceLength + _tagLength || packed[0] != version) {
      throw const DecryptionFailure('Unrecognised data format');
    }
    final nonce = packed.sublist(1, 1 + _nonceLength);
    final macStart = packed.length - _tagLength;
    final cipherText = packed.sublist(1 + _nonceLength, macStart);
    final mac = Mac(packed.sublist(macStart));
    try {
      final clear = await _aes.decrypt(
        SecretBox(cipherText, nonce: nonce, mac: mac),
        secretKey: key,
      );
      return Uint8List.fromList(clear);
    } on SecretBoxAuthenticationError {
      throw const DecryptionFailure();
    }
  }

  /// A fresh random 256-bit key.
  Future<SecretKey> newKey() => _aes.newSecretKey();
}

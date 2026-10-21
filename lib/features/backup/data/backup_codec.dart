import 'dart:convert';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

import '../../../core/crypto/packed_cipher.dart';
import '../../../core/crypto/secret_hasher.dart';
import '../../vault/domain/vault_entry.dart';

/// Thrown when a file isn't a Pinbox backup at all (as opposed to a wrong password).
class NotABackupFile implements Exception {
  const NotABackupFile();
  @override
  String toString() => 'This isn’t a Pinbox backup file';
}

/// Turns the vault into a self-contained encrypted file and back.
///
/// The file is JSON holding the KDF parameters plus one AES-256-GCM blob. The key
/// comes from a password the user picks at export time (PBKDF2-HMAC-SHA256) — not
/// from the 6-digit master PIN, which is far too small a space to protect a file
/// that can be copied off the device and attacked offline.
class BackupCodec {
  BackupCodec({
    this.iterations = SecretHasher.defaultIterations,
    this.minIterations = 100000,
    PackedCipher? cipher,
  }) : _cipher = cipher ?? PackedCipher();

  static const _app = 'pinbox';
  static const _version = 1;

  /// Upper bound accepted when *reading* a file, so a crafted one can't request an
  /// absurd iteration count and freeze the app.
  static const _maxIterations = 5000000;

  final int iterations;

  /// Lower bound accepted when reading (a weak file is treated as untrustworthy).
  /// Only tests lower this.
  final int minIterations;
  final PackedCipher _cipher;

  Future<Uint8List> encode(List<VaultEntry> entries, String password) async {
    final salt = randomBytes(16);
    final key = await _key(password, salt, iterations);
    final body = utf8.encode(
      jsonEncode({
        'entries': [for (final e in entries) e.toJson()],
      }),
    );
    final packed = await _cipher.encrypt(body, key);
    final envelope = {
      'app': _app,
      'version': _version,
      'kdf': 'pbkdf2-sha256',
      'iterations': iterations,
      'salt': base64.encode(salt),
      'data': base64.encode(packed),
    };
    return Uint8List.fromList(utf8.encode(jsonEncode(envelope)));
  }

  /// Throws [NotABackupFile] for a foreign/corrupt file, [DecryptionFailure] for a
  /// wrong password or a tampered one.
  Future<List<VaultEntry>> decode(List<int> bytes, String password) async {
    final Map<String, Object?> envelope;
    final List<int> salt;
    final List<int> packed;
    final int rounds;
    try {
      envelope = jsonDecode(utf8.decode(bytes)) as Map<String, Object?>;
      if (envelope['app'] != _app || envelope['version'] != _version) {
        throw const NotABackupFile();
      }
      rounds = envelope['iterations'] as int;
      salt = base64.decode(envelope['salt'] as String);
      packed = base64.decode(envelope['data'] as String);
    } on NotABackupFile {
      rethrow;
    } on Object {
      throw const NotABackupFile();
    }
    if (rounds < minIterations || rounds > _maxIterations) {
      throw const NotABackupFile();
    }

    final key = await _key(password, salt, rounds);
    final clear = await _cipher.decrypt(packed, key);
    try {
      final json = jsonDecode(utf8.decode(clear)) as Map<String, Object?>;
      return [
        for (final e in (json['entries'] as List).cast<Map<String, Object?>>())
          VaultEntry.fromJson(e),
      ];
    } on Object {
      throw const NotABackupFile();
    }
  }

  Future<SecretKey> _key(String password, List<int> salt, int rounds) {
    return Pbkdf2(
      macAlgorithm: Hmac.sha256(),
      iterations: rounds,
      bits: 256,
    ).deriveKeyFromPassword(password: password, nonce: salt);
  }
}

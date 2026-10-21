import 'dart:convert';
import 'dart:io';

import 'package:cryptography/cryptography.dart';

import '../../../core/crypto/packed_cipher.dart';
import '../../../core/platform/secure_store.dart';
import '../domain/vault_entry.dart';

/// Persists every entry as one AES-256-GCM encrypted file.
///
/// The random data key lives in the OS keystore ([SecureStore]) — never on disk
/// next to the file it protects — so copying `vault.bin` off the device yields
/// nothing usable.
class VaultRepository {
  VaultRepository({
    required this.keyStore,
    required this.file,
    PackedCipher? cipher,
  }) : _cipher = cipher ?? PackedCipher();

  static const _keyName = 'vault_data_key';

  final SecureStore keyStore;

  /// Where the encrypted vault lives (a function so the directory can be resolved lazily).
  final Future<File> Function() file;
  final PackedCipher _cipher;

  Future<List<VaultEntry>> load() async {
    final vaultFile = await file();
    if (!await vaultFile.exists()) return const [];
    final key = await _existingKey();
    if (key == null) {
      // The file survived but its key didn't (e.g. keystore was reset). It can
      // never be decrypted, so surface that instead of silently showing "empty".
      throw const DecryptionFailure(
        'The vault key is missing from this device',
      );
    }
    final clear = await _cipher.decrypt(await vaultFile.readAsBytes(), key);
    final json = jsonDecode(utf8.decode(clear)) as Map<String, Object?>;
    final entries = (json['entries'] as List).cast<Map<String, Object?>>();
    return [for (final e in entries) VaultEntry.fromJson(e)];
  }

  Future<void> save(List<VaultEntry> entries) async {
    final vaultFile = await file();
    final key = await _existingKey() ?? await _createKey();
    final body = utf8.encode(
      jsonEncode({
        'entries': [for (final e in entries) e.toJson()],
      }),
    );
    final packed = await _cipher.encrypt(body, key);

    // Write-then-rename so a crash mid-save can't leave a half-written vault.
    await vaultFile.parent.create(recursive: true);
    final tmp = File('${vaultFile.path}.tmp');
    await tmp.writeAsBytes(packed, flush: true);
    await tmp.rename(vaultFile.path);
  }

  Future<void> wipe() async {
    final vaultFile = await file();
    if (await vaultFile.exists()) await vaultFile.delete();
    await keyStore.delete(_keyName);
  }

  Future<SecretKey?> _existingKey() async {
    final stored = await keyStore.read(_keyName);
    if (stored == null) return null;
    return SecretKey(base64.decode(stored));
  }

  Future<SecretKey> _createKey() async {
    final key = await _cipher.newKey();
    await keyStore.write(_keyName, base64.encode(await key.extractBytes()));
    return key;
  }
}

import 'dart:convert';
import 'dart:io';

import 'package:cryptography/cryptography.dart';

import '../../../core/crypto/packed_cipher.dart';
import '../../../core/platform/secure_store.dart';
import '../../backup/data/snapshot_store.dart';
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
    this.snapshots,
    PackedCipher? cipher,
  }) : _cipher = cipher ?? PackedCipher();

  static const _keyName = 'vault_data_key';

  final SecureStore keyStore;

  /// Where the encrypted vault lives (a function so the directory can be resolved lazily).
  final Future<File> Function() file;

  /// Automatic local snapshots. Omitted in tests that don't care about them.
  final SnapshotStore? snapshots;
  final PackedCipher _cipher;

  Future<List<VaultEntry>> load() async {
    final vaultFile = await file();
    if (!await vaultFile.exists()) return const [];
    return _entriesFrom(await vaultFile.readAsBytes(), await _requireKey());
  }

  /// Entries held in an automatic snapshot, read with the current vault key.
  Future<List<VaultEntry>> readSnapshot(VaultSnapshot snapshot) async {
    return _entriesFrom(
      await snapshot.file.readAsBytes(),
      await _requireKey(),
    );
  }

  /// Writes [entries]. With [snapshot] (the default) the previous state is
  /// copied aside first so the save can be undone; bookkeeping-only saves —
  /// usage times, pins — pass false so they don't push real edits out of the
  /// limited snapshot history.
  Future<void> save(List<VaultEntry> entries, {bool snapshot = true}) async {
    final vaultFile = await file();

    if (snapshot) await snapshots?.capture(vaultFile);

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
    // Snapshots are copies of the same data, so they go too.
    await snapshots?.wipe();
    await keyStore.delete(_keyName);
  }

  List<VaultEntry> _parse(List<int> clear) {
    final json = jsonDecode(utf8.decode(clear)) as Map<String, Object?>;
    final entries = (json['entries'] as List).cast<Map<String, Object?>>();
    return [for (final e in entries) VaultEntry.fromJson(e)];
  }

  Future<List<VaultEntry>> _entriesFrom(List<int> packed, SecretKey key) async {
    return _parse(await _cipher.decrypt(packed, key));
  }

  /// The data key, or [DecryptionFailure] if it is gone. A vault file that
  /// outlived its key (keystore reset, restored-from-backup install) can never be
  /// decrypted, so say so instead of silently showing an empty vault.
  Future<SecretKey> _requireKey() async {
    final key = await _existingKey();
    if (key == null) {
      throw const DecryptionFailure(
        'The vault key is missing from this device',
      );
    }
    return key;
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

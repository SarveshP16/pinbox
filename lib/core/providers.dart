import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'crypto/secret_hasher.dart';
import 'platform/native_bridge.dart';
import 'platform/secure_store.dart';
import '../features/backup/data/snapshot_store.dart';
import '../features/settings/data/settings_repository.dart';
import '../features/vault/data/vault_repository.dart';

/// Overridden in `main()` once preferences have loaded, so settings can be read
/// synchronously everywhere.
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) =>
      throw UnimplementedError('sharedPreferencesProvider must be overridden'),
);

final secureStoreProvider = Provider<SecureStore>(
  (ref) => KeychainSecureStore(),
);

final nativeBridgeProvider = Provider<NativeBridge>(
  (ref) => const NativeBridge(),
);

final secretHasherProvider = Provider<SecretHasher>((ref) => SecretHasher());

final localAuthProvider = Provider<LocalAuthentication>(
  (ref) => LocalAuthentication(),
);

/// App name, version and build number — read once and cached for the session.
final packageInfoProvider = FutureProvider<PackageInfo>(
  (ref) => PackageInfo.fromPlatform(),
);

final settingsRepositoryProvider = Provider<SettingsRepository>(
  (ref) => SettingsRepository(ref.watch(sharedPreferencesProvider)),
);

/// Automatic local snapshots, kept beside the vault in app-private storage.
final snapshotStoreProvider = Provider<SnapshotStore>((ref) {
  return SnapshotStore(
    directory: () async {
      final dir = await getApplicationSupportDirectory();
      return Directory('${dir.path}${Platform.pathSeparator}snapshots');
    },
  );
});

final vaultRepositoryProvider = Provider<VaultRepository>((ref) {
  return VaultRepository(
    keyStore: ref.watch(secureStoreProvider),
    snapshots: ref.watch(snapshotStoreProvider),
    file: () async {
      // Application *support* dir: private to the app and excluded from user-visible storage.
      final dir = await getApplicationSupportDirectory();
      return File('${dir.path}${Platform.pathSeparator}vault.bin');
    },
  );
});

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Minimal key/value seam over the OS keystore so everything above it can be
/// tested with an in-memory fake.
abstract class SecureStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);
}

/// Android Keystore / iOS Keychain backed store.
class KeychainSecureStore implements SecureStore {
  KeychainSecureStore()
    : _storage = const FlutterSecureStorage(
        // Never synced to iCloud or restored onto another device.
        iOptions: IOSOptions(
          accessibility: KeychainAccessibility.first_unlock_this_device,
        ),
      );

  final FlutterSecureStorage _storage;

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);

  @override
  Future<void> delete(String key) => _storage.delete(key: key);
}

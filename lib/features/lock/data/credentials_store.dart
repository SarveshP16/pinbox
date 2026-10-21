import '../../../core/crypto/secret_hasher.dart';
import '../../../core/platform/secure_store.dart';
import '../domain/attempt_result.dart';
import '../domain/lockout_policy.dart';

/// Holds the master PIN and master password — as salted hashes only — plus the
/// failed-attempt counter, all in the OS keystore. The counter is persisted so
/// killing and relaunching the app doesn't reset a brute-force lockout.
class CredentialsStore {
  CredentialsStore(this._store, this._hasher, {DateTime Function()? now})
    : _now = now ?? DateTime.now;

  static const _pinKey = 'master_pin_hash';
  static const _passwordKey = 'master_password_hash';
  static const _failuresKey = 'failed_attempts';
  static const _lockedUntilKey = 'locked_until';

  final SecureStore _store;
  final SecretHasher _hasher;
  final DateTime Function() _now;

  Future<bool> hasCredentials() async =>
      await _store.read(_pinKey) != null &&
      await _store.read(_passwordKey) != null;

  Future<void> save({required String pin, required String password}) async {
    await _store.write(_pinKey, await _hasher.hash(pin));
    await _store.write(_passwordKey, await _hasher.hash(password));
    await _resetFailures();
  }

  Future<void> changePin(String newPin) async {
    await _store.write(_pinKey, await _hasher.hash(newPin));
  }

  Future<AttemptResult> checkPin(String pin) => _check(_pinKey, pin);

  Future<AttemptResult> checkPassword(String password) =>
      _check(_passwordKey, password);

  /// When the current wait ends, or null if unlocking is allowed right now.
  Future<DateTime?> lockedUntil() async {
    final raw = await _store.read(_lockedUntilKey);
    final until = raw == null ? null : DateTime.tryParse(raw);
    if (until == null || !until.isAfter(_now())) return null;
    return until;
  }

  Future<AttemptResult> _check(String key, String secret) async {
    final until = await lockedUntil();
    if (until != null) return AttemptLockedOut(until);

    final stored = await _store.read(key);
    if (stored != null && await _hasher.verify(secret, stored)) {
      await _resetFailures();
      return const AttemptSuccess();
    }

    final failures =
        (int.tryParse(await _store.read(_failuresKey) ?? '') ?? 0) + 1;
    await _store.write(_failuresKey, '$failures');
    final wait = lockoutDuration(failures);
    if (wait > Duration.zero) {
      final end = _now().add(wait);
      await _store.write(_lockedUntilKey, end.toIso8601String());
      return AttemptLockedOut(end);
    }
    return AttemptWrong(attemptsLeft(failures));
  }

  Future<void> _resetFailures() async {
    await _store.delete(_failuresKey);
    await _store.delete(_lockedUntilKey);
  }
}

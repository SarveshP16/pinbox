import '../../../core/crypto/secret_hasher.dart';
import '../../../core/platform/boot_clock.dart';
import '../../../core/platform/secure_store.dart';
import '../domain/attempt_result.dart';
import '../domain/lockout_policy.dart';

/// Holds the master PIN and master password — as salted hashes only — plus the
/// failed-attempt counter, all in the OS keystore. The counter is persisted so
/// killing and relaunching the app doesn't reset a brute-force lockout.
///
/// The rate limit is written to hold against someone holding the phone:
/// - a guess is counted *before* it is checked, so force-stopping the app while
///   the slow hash runs doesn't erase the attempt;
/// - checks run one at a time, so racing two of them can't undercount;
/// - waits are timed on [BootClock] where available, so changing the date or
///   time doesn't end one, and a reboot restarts the wait rather than ending it.
class CredentialsStore {
  CredentialsStore(
    this._store,
    this._hasher, {
    DateTime Function()? now,
    this._bootClock,
  }) : _now = now ?? DateTime.now;

  static const _pinKey = 'master_pin_hash';
  static const _passwordKey = 'master_password_hash';
  static const _failuresKey = 'failed_attempts';

  // The current wait. Wall time is kept for the fallback path and for showing a
  // countdown; the boot-clock pair is what's trusted when it exists.
  static const _lockedUntilKey = 'locked_until';
  static const _lockWaitKey = 'locked_wait_ms';
  static const _lockBootKey = 'locked_boot_id';
  static const _lockEndKey = 'locked_until_elapsed_ms';

  final SecureStore _store;
  final SecretHasher _hasher;
  final DateTime Function() _now;
  final BootClock? _bootClock;

  Future<void> _queue = Future.value();

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

  Future<AttemptResult> checkPin(String pin) =>
      _serially(() => _check(_pinKey, pin));

  Future<AttemptResult> checkPassword(String password) =>
      _serially(() => _check(_passwordKey, password));

  /// When the current wait ends, or null if unlocking is allowed right now.
  Future<DateTime?> lockedUntil() => _serially(_lockedUntil);

  /// Runs [action] after every earlier check has finished.
  Future<T> _serially<T>(Future<T> Function() action) {
    final result = _queue.then((_) => action());
    _queue = result.then<void>((_) {}, onError: (_) {});
    return result;
  }

  Future<AttemptResult> _check(String key, String secret) async {
    final until = await _lockedUntil();
    if (until != null) return AttemptLockedOut(until);

    // Count the guess before checking it. Verification is the slow part, and an
    // attempt recorded only afterwards could be erased by killing the app
    // mid-check. Any wait this guess earns is armed now for the same reason.
    final failures =
        (int.tryParse(await _store.read(_failuresKey) ?? '') ?? 0) + 1;
    await _store.write(_failuresKey, '$failures');
    final wait = lockoutDuration(failures);
    final end = wait > Duration.zero ? await _arm(wait) : null;

    final stored = await _store.read(key);
    if (stored != null && await _hasher.verify(secret, stored)) {
      await _resetFailures();
      return const AttemptSuccess();
    }
    return end == null
        ? AttemptWrong(attemptsLeft(failures))
        : AttemptLockedOut(end);
  }

  /// Starts a [wait], recording it on the boot clock when there is one.
  Future<DateTime> _arm(Duration wait) async {
    final end = _now().add(wait);
    await _store.write(_lockedUntilKey, end.toIso8601String());
    await _store.write(_lockWaitKey, '${wait.inMilliseconds}');

    final boot = await _bootClock?.read();
    if (boot == null) {
      await _store.delete(_lockBootKey);
      await _store.delete(_lockEndKey);
    } else {
      await _store.write(_lockBootKey, '${boot.bootId}');
      await _store.write(
        _lockEndKey,
        '${boot.elapsedMs + wait.inMilliseconds}',
      );
    }
    return end;
  }

  Future<DateTime?> _lockedUntil() async {
    final wall = await _store.read(_lockedUntilKey);
    if (wall == null) return null;

    final boot = await _bootClock?.read();
    final lockBoot = int.tryParse(await _store.read(_lockBootKey) ?? '');
    final lockEnd = int.tryParse(await _store.read(_lockEndKey) ?? '');

    if (boot != null && lockBoot != null && lockEnd != null) {
      if (boot.bootId == lockBoot) {
        final remaining = lockEnd - boot.elapsedMs;
        if (remaining <= 0) {
          await _clearWait();
          return null;
        }
        // Derived from the boot clock, so the countdown stays honest even if the
        // date was changed.
        return _now().add(Duration(milliseconds: remaining));
      }

      // Rebooted mid-wait. How long the phone was off is unknowable, and the
      // wall clock can't be trusted to say, so the wait starts over.
      final wait = int.tryParse(await _store.read(_lockWaitKey) ?? '') ?? 0;
      if (wait <= 0) {
        await _clearWait();
        return null;
      }
      return _arm(Duration(milliseconds: wait));
    }

    // No boot clock (iOS, tests): the wall clock is all there is.
    final until = DateTime.tryParse(wall);
    if (until == null || !until.isAfter(_now())) return null;
    return until;
  }

  Future<void> _clearWait() async {
    for (final key in [
      _lockedUntilKey,
      _lockWaitKey,
      _lockBootKey,
      _lockEndKey,
    ]) {
      await _store.delete(key);
    }
  }

  Future<void> _resetFailures() async {
    await _store.delete(_failuresKey);
    await _clearWait();
  }
}

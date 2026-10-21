import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../settings/application/settings_controller.dart';
import '../data/credentials_store.dart';
import '../domain/attempt_result.dart';

enum LockStatus {
  /// Still checking whether credentials exist.
  loading,

  /// Fresh install: the user must create a master PIN and password.
  needsSetup,
  locked,
  unlocked,
}

final credentialsStoreProvider = Provider<CredentialsStore>(
  (ref) => CredentialsStore(
    ref.watch(secureStoreProvider),
    ref.watch(secretHasherProvider),
  ),
);

final lockProvider = NotifierProvider<LockController, LockStatus>(
  LockController.new,
);

class LockController extends Notifier<LockStatus> {
  DateTime? _backgroundedAt;
  int _suspensions = 0;

  CredentialsStore get _credentials => ref.read(credentialsStoreProvider);

  @override
  LockStatus build() {
    _resolveInitialStatus();
    return LockStatus.loading;
  }

  Future<void> _resolveInitialStatus() async {
    final has = await _credentials.hasCredentials();
    if (state == LockStatus.loading) {
      state = has ? LockStatus.locked : LockStatus.needsSetup;
    }
  }

  // ---- setup & unlock ------------------------------------------------------

  Future<void> completeSetup({
    required String pin,
    required String password,
  }) async {
    await _credentials.save(pin: pin, password: password);
    // Biometrics on by default when the phone has something enrolled.
    if (await biometricsAvailable()) {
      await ref.read(settingsProvider.notifier).setBiometric(true);
    }
    state = LockStatus.unlocked;
  }

  Future<AttemptResult> unlockWithPin(String pin) async {
    final result = await _credentials.checkPin(pin);
    if (result is AttemptSuccess) state = LockStatus.unlocked;
    return result;
  }

  Future<AttemptResult> unlockWithPassword(String password) async {
    final result = await _credentials.checkPassword(password);
    if (result is AttemptSuccess) state = LockStatus.unlocked;
    return result;
  }

  /// Prompts for fingerprint/face. Returns true (and unlocks) on success.
  Future<bool> unlockWithBiometrics() async {
    if (!await authenticateBiometrically('Unlock Pinbox')) return false;
    state = LockStatus.unlocked;
    return true;
  }

  Future<bool> biometricsAvailable() async {
    try {
      final auth = ref.read(localAuthProvider);
      if (!await auth.isDeviceSupported() || !await auth.canCheckBiometrics) {
        return false;
      }
      return (await auth.getAvailableBiometrics()).isNotEmpty;
    } on Exception {
      return false;
    }
  }

  /// Shows the system biometric prompt without changing lock state.
  Future<bool> authenticateBiometrically(String reason) async {
    try {
      return await withoutAutoLock(
        () => ref
            .read(localAuthProvider)
            .authenticate(
              localizedReason: reason,
              biometricOnly: true,
              persistAcrossBackgrounding: true,
            ),
      );
    } on Exception {
      // Cancelled, locked out, hardware error, plugin missing… none of it may crash
      // the unlock screen; the PIN is always still available.
      return false;
    }
  }

  /// Re-checks the PIN (e.g. before changing it) without touching lock state.
  Future<AttemptResult> verifyPin(String pin) => _credentials.checkPin(pin);

  Future<AttemptResult> verifyPassword(String password) =>
      _credentials.checkPassword(password);

  Future<void> changePin(String newPin) => _credentials.changePin(newPin);

  Future<DateTime?> lockedUntil() => _credentials.lockedUntil();

  // ---- locking ---------------------------------------------------------------

  void lock() {
    if (state == LockStatus.unlocked) state = LockStatus.locked;
  }

  /// Runs [action] (share sheet, file picker, biometric prompt…) that backgrounds
  /// the app without that counting toward the auto-lock timer.
  Future<T> withoutAutoLock<T>(Future<T> Function() action) async {
    _suspensions++;
    try {
      return await action();
    } finally {
      _suspensions--;
      _backgroundedAt = null;
    }
  }

  void onBackgrounded() {
    if (state != LockStatus.unlocked || _suspensions > 0) return;
    _backgroundedAt ??= DateTime.now();
  }

  void onForegrounded() {
    final since = _backgroundedAt;
    _backgroundedAt = null;
    if (since == null || state != LockStatus.unlocked) return;
    final away = DateTime.now().difference(since);
    final limit = Duration(seconds: ref.read(settingsProvider).autoLockSeconds);
    // A negative span means the clock was wound back — treat that as expired.
    if (away.isNegative || away >= limit) lock();
  }
}

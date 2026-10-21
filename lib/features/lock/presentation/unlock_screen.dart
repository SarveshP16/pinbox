import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/text_link_button.dart';
import '../../settings/application/settings_controller.dart';
import '../application/lock_controller.dart';
import '../domain/attempt_result.dart';
import 'widgets/lock_header.dart';
import 'widgets/password_unlock_form.dart';
import 'widgets/pin_entry_pad.dart';

/// Screen 1: "Welcome back". Master PIN keypad, with biometrics and a master
/// password fallback. Unlocking flips [lockProvider]; the router does the rest.
class UnlockScreen extends ConsumerStatefulWidget {
  const UnlockScreen({super.key});

  @override
  ConsumerState<UnlockScreen> createState() => _UnlockScreenState();
}

class _UnlockScreenState extends ConsumerState<UnlockScreen> {
  bool _passwordMode = false;
  String? _error;
  DateTime? _lockedUntil;
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _refreshLockout();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && ref.read(settingsProvider).biometricEnabled) _biometric();
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  Future<void> _refreshLockout() async {
    final until = await ref.read(lockProvider.notifier).lockedUntil();
    if (!mounted) return;
    _setLockedUntil(until);
  }

  void _setLockedUntil(DateTime? until) {
    _ticker?.cancel();
    setState(() {
      _lockedUntil = until;
      if (until != null) _error = null;
    });
    if (until == null) return;
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (!until.isAfter(DateTime.now())) {
        _ticker?.cancel();
        setState(() => _lockedUntil = null);
      } else {
        setState(() {});
      }
    });
  }

  /// Returns true when the attempt succeeded.
  bool _handle(AttemptResult result, String what) {
    switch (result) {
      case AttemptSuccess():
        return true;
      case AttemptWrong(:final attemptsLeft):
        setState(() {
          _error = attemptsLeft <= 2
              ? 'Incorrect $what · $attemptsLeft ${attemptsLeft == 1 ? 'try' : 'tries'} left'
              : 'Incorrect $what';
        });
        return false;
      case AttemptLockedOut(:final until):
        _setLockedUntil(until);
        return false;
    }
  }

  Future<bool> _submitPin(String pin) async =>
      _handle(await ref.read(lockProvider.notifier).unlockWithPin(pin), 'PIN');

  Future<bool> _submitPassword(String password) async => _handle(
    await ref.read(lockProvider.notifier).unlockWithPassword(password),
    'password',
  );

  Future<void> _biometric() =>
      ref.read(lockProvider.notifier).unlockWithBiometrics();

  String get _remaining {
    final left = _lockedUntil!.difference(DateTime.now());
    final secs = left.inSeconds < 0 ? 0 : left.inSeconds + 1;
    return '${secs ~/ 60}:${(secs % 60).toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final biometric = ref.watch(
      settingsProvider.select((s) => s.biometricEnabled),
    );
    final lockedOut = _lockedUntil != null;
    final message = lockedOut
        ? 'Too many attempts. Try again in $_remaining'
        : _error ??
              (_passwordMode
                  ? 'Enter your master password to open your PINs'
                  : 'Enter your master PIN to open your PINs');

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(top: 72, bottom: 24),
          child: Column(
            children: [
              LockHeader(
                title: 'Welcome back',
                message: message,
                isError: lockedOut || _error != null,
              ),
              const SizedBox(height: 34),
              if (_passwordMode)
                PasswordUnlockForm(
                  enabled: !lockedOut,
                  onSubmit: _submitPassword,
                )
              else
                PinEntryPad(
                  enabled: !lockedOut,
                  onBiometric: biometric ? _biometric : null,
                  onComplete: _submitPin,
                ),
              const SizedBox(height: 18),
              TextLinkButton(
                label: _passwordMode
                    ? 'Use master PIN instead'
                    : 'Use master password instead',
                onPressed: () => setState(() {
                  _passwordMode = !_passwordMode;
                  _error = null;
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/text_link_button.dart';
import '../application/lock_controller.dart';
import 'widgets/lock_header.dart';
import 'widgets/password_setup_form.dart';
import 'widgets/pin_entry_pad.dart';

enum _Step { createPin, confirmPin, createPassword }

/// First run: create the master PIN (twice), then a master password that acts as
/// the fallback. Finishing flips [lockProvider] to unlocked.
class SetupScreen extends ConsumerStatefulWidget {
  const SetupScreen({super.key});

  @override
  ConsumerState<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends ConsumerState<SetupScreen> {
  _Step _step = _Step.createPin;
  String _pin = '';
  String? _error;

  Future<bool> _onCreatePin(String pin) async {
    setState(() {
      _pin = pin;
      _error = null;
      _step = _Step.confirmPin;
    });
    return true;
  }

  Future<bool> _onConfirmPin(String pin) async {
    if (pin == _pin) {
      setState(() {
        _error = null;
        _step = _Step.createPassword;
      });
      return true;
    }
    setState(() => _error = "PINs didn't match. Try again");
    return false;
  }

  void _startOver() => setState(() {
    _pin = '';
    _error = null;
    _step = _Step.createPin;
  });

  Future<void> _finish(String password) => ref
      .read(lockProvider.notifier)
      .completeSetup(pin: _pin, password: password);

  @override
  Widget build(BuildContext context) {
    final (title, message) = switch (_step) {
      _Step.createPin => (
        'Create your PIN',
        'Choose a 6-digit master PIN to open Pinbox',
      ),
      _Step.confirmPin => ('Confirm your PIN', 'Enter the same 6 digits again'),
      _Step.createPassword => (
        'Add a master password',
        'A backup way in if you forget your PIN. Neither can be recovered, so keep them somewhere safe.',
      ),
    };

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.only(top: 72, bottom: 24),
          child: Column(
            children: [
              LockHeader(
                title: title,
                message: _error ?? message,
                isError: _error != null,
              ),
              const SizedBox(height: 34),
              switch (_step) {
                _Step.createPin => PinEntryPad(
                  key: const ValueKey('create'),
                  onComplete: _onCreatePin,
                ),
                _Step.confirmPin => PinEntryPad(
                  key: const ValueKey('confirm'),
                  onComplete: _onConfirmPin,
                ),
                _Step.createPassword => PasswordSetupForm(
                  pin: _pin,
                  onSubmit: _finish,
                ),
              },
              if (_step != _Step.createPin) ...[
                const SizedBox(height: 16),
                TextLinkButton(label: 'Start over', onPressed: _startOver),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

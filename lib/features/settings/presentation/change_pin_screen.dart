import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/app_snackbar.dart';
import '../../../core/widgets/page_header.dart';
import '../../../core/widgets/text_link_button.dart';
import '../../lock/application/lock_controller.dart';
import '../../lock/domain/attempt_message.dart';
import '../../lock/domain/attempt_result.dart';
import '../../lock/presentation/widgets/lock_header.dart';
import '../../lock/presentation/widgets/password_unlock_form.dart';
import '../../lock/presentation/widgets/pin_entry_pad.dart';

enum _Step { verify, create, confirm }

/// Change the master PIN: prove who you are (current PIN, or the master password),
/// then enter the new one twice.
class ChangePinScreen extends ConsumerStatefulWidget {
  const ChangePinScreen({super.key});

  @override
  ConsumerState<ChangePinScreen> createState() => _ChangePinScreenState();
}

class _ChangePinScreenState extends ConsumerState<ChangePinScreen> {
  _Step _step = _Step.verify;
  bool _usePassword = false;
  String _newPin = '';
  String? _error;

  Future<bool> _verify(
    Future<AttemptResult> Function() check,
    String what,
  ) async {
    final message = attemptMessage(await check(), what);
    if (!mounted) return false;
    setState(() {
      _error = message;
      if (message == null) _step = _Step.create;
    });
    return message == null;
  }

  Future<bool> _onCreate(String pin) async {
    setState(() {
      _newPin = pin;
      _error = null;
      _step = _Step.confirm;
    });
    return true;
  }

  Future<bool> _onConfirm(String pin) async {
    if (pin != _newPin) {
      setState(() => _error = "PINs didn't match. Try again");
      return false;
    }
    await ref.read(lockProvider.notifier).changePin(pin);
    if (!mounted) return true;
    showAppSnackBar(context, 'Master PIN changed');
    context.pop();
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final lock = ref.read(lockProvider.notifier);
    final (title, message) = switch (_step) {
      _Step.verify => (
        'Change master PIN',
        _usePassword
            ? 'Enter your master password to continue'
            : 'Enter your current PIN to continue',
      ),
      _Step.create => ('New master PIN', 'Choose a new 6-digit PIN'),
      _Step.confirm => ('Confirm new PIN', 'Enter the new PIN again'),
    };

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: EdgeInsets.fromLTRB(12, 10, 0, 0),
                child: BackChevron(),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.only(top: 12, bottom: 24),
                child: Column(
                  children: [
                    LockHeader(
                      title: title,
                      message: _error ?? message,
                      isError: _error != null,
                    ),
                    const SizedBox(height: 34),
                    switch (_step) {
                      _Step.verify when _usePassword => PasswordUnlockForm(
                        buttonLabel: 'Continue',
                        onSubmit: (pw) =>
                            _verify(() => lock.verifyPassword(pw), 'password'),
                      ),
                      _Step.verify => PinEntryPad(
                        key: const ValueKey('verify'),
                        onComplete: (pin) =>
                            _verify(() => lock.verifyPin(pin), 'PIN'),
                      ),
                      _Step.create => PinEntryPad(
                        key: const ValueKey('create'),
                        onComplete: _onCreate,
                      ),
                      _Step.confirm => PinEntryPad(
                        key: const ValueKey('confirm'),
                        onComplete: _onConfirm,
                      ),
                    },
                    if (_step == _Step.verify) ...[
                      const SizedBox(height: 24),
                      TextLinkButton(
                        label: _usePassword
                            ? 'Use current PIN instead'
                            : 'Use master password instead',
                        onPressed: () => setState(() {
                          _usePassword = !_usePassword;
                          _error = null;
                        }),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

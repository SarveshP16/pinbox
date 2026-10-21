import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';

const minPasswordLength = 8;

/// Why [password] can't be used as a master password, or null if it's fine.
String? masterPasswordProblem(String password, {String? confirm, String? pin}) {
  if (password.length < minPasswordLength) {
    return 'Use at least $minPasswordLength characters';
  }
  if (pin != null && password == pin) {
    return 'Your password must differ from your PIN';
  }
  if (confirm != null && password != confirm) return "Passwords don't match";
  return null;
}

/// Two-field "create a password" form. [onSubmit] is called with a valid password.
class PasswordSetupForm extends StatefulWidget {
  const PasswordSetupForm({
    super.key,
    required this.onSubmit,
    required this.pin,
    this.buttonLabel = 'Finish setup',
  });

  final Future<void> Function(String password) onSubmit;

  /// The PIN chosen in the previous step, so the password can't simply repeat it.
  final String pin;
  final String buttonLabel;

  @override
  State<PasswordSetupForm> createState() => _PasswordSetupFormState();
}

class _PasswordSetupFormState extends State<PasswordSetupForm> {
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _obscured = true;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final problem = masterPasswordProblem(
      _password.text,
      confirm: _confirm.text,
      pin: widget.pin,
    );
    if (problem != null) {
      setState(() => _error = problem);
      return;
    }
    setState(() {
      _error = null;
      _busy = true;
    });
    await widget.onSubmit(_password.text);
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          AppTextField(
            label: 'Master password',
            controller: _password,
            obscureText: _obscured,
            textInputAction: TextInputAction.next,
            suffix: IconButton(
              tooltip: _obscured ? 'Show password' : 'Hide password',
              onPressed: () => setState(() => _obscured = !_obscured),
              icon: Icon(
                _obscured ? LucideIcons.eye : LucideIcons.eyeOff,
                size: 22,
                color: context.colors.muted,
              ),
            ),
          ),
          const SizedBox(height: 18),
          AppTextField(
            label: 'Confirm password',
            controller: _confirm,
            obscureText: _obscured,
            textInputAction: TextInputAction.done,
            errorText: _error,
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: AppButton(
              label: widget.buttonLabel,
              icon: LucideIcons.lock,
              onPressed: _busy ? null : _submit,
            ),
          ),
        ],
      ),
    );
  }
}

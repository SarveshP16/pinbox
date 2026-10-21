import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';

/// Master-password entry used as the fallback to the keypad. [onSubmit] returns
/// whether the password was accepted; on rejection the field is cleared.
class PasswordUnlockForm extends StatefulWidget {
  const PasswordUnlockForm({
    super.key,
    required this.onSubmit,
    this.enabled = true,
    this.buttonLabel = 'Unlock',
  });

  final Future<bool> Function(String password) onSubmit;
  final bool enabled;
  final String buttonLabel;

  @override
  State<PasswordUnlockForm> createState() => _PasswordUnlockFormState();
}

class _PasswordUnlockFormState extends State<PasswordUnlockForm> {
  final _controller = TextEditingController();
  bool _obscured = true;
  bool _busy = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy || !widget.enabled || _controller.text.isEmpty) return;
    setState(() => _busy = true);
    final ok = await widget.onSubmit(_controller.text);
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (!ok) _controller.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          AppTextField(
            label: 'Master password',
            controller: _controller,
            obscureText: _obscured,
            autofocus: true,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submit(),
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
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: AppButton(
              label: widget.buttonLabel,
              icon: LucideIcons.lockOpen,
              onPressed: widget.enabled && !_busy ? _submit : null,
            ),
          ),
        ],
      ),
    );
  }
}

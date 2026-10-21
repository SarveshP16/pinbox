import 'package:flutter/material.dart';

import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../lock/presentation/widgets/password_setup_form.dart'
    show minPasswordLength;

/// Asks for a backup password. When [creating], it asks twice and enforces a minimum
/// length; otherwise it asks once (restoring).
///
/// [onSubmit] does the actual work and returns an error message to show inline
/// (keeping the dialog open), or null on success (closing it). Resolves to true if
/// it completed, false/null if cancelled.
Future<bool?> showBackupPasswordDialog(
  BuildContext context, {
  required bool creating,
  required Future<String?> Function(String password) onSubmit,
}) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) =>
        _BackupPasswordDialog(creating: creating, onSubmit: onSubmit),
  );
}

class _BackupPasswordDialog extends StatefulWidget {
  const _BackupPasswordDialog({required this.creating, required this.onSubmit});

  final bool creating;
  final Future<String?> Function(String password) onSubmit;

  @override
  State<_BackupPasswordDialog> createState() => _BackupPasswordDialogState();
}

class _BackupPasswordDialogState extends State<_BackupPasswordDialog> {
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy) return;
    final password = _password.text;
    if (widget.creating) {
      if (password.length < minPasswordLength) {
        setState(() => _error = 'Use at least $minPasswordLength characters');
        return;
      }
      if (password != _confirm.text) {
        setState(() => _error = "Passwords don't match");
        return;
      }
    } else if (password.isEmpty) {
      setState(() => _error = 'Enter the backup password');
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });
    final error = await widget.onSubmit(password);
    if (!mounted) return;
    if (error == null) {
      Navigator.pop(context, true);
    } else {
      setState(() {
        _busy = false;
        _error = error;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.creating ? 'Choose a backup password' : 'Enter backup password',
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.creating
                  ? 'You’ll need this password to restore the backup. It can’t be recovered, so keep it safe.'
                  : 'The password you chose when you exported this backup.',
              style: AppText.body(15, color: context.colors.muted, height: 1.4),
            ),
            const SizedBox(height: 18),
            AppTextField(
              label: 'Password',
              controller: _password,
              obscureText: true,
              autofocus: true,
              textInputAction: widget.creating
                  ? TextInputAction.next
                  : TextInputAction.done,
              onSubmitted: widget.creating ? null : (_) => _submit(),
              errorText: widget.creating ? null : _error,
            ),
            if (widget.creating) ...[
              const SizedBox(height: 16),
              AppTextField(
                label: 'Confirm password',
                controller: _confirm,
                obscureText: true,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _submit(),
                errorText: _error,
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.pop(context, false),
          child: Text(
            'Cancel',
            style: AppText.body(16, weight: 600, color: context.colors.muted),
          ),
        ),
        TextButton(
          onPressed: _busy ? null : _submit,
          child: _busy
              ? SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    color: context.colors.primary,
                  ),
                )
              : Text(
                  widget.creating ? 'Export' : 'Restore',
                  style: AppText.body(
                    16,
                    weight: 700,
                    color: context.colors.primary,
                  ),
                ),
        ),
      ],
    );
  }
}

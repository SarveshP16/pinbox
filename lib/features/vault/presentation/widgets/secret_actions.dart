import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/widgets/app_button.dart';
import '../../domain/vault_entry.dart';

/// The "Copy PIN" + "Reveal/Hide" button pair under a secret.
class SecretActions extends StatelessWidget {
  const SecretActions({
    super.key,
    required this.entry,
    required this.revealed,
    required this.onCopy,
    required this.onToggleReveal,
  });

  final VaultEntry entry;
  final bool revealed;
  final VoidCallback onCopy;
  final VoidCallback onToggleReveal;

  @override
  Widget build(BuildContext context) {
    final copyLabel = entry.type.isBankInfo
        ? 'Copy account no.'
        : 'Copy ${entry.type.secretNoun}';
    return Row(
      children: [
        Expanded(
          flex: 216,
          child: AppButton(
            label: copyLabel,
            icon: LucideIcons.copy,
            height: 52,
            onPressed: onCopy,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 114,
          child: AppButton(
            label: revealed ? 'Hide' : 'Reveal',
            icon: revealed ? LucideIcons.eyeOff : LucideIcons.eye,
            style: AppButtonStyle.tonal,
            height: 52,
            onPressed: onToggleReveal,
          ),
        ),
      ],
    );
  }
}

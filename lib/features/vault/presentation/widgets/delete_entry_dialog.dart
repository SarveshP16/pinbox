import 'package:flutter/material.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/vault_entry.dart';

/// Asks before permanently deleting [entry]. Resolves to true if confirmed.
Future<bool> confirmDeleteEntry(BuildContext context, VaultEntry entry) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Delete this ${entry.type.entryNoun}?'),
      content: Text(
        '${entry.bank} · ${entry.type.label} will be removed from this device. This can’t be undone.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(
            'Cancel',
            style: AppText.body(16, weight: 600, color: context.colors.muted),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(
            'Delete',
            style: AppText.body(16, weight: 700, color: context.colors.danger),
          ),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}

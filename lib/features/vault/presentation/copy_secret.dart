import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/app_snackbar.dart';
import '../../settings/application/settings_controller.dart';
import '../application/clipboard_service.dart';
import '../application/vault_controller.dart';
import '../domain/vault_entry.dart';

/// Copies [value] and tells the user when it will be wiped from the clipboard.
/// [label] names what was copied ("PIN", "Account name").
Future<void> copyValue(
  BuildContext context,
  WidgetRef ref,
  String value, {
  required String label,
}) async {
  await ref.read(clipboardServiceProvider).copy(value);
  if (!context.mounted) return;
  final seconds = ref.read(settingsProvider).clearClipboardSeconds;
  final capitalised = '${label[0].toUpperCase()}${label.substring(1)}';
  showAppSnackBar(
    context,
    seconds > 0
        ? '$capitalised copied · clears in $seconds s'
        : '$capitalised copied',
  );
}

/// Copies an entry's main secret (PIN, password or account number), and counts
/// as using the entry for the "Recently used" sort.
Future<void> copyEntrySecret(
  BuildContext context,
  WidgetRef ref,
  VaultEntry entry,
) async {
  await copyValue(context, ref, entry.secret, label: entry.type.secretNoun);
  await ref.read(vaultProvider.notifier).markUsed(entry.id);
}

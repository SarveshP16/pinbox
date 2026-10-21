import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/crypto/packed_cipher.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../lock/application/lock_controller.dart';
import '../../vault/application/vault_controller.dart';
import '../data/backup_codec.dart';
import 'backup_password_dialog.dart';

/// Largest backup file we'll read; a real one is a few KB.
const _maxBackupBytes = 5 * 1024 * 1024;

/// Encrypts every entry under a password the user picks, then hands the file to the
/// system share sheet (save to Files/Drive, send to yourself, …).
Future<void> exportBackup(BuildContext context, WidgetRef ref) async {
  final entries = ref.read(vaultProvider).value ?? const [];
  if (entries.isEmpty) {
    showAppSnackBar(context, 'Nothing to export yet');
    return;
  }

  final codec = BackupCodec();
  Uint8List? encoded;
  final done = await showBackupPasswordDialog(
    context,
    creating: true,
    onSubmit: (password) async {
      encoded = await codec.encode(entries, password);
      return null;
    },
  );
  final bytes = encoded;
  if (done != true || bytes == null || !context.mounted) return;

  final dir = await getTemporaryDirectory();
  final now = DateTime.now();
  String two(int n) => n.toString().padLeft(2, '0');
  final name =
      'pinbox-backup-${now.year}-${two(now.month)}-${two(now.day)}.pinbox';
  final file = File('${dir.path}${Platform.pathSeparator}$name');
  await file.writeAsBytes(bytes, flush: true);

  try {
    await ref
        .read(lockProvider.notifier)
        .withoutAutoLock(
          () => SharePlus.instance.share(
            ShareParams(
              files: [XFile(file.path, mimeType: 'application/octet-stream')],
              subject: name,
            ),
          ),
        );
  } finally {
    // The encrypted copy shouldn't linger in the cache once it's been handed off.
    if (await file.exists()) await file.delete();
  }
}

/// Picks a backup file, asks for its password, and merges the entries into the vault.
Future<void> importBackup(BuildContext context, WidgetRef ref) async {
  final picked = await ref
      .read(lockProvider.notifier)
      .withoutAutoLock(
        () => FilePicker.pickFile(dialogTitle: 'Choose a Pinbox backup'),
      );
  if (picked == null || !context.mounted) return;

  if ((await picked.length() ?? 0) > _maxBackupBytes) {
    if (context.mounted) {
      showAppSnackBar(context, 'That file is too large to be a Pinbox backup');
    }
    return;
  }
  final bytes = await picked.readAsBytes();
  if (!context.mounted) return;

  final codec = BackupCodec();
  var restored = 0;
  final done = await showBackupPasswordDialog(
    context,
    creating: false,
    onSubmit: (password) async {
      try {
        final incoming = await codec.decode(bytes, password);
        restored = await ref.read(vaultProvider.notifier).merge(incoming);
        return null;
      } on DecryptionFailure {
        return 'Wrong password, or the file has been altered';
      } on NotABackupFile {
        return 'This isn’t a Pinbox backup file';
      }
    },
  );
  if (done != true || !context.mounted) return;

  showAppSnackBar(
    context,
    restored == 0
        ? 'Backup restored · nothing new to add'
        : 'Restored $restored ${restored == 1 ? 'entry' : 'entries'}',
  );
}

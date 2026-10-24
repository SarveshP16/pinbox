import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pinbox/features/backup/data/snapshot_store.dart';
import 'package:pinbox/features/vault/domain/entry_type.dart';

import '../../support/entries.dart';
import '../../support/harness.dart';

/// From an unlocked vault, opens Settings and scrolls to the BACKUP group.
Future<void> _openSettingsBackup(WidgetTester tester) async {
  await tester.tap(find.byTooltip('Settings'));
  await settle(tester);
  await tester.scrollUntilVisible(
    find.text('Automatic backups'),
    200,
    scrollable: find.byType(Scrollable),
  );
  await settle(tester);
}

/// Deletes the entry whose row shows [label], confirming the dialog.
Future<void> _deleteEntry(WidgetTester tester, String label) async {
  await tester.tap(find.text(label));
  await settle(tester);
  await tester.tap(find.byTooltip('More'));
  await settle(tester);
  await tester.tap(find.text('Delete'));
  await settle(tester);
  await tester.tap(find.widgetWithText(TextButton, 'Delete'));
  await settle(tester);
}

void main() {
  testWidgets('Settings offers automatic backups, and says so when there are none', (
    tester,
  ) async {
    await pumpPinbox(tester, seed: [entry()]);
    await tapPin(tester, testPin);
    await _openSettingsBackup(tester);

    expect(find.text('Automatic backups'), findsOneWidget);
    expect(find.text('None yet · taken before each change'), findsOneWidget);
  });

  testWidgets('the sheet explains what an automatic backup is and is not', (
    tester,
  ) async {
    await pumpPinbox(tester, seed: [entry()]);
    await tapPin(tester, testPin);
    await _openSettingsBackup(tester);

    await tester.tap(find.text('Automatic backups'));
    await settle(tester);

    // These die with the install, so the sheet has to say so plainly.
    expect(
      find.textContaining('cannot be read after the app is uninstalled'),
      findsOneWidget,
    );
    expect(find.textContaining('No automatic backups yet'), findsOneWidget);
  });

  testWidgets('the delete dialog points at automatic backups instead of "can’t be undone"', (
    tester,
  ) async {
    await pumpPinbox(
      tester,
      seed: [entry(id: 'p', type: EntryType.password, secret: 'hunter22')],
    );
    await tapPin(tester, testPin);

    await tester.tap(find.text('Password'));
    await settle(tester);
    await tester.tap(find.byTooltip('More'));
    await settle(tester);
    await tester.tap(find.text('Delete'));
    await settle(tester);

    expect(find.textContaining('Automatic backups'), findsOneWidget);
    expect(find.textContaining('can’t be undone'), findsNothing);
  });

  testWidgets('a deleted entry comes back by restoring the automatic backup', (
    tester,
  ) async {
    final app = await pumpPinbox(
      tester,
      seed: [
        entry(id: 'keep', type: EntryType.loginPin),
        entry(id: 'gone', type: EntryType.password, secret: 'hunter22'),
      ],
    );
    await tapPin(tester, testPin);

    await _deleteEntry(tester, 'Password');
    expect(app.vault.stored.map((e) => e.id), ['keep']);
    expect(app.snapshots.held, hasLength(1));

    await _openSettingsBackup(tester);
    expect(find.textContaining('1 kept · newest'), findsOneWidget);

    await tester.tap(find.text('Automatic backups'));
    await settle(tester);
    expect(find.text('2 entries'), findsOneWidget);

    await tester.tap(find.text('2 entries'));
    await settle(tester);
    expect(find.text('Restore this backup?'), findsOneWidget);
    await tester.tap(find.widgetWithText(TextButton, 'Restore'));
    await settle(tester);

    expect(app.vault.stored.map((e) => e.id), unorderedEquals(['keep', 'gone']));
    expect(find.text('Restored 2 entries'), findsOneWidget);
    // Restoring is itself a save, so the post-delete state was kept too.
    expect(app.snapshots.held, hasLength(2));
  });

  testWidgets('cancelling the restore leaves the vault alone', (tester) async {
    final app = await pumpPinbox(
      tester,
      seed: [
        entry(id: 'keep', type: EntryType.loginPin),
        entry(id: 'gone', type: EntryType.password, secret: 'hunter22'),
      ],
    );
    await tapPin(tester, testPin);
    await _deleteEntry(tester, 'Password');

    await _openSettingsBackup(tester);
    await tester.tap(find.text('Automatic backups'));
    await settle(tester);
    await tester.tap(find.text('2 entries'));
    await settle(tester);
    await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
    await settle(tester);

    expect(app.vault.stored.map((e) => e.id), ['keep']);
  });

  testWidgets('a snapshot that can’t be decrypted is left out of the list', (
    tester,
  ) async {
    final app = await pumpPinbox(tester, seed: [entry()]);
    // Present on disk but not readable — e.g. left over from a previous install.
    app.snapshots.held.add(
      VaultSnapshot(file: File('orphan'), takenAt: DateTime.now()),
    );
    await tapPin(tester, testPin);
    await _openSettingsBackup(tester);

    expect(find.text('None yet · taken before each change'), findsOneWidget);
  });
}

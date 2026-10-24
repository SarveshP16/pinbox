// Dev tool, not a regression test: renders each designed screen, light and dark, to
// test/preview/*.png at the mockups' 780x1688 size, for eyeballing against the
// reference screenshots. Skipped in normal runs; render with:
//   flutter test test/preview_test.dart --update-goldens
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pinbox/features/backup/data/snapshot_store.dart';
import 'package:pinbox/features/vault/domain/entry_type.dart';

import 'support/entries.dart';
import 'support/harness.dart';

void main() {
  final skip = !autoUpdateGoldenFiles;

  final seeded = [
    entry(
      id: '1',
      bank: 'Harbour Bank',
      type: EntryType.debitCard,
      secret: '4829',
      last4: '4417',
      nickname: 'Everyday account',
      notes: 'New PIN set after card replacement',
      created: DateTime.utc(2026, 1, 1),
    ),
    entry(
      id: '2',
      bank: 'Harbour Bank',
      type: EntryType.creditCard,
      secret: '7301',
      last4: '9032',
      created: DateTime.utc(2026, 1, 2),
    ),
    entry(
      id: '3',
      bank: 'Harbour Bank',
      type: EntryType.loginPin,
      secret: '7301552',
      created: DateTime.utc(2026, 1, 3),
    ),
    entry(
      id: '4',
      bank: 'Meridian CU',
      type: EntryType.debitCard,
      secret: '5512',
      last4: '2260',
      created: DateTime.utc(2026, 1, 4),
    ),
    entry(
      id: '5',
      bank: 'Meridian CU',
      type: EntryType.password,
      secret: 'correct-horse',
      created: DateTime.utc(2026, 1, 5),
    ),
    entry(
      id: '6',
      bank: 'Lantern Savings',
      type: EntryType.phonePin,
      secret: '2468',
      created: DateTime.utc(2026, 1, 6),
    ),
  ];

  // Everything the mockups don't show: the two new types.
  final extras = [
    entry(
      id: 'lock',
      bank: 'Harbour Bank',
      type: EntryType.cardLockPin,
      secret: '0246',
      last4: '4417',
      nickname: 'Freeze / unfreeze',
      created: DateTime.utc(2026, 1, 1),
    ),
    entry(
      id: 'bank',
      bank: 'Harbour Bank',
      type: EntryType.bankInfo,
      secret: '001122334455',
      nickname: 'Salary account',
      created: DateTime.utc(2026, 1, 2),
    ).copyWith(
      accountName: 'Jane Citizen',
      routingCode: '123-456',
      cifNumber: '99887766',
    ),
  ];

  Future<void> shot(WidgetTester tester, String name) async {
    await tester.pump(const Duration(milliseconds: 50));
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('preview/$name.png'),
    );
  }

  void useMockupSize(WidgetTester tester) {
    tester.view
      ..physicalSize = const Size(780, 1688)
      ..devicePixelRatio = 2
      // A typical 24dp Android status bar above the content.
      ..padding = const FakeViewPadding(top: 48)
      ..viewPadding = const FakeViewPadding(top: 48);
    addTearDown(tester.view.resetPadding);
    addTearDown(tester.view.resetViewPadding);
  }

  for (final (suffix, theme) in [('', 'light'), ('_dark', 'dark')]) {
    final prefs = <String, Object>{
      'biometric_enabled': true,
      'theme_mode': theme,
    };

    testWidgets('1 unlock ($theme)', skip: skip, (tester) async {
      await pumpPinbox(tester, seed: seeded, prefs: prefs);
      useMockupSize(tester);
      await tester.pump();
      for (final d in ['1', '2', '3']) {
        await tester.tap(find.text(d));
        await tester.pump(const Duration(milliseconds: 200));
      }
      await tester.pump(const Duration(milliseconds: 600));
      await shot(tester, '1_unlock$suffix');
    });

    testWidgets('2-4 list, detail, add ($theme)', skip: skip, (tester) async {
      await pumpPinbox(tester, seed: seeded, prefs: prefs);
      useMockupSize(tester);
      await tapPin(tester, testPin);

      await tester.tap(find.bySemanticsLabel('Reveal PIN').first);
      await tester.pump(const Duration(milliseconds: 2100));
      await tester.pump(const Duration(milliseconds: 400));
      await shot(tester, '2_my_pins$suffix');

      await tester.tap(find.text('Debit card').first);
      await settle(tester);
      await shot(tester, '3_detail$suffix');

      await tester.tap(find.byTooltip('Back'));
      await settle(tester);
      await tester.tap(find.text('Add PIN'));
      await settle(tester);
      await tester.enterText(find.byType(TextField).at(0), 'Harbour Bank');
      await tester.enterText(find.byType(TextField).at(1), '4417');
      await tester.enterText(find.byType(TextField).at(2), '1234');
      await tester.pump(const Duration(milliseconds: 300));
      await shot(tester, '4_add$suffix');
    });

    testWidgets('5 settings ($theme)', skip: skip, (tester) async {
      await pumpPinbox(tester, seed: seeded, prefs: prefs);
      useMockupSize(tester);
      await tapPin(tester, testPin);
      await tester.tap(find.byTooltip('Settings'));
      await settle(tester);
      await shot(tester, '5_settings$suffix');
    });

    testWidgets('9 automatic backups ($theme)', skip: skip, (tester) async {
      final app = await pumpPinbox(tester, seed: seeded, prefs: prefs);
      useMockupSize(tester);

      // A realistic history: a deletion a few minutes ago, an edit earlier
      // today, and the state as of yesterday evening.
      final now = DateTime.now();
      for (final (ago, count) in [
        (const Duration(minutes: 3), seeded.length),
        (const Duration(hours: 4), seeded.length - 1),
        (const Duration(hours: 22), seeded.length - 2),
      ]) {
        final file = File('preview-snapshot-${ago.inMinutes}');
        app.vault.snapshotContents[file.path] = seeded.take(count).toList();
        app.snapshots.held.add(
          VaultSnapshot(file: file, takenAt: now.subtract(ago)),
        );
      }

      await tapPin(tester, testPin);
      await tester.tap(find.byTooltip('Settings'));
      await settle(tester);
      await tester.scrollUntilVisible(
        find.text('Automatic backups'),
        200,
        scrollable: find.byType(Scrollable),
      );
      await settle(tester);
      await tester.tap(find.text('Automatic backups'));
      await settle(tester);
      await shot(tester, '9_automatic_backups$suffix');
    });

    testWidgets('new types ($theme)', skip: skip, (tester) async {
      await pumpPinbox(tester, seed: [...seeded, ...extras], prefs: prefs);
      useMockupSize(tester);
      await tapPin(tester, testPin);
      await shot(tester, '6_list_new_types$suffix');

      await tester.tap(find.text('Bank Info'));
      await settle(tester);
      await tester.tap(find.text('Reveal'));
      await tester.pump(const Duration(milliseconds: 2100));
      await tester.pump(const Duration(milliseconds: 400));
      await shot(tester, '7_bank_info_detail$suffix');

      await tester.tap(find.byTooltip('Back'));
      await settle(tester);
      await tester.tap(find.text('Add PIN'));
      await settle(tester);
      await tester.tap(find.text('Bank Info'));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.enterText(find.byType(TextField).at(0), 'Harbour Bank');
      await tester.enterText(find.byType(TextField).at(1), 'Jane Citizen');
      await tester.enterText(find.byType(TextField).at(2), '001122334455');
      await tester.pump(const Duration(milliseconds: 300));
      await shot(tester, '8_add_bank_info$suffix');
    });
  }
}

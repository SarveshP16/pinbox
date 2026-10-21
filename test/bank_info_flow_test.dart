import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pinbox/features/vault/domain/entry_type.dart';

import 'support/entries.dart';
import 'support/harness.dart';

void main() {
  final bankInfo =
      entry(
        id: 'bi',
        bank: 'Harbour Bank',
        type: EntryType.bankInfo,
        secret: '001122334455',
        nickname: 'Salary account',
        created: DateTime.utc(2026, 1, 1),
      ).copyWith(
        accountName: 'Jane Citizen',
        routingCode: '123-456',
        cifNumber: '99887766',
      );

  Future<void> openAdd(WidgetTester tester) async {
    await tester.tap(find.text('Add PIN'));
    await settle(tester);
  }

  testWidgets('the Add screen offers all seven types in order', (tester) async {
    await pumpPinbox(tester);
    await tapPin(tester, testPin);
    await openAdd(tester);

    final labels = [
      'Debit card',
      'Card lock PIN',
      'Credit card',
      'Login PIN',
      'Phone PIN',
      'Password',
      'Bank Info',
    ];
    var lastY = -1.0;
    var lastX = -1.0;
    for (final label in labels) {
      final at = tester.getTopLeft(find.text(label));
      // Chips wrap left-to-right, top-to-bottom.
      expect(
        at.dy > lastY || (at.dy == lastY && at.dx > lastX),
        isTrue,
        reason: '$label out of order',
      );
      lastY = at.dy;
      lastX = at.dx;
    }
  });

  testWidgets('Card lock PIN asks for the card ending and a numeric PIN', (
    tester,
  ) async {
    final app = await pumpPinbox(tester);
    await tapPin(tester, testPin);
    await openAdd(tester);

    await tester.enterText(find.byType(TextField).at(0), 'Harbour Bank');
    await tester.tap(find.text('Card lock PIN'));
    await tester.pump();
    expect(find.text('Last 4 digits of the card'), findsOneWidget);
    await tester.enterText(find.byType(TextField).at(1), '4417');
    await tester.enterText(find.byType(TextField).at(2), '0246');
    await tester.tap(find.text('Save PIN'));
    await settle(tester);

    final saved = app.vault.stored.single;
    expect(saved.type, EntryType.cardLockPin);
    expect(saved.cardLast4, '4417');
    expect(saved.secret, '0246');
    expect(find.text('Card lock PIN'), findsOneWidget); // its row title
  });

  testWidgets('Bank Info shows its own fields instead of a PIN box', (
    tester,
  ) async {
    await pumpPinbox(tester);
    await tapPin(tester, testPin);
    await openAdd(tester);

    await tester.tap(find.text('Bank Info'));
    await tester.pump();

    for (final label in [
      'Account name',
      'Account number',
      'BSB / IFSC',
      'CIF number (optional)',
    ]) {
      expect(find.text(label), findsOneWidget, reason: label);
    }
    expect(find.text('Last 4 digits of the card'), findsNothing);
    expect(find.text('Add a password too'), findsNothing);
    expect(find.text('Save details'), findsOneWidget);
  });

  testWidgets('saving Bank Info stores every field, tidied', (tester) async {
    final app = await pumpPinbox(tester);
    await tapPin(tester, testPin);
    await openAdd(tester);

    await tester.enterText(find.byType(TextField).at(0), 'Harbour Bank');
    await tester.tap(find.text('Bank Info'));
    await tester.pump();
    await tester.enterText(find.byType(TextField).at(1), '  Jane Citizen ');
    await tester.enterText(find.byType(TextField).at(2), '001122334455');
    await tester.enterText(find.byType(TextField).at(3), 'sbin0001234');
    await tester.enterText(find.byType(TextField).at(4), 'cif123');
    await tester.tap(find.text('Save details'));
    await settle(tester);

    final saved = app.vault.stored.single;
    expect(saved.type, EntryType.bankInfo);
    expect(saved.accountName, 'Jane Citizen');
    expect(saved.secret, '001122334455');
    expect(saved.routingCode, 'SBIN0001234');
    expect(saved.cifNumber, 'CIF123');
    expect(find.text('Bank Info'), findsOneWidget); // its list row
  });

  testWidgets('the CIF number is optional', (tester) async {
    final app = await pumpPinbox(tester);
    await tapPin(tester, testPin);
    await openAdd(tester);

    await tester.enterText(find.byType(TextField).at(0), 'Harbour Bank');
    await tester.tap(find.text('Bank Info'));
    await tester.pump();
    await tester.enterText(find.byType(TextField).at(1), 'Jane Citizen');
    await tester.enterText(find.byType(TextField).at(2), '001122334455');
    await tester.enterText(find.byType(TextField).at(3), '123-456');
    await tester.tap(find.text('Save details'));
    await settle(tester);

    expect(app.vault.stored.single.cifNumber, '');
  });

  testWidgets('Bank Info refuses empty or malformed fields', (tester) async {
    final app = await pumpPinbox(tester);
    await tapPin(tester, testPin);
    await openAdd(tester);

    await tester.enterText(find.byType(TextField).at(0), 'Harbour Bank');
    await tester.tap(find.text('Bank Info'));
    await tester.pump();
    await tester.enterText(find.byType(TextField).at(2), '12');
    await tester.enterText(find.byType(TextField).at(3), '12');
    await tester.tap(find.text('Save details'));
    await settle(tester);

    expect(find.text('Enter the account name'), findsOneWidget);
    expect(find.textContaining('An account number is'), findsOneWidget);
    expect(find.textContaining('A BSB has 6 digits'), findsOneWidget);
    expect(app.vault.stored, isEmpty);
  });

  testWidgets('the account number field only accepts digits', (tester) async {
    await pumpPinbox(tester);
    await tapPin(tester, testPin);
    await openAdd(tester);
    await tester.tap(find.text('Bank Info'));
    await tester.pump();

    await tester.enterText(find.byType(TextField).at(2), '12ab-34 56');
    expect(
      tester.widget<TextField>(find.byType(TextField).at(2)).controller!.text,
      '123456',
    );
  });

  testWidgets(
    'Bank Info detail hides the account and CIF numbers until revealed',
    (tester) async {
      await pumpPinbox(tester, seed: [bankInfo]);
      await tapPin(tester, testPin);
      await tester.tap(find.text('Bank Info'));
      await settle(tester);

      // Always visible.
      expect(find.text('BANK INFO'), findsOneWidget);
      expect(find.text('Jane Citizen'), findsWidgets);
      expect(find.text('123-456'), findsWidgets);
      // Hidden.
      expect(find.text('001122334455'), findsNothing);
      expect(find.text('99887766'), findsNothing);

      await tester.tap(find.text('Reveal'));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('001122334455'), findsOneWidget);
      expect(find.text('99887766'), findsOneWidget);
      expect(find.text('Hides in 10 s'), findsOneWidget);

      await tester.tap(find.text('Hide'));
      await settle(tester);
      expect(find.text('001122334455'), findsNothing);
      expect(find.text('99887766'), findsNothing);
    },
  );

  testWidgets('each Bank Info field has its own copy button', (tester) async {
    final app = await pumpPinbox(tester, seed: [bankInfo]);
    await tapPin(tester, testPin);
    await tester.tap(find.text('Bank Info'));
    await settle(tester);

    for (final tooltip in [
      'Copy account name',
      'Copy account number',
      'Copy bsb / ifsc',
      'Copy cif number',
    ]) {
      expect(find.byTooltip(tooltip), findsOneWidget, reason: tooltip);
    }

    await tester.tap(find.byTooltip('Copy account name'));
    await settle(tester);
    expect(find.text('Account name copied · clears in 30 s'), findsOneWidget);
    expect(app.clipboard.text, 'Jane Citizen');

    await tester.tap(find.byTooltip('Copy account number'));
    await settle(tester);
    expect(app.clipboard.text, '001122334455');
    expect(find.text('Account number copied · clears in 30 s'), findsOneWidget);

    await tester.tap(find.byTooltip('Copy bsb / ifsc'));
    await settle(tester);
    expect(app.clipboard.text, '123-456');

    await tester.tap(find.byTooltip('Copy cif number'));
    await settle(tester);
    expect(app.clipboard.text, '99887766');

    // The clipboard is wiped once the timeout passes.
    await tester.pump(const Duration(seconds: 31));
    expect(app.clipboard.text, '');
  });

  testWidgets('Bank Info without a CIF number omits that row', (tester) async {
    await pumpPinbox(tester, seed: [bankInfo.copyWith(cifNumber: '')]);
    await tapPin(tester, testPin);
    await tester.tap(find.text('Bank Info'));
    await settle(tester);

    expect(find.text('CIF number'), findsNothing);
    expect(find.text('Account number'), findsOneWidget);
  });

  testWidgets(
    'a Bank Info row peeks the account number, and deleting says "bank info"',
    (tester) async {
      final app = await pumpPinbox(tester, seed: [bankInfo]);
      await tapPin(tester, testPin);

      expect(
        find.text('Salary account'),
        findsOneWidget,
      ); // nickname as subtitle
      await tester.tap(find.bySemanticsLabel('Reveal account number'));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('001122334455'), findsOneWidget);

      await tester.tap(find.text('Bank Info'));
      await settle(tester);
      await tester.tap(find.byTooltip('More'));
      await settle(tester);
      await tester.tap(find.text('Delete'));
      await settle(tester);
      expect(find.text('Delete this bank info?'), findsOneWidget);
      await tester.tap(find.widgetWithText(TextButton, 'Delete'));
      await settle(tester);
      expect(app.vault.stored, isEmpty);
    },
  );

  testWidgets('editing Bank Info keeps its fields and lets you change them', (
    tester,
  ) async {
    final app = await pumpPinbox(tester, seed: [bankInfo]);
    await tapPin(tester, testPin);
    await tester.tap(find.text('Bank Info'));
    await settle(tester);
    await tester.tap(find.byTooltip('Edit'));
    await settle(tester);

    expect(find.text('Save changes'), findsOneWidget);
    final fields = tester
        .widgetList<TextField>(find.byType(TextField))
        .toList();
    expect(fields[1].controller!.text, 'Jane Citizen');
    expect(fields[2].controller!.text, '001122334455');
    expect(fields[3].controller!.text, '123-456');
    expect(fields[4].controller!.text, '99887766');

    await tester.enterText(find.byType(TextField).at(3), 'sbin0009999');
    await tester.tap(find.text('Save changes'));
    await settle(tester);

    final saved = app.vault.stored.single;
    expect(saved.routingCode, 'SBIN0009999');
    expect(saved.accountName, 'Jane Citizen');
    expect(saved.id, 'bi');
  });

  testWidgets(
    'switching a Bank Info entry to another type drops its bank fields',
    (tester) async {
      final app = await pumpPinbox(tester, seed: [bankInfo]);
      await tapPin(tester, testPin);
      await tester.tap(find.text('Bank Info'));
      await settle(tester);
      await tester.tap(find.byTooltip('Edit'));
      await settle(tester);

      await tester.tap(find.text('Login PIN'));
      await tester.pump();
      await tester.enterText(find.byType(TextField).at(1), '13579');
      await tester.tap(find.text('Save changes'));
      await settle(tester);

      final saved = app.vault.stored.single;
      expect(saved.type, EntryType.loginPin);
      expect(saved.accountName, '');
      expect(saved.routingCode, '');
      expect(saved.cifNumber, '');
    },
  );
}

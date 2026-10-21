import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pinbox/features/lock/application/lock_controller.dart';
import 'package:pinbox/features/vault/application/vault_controller.dart';
import 'package:pinbox/features/vault/domain/entry_type.dart';
import 'package:pinbox/features/vault/presentation/my_pins_screen.dart';

import 'support/entries.dart';
import 'support/harness.dart';

/// The OS walks these states in order; Flutter asserts on any shortcut.
void leaveApp(WidgetTester tester) {
  for (final state in [
    AppLifecycleState.inactive,
    AppLifecycleState.hidden,
    AppLifecycleState.paused,
  ]) {
    tester.binding.handleAppLifecycleStateChanged(state);
  }
}

void returnToApp(WidgetTester tester) {
  for (final state in [
    AppLifecycleState.hidden,
    AppLifecycleState.inactive,
    AppLifecycleState.resumed,
  ]) {
    tester.binding.handleAppLifecycleStateChanged(state);
  }
}

void main() {
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
      type: EntryType.loginPin,
      secret: '7301552',
      created: DateTime.utc(2026, 1, 2),
    ),
    entry(
      id: '3',
      bank: 'Meridian CU',
      type: EntryType.password,
      secret: 'correct-horse',
      created: DateTime.utc(2026, 1, 3),
    ),
  ];

  testWidgets(
    'first run walks through PIN, confirm, password, then opens an empty vault',
    (tester) async {
      await pumpPinbox(tester, withCredentials: false);

      expect(find.text('Create your PIN'), findsOneWidget);
      await tapPin(tester, testPin);
      expect(find.text('Confirm your PIN'), findsOneWidget);
      await tapPin(tester, testPin);
      expect(find.text('Add a master password'), findsOneWidget);

      await tester.enterText(find.byType(TextField).at(0), testPassword);
      await tester.enterText(find.byType(TextField).at(1), testPassword);
      await tester.tap(find.text('Finish setup'));
      await settle(tester);

      expect(find.text('My PINs'), findsOneWidget);
      expect(find.text('No PINs yet'), findsOneWidget);
    },
  );

  testWidgets('a mismatched confirmation is rejected and the dots reset', (
    tester,
  ) async {
    await pumpPinbox(tester, withCredentials: false);
    await tapPin(tester, testPin);
    await tapPin(tester, '654321');
    expect(find.text("PINs didn't match. Try again"), findsOneWidget);
    expect(find.text('Confirm your PIN'), findsOneWidget);
  });

  testWidgets('a short master password is refused', (tester) async {
    await pumpPinbox(tester, withCredentials: false);
    await tapPin(tester, testPin);
    await tapPin(tester, testPin);
    await tester.enterText(find.byType(TextField).at(0), 'short');
    await tester.enterText(find.byType(TextField).at(1), 'short');
    await tester.tap(find.text('Finish setup'));
    await tester.pump();
    expect(find.text('Use at least 8 characters'), findsOneWidget);
    expect(find.text('My PINs'), findsNothing);
  });

  testWidgets('unlock: wrong PIN is refused, right PIN opens the list', (
    tester,
  ) async {
    await pumpPinbox(tester, seed: seeded);

    expect(find.text('Welcome back'), findsOneWidget);
    expect(
      find.text('Enter your master PIN to open your PINs'),
      findsOneWidget,
    );

    await tapPin(tester, '000000');
    expect(find.text('Incorrect PIN'), findsOneWidget);
    expect(find.text('My PINs'), findsNothing);

    await tapPin(tester, testPin);
    expect(find.text('My PINs'), findsOneWidget);
    expect(find.text('2 banks · 3 saved'), findsOneWidget);
    expect(find.text('Harbour Bank'), findsOneWidget);
    expect(find.text('Meridian CU'), findsOneWidget);
    expect(find.text('HB'), findsOneWidget);
  });

  testWidgets('five wrong PINs lock the keypad out with a countdown', (
    tester,
  ) async {
    await pumpPinbox(tester, seed: seeded);
    for (var i = 0; i < 5; i++) {
      await tapPin(tester, '000000');
    }
    expect(find.textContaining('Too many attempts'), findsOneWidget);

    // Even the right PIN is ignored while locked out.
    await tapPin(tester, testPin);
    expect(find.text('My PINs'), findsNothing);
    // Drain the countdown timer so the test ends clean.
    await tester.pump(const Duration(seconds: 31));
  });

  testWidgets('the master password is a working fallback', (tester) async {
    await pumpPinbox(tester, seed: seeded);
    await tester.tap(find.text('Use master password instead'));
    await settle(tester);

    await tester.enterText(find.byType(TextField), testPassword);
    await tester.tap(find.text('Unlock'));
    await settle(tester);
    expect(find.text('My PINs'), findsOneWidget);
  });

  testWidgets(
    'tapping the dots reveals a PIN, and it hides itself after 10 seconds',
    (tester) async {
      await pumpPinbox(tester, seed: seeded);
      await tapPin(tester, testPin);

      expect(find.text('4829'), findsNothing);
      await tester.tap(find.bySemanticsLabel('Reveal PIN').first);
      // Short pump: the countdown ticks once a second, so don't let it run yet.
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('4829'), findsOneWidget);
      expect(find.textContaining('Hides in 10 s'), findsOneWidget);

      await tester.pump(const Duration(seconds: 3));
      expect(find.textContaining('Hides in 7 s'), findsOneWidget);

      await tester.pump(const Duration(seconds: 8));
      await settle(tester);
      expect(find.text('4829'), findsNothing);
    },
  );

  testWidgets(
    'opening an entry shows its detail, and Reveal/Hide toggles the PIN',
    (tester) async {
      await pumpPinbox(tester, seed: seeded);
      await tapPin(tester, testPin);

      await tester.tap(find.text('Debit card'));
      await settle(tester);

      expect(find.text('DEBIT'), findsOneWidget);
      expect(find.text('Card PIN'), findsOneWidget);
      expect(find.text('Everyday account'), findsOneWidget);
      expect(find.text('Card ending'), findsOneWidget);
      expect(find.text('New PIN set after card replacement'), findsOneWidget);
      expect(find.text('4829'), findsNothing);

      await tester.tap(find.text('Reveal'));
      await settle(tester);
      for (final d in ['4', '8', '2', '9']) {
        expect(find.text(d), findsWidgets);
      }
      expect(find.text('Hide'), findsOneWidget);

      await tester.tap(find.text('Hide'));
      await settle(tester);
      expect(find.text('Reveal'), findsOneWidget);
    },
  );

  testWidgets(
    'adding an entry files it under an existing bank regardless of case',
    (tester) async {
      final app = await pumpPinbox(tester, seed: seeded);
      await tapPin(tester, testPin);

      await tester.tap(find.text('Add PIN'));
      await settle(tester);

      await tester.enterText(find.byType(TextField).at(0), 'harbour bank');
      await tester.tap(find.text('Credit card'));
      await tester.pump();
      await tester.enterText(find.byType(TextField).at(1), '9032');
      await tester.enterText(find.byType(TextField).at(2), '5566');
      await tester.tap(find.text('Save PIN'));
      await settle(tester);

      expect(app.vault.stored, hasLength(4));
      final added = app.vault.stored.last;
      expect(added.bank, 'Harbour Bank'); // adopted the existing spelling
      expect(added.type, EntryType.creditCard);
      expect(added.secret, '5566');
      expect(added.cardLast4, '9032');

      expect(find.text('2 banks · 4 saved'), findsOneWidget);
    },
  );

  testWidgets('"Add a password too" saves a second, separate password entry', (
    tester,
  ) async {
    final app = await pumpPinbox(tester, seed: seeded);
    await tapPin(tester, testPin);

    await tester.tap(find.text('Add PIN'));
    await settle(tester);
    await tester.enterText(find.byType(TextField).at(0), 'Lantern Savings');
    await tester.tap(find.text('Phone PIN'));
    await tester.pump();
    await tester.enterText(find.byType(TextField).at(1), '2468');
    await tester.tap(find.text('Add a password too'));
    await tester.pump();
    await tester.enterText(find.byType(TextField).at(2), 'my-bank-pass');
    await tester.tap(find.text('Save PIN'));
    await settle(tester);

    final lantern = app.vault.stored
        .where((e) => e.bank == 'Lantern Savings')
        .toList();
    expect(
      lantern.map((e) => e.type),
      containsAll([EntryType.phonePin, EntryType.password]),
    );
    expect(
      lantern.firstWhere((e) => e.type == EntryType.password).secret,
      'my-bank-pass',
    );
  });

  testWidgets(
    'saving with a missing bank or a too-short PIN shows errors and saves nothing',
    (tester) async {
      final app = await pumpPinbox(tester, seed: seeded);
      await tapPin(tester, testPin);
      await tester.tap(find.text('Add PIN'));
      await settle(tester);

      await tester.enterText(find.byType(TextField).at(2), '12');
      await tester.tap(find.text('Save PIN'));
      await tester.pump();

      expect(find.text('Enter a bank name'), findsOneWidget);
      expect(find.text('A PIN is 4–12 digits'), findsOneWidget);
      expect(app.vault.stored, hasLength(3));
    },
  );

  testWidgets('search narrows the list and never matches secrets', (
    tester,
  ) async {
    await pumpPinbox(tester, seed: seeded);
    await tapPin(tester, testPin);

    await tester.enterText(find.byType(TextField), 'meridian');
    await tester.pump();
    expect(find.text('Meridian CU'), findsOneWidget);
    expect(find.text('Harbour Bank'), findsNothing);

    await tester.enterText(find.byType(TextField), 'correct-horse');
    await tester.pump();
    expect(find.text('No matches'), findsOneWidget);
  });

  testWidgets(
    'deleting from the detail screen asks first, then removes the entry',
    (tester) async {
      final app = await pumpPinbox(tester, seed: seeded);
      await tapPin(tester, testPin);

      await tester.tap(find.text('Password'));
      await settle(tester);
      await tester.tap(find.byTooltip('More'));
      await settle(tester);
      await tester.tap(find.text('Delete'));
      await settle(tester);

      expect(find.text('Delete this password?'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await settle(tester);
      expect(app.vault.stored, hasLength(3));

      await tester.tap(find.byTooltip('More'));
      await settle(tester);
      await tester.tap(find.text('Delete'));
      await settle(tester);
      await tester.tap(find.widgetWithText(TextButton, 'Delete'));
      await settle(tester);

      expect(app.vault.stored.map((e) => e.id), ['1', '2']);
      expect(find.text('1 bank · 2 saved'), findsOneWidget);
    },
  );

  testWidgets(
    'locking sends you to unlock, frees the decrypted list, and un-reveals PINs',
    (tester) async {
      await pumpPinbox(tester, seed: seeded);
      await tapPin(tester, testPin);

      final container = ProviderScope.containerOf(
        tester.element(find.byType(MyPinsScreen)),
      );
      await tester.tap(find.bySemanticsLabel('Reveal PIN').first);
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('4829'), findsOneWidget);
      expect(container.exists(vaultProvider), isTrue);

      container.read(lockProvider.notifier).lock();
      await settle(tester);

      expect(find.text('Welcome back'), findsOneWidget);
      expect(find.text('Harbour Bank'), findsNothing);
      expect(find.text('4829'), findsNothing);
      // Nothing is listening any more, so the decrypted entries are released.
      expect(container.exists(vaultProvider), isFalse);

      await tapPin(tester, testPin);
      expect(find.text('Harbour Bank'), findsOneWidget);
      expect(find.text('4829'), findsNothing); // still hidden after unlocking
    },
  );

  testWidgets('auto-lock: away longer than the limit locks, shorter does not', (
    tester,
  ) async {
    await pumpPinbox(tester, seed: seeded, prefs: {'auto_lock_seconds': 0});
    await tapPin(tester, testPin);
    expect(find.text('My PINs'), findsOneWidget);

    leaveApp(tester);
    await tester.pump(const Duration(milliseconds: 50));
    returnToApp(tester);
    await settle(tester);

    expect(find.text('Welcome back'), findsOneWidget);
  });

  testWidgets('auto-lock: a quick trip to another app does not lock', (
    tester,
  ) async {
    // Default limit is 60 seconds.
    await pumpPinbox(tester, seed: seeded);
    await tapPin(tester, testPin);

    leaveApp(tester);
    returnToApp(tester);
    await settle(tester);

    expect(find.text('My PINs'), findsOneWidget);
  });

  testWidgets('settings shows the designed sections and current values', (
    tester,
  ) async {
    await pumpPinbox(tester, seed: seeded);
    await tapPin(tester, testPin);

    await tester.tap(find.byTooltip('Settings'));
    await settle(tester);

    for (final text in [
      'UNLOCK',
      'Biometric unlock',
      'Change master PIN',
      'Auto-lock',
      '1 minute',
      'PRIVACY',
      'Block screenshots',
      'Hide revealed PINs after',
      '10 seconds',
      'Clear clipboard',
      '30 seconds',
      'BACKUP',
      'Export encrypted backup',
    ]) {
      expect(find.text(text), findsOneWidget, reason: text);
    }

    await tester.tap(find.text('Auto-lock'));
    await settle(tester);
    await tester.tap(find.text('5 minutes'));
    await settle(tester);
    expect(find.text('5 minutes'), findsOneWidget);
  });
}

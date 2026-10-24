import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:pinbox/features/vault/domain/entry_type.dart';
import 'package:pinbox/features/vault/presentation/widgets/bank_card.dart';
import 'package:pinbox/features/vault/presentation/widgets/pinned_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/entries.dart';
import '../../support/harness.dart';

final _seed = [
  entry(
    id: 'm',
    bank: 'Meridian CU',
    type: EntryType.phonePin,
    created: DateTime.utc(2026, 1, 1),
  ),
  entry(
    id: 'h',
    bank: 'Harbour Bank',
    type: EntryType.password,
    secret: 'hunter22',
    created: DateTime.utc(2026, 1, 2),
  ),
  entry(
    id: 'z',
    bank: 'Zenith',
    type: EntryType.loginPin,
    secret: '24680',
    created: DateTime.utc(2026, 1, 3),
  ),
];

/// Bank card titles from top to bottom.
List<String> _bankOrder(WidgetTester tester) {
  final names = ['Harbour Bank', 'Meridian CU', 'Zenith']
      .where((n) => find.text(n).evaluate().isNotEmpty)
      .toList()
    ..sort(
      (a, b) => tester
          .getTopLeft(find.text(a))
          .dy
          .compareTo(tester.getTopLeft(find.text(b)).dy),
    );
  return names;
}

Future<void> _chooseSort(WidgetTester tester, String label) async {
  await tester.tap(find.byTooltip('Sort'));
  await settle(tester);
  await tester.tap(find.text(label));
  await settle(tester);
}

Future<void> _back(WidgetTester tester) async {
  await tester.tap(find.byTooltip('Back'));
  await settle(tester);
}

void main() {
  testWidgets('the list starts A–Z, whatever order things were added in', (
    tester,
  ) async {
    await pumpPinbox(tester, seed: _seed);
    await tapPin(tester, testPin);
    expect(_bankOrder(tester), ['Harbour Bank', 'Meridian CU', 'Zenith']);
  });

  testWidgets('the sort sheet offers the three orders, A–Z ticked', (
    tester,
  ) async {
    await pumpPinbox(tester, seed: _seed);
    await tapPin(tester, testPin);
    await tester.tap(find.byTooltip('Sort'));
    await settle(tester);

    expect(find.text('Sort by'), findsOneWidget);
    for (final label in ['A–Z', 'Recently used', 'Recently added']) {
      expect(find.text(label), findsOneWidget);
    }
    // The tick sits on the A–Z row.
    final tick = find.byIcon(LucideIcons.check);
    expect(tick, findsOneWidget);
    expect(
      tester.getCenter(tick).dy,
      moreOrLessEquals(tester.getCenter(find.text('A–Z')).dy, epsilon: 4),
    );
  });

  testWidgets('choosing Recently added reorders and is remembered', (
    tester,
  ) async {
    await pumpPinbox(tester, seed: _seed);
    await tapPin(tester, testPin);
    await _chooseSort(tester, 'Recently added');

    expect(_bankOrder(tester), ['Zenith', 'Harbour Bank', 'Meridian CU']);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('entry_sort'), 'recentlyAdded');
  });

  testWidgets('a saved sort choice is used on the next launch', (tester) async {
    await pumpPinbox(
      tester,
      seed: _seed,
      prefs: {'entry_sort': 'recentlyAdded'},
    );
    await tapPin(tester, testPin);
    expect(_bankOrder(tester), ['Zenith', 'Harbour Bank', 'Meridian CU']);
  });

  testWidgets('opening an entry moves it up under Recently used', (
    tester,
  ) async {
    final app = await pumpPinbox(tester, seed: _seed);
    await tapPin(tester, testPin);
    await _chooseSort(tester, 'Recently used');
    expect(_bankOrder(tester).first, 'Zenith'); // nothing used: newest first

    await tester.tap(find.text('Phone PIN')); // Meridian's only entry
    await settle(tester);
    await _back(tester);

    expect(_bankOrder(tester).first, 'Meridian CU');
    expect(
      app.vault.stored.firstWhere((e) => e.id == 'm').lastUsedAt,
      isNotNull,
    );
    // Bookkeeping, not an edit: no automatic backup was spent on it.
    expect(app.snapshots.held, isEmpty);
  });

  testWidgets('copying from the list counts as using the entry', (
    tester,
  ) async {
    final app = await pumpPinbox(tester, seed: _seed);
    await tapPin(tester, testPin);
    await _chooseSort(tester, 'Recently used');

    // Harbour's password is the only password in the vault.
    await tester.tap(find.byTooltip('Copy password'));
    await settle(tester);

    expect(app.clipboard.text, 'hunter22');
    expect(_bankOrder(tester).first, 'Harbour Bank');
  });

  testWidgets('peeking at a PIN on the list does not reorder it', (
    tester,
  ) async {
    await pumpPinbox(tester, seed: _seed);
    await tapPin(tester, testPin);
    await _chooseSort(tester, 'Recently used');
    final before = _bankOrder(tester);

    await tester.tap(find.bySemanticsLabel('Reveal PIN').last);
    await tester.pump(const Duration(milliseconds: 300));

    expect(_bankOrder(tester), before);
  });

  group('pinning', () {
    Future<void> pinFromDetail(WidgetTester tester, String typeLabel) async {
      await tester.tap(find.text(typeLabel));
      await settle(tester);
      expect(find.byTooltip('Pin to top'), findsOneWidget);
      await tester.tap(find.byTooltip('Pin to top'));
      await settle(tester);
    }

    testWidgets('a pinned entry sits above the banks and names its bank', (
      tester,
    ) async {
      final app = await pumpPinbox(tester, seed: _seed);
      await tapPin(tester, testPin);
      expect(find.text('Pinned'), findsNothing);

      await pinFromDetail(tester, 'Login PIN');
      expect(find.text('Pinned to the top of My PINs'), findsOneWidget);
      expect(find.byTooltip('Unpin'), findsOneWidget);
      await _back(tester);

      expect(find.text('Pinned'), findsOneWidget);
      expect(find.text('1 pinned'), findsOneWidget);
      // The row names its bank (alone: "Mobile app" is just a placeholder)…
      expect(
        find.descendant(
          of: find.byType(PinnedCard),
          matching: find.text('Zenith'),
        ),
        findsOneWidget,
      );
      // …and Zenith's only entry left its card, so the card is gone.
      expect(find.byType(BankCard), findsNWidgets(2));
      expect(
        find.descendant(of: find.byType(BankCard), matching: find.text('Zenith')),
        findsNothing,
      );
      expect(
        tester.getTopLeft(find.text('Pinned')).dy,
        lessThan(tester.getTopLeft(find.text('Harbour Bank')).dy),
      );
      expect(app.vault.stored.firstWhere((e) => e.id == 'z').pinned, isTrue);
    });

    testWidgets('unpinning puts it back in its bank', (tester) async {
      await pumpPinbox(tester, seed: _seed);
      await tapPin(tester, testPin);
      await pinFromDetail(tester, 'Login PIN');
      await tester.tap(find.byTooltip('Unpin'));
      await settle(tester);
      expect(find.text('Unpinned'), findsOneWidget);
      await _back(tester);

      expect(find.byType(PinnedCard), findsNothing);
      expect(
        find.descendant(of: find.byType(BankCard), matching: find.text('Zenith')),
        findsOneWidget,
      );
    });

    testWidgets('a pinned row keeps real detail after the bank name', (
      tester,
    ) async {
      await pumpPinbox(
        tester,
        seed: [
          entry(id: 'c', bank: 'Harbour Bank', last4: '4417')
              .copyWith(pinned: true),
          entry(
            id: 'n',
            bank: 'Meridian CU',
            type: EntryType.password,
            nickname: 'Joint account',
          ).copyWith(pinned: true),
        ],
      );
      await tapPin(tester, testPin);

      expect(find.text('Harbour Bank · •• 4417'), findsOneWidget);
      expect(find.text('Meridian CU · Joint account'), findsOneWidget);
    });

    testWidgets('search reaches pinned entries by bank name', (tester) async {
      await pumpPinbox(
        tester,
        seed: [
          for (final e in _seed) e.id == 'z' ? e.copyWith(pinned: true) : e,
        ],
      );
      await tapPin(tester, testPin);
      await tester.enterText(find.byType(TextField), 'zen');
      await settle(tester);

      expect(find.text('Pinned'), findsOneWidget);
      expect(find.text('Harbour Bank'), findsNothing);
      expect(find.text('Meridian CU'), findsNothing);
    });

    testWidgets('the summary still counts pinned entries', (tester) async {
      await pumpPinbox(
        tester,
        seed: [
          for (final e in _seed) e.id == 'z' ? e.copyWith(pinned: true) : e,
        ],
      );
      await tapPin(tester, testPin);
      expect(find.text('3 banks · 3 saved'), findsOneWidget);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:pinbox/features/vault/domain/entry_sort.dart';
import 'package:pinbox/features/vault/domain/entry_type.dart';
import 'package:pinbox/features/vault/domain/vault_arrangement.dart';
import 'package:pinbox/features/vault/domain/vault_entry.dart';

import '../../support/entries.dart';

DateTime day(int d, [int hour = 12]) => DateTime.utc(2026, 1, d, hour);

/// Ids in display order: pinned first, then each bank's entries in turn.
List<String> idsOf(VaultSections s) => [
  ...s.pinned.map((e) => e.id),
  for (final g in s.groups) ...g.entries.map((e) => e.id),
];

List<String> banksOf(VaultSections s) => s.groups.map((g) => g.name).toList();

void main() {
  // Added in this order: Meridian, Harbour, Zenith, Harbour, Meridian.
  final vault = [
    entry(id: 'm-debit', bank: 'Meridian CU', created: day(1)),
    entry(
      id: 'h-pass',
      bank: 'Harbour Bank',
      type: EntryType.password,
      created: day(2),
    ),
    entry(
      id: 'z-login',
      bank: 'Zenith',
      type: EntryType.loginPin,
      created: day(3),
    ),
    entry(
      id: 'h-credit',
      bank: 'harbour  bank',
      type: EntryType.creditCard,
      created: day(4),
    ),
    entry(
      id: 'm-phone',
      bank: 'Meridian CU',
      type: EntryType.phonePin,
      created: day(5),
    ),
  ];

  group('EntrySort', () {
    test('defaults to A–Z for a missing or unknown stored value', () {
      expect(EntrySort.fromName(null), EntrySort.alphabetical);
      expect(EntrySort.fromName('nonsense'), EntrySort.alphabetical);
      expect(EntrySort.fromName('recentlyUsed'), EntrySort.recentlyUsed);
    });

    test('labels read as the sheet shows them', () {
      expect(EntrySort.values.map((s) => s.label), [
        'A–Z',
        'Recently used',
        'Recently added',
      ]);
    });
  });

  group('A–Z', () {
    final s = arrangeVault(vault, sort: EntrySort.alphabetical);

    test('orders banks by name, whatever order they were added in', () {
      expect(banksOf(s), ['Harbour Bank', 'Meridian CU', 'Zenith']);
    });

    test('orders a bank’s entries by type', () {
      expect(s.groups.first.entries.map((e) => e.type.label), [
        'Credit card',
        'Password',
      ]);
      expect(s.groups[1].entries.map((e) => e.type.label), [
        'Debit card',
        'Phone PIN',
      ]);
    });

    test('is case- and spacing-insensitive, keeping banks merged', () {
      expect(s.groups.first.entries, hasLength(2));
    });
  });

  group('Recently added', () {
    final s = arrangeVault(vault, sort: EntrySort.recentlyAdded);

    test('puts the bank with the newest entry first', () {
      expect(banksOf(s), ['Meridian CU', 'Harbour Bank', 'Zenith']);
    });

    test('orders entries newest first', () {
      expect(idsOf(s), ['m-phone', 'm-debit', 'h-credit', 'h-pass', 'z-login']);
    });
  });

  group('Recently used', () {
    final used = [
      for (final e in vault)
        switch (e.id) {
          'z-login' => e.copyWith(lastUsedAt: day(9)),
          'h-pass' => e.copyWith(lastUsedAt: day(8)),
          'm-debit' => e.copyWith(lastUsedAt: day(7)),
          _ => e,
        },
    ];
    final s = arrangeVault(used, sort: EntrySort.recentlyUsed);

    test('puts the bank used most recently first', () {
      expect(banksOf(s), ['Zenith', 'Harbour Bank', 'Meridian CU']);
    });

    test('orders a bank’s used entries before ones never used', () {
      expect(s.groups[1].entries.map((e) => e.id), ['h-pass', 'h-credit']);
      expect(s.groups[2].entries.map((e) => e.id), ['m-debit', 'm-phone']);
    });

    test('with nothing used yet, falls back to recently added', () {
      final fresh = arrangeVault(vault, sort: EntrySort.recentlyUsed);
      expect(banksOf(fresh), ['Meridian CU', 'Harbour Bank', 'Zenith']);
      expect(
        idsOf(fresh),
        idsOf(arrangeVault(vault, sort: EntrySort.recentlyAdded)),
      );
    });
  });

  group('pinned entries', () {
    final pinned = [
      for (final e in vault)
        e.id == 'z-login' || e.id == 'h-credit' ? e.copyWith(pinned: true) : e,
    ];

    test('leave their bank and appear only in the Pinned section', () {
      final s = arrangeVault(pinned, sort: EntrySort.alphabetical);
      expect(s.pinned.map((e) => e.id), ['h-credit', 'z-login']);
      expect(idsOf(s).where((id) => id == 'h-credit'), hasLength(1));
      expect(s.groups.first.entries.map((e) => e.id), ['h-pass']);
    });

    test('a bank whose every entry is pinned drops out of the groups', () {
      final s = arrangeVault(pinned, sort: EntrySort.alphabetical);
      expect(banksOf(s), isNot(contains('Zenith')));
    });

    test('follow the chosen sort among themselves', () {
      final s = arrangeVault(pinned, sort: EntrySort.recentlyAdded);
      expect(s.pinned.map((e) => e.id), ['h-credit', 'z-login']);
      final used = [
        for (final e in pinned)
          e.id == 'z-login' ? e.copyWith(lastUsedAt: day(9)) : e,
      ];
      expect(
        arrangeVault(used, sort: EntrySort.recentlyUsed).pinned.map((e) => e.id),
        ['z-login', 'h-credit'],
      );
    });
  });

  group('search', () {
    final pinned = [
      for (final e in vault) e.id == 'z-login' ? e.copyWith(pinned: true) : e,
    ];

    test('finds a pinned entry by its bank’s name', () {
      final s = arrangeVault(
        pinned,
        sort: EntrySort.alphabetical,
        query: 'zen',
      );
      expect(s.pinned.map((e) => e.id), ['z-login']);
      expect(s.groups, isEmpty);
    });

    test('finds pinned and unpinned entries by type', () {
      final s = arrangeVault(
        pinned,
        sort: EntrySort.alphabetical,
        query: 'login',
      );
      expect(idsOf(s), ['z-login']);
    });

    test('never matches the secret, pinned or not', () {
      final secret = [
        entry(id: 'p', secret: '987654').copyWith(pinned: true),
        entry(id: 'u', secret: '987654'),
      ];
      final s = arrangeVault(
        secret,
        sort: EntrySort.alphabetical,
        query: '987654',
      );
      expect(s.isEmpty, isTrue);
    });
  });

  test('ties keep a stable order', () {
    final twins = [
      entry(id: 'b', created: day(1)),
      entry(id: 'a', created: day(1)),
    ];
    for (final sort in EntrySort.values) {
      expect(idsOf(arrangeVault(twins, sort: sort)), ['a', 'b'], reason: '$sort');
    }
  });

  group('storage', () {
    test('pinned and last-used round-trip through JSON', () {
      final e = entry().copyWith(pinned: true, lastUsedAt: day(9, 15));
      final back = VaultEntry.fromJson(e.toJson());
      expect(back.pinned, isTrue);
      expect(back.lastUsedAt, day(9, 15));
    });

    test('older vault files load unpinned and never used', () {
      final json = entry().toJson()
        ..remove('pinned')
        ..remove('lastUsedAt');
      final back = VaultEntry.fromJson(json);
      expect(back.pinned, isFalse);
      expect(back.lastUsedAt, isNull);
    });

    test('a malformed last-used time is ignored, not fatal', () {
      final json = entry().toJson()..['lastUsedAt'] = 'not a date';
      expect(VaultEntry.fromJson(json).lastUsedAt, isNull);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:pinbox/features/vault/domain/bank_grouping.dart';
import 'package:pinbox/features/vault/domain/bank_initials.dart';
import 'package:pinbox/features/vault/domain/entry_type.dart';
import 'package:pinbox/features/vault/domain/entry_validation.dart';
import 'package:pinbox/features/vault/domain/vault_entry.dart';

import '../../support/entries.dart';

void main() {
  group('bankInitials', () {
    test('uses the first letters of the first two words', () {
      expect(bankInitials('Harbour Bank'), 'HB');
      expect(bankInitials('Meridian CU'), 'MC');
      expect(bankInitials('Lantern Savings'), 'LS');
      expect(bankInitials('First National Trust'), 'FN');
    });
    test(
      'uses two letters of a single word',
      () => expect(bankInitials('nordea'), 'NO'),
    );
    test('copes with blanks and stray spaces', () {
      expect(bankInitials('   '), '?');
      expect(bankInitials('  ab   cd  '), 'AC');
    });
  });

  group('grouping', () {
    test('groups by bank in first-added order, ignoring case and spacing', () {
      final groups = groupByBank([
        entry(id: '1', bank: 'Harbour Bank', created: DateTime.utc(2026, 1, 1)),
        entry(id: '2', bank: 'Meridian CU', created: DateTime.utc(2026, 1, 2)),
        entry(
          id: '3',
          bank: 'harbour   bank',
          created: DateTime.utc(2026, 1, 3),
        ),
      ]);
      expect(groups.map((g) => g.name), ['Harbour Bank', 'Meridian CU']);
      expect(groups.first.entries.map((e) => e.id), ['1', '3']);
    });

    test('resolveBankName reuses an existing spelling', () {
      final existing = [entry(bank: 'Harbour Bank')];
      expect(resolveBankName('  harbour  BANK ', existing), 'Harbour Bank');
      expect(resolveBankName('  New   Bank ', existing), 'New Bank');
    });
  });

  group('search', () {
    final groups = groupByBank([
      entry(
        id: '1',
        bank: 'Harbour Bank',
        type: EntryType.debitCard,
        last4: '4417',
        nickname: 'Everyday',
      ),
      entry(
        id: '2',
        bank: 'Harbour Bank',
        type: EntryType.password,
        secret: 'pa55word',
      ),
      entry(
        id: '3',
        bank: 'Meridian CU',
        type: EntryType.creditCard,
        last4: '9032',
      ),
    ]);

    test(
      'empty query returns everything',
      () => expect(searchGroups(groups, '  '), groups),
    );

    test('a bank-name match keeps the whole bank', () {
      final r = searchGroups(groups, 'harb');
      expect(r.single.entries, hasLength(2));
    });

    test('matches card endings, types and nicknames within a bank', () {
      expect(searchGroups(groups, '9032').single.name, 'Meridian CU');
      expect(searchGroups(groups, 'credit').single.entries.single.id, '3');
      expect(searchGroups(groups, 'everyday').single.entries.single.id, '1');
    });

    test('never matches on the secret itself', () {
      expect(searchGroups(groups, 'pa55word'), isEmpty);
      expect(searchGroups(groups, '4829'), isEmpty);
    });
  });

  group('validation', () {
    test('bank is required', () {
      expect(EntryValidation.bank('  '), isNotNull);
      expect(EntryValidation.bank('X'), isNull);
    });
    test('card ending is optional but must be 4 digits', () {
      expect(EntryValidation.cardLast4(''), isNull);
      expect(EntryValidation.cardLast4('4417'), isNull);
      expect(EntryValidation.cardLast4('441'), isNotNull);
      expect(EntryValidation.cardLast4('44a7'), isNotNull);
    });
    test('PINs are 4-12 digits, passwords just non-empty', () {
      expect(EntryValidation.secret(EntryType.debitCard, '123'), isNotNull);
      expect(EntryValidation.secret(EntryType.debitCard, '1234'), isNull);
      expect(EntryValidation.secret(EntryType.loginPin, '1' * 13), isNotNull);
      expect(EntryValidation.secret(EntryType.password, ''), isNotNull);
      expect(EntryValidation.secret(EntryType.password, 'x'), isNull);
    });
  });

  group('VaultEntry', () {
    test('JSON round-trip preserves everything', () {
      final e = entry(
        type: EntryType.creditCard,
        last4: '9032',
        nickname: 'Travel',
        notes: 'multi\nline',
        secret: 'päss',
      );
      final back = VaultEntry.fromJson(e.toJson());
      expect(back.toJson(), e.toJson());
    });

    test('subtitle prefers card ending, then nickname, then a type hint', () {
      expect(entry(last4: '4417').subtitle, '•• 4417');
      expect(
        entry(type: EntryType.password, nickname: 'Online').subtitle,
        'Online',
      );
      expect(entry(type: EntryType.loginPin).subtitle, 'Mobile app');
      // A nickname doesn't hide the card ending.
      expect(entry(last4: '4417', nickname: 'Everyday').subtitle, '•• 4417');
    });

    test('an unknown stored type falls back rather than crashing', () {
      final json = entry().toJson()..['type'] = 'hologram';
      expect(VaultEntry.fromJson(json).type, EntryType.debitCard);
    });
  });
}

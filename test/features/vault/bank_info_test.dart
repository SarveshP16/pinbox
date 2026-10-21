import 'package:flutter_test/flutter_test.dart';
import 'package:pinbox/features/vault/domain/bank_grouping.dart';
import 'package:pinbox/features/vault/domain/entry_type.dart';
import 'package:pinbox/features/vault/domain/entry_validation.dart';
import 'package:pinbox/features/vault/domain/vault_entry.dart';

import '../../support/entries.dart';

void main() {
  group('EntryType', () {
    test('chips appear in the requested order', () {
      expect(EntryType.values.map((t) => t.label), [
        'Debit card',
        'Card lock PIN',
        'Credit card',
        'Login PIN',
        'Phone PIN',
        'Password',
        'Bank Info',
      ]);
    });

    test('Card lock PIN is a numeric PIN that belongs to a card', () {
      const t = EntryType.cardLockPin;
      expect(t.isCard, isTrue);
      expect(t.isNumeric, isTrue);
      expect(t.secretNoun, 'PIN');
      expect(t.secretLabel, 'Card lock PIN');
    });

    test('Bank Info is neither a PIN nor a card, and its secret is the account no.', () {
      const t = EntryType.bankInfo;
      expect(t.isBankInfo, isTrue);
      expect(t.isCard, isFalse);
      expect(t.isNumeric, isFalse);
      expect(t.secretNoun, 'account number');
      expect(t.entryNoun, 'bank info');
    });

    test('deleting a password still says "password"', () {
      expect(EntryType.password.entryNoun, 'password');
    });
  });

  group('Bank Info validation', () {
    test('account name is required', () {
      expect(EntryValidation.accountName('  '), isNotNull);
      expect(EntryValidation.accountName('Jane Citizen'), isNull);
    });

    test('account number must be 5-20 digits', () {
      expect(EntryValidation.accountNumber(''), isNotNull);
      expect(EntryValidation.accountNumber('1234'), isNotNull);
      expect(EntryValidation.accountNumber('12345'), isNull);
      expect(EntryValidation.accountNumber('1' * 20), isNull);
      expect(EntryValidation.accountNumber('1' * 21), isNotNull);
      expect(EntryValidation.accountNumber('1234a6'), isNotNull);
    });

    test('secret() applies the account rules to Bank Info', () {
      expect(EntryValidation.secret(EntryType.bankInfo, '1234'), isNotNull);
      expect(EntryValidation.secret(EntryType.bankInfo, '12345678'), isNull);
    });

    test('accepts BSB and IFSC formats, ignoring case, spaces and hyphens', () {
      expect(EntryValidation.routingCode('123-456'), isNull);
      expect(EntryValidation.routingCode('123456'), isNull);
      expect(EntryValidation.routingCode('sbin0001234'), isNull);
      expect(EntryValidation.routingCode('SBIN 0001234'), isNull);
    });

    test('rejects an empty, too-short or too-long routing code', () {
      expect(EntryValidation.routingCode(''), isNotNull);
      expect(EntryValidation.routingCode('  - '), isNotNull);
      expect(EntryValidation.routingCode('12345'), isNotNull);
      expect(EntryValidation.routingCode('SBIN00012345'), isNotNull);
      expect(EntryValidation.routingCode('12#456'), isNotNull);
    });

    test(
      'tidyRoutingCode upper-cases and drops spaces but keeps the hyphen',
      () {
        expect(EntryValidation.tidyRoutingCode(' 123-456 '), '123-456');
        expect(EntryValidation.tidyRoutingCode('sbin 0001234'), 'SBIN0001234');
      },
    );
  });

  group('VaultEntry with bank details', () {
    final bankInfo = entry(type: EntryType.bankInfo, secret: '00112233')
        .copyWith(
          accountName: 'Jane Citizen',
          routingCode: '123-456',
          cifNumber: '99887766',
        );

    test('JSON round-trip keeps the Bank Info fields', () {
      final back = VaultEntry.fromJson(bankInfo.toJson());
      expect(back.accountName, 'Jane Citizen');
      expect(back.routingCode, '123-456');
      expect(back.cifNumber, '99887766');
      expect(back.secret, '00112233');
    });

    test('entries saved before Bank Info existed still load', () {
      final legacy = entry().toJson()
        ..remove('accountName')
        ..remove('routingCode')
        ..remove('cifNumber');
      final back = VaultEntry.fromJson(legacy);
      expect(back.accountName, '');
      expect(back.routingCode, '');
      expect(back.cifNumber, '');
    });

    test('subtitle: nickname wins, then account name, then the default', () {
      expect(bankInfo.subtitle, 'Jane Citizen');
      expect(bankInfo.copyWith(nickname: 'Salary').subtitle, 'Salary');
      expect(entry(type: EntryType.bankInfo).subtitle, 'Account details');
    });

    test('a Card lock PIN shows its card ending like other cards', () {
      expect(
        entry(type: EntryType.cardLockPin, last4: '4417').subtitle,
        '•• 4417',
      );
    });
  });

  group('search with Bank Info', () {
    final groups = groupByBank([
      entry(
        id: '1',
        bank: 'Harbour Bank',
        type: EntryType.bankInfo,
        secret: '00112233',
      ).copyWith(
        accountName: 'Jane Citizen',
        routingCode: '123-456',
        cifNumber: '99887766',
      ),
      entry(
        id: '2',
        bank: 'Meridian CU',
        type: EntryType.cardLockPin,
        last4: '2260',
      ),
    ]);

    test('finds an account by name and by BSB/IFSC', () {
      expect(searchGroups(groups, 'jane').single.name, 'Harbour Bank');
      expect(searchGroups(groups, '123-456').single.name, 'Harbour Bank');
    });

    test('finds a card lock PIN by its type name', () {
      expect(searchGroups(groups, 'card lock').single.name, 'Meridian CU');
    });

    test('never matches the account number or CIF number', () {
      expect(searchGroups(groups, '00112233'), isEmpty);
      expect(searchGroups(groups, '99887766'), isEmpty);
    });
  });
}

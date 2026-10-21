import 'package:flutter_test/flutter_test.dart';
import 'package:pinbox/core/crypto/secret_hasher.dart';
import 'package:pinbox/features/lock/data/credentials_store.dart';
import 'package:pinbox/features/lock/domain/attempt_message.dart';
import 'package:pinbox/features/lock/domain/attempt_result.dart';
import 'package:pinbox/features/lock/domain/lockout_policy.dart';

import '../../support/memory_secure_store.dart';

void main() {
  group('lockoutDuration', () {
    test('is free for the first few misses', () {
      for (var i = 0; i < freeAttempts; i++) {
        expect(lockoutDuration(i), Duration.zero);
      }
    });

    test('starts at 30s then doubles', () {
      expect(lockoutDuration(5), const Duration(seconds: 30));
      expect(lockoutDuration(6), const Duration(seconds: 60));
      expect(lockoutDuration(7), const Duration(seconds: 120));
    });

    test('caps at one hour', () {
      expect(lockoutDuration(50), const Duration(hours: 1));
    });
  });

  group('CredentialsStore', () {
    late MemorySecureStore store;
    late DateTime now;
    late CredentialsStore creds;

    setUp(() async {
      store = MemorySecureStore();
      now = DateTime(2026, 1, 1, 12);
      creds = CredentialsStore(
        store,
        SecretHasher(iterations: 1000),
        now: () => now,
      );
      await creds.save(pin: '123456', password: 'hunter2hunter2');
    });

    test('never stores the PIN or password in the clear', () {
      final blob = store.values.values.join();
      expect(blob, isNot(contains('123456')));
      expect(blob, isNot(contains('hunter2')));
    });

    test('accepts the right PIN and password', () async {
      expect(await creds.checkPin('123456'), isA<AttemptSuccess>());
      expect(
        await creds.checkPassword('hunter2hunter2'),
        isA<AttemptSuccess>(),
      );
    });

    test('counts down the free attempts', () async {
      final r = await creds.checkPin('000000');
      expect(r, isA<AttemptWrong>().having((w) => w.attemptsLeft, 'left', 4));
    });

    test('locks out after too many misses, even for the right PIN', () async {
      for (var i = 0; i < freeAttempts; i++) {
        await creds.checkPin('000000');
      }
      expect(await creds.checkPin('123456'), isA<AttemptLockedOut>());
      expect(await creds.lockedUntil(), isNotNull);
    });

    test('the lockout survives a "restart" (state is persisted)', () async {
      for (var i = 0; i < freeAttempts; i++) {
        await creds.checkPin('000000');
      }
      final reopened = CredentialsStore(
        store,
        SecretHasher(iterations: 1000),
        now: () => now,
      );
      expect(await reopened.checkPin('123456'), isA<AttemptLockedOut>());
    });

    test('unlocks again once the wait has passed', () async {
      for (var i = 0; i < freeAttempts; i++) {
        await creds.checkPin('000000');
      }
      now = now.add(const Duration(seconds: 31));
      expect(await creds.checkPin('123456'), isA<AttemptSuccess>());
    });

    test('a success resets the miss counter', () async {
      await creds.checkPin('000000');
      await creds.checkPin('000000');
      await creds.checkPin('123456');
      final r = await creds.checkPin('000000');
      expect(r, isA<AttemptWrong>().having((w) => w.attemptsLeft, 'left', 4));
    });

    test('changePin replaces only the PIN', () async {
      await creds.changePin('654321');
      expect(await creds.checkPin('654321'), isA<AttemptSuccess>());
      expect(await creds.checkPin('123456'), isA<AttemptWrong>());
      expect(
        await creds.checkPassword('hunter2hunter2'),
        isA<AttemptSuccess>(),
      );
    });
  });

  test('attemptMessage wording', () {
    expect(attemptMessage(const AttemptSuccess(), 'PIN'), isNull);
    expect(attemptMessage(const AttemptWrong(4), 'PIN'), 'Incorrect PIN');
    expect(
      attemptMessage(const AttemptWrong(1), 'PIN'),
      'Incorrect PIN · 1 try left',
    );
    final now = DateTime(2026, 1, 1);
    expect(
      attemptMessage(
        AttemptLockedOut(now.add(const Duration(seconds: 89))),
        'PIN',
        now: now,
      ),
      'Too many attempts. Try again in 1:30',
    );
  });
}

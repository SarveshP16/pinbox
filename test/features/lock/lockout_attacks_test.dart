// Attacks on the unlock rate limit, written from the attacker's side.
//
// Each test models something a person holding the phone can actually do — kill
// the app mid-check, change the system clock, reboot — and asserts that it does
// not buy them extra guesses or shorten a wait.
import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:pinbox/core/crypto/secret_hasher.dart';
import 'package:pinbox/core/platform/boot_clock.dart';
import 'package:pinbox/features/lock/data/credentials_store.dart';
import 'package:pinbox/features/lock/domain/attempt_result.dart';
import 'package:pinbox/features/lock/domain/lockout_policy.dart';

import '../../support/memory_secure_store.dart';

/// A hasher whose verification can be held open, standing in for the window
/// between "the guess is being checked" and "the app was force-stopped".
class StallingHasher extends SecretHasher {
  StallingHasher() : super(iterations: 1000);

  Completer<bool>? stall;

  @override
  Future<bool> verify(String secret, String encoded) {
    final gate = stall;
    if (gate == null) return super.verify(secret, encoded);
    return gate.future;
  }
}

/// Monotonic time since boot, moved by hand. The wall clock is separate, so a
/// test can wind one without the other — exactly what changing the date does.
class FakeBootClock implements BootClock {
  int elapsedMs = 1000000;
  int bootId = 7;
  bool available = true;

  @override
  Future<BootTime?> read() async =>
      available ? BootTime(elapsedMs: elapsedMs, bootId: bootId) : null;
}

void main() {
  late MemorySecureStore store;
  late StallingHasher hasher;
  late FakeBootClock boot;
  late DateTime wall;
  late CredentialsStore creds;

  CredentialsStore build() =>
      CredentialsStore(store, hasher, now: () => wall, bootClock: boot);

  setUp(() async {
    store = MemorySecureStore();
    hasher = StallingHasher();
    boot = FakeBootClock();
    wall = DateTime(2026, 1, 1, 12);
    creds = build();
    await creds.save(pin: '123456', password: 'hunter2hunter2');
  });

  /// Burns the free attempts so the next miss starts a wait.
  Future<AttemptResult> exhaust() async {
    AttemptResult last = const AttemptSuccess();
    for (var i = 0; i < freeAttempts; i++) {
      last = await creds.checkPin('000000');
    }
    return last;
  }

  group('killing the app during the check', () {
    test('a guess is counted before it is verified, not after', () async {
      hasher.stall = Completer<bool>();
      // The guess is in flight; the attacker force-stops the app right now.
      unawaited(creds.checkPin('000000'));
      await Future<void>.delayed(Duration.zero);

      // Relaunch: a fresh store object reads only what reached the keystore.
      hasher.stall = null;
      final relaunched = build();
      expect(
        store.values['failed_attempts'],
        '1',
        reason: 'the attempt must already be on record when verification starts',
      );

      // And the count carries on from there.
      final next = await relaunched.checkPin('000000');
      expect(next, isA<AttemptWrong>());
      expect((next as AttemptWrong).attemptsLeft, freeAttempts - 2);
    });

    test('killing during the guess that trips the lockout still arms it', () async {
      for (var i = 0; i < freeAttempts - 1; i++) {
        await creds.checkPin('000000');
      }
      hasher.stall = Completer<bool>();
      unawaited(creds.checkPin('000000'));
      await Future<void>.delayed(Duration.zero);

      hasher.stall = null;
      expect(await build().lockedUntil(), isNotNull);
    });

    test('a correct PIN still unlocks, and clears the pre-counted attempt', () async {
      await creds.checkPin('000000');
      expect(await creds.checkPin('123456'), isA<AttemptSuccess>());
      expect(store.values.containsKey('failed_attempts'), isFalse);
      expect(await creds.lockedUntil(), isNull);
    });

    test('the right PIN on the guess that trips the lockout still unlocks', () async {
      for (var i = 0; i < freeAttempts - 1; i++) {
        await creds.checkPin('000000');
      }
      expect(await creds.checkPin('123456'), isA<AttemptSuccess>());
      expect(await creds.lockedUntil(), isNull);
    });
  });

  group('concurrent guesses', () {
    test('two checks racing each other are both counted', () async {
      await Future.wait([creds.checkPin('000000'), creds.checkPin('111111')]);
      expect(store.values['failed_attempts'], '2');
    });
  });

  group('changing the system clock', () {
    test('winding the clock forward does not end the wait', () async {
      expect(await exhaust(), isA<AttemptLockedOut>());

      wall = wall.add(const Duration(days: 1)); // the attack
      expect(await creds.lockedUntil(), isNotNull);
      expect(await creds.checkPin('123456'), isA<AttemptLockedOut>());
    });

    test('winding it back does not extend the wait either', () async {
      await exhaust();
      wall = wall.subtract(const Duration(days: 1));
      boot.elapsedMs += 31 * 1000; // 31 real seconds pass
      expect(await creds.lockedUntil(), isNull);
    });

    test('the wait ends once enough real time has passed', () async {
      await exhaust();
      boot.elapsedMs += 29 * 1000;
      expect(await creds.lockedUntil(), isNotNull);
      boot.elapsedMs += 2 * 1000;
      expect(await creds.lockedUntil(), isNull);
      expect(await creds.checkPin('123456'), isA<AttemptSuccess>());
    });

    test('the countdown shown is real remaining time, whatever the clock says', () async {
      await exhaust();
      boot.elapsedMs += 10 * 1000;
      wall = wall.add(const Duration(hours: 5));

      final until = await creds.lockedUntil();
      expect(until!.difference(wall), const Duration(seconds: 20));
    });
  });

  group('rebooting', () {
    test('a reboot does not end the wait, it starts it over', () async {
      await exhaust();
      boot
        ..bootId = 8 // new boot…
        ..elapsedMs = 5000; // …with uptime back near zero
      wall = wall.add(const Duration(days: 1)); // and the clock moved for good measure

      expect(await creds.lockedUntil(), isNotNull);
      boot.elapsedMs += 29 * 1000;
      expect(await creds.lockedUntil(), isNotNull);
      boot.elapsedMs += 2 * 1000;
      expect(await creds.lockedUntil(), isNull);
    });

    test('rebooting again mid-wait cannot be used to skip it', () async {
      await exhaust();
      for (final id in [8, 9, 10]) {
        boot
          ..bootId = id
          ..elapsedMs = 5000;
        expect(await creds.lockedUntil(), isNotNull, reason: 'boot $id');
      }
    });
  });

  group('without a boot clock (iOS, tests)', () {
    test('falls back to the wall clock, as before', () async {
      boot.available = false;
      creds = build();
      await exhaust();
      expect(await creds.lockedUntil(), isNotNull);
      wall = wall.add(const Duration(seconds: 31));
      expect(await creds.lockedUntil(), isNull);
    });
  });
}

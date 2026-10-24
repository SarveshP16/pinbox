import 'package:flutter_test/flutter_test.dart';
import 'package:pinbox/features/backup/domain/snapshot_labels.dart';

void main() {
  final now = DateTime(2026, 10, 24, 14, 30);

  group('describeSnapshotTime', () {
    test('under a minute reads as just now', () {
      expect(
        describeSnapshotTime(now.subtract(const Duration(seconds: 40)), now: now),
        'Just now',
      );
    });

    test('minutes are singular at one', () {
      expect(
        describeSnapshotTime(now.subtract(const Duration(minutes: 1)), now: now),
        '1 minute ago',
      );
      expect(
        describeSnapshotTime(now.subtract(const Duration(minutes: 12)), now: now),
        '12 minutes ago',
      );
    });

    test('earlier the same day shows the clock time', () {
      expect(
        describeSnapshotTime(DateTime(2026, 10, 24, 9, 5), now: now),
        'Today 09:05',
      );
    });

    test('the previous day reads as yesterday', () {
      expect(
        describeSnapshotTime(DateTime(2026, 10, 23, 22, 40), now: now),
        'Yesterday 22:40',
      );
    });

    test('older than that shows the date', () {
      expect(
        describeSnapshotTime(DateTime(2026, 10, 3, 22, 40), now: now),
        '3 Oct 22:40',
      );
    });

    test('an hour ago on the same day is a clock time, not "60 minutes ago"', () {
      expect(
        describeSnapshotTime(DateTime(2026, 10, 24, 13, 30), now: now),
        'Today 13:30',
      );
    });

    test('the relative form wins across midnight, where it reads better', () {
      // 30 minutes before 00:20 is the previous calendar day, but "Yesterday
      // 23:50" would overstate the age of something that just happened.
      final midnight = DateTime(2026, 10, 24, 0, 20);
      expect(
        describeSnapshotTime(DateTime(2026, 10, 23, 23, 50), now: midnight),
        '30 minutes ago',
      );
      // Once it is more than an hour old, the day label takes over.
      expect(
        describeSnapshotTime(DateTime(2026, 10, 23, 22, 50), now: midnight),
        'Yesterday 22:50',
      );
    });
  });

  group('describeSnapshotSize', () {
    test('counts read naturally', () {
      expect(describeSnapshotSize(0), 'empty');
      expect(describeSnapshotSize(1), '1 entry');
      expect(describeSnapshotSize(12), '12 entries');
    });
  });
}

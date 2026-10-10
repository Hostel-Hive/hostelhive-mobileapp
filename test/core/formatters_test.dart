import 'package:flutter_test/flutter_test.dart';
import 'package:hostelhive_mobile/core/utils/formatters.dart';

void main() {
  group('formatDuration', () {
    test('given days and hours, then both are shown', () {
      expect(
        formatDuration(const Duration(days: 2, hours: 9)),
        '2 days 9 hours',
      );
    });

    test('given exactly one of each unit, then singular is used', () {
      expect(formatDuration(const Duration(days: 1, hours: 1)), '1 day 1 hour');
    });

    test('given whole days, then hours are omitted', () {
      expect(formatDuration(const Duration(days: 3)), '3 days');
    });

    test('given hours and minutes, then both are shown', () {
      expect(
        formatDuration(const Duration(hours: 4, minutes: 30)),
        '4 hours 30 minutes',
      );
    });

    test('given whole hours, then minutes are omitted', () {
      expect(formatDuration(const Duration(hours: 5)), '5 hours');
    });

    test('given only minutes, then minutes are shown', () {
      expect(formatDuration(const Duration(minutes: 45)), '45 minutes');
    });

    test('given a negative duration, then it is shown as zero', () {
      expect(formatDuration(const Duration(minutes: -5)), '0 minutes');
    });
  });

  group('relativeTime', () {
    final now = DateTime(2026, 4, 18, 21, 14);

    test('given less than a minute ago, then it is just now', () {
      expect(
        relativeTime(now.subtract(const Duration(seconds: 20)), now: now),
        'just now',
      );
    });

    test('given minutes ago, then minutes are shown', () {
      expect(
        relativeTime(now.subtract(const Duration(minutes: 22)), now: now),
        '22m ago',
      );
    });

    test('given hours ago, then hours are shown', () {
      expect(
        relativeTime(now.subtract(const Duration(hours: 4)), now: now),
        '4h ago',
      );
    });

    test('given one day ago, then it is Yesterday', () {
      expect(
        relativeTime(now.subtract(const Duration(days: 1, hours: 2)), now: now),
        'Yesterday',
      );
    });

    test('given a few days ago, then days are shown', () {
      expect(
        relativeTime(now.subtract(const Duration(days: 4)), now: now),
        '4d ago',
      );
    });

    test('given weeks ago, then weeks are shown', () {
      expect(
        relativeTime(now.subtract(const Duration(days: 15)), now: now),
        '2w ago',
      );
    });

    test('given no reference time, then the current time is used', () {
      expect(relativeTime(DateTime.now()), 'just now');
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:house_mira_core/subscriptions/usage_limits.dart';

void main() {
  group('UsageLimits', () {
    test('free caps are 10 reminders and 3 notes', () {
      expect(UsageLimits.freeRemindersLimit, 10);
      expect(UsageLimits.freeNotesLimit, 3);
    });

    test('reminders: free user hits the cap at 10, paid never does', () {
      expect(
        UsageLimits.isReminderLimitReached(count: 9, isPro: false),
        isFalse,
      );
      expect(
        UsageLimits.isReminderLimitReached(count: 10, isPro: false),
        isTrue,
      );
      expect(
        UsageLimits.isReminderLimitReached(count: 11, isPro: false),
        isTrue,
      );
      expect(
        UsageLimits.isReminderLimitReached(count: 100, isPro: true),
        isFalse,
      );
    });

    test('notes: free user hits the cap at 3, paid never does', () {
      expect(
        UsageLimits.isNoteLimitReached(count: 2, isPro: false),
        isFalse,
      );
      expect(
        UsageLimits.isNoteLimitReached(count: 3, isPro: false),
        isTrue,
      );
      expect(
        UsageLimits.isNoteLimitReached(count: 4, isPro: false),
        isTrue,
      );
      expect(
        UsageLimits.isNoteLimitReached(count: 100, isPro: true),
        isFalse,
      );
    });
  });
}

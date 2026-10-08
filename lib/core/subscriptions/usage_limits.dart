/// Free-tier usage caps for reminders and notes.
///
/// Paid users get unlimited reminders and notes. Free users are capped at
/// [freeRemindersLimit] reminders and [freeNotesLimit] notes; creation
/// flows must check these limits before allowing new entries and route
/// capped users to the paywall.
abstract final class UsageLimits {
  /// Maximum reminders for a free-tier user.
  static const int freeRemindersLimit = 10;

  /// Maximum notes for a free-tier user.
  static const int freeNotesLimit = 3;

  /// Whether a user with [count] reminders has hit the free cap.
  ///
  /// Paid users never hit the cap; pure so it is unit-testable.
  static bool isReminderLimitReached({
    required int count,
    required bool isPro,
  }) {
    if (isPro) return false;
    return count >= freeRemindersLimit;
  }

  /// Whether a user with [count] notes has hit the free cap.
  ///
  /// Paid users never hit the cap; pure so it is unit-testable.
  static bool isNoteLimitReached({required int count, required bool isPro}) {
    if (isPro) return false;
    return count >= freeNotesLimit;
  }
}

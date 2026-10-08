/// Free-tier usage caps for reminders and notes.
///
/// Paid users get unlimited reminders and notes. Free users are capped at
/// [freeRemindersLimit] reminders and [freeNotesLimit] notes; creation
/// flows must check these limits before allowing new entries and route
/// capped users to the paywall.
///
/// Quota semantics (family-quota vs per-user entitlement):
/// * Counts are per-family (shared quota): every member's rows count toward
///   the same cap, so a free user in an already-full family is blocked even
///   if they personally created nothing.
/// * The entitlement is per-user: `SubscriptionService.isPro()` reflects the
///   current device user's purchase only, not the family's.
/// * Enforcement is client-side UX friction only (no server/RLS cap check):
///   direct API inserts bypass it, and the check-then-create sequence is not
///   atomic — two devices racing at 9/10 can both pass the count and push
///   the family over the cap (TOCTOU accepted explicitly).
/// * Limit checks fail open (`false`) on billing/count errors so an outage
///   never blocks creation, while `isPro()` itself fails closed.
///
/// The entitlement lookup is cached briefly inside SubscriptionService
/// so a view pre-check plus the cubit's create-time re-check costs one
/// billing lookup per flow.
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

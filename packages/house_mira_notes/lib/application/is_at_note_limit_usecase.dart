import 'package:house_mira_core/config/remote_config_service.dart';
import 'package:house_mira_core/subscriptions/subscription_service.dart';
import 'package:house_mira_core/subscriptions/usage_limits.dart';
import 'package:house_mira_notes/domain/repository/notes_repository.dart';

/// Free-tier gate for notes.
///
/// Returns `true` when a free-tier user has hit
/// [UsageLimits.freeNotesLimit]. Paid users never hit the cap.
///
/// The remote flag [`RemoteConfigService.enableLimitAndPaywall`] is the
/// master switch: when it is `false` usage limits are disabled entirely and
/// this always returns `false`. When `true` the normal free-tier cap
/// applies. Fail-closed on billing (`isPro` false on lookup error, so free
/// limits apply), fail-open (`false`) on count errors so a count failure
/// never blocks creation; callers re-check before saving anyway.
///
/// The count is a per-family shared quota while the entitlement is
/// per-user (see [UsageLimits]): a free user in a full family is blocked
/// even for rows they did not create. Enforcement is client-side only and
/// check-then-create is not atomic — concurrent creates can overshoot the
/// cap (TOCTOU accepted explicitly; no server-side cap exists yet).
// TODO(diogohenrique): enforce the cap server-side (RLS policy, trigger,
// or edge-function atomic check-then-insert) before relying on these
// limits for revenue. Client-side gating is UX friction only: direct API
// inserts bypass it.
class IsAtNoteLimitUsecase {
  const IsAtNoteLimitUsecase({
    required this.subscriptionService,
    required this.notesRepository,
    this.remoteConfigService,
  });

  final SubscriptionService subscriptionService;
  final NotesRepository notesRepository;
  final RemoteConfigService? remoteConfigService;

  /// [userId] scopes the entitlement-cache lookup to one account (see
  /// `SubscriptionService.isPro`); pass `AuthService.currentUserId`.
  Future<bool> call({String? familyId, String? userId}) async {
    // Master switch: when the remote flag is off (or no config service is
    // wired), usage limits are disabled entirely and no cap is enforced.
    if (remoteConfigService?.enableLimitAndPaywall != true) return false;
    try {
      if (familyId == null) return false;
      if (await subscriptionService.isPro(userId: userId)) return false;
      final result = await notesRepository.getNotesCount(familyId);
      final bool limitReached = result.fold(
        (_) => false,
        (count) => UsageLimits.isNoteLimitReached(count: count, isPro: false),
      );
      return limitReached;
    } on Object catch (_) {
      return false;
    }
  }
}

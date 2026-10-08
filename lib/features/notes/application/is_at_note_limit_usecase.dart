import 'package:house_mira/core/subscriptions/subscription_service.dart';
import 'package:house_mira/core/subscriptions/usage_limits.dart';
import 'package:house_mira/features/notes/domain/repository/notes_repository.dart';

/// Free-tier gate for notes.
///
/// Returns `true` when a free-tier user has hit
/// [UsageLimits.freeNotesLimit]. Paid users never hit the cap.
/// Fail-open (`false`) on every lookup error so a billing or count
/// failure never blocks creation; callers re-check before saving anyway.
///
/// The count is a per-family shared quota while the entitlement is
/// per-user (see [UsageLimits]): a free user in a full family is blocked
/// even for rows they did not create. Enforcement is client-side only and
/// check-then-create is not atomic — concurrent creates can overshoot the
/// cap (TOCTOU accepted explicitly; no server-side cap exists yet).
class IsAtNoteLimitUsecase {
  const IsAtNoteLimitUsecase({
    required this.subscriptionService,
    required this.notesRepository,
  });

  final SubscriptionService subscriptionService;
  final NotesRepository notesRepository;

  Future<bool> call({String? familyId}) async {
    try {
      if (await subscriptionService.isPro()) return false;
      if (familyId == null) return false;
      final result = await notesRepository.getNotesCount(familyId);
      return result.fold(
        (_) => false,
        (count) => UsageLimits.isNoteLimitReached(count: count, isPro: false),
      );
    } on Object catch (_) {
      return false;
    }
  }
}

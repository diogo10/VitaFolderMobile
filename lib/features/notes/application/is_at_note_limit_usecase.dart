import 'package:house_mira/core/subscriptions/subscription_service.dart';
import 'package:house_mira/core/subscriptions/usage_limits.dart';
import 'package:house_mira/features/notes/domain/repository/notes_repository.dart';

/// Free-tier gate for notes.
///
/// Returns `true` when a free-tier user has hit
/// [UsageLimits.freeNotesLimit]. Paid users never hit the cap.
/// Fail-open (`false`) on every lookup error so a billing or count
/// failure never blocks creation; callers re-check before saving anyway.
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
      final result = await notesRepository.getNotes(familyId);
      return result.fold(
        (_) => false,
        (notes) =>
            UsageLimits.isNoteLimitReached(count: notes.length, isPro: false),
      );
    } on Object catch (_) {
      return false;
    }
  }
}

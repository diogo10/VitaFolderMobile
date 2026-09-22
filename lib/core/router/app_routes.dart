import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:house_mira/features/reminders/domain/entities/reminder_entity.dart';
import 'package:house_mira/features/reminders/domain/entities/reminder_type.dart';

/// Centralized route table for the app.
///
/// All in-app locations live here as constants or validated builders so
/// navigation call sites never scatter raw string paths or unchecked
/// `state.extra` casts. Deep links served from the backend invite flow share
/// the same constants ([inviteLink]) so mobile and email links cannot drift.
abstract final class AppRoutes {
  static const splash = '/splash';
  static const onboarding = '/onboarding';
  static const signUp = '/sign-up';
  static const home = '/home';
  static const people = '/people';
  static const reminders = '/reminders';
  static const account = '/account';
  static const invitePeople = '/invite-people';
  static const createReminder = '/create-reminder';
  static const familySettings = '/family-settings';
  static const manageProfile = '/manage-profile';
  static const notificationSettings = '/notification-settings';

  /// Deep-link entry for family invites: `/invite/<code>`.
  ///
  /// Served over App Links at [inviteLink] and handled in-app by the same
  /// path. The invite code is also accepted as `/invite?code=<code>`.
  static const inviteJoinBase = '/invite';

  /// Query parameter carrying a pending invite code or family name.
  static const inviteCodeParam = 'code';
  static const familyNameParam = 'familyName';

  /// Query parameter used by the splash gate to preserve the pre-auth
  /// location (deep link or tab) across session recovery.
  static const nextParam = 'next';

  /// Query parameter carrying a reminder type for the create screen.
  static const reminderTypeParam = 'type';

  /// Public web base for family invites. Must match the backend invite flow
  /// (email template in `EdgetFunctions`, share sheet) and the native
  /// App Link / Associated Domain declarations.
  static const inviteWebBase = 'https://vitafolder.app/invite';

  /// Builds the shareable/emailable invite link for [code].
  ///
  /// Returns `null` when [code] is blank after masking characters (`•`)
  /// are stripped — never fabricates a link. Explicit failure beats a
  /// wrong link.
  static String? inviteLink(String? code) {
    final sanitized = code?.replaceAll('•', '').trim() ?? '';
    if (sanitized.isEmpty || !inviteCodePattern.hasMatch(sanitized)) {
      return null;
    }
    return '$inviteWebBase/$sanitized';
  }

  /// Location of the join-invite deep link for a validated [code].
  static String inviteJoinLocation(String code) => '$inviteJoinBase/$code';

  /// Invite codes are short opaque tokens (see `joinFamily`).
  static final RegExp inviteCodePattern = RegExp(
    r'^[A-Za-z0-9][A-Za-z0-9\-_]{2,63}$',
  );

  /// Tabs that guests may browse without signing in.
  static const guestTabs = <String>{home, people, reminders, account};
}

/// Validated redirect matrix for the router.
///
/// | Auth state | Location | Outcome |
/// | --- | --- | --- |
/// | recovery in flight | not splash | `/splash?next=<from>` (preserved) |
/// | recovery in flight | splash | hold (null) |
/// | initialized, on splash | splash | validated `next`, else home/onboarding |
/// | signed in, on sign-up | sign-up | home |
/// | signed out, on sign-up | sign-up | allowed (guest may register) |
/// | invite deep link, bad code | invite | `/people` (join manually) |
/// | anything else | anywhere | allowed (guests browse; onboarding unforced) |
///
/// Pure and synchronous so it is unit-testable without pumping widgets.
/// Returns the redirect location, or `null` to stay put.
String? resolveAppRedirect({
  required Uri uri,
  required bool isInitialized,
  required bool isAuthenticated,
  required bool onboardingCompleted,
}) {
  final location = uri.path;
  // `state.uri` is in-app (path + query), but be defensive: an absolute
  // invite URL carries the same path once the scheme/host are stripped.
  final query = uri.hasQuery ? '?${uri.query}' : '';
  final rawPath = uri.path.isEmpty ? '/' : uri.path;
  final fullLocation = '$rawPath$query';

  if (!isInitialized) {
    if (location == AppRoutes.splash) return null;
    return _splashHolding(fullLocation);
  }

  if (location == AppRoutes.splash) {
    final next = _validatedNext(uri);
    if (next != null) return next;
    return onboardingCompleted ? AppRoutes.home : AppRoutes.onboarding;
  }

  if (location == AppRoutes.signUp && isAuthenticated) {
    return AppRoutes.home;
  }

  final inviteCode = JoinInviteRoute.parseCode(uri);
  if (inviteCode == null && _isInvitePath(location)) {
    return AppRoutes.people;
  }

  return null;
}

String _splashHolding(String fullLocation) {
  if (fullLocation == AppRoutes.splash) return AppRoutes.splash;
  final encoded = Uri.encodeComponent(fullLocation);
  return '${AppRoutes.splash}?${AppRoutes.nextParam}=$encoded';
}

/// Returns the preserved post-splash location, or `null` when absent or
/// invalid. A `next` pointing back at splash or sign-up-while-authed is
/// rejected here; the sign-up rule re-applies naturally on the next pass.
String? _validatedNext(Uri uri) {
  final next = uri.queryParameters[AppRoutes.nextParam];
  if (next == null || next.isEmpty) return null;
  final parsed = Uri.tryParse(next);
  if (parsed == null) return null;
  if (parsed.hasScheme || parsed.hasAuthority) return null;
  final path = parsed.path.isEmpty ? '/' : parsed.path;
  if (path == AppRoutes.splash) return null;
  if (path == AppRoutes.inviteJoinBase ||
      path.startsWith('${AppRoutes.inviteJoinBase}/')) {
    final code = JoinInviteRoute.parseCode(parsed);
    if (code == null) return AppRoutes.people;
  }
  final remaining = Map.of(parsed.queryParameters)..remove(AppRoutes.nextParam);
  final rebuilt = remaining.isEmpty
      ? Uri(path: parsed.path)
      : parsed.replace(queryParameters: remaining);
  final result = rebuilt.toString();
  if (result.isEmpty) return null;
  return result.startsWith('/') ? result : '/$result';
}

bool _isInvitePath(String path) {
  return path == AppRoutes.inviteJoinBase ||
      path.startsWith('${AppRoutes.inviteJoinBase}/');
}

/// Maps a local-notification tap/launch payload to an in-app location.
///
/// Payloads carry a reminder id, but there is no reminder-detail screen, so
/// every non-blocking payload lands on the reminders list. Never throws and
/// never returns an empty location.
String notificationLocationFor(String? payload) {
  if (payload == null || payload.trim().isEmpty) return AppRoutes.reminders;
  return AppRoutes.reminders;
}

/// Typed wrapper for the send-invite screen.
///
/// Carries an optional family name for the hero copy. Parses from `extra`
/// (legacy `String` cast centralized here) or the `familyName` query
/// parameter. `null` family name means the generic copy.
@immutable
class InvitePeopleRoute {
  const InvitePeopleRoute({this.familyName});

  factory InvitePeopleRoute.fromState(GoRouterState state) {
    final extra = state.extra;
    if (extra is String && extra.trim().isNotEmpty) {
      return InvitePeopleRoute(familyName: extra.trim());
    }
    final query =
        state.uri.queryParameters[AppRoutes.familyNameParam]?.trim() ?? '';
    return InvitePeopleRoute(familyName: query.isEmpty ? null : query);
  }

  final String? familyName;

  String get location {
    final name = familyName?.trim() ?? '';
    if (name.isEmpty) return AppRoutes.invitePeople;
    final encoded = Uri.encodeComponent(name);
    return '${AppRoutes.invitePeople}?${AppRoutes.familyNameParam}=$encoded';
  }

  Future<T?> push<T extends Object?>(BuildContext context) =>
      context.push<T>(location, extra: familyName);
}

/// Typed wrapper for the create/edit reminder screen.
///
/// Editing an existing reminder travels via `extra` ([ReminderEntity]);
/// pre-selecting a type travels via `extra` ([ReminderType]) or the `type`
/// query parameter so it survives deep links. Unknown extras are ignored
/// (fresh create form) instead of crashing.
@immutable
class CreateReminderRoute {
  const CreateReminderRoute({this.reminder, this.initialType});

  const CreateReminderRoute.create() : reminder = null, initialType = null;

  const CreateReminderRoute.forEdit(this.reminder) : initialType = null;

  const CreateReminderRoute.forType(this.initialType) : reminder = null;

  factory CreateReminderRoute.fromState(GoRouterState state) {
    final extra = state.extra;
    if (extra is ReminderEntity) return CreateReminderRoute.forEdit(extra);
    if (extra is ReminderType) return CreateReminderRoute.forType(extra);
    final type = ReminderType.fromString(
      state.uri.queryParameters[AppRoutes.reminderTypeParam],
    );
    if (type != null) return CreateReminderRoute.forType(type);
    return const CreateReminderRoute.create();
  }

  final ReminderEntity? reminder;
  final ReminderType? initialType;

  String get location {
    final type = initialType;
    if (reminder != null || type == null) return AppRoutes.createReminder;
    return '${AppRoutes.createReminder}?'
        '${AppRoutes.reminderTypeParam}=${type.value}';
  }

  Object? get extra => reminder ?? initialType;

  Future<T?> push<T extends Object?>(BuildContext context) =>
      context.push<T>(location, extra: extra);
}

/// Typed wrapper for the family-invite deep link.
///
/// Accepts `/invite/<code>` (App Link) and `/invite?code=<code>`.
/// [parseCode] returns the validated code, or `null` when missing/invalid —
/// callers fall back to [AppRoutes.people] instead of inventing a code.
@immutable
class JoinInviteRoute {
  const JoinInviteRoute(this.code);

  final String code;

  String get location => AppRoutes.inviteJoinLocation(code);

  static String? parseCode(Uri uri) {
    final segments = uri.pathSegments;
    if (segments.length == 2 && segments[0] == 'invite') {
      final code = segments[1].trim();
      if (AppRoutes.inviteCodePattern.hasMatch(code)) return code;
      return null;
    }
    if (segments.length == 1 && segments[0] == 'invite') {
      final code = (uri.queryParameters[AppRoutes.inviteCodeParam] ?? '')
          .trim();
      if (AppRoutes.inviteCodePattern.hasMatch(code)) return code;
      return null;
    }
    return null;
  }

  static JoinInviteRoute? fromUri(Uri uri) {
    final code = parseCode(uri);
    return code == null ? null : JoinInviteRoute(code);
  }

  void go(BuildContext context) => context.go(location);
}

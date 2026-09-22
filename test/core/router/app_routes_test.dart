import 'package:flutter_test/flutter_test.dart';
import 'package:house_mira/core/router/app_routes.dart';
import 'package:house_mira/features/reminders/domain/entities/reminder_entity.dart';
import 'package:house_mira/features/reminders/domain/entities/reminder_type.dart';

void main() {
  group('resolveAppRedirect', () {
    String? redirect(
      String location, {
      bool initialized = true,
      bool authenticated = false,
      bool onboardingCompleted = true,
    }) {
      return resolveAppRedirect(
        uri: Uri.parse(location),
        isInitialized: initialized,
        isAuthenticated: authenticated,
        onboardingCompleted: onboardingCompleted,
      );
    }

    group('splash gate (session recovery in flight)', () {
      test('holds any location on splash, preserving it in next', () {
        expect(
          redirect('/home', initialized: false),
          '/splash?next=%2Fhome',
        );
      });

      test('preserves deep links with query strings', () {
        expect(
          redirect('/invite/ABC123', initialized: false),
          '/splash?next=%2Finvite%2FABC123',
        );
        expect(
          redirect(
            '/invite-people?familyName=Fam',
            initialized: false,
          ),
          '/splash?next=%2Finvite-people%3FfamilyName%3DFam',
        );
      });

      test('stays on splash while uninitialized', () {
        expect(redirect('/splash', initialized: false), isNull);
        expect(
          redirect('/splash?next=%2Fhome', initialized: false),
          isNull,
        );
      });
    });

    group('splash exit (recovery complete)', () {
      test('restores the preserved deep link', () {
        expect(
          redirect('/splash?next=%2Finvite%2FABC123'),
          '/invite/ABC123',
        );
      });

      test('falls back to home when onboarding is completed', () {
        expect(redirect('/splash'), '/home');
      });

      test('falls back to onboarding when it is not completed', () {
        expect(
          redirect('/splash', onboardingCompleted: false),
          '/onboarding',
        );
      });

      test('rejects a next that points back at splash', () {
        expect(
          redirect('/splash?next=%2Fsplash'),
          '/home',
        );
      });

      test('rejects external next URLs', () {
        expect(
          redirect('/splash?next=https%3A%2F%2Fevil.example%2Fsteal'),
          '/home',
        );
      });

      test('downgrades an invalid invite next to people', () {
        expect(
          redirect('/splash?next=%2Finvite%2F!!!'),
          '/people',
        );
      });
    });

    group('sign-up', () {
      test('redirects signed-in users away from sign-up', () {
        expect(
          redirect('/sign-up', authenticated: true),
          '/home',
        );
      });

      test('allows guests on sign-up', () {
        expect(redirect('/sign-up'), isNull);
      });
    });

    group('guests', () {
      test('browse tabs freely', () {
        for (final tab in AppRoutes.guestTabs) {
          expect(redirect(tab), isNull, reason: tab);
        }
      });

      test('onboarding is not forced', () {
        expect(
          redirect('/home', onboardingCompleted: false),
          isNull,
        );
      });
    });

    group('invite deep links', () {
      test('lets valid codes through', () {
        expect(redirect('/invite/ABC123'), isNull);
        expect(redirect('/invite?code=XYZ789'), isNull);
      });

      test('falls back to people for missing or invalid codes', () {
        expect(redirect('/invite'), '/people');
        expect(redirect('/invite/!!!'), '/people');
        expect(redirect('/invite?code=%20'), '/people');
        expect(redirect('/invite?code=!!'), '/people');
      });

      test('still gates invites behind session recovery', () {
        expect(
          redirect('/invite/ABC123', initialized: false),
          '/splash?next=%2Finvite%2FABC123',
        );
      });
    });
  });

  group('JoinInviteRoute.parseCode', () {
    test('parses path codes', () {
      expect(
        JoinInviteRoute.parseCode(Uri.parse('/invite/ABC123')),
        'ABC123',
      );
    });

    test('parses query codes', () {
      expect(
        JoinInviteRoute.parseCode(Uri.parse('/invite?code=XYZ789')),
        'XYZ789',
      );
    });

    test('returns null for missing, blank, or invalid codes', () {
      expect(JoinInviteRoute.parseCode(Uri.parse('/invite')), isNull);
      expect(
        JoinInviteRoute.parseCode(Uri.parse('/invite?code=%20')),
        isNull,
      );
      expect(
        JoinInviteRoute.parseCode(Uri.parse('/invite/!!!')),
        isNull,
      );
      expect(
        JoinInviteRoute.parseCode(Uri.parse('/invite/AB')),
        isNull,
      );
    });

    test('returns null outside invite paths', () {
      expect(JoinInviteRoute.parseCode(Uri.parse('/people')), isNull);
      expect(
        JoinInviteRoute.parseCode(Uri.parse('/invite/ABC/extra')),
        isNull,
      );
    });

    test('location round-trips through parseCode', () {
      const route = JoinInviteRoute('ABC123');
      expect(route.location, '/invite/ABC123');
      expect(
        JoinInviteRoute.fromUri(Uri.parse(route.location))?.code,
        'ABC123',
      );
      expect(JoinInviteRoute.fromUri(Uri.parse('/people')), isNull);
    });
  });

  group('AppRoutes.inviteLink', () {
    test('builds the App Link for a valid code', () {
      expect(
        AppRoutes.inviteLink('ABC123'),
        'https://vitafolder.app/invite/ABC123',
      );
    });

    test('trims whitespace and strips masking characters', () {
      expect(
        AppRoutes.inviteLink('  ABC123  '),
        'https://vitafolder.app/invite/ABC123',
      );
      expect(
        AppRoutes.inviteLink('AB•C123'),
        'https://vitafolder.app/invite/ABC123',
      );
    });

    test('returns null instead of fabricating a link', () {
      expect(AppRoutes.inviteLink(null), isNull);
      expect(AppRoutes.inviteLink(''), isNull);
      expect(AppRoutes.inviteLink('   '), isNull);
      expect(AppRoutes.inviteLink('•••'), isNull);
      expect(AppRoutes.inviteLink('!!!'), isNull);
    });
  });

  group('notificationLocationFor', () {
    test('routes every payload shape to the reminders list', () {
      expect(notificationLocationFor(null), '/reminders');
      expect(notificationLocationFor(''), '/reminders');
      expect(notificationLocationFor('   '), '/reminders');
      expect(
        notificationLocationFor('reminder-id-123'),
        '/reminders',
      );
    });
  });

  group('typed route locations', () {
    test('InvitePeopleRoute omits blank family names', () {
      expect(
        const InvitePeopleRoute().location,
        '/invite-people',
      );
      expect(
        const InvitePeopleRoute(familyName: '  ').location,
        '/invite-people',
      );
      expect(
        const InvitePeopleRoute(familyName: 'Fam').location,
        '/invite-people?familyName=Fam',
      );
    });

    test('CreateReminderRoute locations', () {
      expect(
        const CreateReminderRoute.create().location,
        '/create-reminder',
      );
      expect(
        const CreateReminderRoute.forType(ReminderType.birthday).location,
        '/create-reminder?type=birthday',
      );
      const reminder = ReminderEntity(
        id: '1',
        title: 'Title',
        body: 'Body',
        type: ReminderType.chores,
        dueDate: '22/08/2026 09:00',
        repeatRule: 'never',
        status: 'pending',
        createdBy: 'me',
        createdAt: '2026-08-01',
      );
      const edit = CreateReminderRoute.forEdit(reminder);
      expect(edit.location, '/create-reminder');
      expect(edit.extra, reminder);
      expect(
        const CreateReminderRoute.forType(ReminderType.vaccine).extra,
        ReminderType.vaccine,
      );
      expect(const CreateReminderRoute.create().extra, isNull);
    });
  });
}

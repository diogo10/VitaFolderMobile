import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:house_mira_core/auth/auth_service.dart';
import 'package:house_mira_core/errors/failure.dart';
import 'package:house_mira_core/subscriptions/subscription_service.dart';
import 'package:house_mira_core/subscriptions/usage_limits.dart';
import 'package:house_mira_people/domain/entities/person_entity.dart';
import 'package:house_mira_people/domain/repository/people_repository.dart';
import 'package:house_mira_reminders/application/is_at_reminder_limit_usecase.dart';
import 'package:house_mira_reminders/application/reminder_notification_service.dart';
import 'package:house_mira_reminders/domain/entities/reminder_entity.dart';
import 'package:house_mira_reminders/domain/entities/reminder_lead_time.dart';
import 'package:house_mira_reminders/domain/entities/reminder_type.dart';
import 'package:house_mira_reminders/domain/repository/reminder_repository.dart';
import 'package:house_mira_reminders/domain/usecase/get_reminder_usecase.dart';
import 'package:house_mira_reminders/presentation/cubit/reminders_cubit.dart';
import 'package:house_mira_reminders/presentation/screens/reminders_view.dart';
import 'package:house_mira_reminders/presentation/widgets/reminder_widget.dart';
import 'package:house_mira_reminders/presentation/widgets/reminders_empty_widget.dart';
import 'package:house_mira_core/generated/app_localizations.dart';
import 'package:mocktail/mocktail.dart';

class _FakeAuthService extends Mock implements AuthService {}

class _FakePeopleRepository extends Mock implements PeopleRepository {}

class _FakeReminderRepository extends Mock implements ReminderRepository {}

class _FakeGetReminderUsecase extends Mock implements GetReminderUsecase {}

/// Paid by default so existing tests exercise the uncapped path.
class _PaidSubscriptions extends SubscriptionService {
  @override
  Future<bool> isPro({String? userId}) async => true;
}

class _NoopNotificationService implements IReminderNotificationService {
  @override
  Future<void> init() async {}

  @override
  Stream<String?> get onNotificationTap => const Stream.empty();

  @override
  Future<String?> getLaunchPayload() async => null;

  @override
  Future<bool> hasSystemPermission() async => false;

  @override
  Future<bool> requestSystemPermission() async => false;

  @override
  Future<bool> canScheduleExactAlarms() async => true;

  @override
  Future<void> requestExactAlarmPermission() async {}

  @override
  Future<ReminderNotificationPrefs> getReminderNotification(
    String reminderId,
  ) async => ReminderNotificationPrefs.disabled;

  @override
  Future<bool> setReminderNotification({
    required String reminderId,
    required bool enabled,
    required ReminderLeadTime leadTime,
    required DateTime? dueDate,
    required String title,
    required String body,
    required String repeatRule,
  }) async => true;

  @override
  Future<void> cancelReminderNotification(String reminderId) async {}

  @override
  Future<bool> showTestNotification({
    required String title,
    required String body,
  }) async => true;

  @override
  Future<void> rescheduleAll(List<ReminderEntity> reminders) async {}
}

void main() {
  late _FakeAuthService authService;
  late _FakePeopleRepository peopleRepository;
  late _FakeGetReminderUsecase getReminderUsecase;
  late _FakeReminderRepository reminderRepository;

  setUp(() {
    authService = _FakeAuthService();
    peopleRepository = _FakePeopleRepository();
    getReminderUsecase = _FakeGetReminderUsecase();
    reminderRepository = _FakeReminderRepository();
    registerFallbackValue(ReminderType.appointment);
  });

  Widget pumpView() {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: BlocProvider<RemindersCubit>(
        create: (_) => RemindersCubit(
          getReminderUsecase: getReminderUsecase,
          peopleRepository: peopleRepository,
          authService: authService,
          reminderRepository: reminderRepository,
          notificationService: _NoopNotificationService(),
          isAtReminderLimitUsecase: IsAtReminderLimitUsecase(
            subscriptionService: _PaidSubscriptions(),
            reminderRepository: reminderRepository,
          ),
        ),
        child: const RemindersView(),
      ),
    );
  }

  group('RemindersView', () {
    testWidgets(
      'shows RemindersEmptyWidget and skips fetch when not logged in',
      (tester) async {
        when(() => authService.isLoggedIn()).thenReturn(false);

        await tester.pumpWidget(pumpView());
        await tester.pump();

        expect(find.byType(RemindersEmptyWidget), findsOneWidget);
        expect(find.byType(ReminderWidget), findsNothing);
        verifyNever(() => getReminderUsecase(any(), type: any(named: 'type')));
      },
    );

    testWidgets('loads reminders when logged in', (tester) async {
      when(() => authService.isLoggedIn()).thenReturn(true);
      when(() => authService.currentUserId).thenReturn('user-1');
      when(
        () => peopleRepository.getMyFamilyRole(),
      ).thenAnswer((_) async => <String>[]);
      when(
        () => peopleRepository.getFamilyIdsForUser('user-1'),
      ).thenAnswer((_) async => ['fam-1']);
      when(
        () => getReminderUsecase('fam-1', type: any(named: 'type')),
      ).thenAnswer(
        (_) async => const Right([
          ReminderEntity(
            id: '1',
            title: 'Test Title',
            body: 'Test Body',
            type: ReminderType.appointment,
            dueDate: '22/08/2026 15:00',
            repeatRule: 'never',
            status: 'pending',
            createdBy: 'Mom',
            createdAt: '2026-08-01',
          ),
        ]),
      );
      when(
        () => peopleRepository.getProfilesWithRoleForFamily('fam-1'),
      ).thenAnswer((_) async => <PersonEntity>[]);

      await tester.pumpWidget(pumpView());
      await tester.pump();

      expect(find.byType(RemindersEmptyWidget), findsNothing);
      expect(find.text('Test Title'), findsOneWidget);
      verify(
        () => getReminderUsecase('fam-1', type: any(named: 'type')),
      ).called(1);
    });

    testWidgets('shows empty state when a logged-in user has no family', (
      tester,
    ) async {
      when(() => authService.isLoggedIn()).thenReturn(true);
      when(() => authService.currentUserId).thenReturn('user-1');
      when(
        () => peopleRepository.getMyFamilyRole(),
      ).thenAnswer((_) async => <String>[]);
      when(
        () => peopleRepository.getFamilyIdsForUser('user-1'),
      ).thenAnswer((_) async => <String>[]);

      await tester.pumpWidget(pumpView());
      await tester.pump();
      await tester.pump();

      expect(find.byType(RemindersEmptyWidget), findsOneWidget);
      verifyNever(() => getReminderUsecase(any(), type: any(named: 'type')));
    });

    testWidgets('free user at cap sees the limit message on add', (
      tester,
    ) async {
      List<ReminderEntity> rows(int count) => List.generate(
        count,
        (i) => ReminderEntity(
          id: 'r$i',
          title: 'T $i',
          body: '',
          type: ReminderType.appointment,
          dueDate: '22/08/2026 15:00',
          repeatRule: 'never',
          status: 'pending',
          createdBy: 'Mom',
          createdAt: '2026-08-01',
        ),
      );
      when(() => authService.isLoggedIn()).thenReturn(true);
      when(() => authService.currentUserId).thenReturn('user-1');
      when(
        () => peopleRepository.getMyFamilyRole(),
      ).thenAnswer((_) async => <String>[]);
      when(
        () => peopleRepository.getFamilyIdsForUser('user-1'),
      ).thenAnswer((_) async => ['fam-1']);
      when(
        () => peopleRepository.getProfilesWithRoleForFamily('fam-1'),
      ).thenAnswer((_) async => <PersonEntity>[]);
      when(
        () => getReminderUsecase('fam-1', type: any(named: 'type')),
      ).thenAnswer((_) async => Right(rows(10)));
      // Free tier: the add-button gate counts via the repository.
      final freeSubs = _FreeSubscriptions();
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: BlocProvider<RemindersCubit>(
            create: (_) => RemindersCubit(
              getReminderUsecase: getReminderUsecase,
              peopleRepository: peopleRepository,
              authService: authService,
              reminderRepository: reminderRepository,
              notificationService: _NoopNotificationService(),
              isAtReminderLimitUsecase: IsAtReminderLimitUsecase(
                subscriptionService: freeSubs,
                reminderRepository: reminderRepository,
              ),
            ),
            child: const RemindersView(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      when(
        () => reminderRepository.getRemindersCount('fam-1'),
      ).thenAnswer((_) async => const Right<Failure, int>(10));

      // The add gate resolves the family once and reuses it for the limit
      // check (single lookup, not one per check).
      clearInteractions(peopleRepository);
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      final l = AppLocalizations.of(
        tester.element(find.byType(RemindersView)),
      )!;
      expect(
        find.text(
          l.createReminderErrorLimitReached(UsageLimits.freeRemindersLimit),
        ),
        findsOneWidget,
      );
      expect(find.text(l.limitReachedUpgrade), findsOneWidget);
      // The create screen never opens: no editor title appears.
      expect(find.text(l.createReminderTitle), findsNothing);
      verify(() => peopleRepository.getFamilyIdsForUser('user-1')).called(1);
    });
  });
}

/// Free-tier subscription fake for limit-gate widget tests.
class _FreeSubscriptions extends SubscriptionService {
  @override
  Future<bool> isPro({String? userId}) async => false;
}

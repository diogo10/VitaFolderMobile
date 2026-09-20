import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:house_mira/core/auth/auth_service.dart';
import 'package:house_mira/core/errors/failure.dart';
import 'package:house_mira/features/people/domain/repository/people_repository.dart';
import 'package:house_mira/features/reminders/application/reminder_notification_service.dart';
import 'package:house_mira/features/reminders/data/models/reminder_model.dart';
import 'package:house_mira/features/reminders/domain/entities/reminder_entity.dart';
import 'package:house_mira/features/reminders/domain/entities/reminder_lead_time.dart';
import 'package:house_mira/features/reminders/domain/entities/reminder_type.dart';
import 'package:house_mira/features/reminders/domain/usecase/create_reminder_usecase.dart';
import 'package:house_mira/features/reminders/domain/usecase/update_reminder_usecase.dart';
import 'package:house_mira/features/reminders/presentation/cubit/create_reminder_cubit.dart';
import 'package:house_mira/features/reminders/presentation/cubit/create_reminder_state.dart';
import 'package:mocktail/mocktail.dart';

class _FakeAuthService extends Mock implements AuthService {}

class _FakePeopleRepository extends Mock implements PeopleRepository {}

class _FakeCreateReminderUsecase extends Mock
    implements CreateReminderUsecase {}

class _FakeUpdateReminderUsecase extends Mock
    implements UpdateReminderUsecase {}

class _FakeNotificationService extends Mock
    implements IReminderNotificationService {}

void main() {
  late _FakeAuthService authService;
  late _FakePeopleRepository peopleRepository;
  late _FakeCreateReminderUsecase createReminderUsecase;
  late _FakeUpdateReminderUsecase updateReminderUsecase;
  late _FakeNotificationService notificationService;

  setUp(() {
    authService = _FakeAuthService();
    peopleRepository = _FakePeopleRepository();
    createReminderUsecase = _FakeCreateReminderUsecase();
    updateReminderUsecase = _FakeUpdateReminderUsecase();
    notificationService = _FakeNotificationService();
    when(
      () => notificationService.setReminderNotification(
        reminderId: any(named: 'reminderId'),
        enabled: any(named: 'enabled'),
        leadTime: any(named: 'leadTime'),
        dueDate: any(named: 'dueDate'),
        title: any(named: 'title'),
        body: any(named: 'body'),
        repeatRule: any(named: 'repeatRule'),
      ),
    ).thenAnswer((_) async => true);
    when(
      () => notificationService.hasSystemPermission(),
    ).thenAnswer((_) async => true);
    when(
      () => notificationService.canScheduleExactAlarms(),
    ).thenAnswer((_) async => true);
  });

  setUpAll(() {
    registerFallbackValue(ReminderLeadTime.fifteenMinutes);
    registerFallbackValue(
      const ReminderModel(
        title: '',
        body: '',
        id: '',
        type: ReminderType.custom,
        dueDate: '',
        repeatRule: 'never',
        status: '',
        createdBy: '',
        createdAt: '',
      ),
    );
  });

  CreateReminderCubit buildCubit() => CreateReminderCubit(
    createReminderUsecase: createReminderUsecase,
    updateReminderUsecase: updateReminderUsecase,
    authService: authService,
    peopleRepository: peopleRepository,
    notificationService: notificationService,
  );

  const reminder = ReminderEntity(
    id: '1',
    title: 'Old title',
    body: 'Old body',
    type: ReminderType.appointment,
    dueDate: '22/08/2026 15:00',
    repeatRule: 'weekly',
    status: 'pending',
    createdBy: 'Mom',
    createdAt: '2026-08-01',
  );

  group('CreateReminderCubit.createReminder', () {
    void stubFamily(String? familyId, {String userId = 'u1'}) {
      when(() => authService.currentUserId).thenReturn(userId);
      when(
        () => peopleRepository.getFamilyIdsForUser(userId),
      ).thenAnswer((_) async => familyId == null ? [] : [familyId]);
    }

    blocTest<CreateReminderCubit, CreateReminderState>(
      'emits loading then success when create succeeds',
      build: buildCubit,
      setUp: () {
        stubFamily('f1');
        when(
          () => createReminderUsecase.call(any(), any()),
        ).thenAnswer((_) async => const Right('new-id'));
      },
      act: (cubit) => cubit.createReminder(
        title: 'T',
        body: 'B',
        type: ReminderType.chores,
        dueDate: DateTime(2026, 9, 1, 10, 30),
        repeatRule: 'never',
      ),
      expect: () => [
        isA<CreateReminderLoading>(),
        isA<CreateReminderSuccess>().having(
          (s) => s.reminderId,
          'reminderId',
          'new-id',
        ),
      ],
      verify: (_) {
        final captured = verify(
          () => createReminderUsecase.call(captureAny(), captureAny()),
        ).captured;
        expect((captured[0] as ReminderModel).title, 'T');
        expect(captured[1] as String, 'f1');
      },
    );

    blocTest<CreateReminderCubit, CreateReminderState>(
      'emits noFamily when user has no family',
      build: buildCubit,
      setUp: () => stubFamily(null),
      act: (cubit) => cubit.createReminder(
        title: 'T',
        body: 'B',
        type: ReminderType.chores,
        dueDate: null,
        repeatRule: 'never',
      ),
      expect: () => [
        isA<CreateReminderLoading>(),
        isA<CreateReminderError>().having(
          (e) => e.code,
          'code',
          CreateReminderErrorCode.noFamily,
        ),
      ],
    );

    blocTest<CreateReminderCubit, CreateReminderState>(
      'emits noFamily when there is no logged-in user',
      build: buildCubit,
      setUp: () {
        when(() => authService.currentUserId).thenReturn(null);
      },
      act: (cubit) => cubit.createReminder(
        title: 'T',
        body: 'B',
        type: ReminderType.chores,
        dueDate: null,
        repeatRule: 'never',
      ),
      expect: () => [
        isA<CreateReminderLoading>(),
        isA<CreateReminderError>().having(
          (e) => e.code,
          'code',
          CreateReminderErrorCode.noFamily,
        ),
      ],
    );

    blocTest<CreateReminderCubit, CreateReminderState>(
      'emits authRequired when the session lapses mid-creation',
      build: buildCubit,
      setUp: () {
        // _resolveFamilyId reads currentUserId first (returns 'u1', so a
        // family resolves), then the cubit re-reads it and finds null.
        final userIds = <String?>['u1', null];
        when(
          () => authService.currentUserId,
        ).thenAnswer((_) => userIds.isEmpty ? null : userIds.removeAt(0));
        when(
          () => peopleRepository.getFamilyIdsForUser('u1'),
        ).thenAnswer((_) async => ['f1']);
      },
      act: (cubit) => cubit.createReminder(
        title: 'T',
        body: 'B',
        type: ReminderType.chores,
        dueDate: null,
        repeatRule: 'never',
      ),
      expect: () => [
        isA<CreateReminderLoading>(),
        isA<CreateReminderError>().having(
          (e) => e.code,
          'code',
          CreateReminderErrorCode.authRequired,
        ),
      ],
    );

    blocTest<CreateReminderCubit, CreateReminderState>(
      'emits error message when create fails',
      build: buildCubit,
      setUp: () {
        stubFamily('f1');
        when(
          () => createReminderUsecase.call(any(), any()),
        ).thenAnswer((_) async => Left(Failure(message: 'boom')));
      },
      act: (cubit) => cubit.createReminder(
        title: 'T',
        body: 'B',
        type: ReminderType.chores,
        dueDate: null,
        repeatRule: 'never',
      ),
      expect: () => [
        isA<CreateReminderLoading>(),
        isA<CreateReminderError>().having((e) => e.message, 'message', 'boom'),
      ],
    );
  });

  group('CreateReminderCubit.updateReminder', () {
    blocTest<CreateReminderCubit, CreateReminderState>(
      'emits loading then success when update succeeds',
      build: buildCubit,
      setUp: () {
        when(
          () => updateReminderUsecase.call(any()),
        ).thenAnswer((_) async => const Right(true));
      },
      act: (cubit) => cubit.updateReminder(
        reminder: reminder,
        title: 'New title',
        body: 'New body',
        type: ReminderType.chores,
        dueDate: DateTime(2026, 9, 1, 10, 30),
        repeatRule: 'daily',
      ),
      expect: () => [
        isA<CreateReminderLoading>(),
        isA<UpdatedReminderSuccess>(),
      ],
      verify: (_) {
        final captured =
            verify(
                  () => updateReminderUsecase.call(captureAny()),
                ).captured.single
                as ReminderModel;
        expect(captured.id, '1');
        expect(captured.title, 'New title');
        expect(captured.type, ReminderType.chores);
        expect(captured.status, 'pending');
        expect(captured.createdBy, 'Mom');
        expect(captured.createdAt, '2026-08-01');
      },
    );

    blocTest<CreateReminderCubit, CreateReminderState>(
      'emits error when update fails',
      build: buildCubit,
      setUp: () {
        when(
          () => updateReminderUsecase.call(any()),
        ).thenAnswer((_) async => Left(Failure(message: 'boom')));
      },
      act: (cubit) => cubit.updateReminder(
        reminder: reminder,
        title: 'New title',
        body: 'New body',
        type: ReminderType.chores,
        dueDate: DateTime(2026, 9, 1, 10, 30),
        repeatRule: 'daily',
      ),
      expect: () => [
        isA<CreateReminderLoading>(),
        isA<CreateReminderError>().having(
          (state) => state.message,
          'message',
          'boom',
        ),
      ],
    );
  });

  group('CreateReminderCubit notifications', () {
    void stubFamily() {
      when(() => authService.currentUserId).thenReturn('u1');
      when(
        () => peopleRepository.getFamilyIdsForUser('u1'),
      ).thenAnswer((_) async => ['f1']);
    }

    blocTest<CreateReminderCubit, CreateReminderState>(
      'schedules the notification on create and reports it armed',
      build: buildCubit,
      setUp: () {
        stubFamily();
        when(
          () => createReminderUsecase.call(any(), any()),
        ).thenAnswer((_) async => const Right('new-id'));
      },
      act: (cubit) => cubit.createReminder(
        title: 'T',
        body: 'B',
        type: ReminderType.chores,
        dueDate: DateTime(2030, 9, 1, 10, 30),
        repeatRule: 'never',
        notifyEnabled: true,
        leadTime: ReminderLeadTime.oneHour,
      ),
      expect: () => [
        isA<CreateReminderLoading>(),
        isA<CreateReminderSuccess>()
            .having((s) => s.reminderId, 'reminderId', 'new-id')
            .having((s) => s.notificationArmed, 'armed', isTrue)
            .having((s) => s.notificationTimePassed, 'timePassed', isFalse)
            .having((s) => s.notificationInexact, 'inexact', isFalse),
      ],
      verify: (_) {
        verify(
          () => notificationService.setReminderNotification(
            reminderId: 'new-id',
            enabled: true,
            leadTime: ReminderLeadTime.oneHour,
            dueDate: DateTime(2030, 9, 1, 10, 30),
            title: 'T',
            body: 'B',
            repeatRule: 'never',
          ),
        ).called(1);
      },
    );

    blocTest<CreateReminderCubit, CreateReminderState>(
      'reports inexact when exact alarms are denied',
      build: buildCubit,
      setUp: () {
        stubFamily();
        when(
          () => createReminderUsecase.call(any(), any()),
        ).thenAnswer((_) async => const Right('new-id'));
        when(
          () => notificationService.canScheduleExactAlarms(),
        ).thenAnswer((_) async => false);
      },
      act: (cubit) => cubit.createReminder(
        title: 'T',
        body: 'B',
        type: ReminderType.chores,
        dueDate: DateTime(2030, 9, 1, 10, 30),
        repeatRule: 'never',
        notifyEnabled: true,
      ),
      expect: () => [
        isA<CreateReminderLoading>(),
        isA<CreateReminderSuccess>()
            .having((s) => s.notificationArmed, 'armed', isTrue)
            .having((s) => s.notificationTimePassed, 'timePassed', isFalse)
            .having((s) => s.notificationInexact, 'inexact', isTrue),
      ],
    );

    blocTest<CreateReminderCubit, CreateReminderState>(
      'reports timePassed when the one-shot time already passed',
      build: buildCubit,
      setUp: () {
        stubFamily();
        when(
          () => createReminderUsecase.call(any(), any()),
        ).thenAnswer((_) async => const Right('new-id'));
        when(
          () => notificationService.setReminderNotification(
            reminderId: any(named: 'reminderId'),
            enabled: any(named: 'enabled'),
            leadTime: any(named: 'leadTime'),
            dueDate: any(named: 'dueDate'),
            title: any(named: 'title'),
            body: any(named: 'body'),
            repeatRule: any(named: 'repeatRule'),
          ),
        ).thenAnswer((_) async => false);
      },
      act: (cubit) => cubit.createReminder(
        title: 'T',
        body: 'B',
        type: ReminderType.chores,
        dueDate: DateTime(2020, 9, 1, 10, 30),
        repeatRule: 'never',
        notifyEnabled: true,
      ),
      expect: () => [
        isA<CreateReminderLoading>(),
        isA<CreateReminderSuccess>()
            .having((s) => s.notificationArmed, 'armed', isFalse)
            .having((s) => s.notificationTimePassed, 'timePassed', isTrue),
      ],
    );

    blocTest<CreateReminderCubit, CreateReminderState>(
      'reports blocked when system permission is denied',
      build: buildCubit,
      setUp: () {
        stubFamily();
        when(
          () => createReminderUsecase.call(any(), any()),
        ).thenAnswer((_) async => const Right('new-id'));
        when(
          () => notificationService.hasSystemPermission(),
        ).thenAnswer((_) async => false);
      },
      act: (cubit) => cubit.createReminder(
        title: 'T',
        body: 'B',
        type: ReminderType.chores,
        dueDate: DateTime(2030, 9, 1, 10, 30),
        repeatRule: 'never',
        notifyEnabled: true,
      ),
      expect: () => [
        isA<CreateReminderLoading>(),
        isA<CreateReminderSuccess>()
            .having((s) => s.notificationArmed, 'armed', isFalse)
            .having((s) => s.notificationTimePassed, 'timePassed', isFalse),
      ],
    );

    blocTest<CreateReminderCubit, CreateReminderState>(
      'still succeeds when notification scheduling throws',
      build: buildCubit,
      setUp: () {
        stubFamily();
        when(
          () => createReminderUsecase.call(any(), any()),
        ).thenAnswer((_) async => const Right('new-id'));
        when(
          () => notificationService.setReminderNotification(
            reminderId: any(named: 'reminderId'),
            enabled: any(named: 'enabled'),
            leadTime: any(named: 'leadTime'),
            dueDate: any(named: 'dueDate'),
            title: any(named: 'title'),
            body: any(named: 'body'),
            repeatRule: any(named: 'repeatRule'),
          ),
        ).thenThrow(Exception('os'));
      },
      act: (cubit) => cubit.createReminder(
        title: 'T',
        body: 'B',
        type: ReminderType.chores,
        dueDate: DateTime(2030, 9, 1, 10, 30),
        repeatRule: 'never',
        notifyEnabled: true,
      ),
      expect: () => [
        isA<CreateReminderLoading>(),
        isA<CreateReminderSuccess>()
            .having((s) => s.notificationArmed, 'armed', isFalse)
            .having((s) => s.notificationTimePassed, 'timePassed', isFalse),
      ],
    );

    blocTest<CreateReminderCubit, CreateReminderState>(
      'schedules the notification on update',
      build: buildCubit,
      setUp: () {
        when(
          () => updateReminderUsecase.call(any()),
        ).thenAnswer((_) async => const Right(true));
      },
      act: (cubit) => cubit.updateReminder(
        reminder: reminder,
        title: 'New title',
        body: 'New body',
        type: ReminderType.chores,
        dueDate: DateTime(2030, 9, 1, 10, 30),
        repeatRule: 'daily',
        notifyEnabled: true,
        leadTime: ReminderLeadTime.oneHour,
      ),
      expect: () => [
        isA<CreateReminderLoading>(),
        isA<UpdatedReminderSuccess>()
            .having((s) => s.notificationArmed, 'armed', isTrue)
            .having((s) => s.notificationTimePassed, 'timePassed', isFalse),
      ],
      verify: (_) {
        verify(
          () => notificationService.setReminderNotification(
            reminderId: '1',
            enabled: true,
            leadTime: ReminderLeadTime.oneHour,
            dueDate: DateTime(2030, 9, 1, 10, 30),
            title: 'New title',
            body: 'New body',
            repeatRule: 'daily',
          ),
        ).called(1);
      },
    );

    test('notification helpers degrade gracefully', () async {
      final cubit = buildCubit();
      addTearDown(cubit.close);
      when(
        () => notificationService.getReminderNotification(any()),
      ).thenThrow(Exception('db'));
      when(
        () => notificationService.requestSystemPermission(),
      ).thenThrow(Exception('os'));
      when(
        () => notificationService.canScheduleExactAlarms(),
      ).thenThrow(Exception('os'));

      expect(
        await cubit.getNotificationPrefs('r1'),
        ReminderNotificationPrefs.disabled,
      );
      expect(await cubit.requestSystemPermission(), isFalse);
      expect(await cubit.canScheduleExactAlarms(), isTrue);
      await cubit.requestExactAlarmPermission();
      verify(
        () => notificationService.requestExactAlarmPermission(),
      ).called(1);
    });
  });
}

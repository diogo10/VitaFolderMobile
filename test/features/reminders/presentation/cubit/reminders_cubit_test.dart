import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:house_mira/core/auth/auth_service.dart';
import 'package:house_mira/core/errors/failure.dart';
import 'package:house_mira/features/people/domain/repository/people_repository.dart';
import 'package:house_mira/features/reminders/application/reminder_notification_service.dart';
import 'package:house_mira/features/reminders/domain/entities/reminder_entity.dart';
import 'package:house_mira/features/reminders/domain/entities/reminder_type.dart';
import 'package:house_mira/features/reminders/domain/repository/reminder_repository.dart';
import 'package:house_mira/features/reminders/domain/usecase/get_reminder_usecase.dart';
import 'package:house_mira/features/reminders/presentation/cubit/reminders_cubit.dart';
import 'package:house_mira/features/reminders/presentation/cubit/reminders_state.dart';
import 'package:house_mira/features/reminders/presentation/cubit/reminders_view_mode.dart';
import 'package:mocktail/mocktail.dart';

class _FakePeopleRepository extends Mock implements PeopleRepository {}

class _FakeAuthService extends Mock implements AuthService {}

class _FakeGetReminderUsecase extends Mock implements GetReminderUsecase {}

class _FakeReminderRepository extends Mock implements ReminderRepository {}

class _FakeNotificationService extends Mock
    implements IReminderNotificationService {}

void main() {
  late _FakePeopleRepository peopleRepository;
  late _FakeAuthService authService;
  late _FakeGetReminderUsecase getReminderUsecase;
  late _FakeReminderRepository reminderRepository;
  late _FakeNotificationService notificationService;

  setUp(() {
    peopleRepository = _FakePeopleRepository();
    authService = _FakeAuthService();
    getReminderUsecase = _FakeGetReminderUsecase();
    reminderRepository = _FakeReminderRepository();
    notificationService = _FakeNotificationService();
  });

  setUpAll(() {
    registerFallbackValue(ReminderType.custom);
  });

  void stubFamily({String userId = 'u1', String familyId = 'f1'}) {
    when(() => authService.currentUserId).thenReturn(userId);
    when(
      () => peopleRepository.getFamilyIdsForUser(userId),
    ).thenAnswer((_) async => [familyId]);
    when(
      () => peopleRepository.getMyFamilyRole(),
    ).thenAnswer((_) async => ['member']);
    when(
      () => peopleRepository.getProfilesWithRoleForFamily(familyId),
    ).thenAnswer((_) async => []);
  }

  RemindersCubit buildCubit() => RemindersCubit(
    getReminderUsecase: getReminderUsecase,
    peopleRepository: peopleRepository,
    authService: authService,
    reminderRepository: reminderRepository,
  );

  group('RemindersCubit.getReminders', () {
    ReminderEntity reminder(String id, ReminderType type) => ReminderEntity(
      title: 'T $id',
      body: '',
      id: id,
      type: type,
      dueDate: '19/08/2026',
      repeatRule: 'never',
      status: 'pending',
      createdBy: 'Mom',
      createdAt: '',
    );

    blocTest<RemindersCubit, RemindersState>(
      'emits loading then loaded when reminders exist',
      build: buildCubit,
      setUp: () {
        stubFamily();
        when(
          () => getReminderUsecase.call('f1', type: any(named: 'type')),
        ).thenAnswer((_) async => Right([reminder('1', ReminderType.custom)]));
      },
      act: (cubit) => cubit.getReminders(),
      expect: () => [isA<RemindersLoading>(), isA<LoadedReminders>()],
    );

    blocTest<RemindersCubit, RemindersState>(
      'emits loading then empty when no reminders',
      build: buildCubit,
      setUp: () {
        stubFamily();
        when(
          () => getReminderUsecase.call('f1', type: any(named: 'type')),
        ).thenAnswer((_) async => const Right([]));
      },
      act: (cubit) => cubit.getReminders(),
      expect: () => [isA<RemindersLoading>(), isA<EmptyReminders>()],
    );

    blocTest<RemindersCubit, RemindersState>(
      'emits error when usecase fails',
      build: buildCubit,
      setUp: () {
        stubFamily();
        when(
          () => getReminderUsecase.call('f1', type: any(named: 'type')),
        ).thenAnswer((_) async => Left(Failure(message: 'boom')));
      },
      act: (cubit) => cubit.getReminders(),
      expect: () => [isA<RemindersLoading>(), isA<ReminderError>()],
    );

    blocTest<RemindersCubit, RemindersState>(
      'emits empty when there is no family',
      build: buildCubit,
      setUp: () {
        when(() => authService.currentUserId).thenReturn(null);
        when(
          () => peopleRepository.getMyFamilyRole(),
        ).thenAnswer((_) async => []);
      },
      act: (cubit) => cubit.getReminders(),
      expect: () => [isA<RemindersLoading>(), isA<EmptyReminders>()],
    );

    blocTest<RemindersCubit, RemindersState>(
      'emits empty when a logged-in user has no family',
      build: buildCubit,
      setUp: () {
        when(() => authService.currentUserId).thenReturn('u1');
        when(
          () => peopleRepository.getFamilyIdsForUser('u1'),
        ).thenAnswer((_) async => <String>[]);
        when(
          () => peopleRepository.getMyFamilyRole(),
        ).thenAnswer((_) async => <String>[]);
      },
      act: (cubit) => cubit.getReminders(),
      expect: () => [isA<RemindersLoading>(), isA<EmptyReminders>()],
    );

    blocTest<RemindersCubit, RemindersState>(
      're-emits loading when refreshing from loaded state',
      build: buildCubit,
      seed: () => LoadedReminders(
        reminders: [reminder('9', ReminderType.custom)],
      ),
      setUp: () {
        stubFamily();
        when(
          () => getReminderUsecase.call('f1', type: any(named: 'type')),
        ).thenAnswer((_) async => Right([reminder('1', ReminderType.custom)]));
      },
      act: (cubit) => cubit.getReminders(),
      expect: () => [
        isA<LoadedReminders>().having(
          (s) => s.isLoading,
          'isLoading',
          isTrue,
        ),
        isA<LoadedReminders>().having(
          (s) => s.reminders.length,
          'length',
          1,
        ),
      ],
    );

    blocTest<RemindersCubit, RemindersState>(
      're-emits loading when refreshing from empty state',
      build: buildCubit,
      seed: EmptyReminders.new,
      setUp: () {
        stubFamily();
        when(
          () => getReminderUsecase.call('f1', type: any(named: 'type')),
        ).thenAnswer((_) async => const Right([]));
      },
      act: (cubit) => cubit.getReminders(),
      expect: () => [
        isA<EmptyReminders>().having((s) => s.isLoading, 'isLoading', isTrue),
        isA<EmptyReminders>(),
      ],
    );
  });

  group('RemindersCubit.removeReminder', () {
    ReminderEntity reminder(String id) => ReminderEntity(
      title: 'T $id',
      body: '',
      id: id,
      type: ReminderType.custom,
      dueDate: '19/08/2026',
      repeatRule: 'never',
      status: 'pending',
      createdBy: 'Mom',
      createdAt: '',
    );

    blocTest<RemindersCubit, RemindersState>(
      're-emits loaded state when removal fails',
      build: buildCubit,
      seed: () => LoadedReminders(
        reminders: [reminder('1'), reminder('2')],
      ),
      setUp: () {
        when(
          () => reminderRepository.removeReminder('1'),
        ).thenAnswer((_) async => Left(Failure(message: 'boom')));
      },
      act: (cubit) => cubit.removeReminder('1'),
      expect: () => [
        isA<LoadedReminders>()
            .having((s) => s.reminders.length, 'length', 2)
            .having((s) => s.isLoading, 'isLoading', isFalse),
      ],
    );

    blocTest<RemindersCubit, RemindersState>(
      'reloads when removal succeeds without a loaded list',
      build: buildCubit,
      seed: EmptyReminders.new,
      setUp: () {
        stubFamily();
        when(
          () => reminderRepository.removeReminder('1'),
        ).thenAnswer((_) async => const Right(true));
        when(
          () => getReminderUsecase.call('f1', type: any(named: 'type')),
        ).thenAnswer((_) async => const Right([]));
      },
      act: (cubit) => cubit.removeReminder('1'),
      wait: const Duration(milliseconds: 100),
      expect: () => [
        isA<EmptyReminders>().having((s) => s.isLoading, 'isLoading', isTrue),
        isA<EmptyReminders>().having((s) => s.isLoading, 'isLoading', isFalse),
      ],
    );

    blocTest<RemindersCubit, RemindersState>(
      'removes item from loaded list on success',
      build: buildCubit,
      setUp: () {
        when(() => authService.currentUserId).thenReturn('u1');
        when(
          () => peopleRepository.getFamilyIdsForUser('u1'),
        ).thenAnswer((_) async => ['f1']);
        when(
          () => peopleRepository.getMyFamilyRole(),
        ).thenAnswer((_) async => ['member']);
        when(
          () => peopleRepository.getProfilesWithRoleForFamily('f1'),
        ).thenAnswer((_) async => []);
        when(
          () => getReminderUsecase.call('f1', type: any(named: 'type')),
        ).thenAnswer((_) async => Right([reminder('1'), reminder('2')]));
        when(
          () => reminderRepository.removeReminder('1'),
        ).thenAnswer((_) async => const Right(true));
      },
      act: (cubit) async {
        await cubit.getReminders();
        await cubit.removeReminder('1');
      },
      expect: () => [
        isA<RemindersLoading>(),
        isA<LoadedReminders>().having((s) => s.reminders.length, 'length', 2),
        isA<LoadedReminders>()
            .having((s) => s.reminders.length, 'length', 1)
            .having((s) => s.reminders.first.id, 'remaining id', '2'),
      ],
    );

    blocTest<RemindersCubit, RemindersState>(
      'emits empty when the last reminder is removed',
      build: buildCubit,
      setUp: () {
        when(() => authService.currentUserId).thenReturn('u1');
        when(
          () => peopleRepository.getFamilyIdsForUser('u1'),
        ).thenAnswer((_) async => ['f1']);
        when(
          () => peopleRepository.getMyFamilyRole(),
        ).thenAnswer((_) async => ['member']);
        when(
          () => peopleRepository.getProfilesWithRoleForFamily('f1'),
        ).thenAnswer((_) async => []);
        when(
          () => getReminderUsecase.call('f1', type: any(named: 'type')),
        ).thenAnswer((_) async => Right([reminder('1')]));
        when(
          () => reminderRepository.removeReminder('1'),
        ).thenAnswer((_) async => const Right(true));
      },
      act: (cubit) async {
        await cubit.getReminders();
        await cubit.removeReminder('1');
      },
      expect: () => [
        isA<RemindersLoading>(),
        isA<LoadedReminders>(),
        isA<EmptyReminders>(),
      ],
    );

    blocTest<RemindersCubit, RemindersState>(
      'cancels the scheduled notification on delete',
      build: () => RemindersCubit(
        getReminderUsecase: getReminderUsecase,
        peopleRepository: peopleRepository,
        authService: authService,
        reminderRepository: reminderRepository,
        notificationService: notificationService,
      ),
      setUp: () {
        when(() => authService.currentUserId).thenReturn('u1');
        when(
          () => peopleRepository.getFamilyIdsForUser('u1'),
        ).thenAnswer((_) async => ['f1']);
        when(
          () => peopleRepository.getMyFamilyRole(),
        ).thenAnswer((_) async => ['member']);
        when(
          () => peopleRepository.getProfilesWithRoleForFamily('f1'),
        ).thenAnswer((_) async => []);
        when(
          () => getReminderUsecase.call('f1', type: any(named: 'type')),
        ).thenAnswer((_) async => Right([reminder('1')]));
        when(
          () => reminderRepository.removeReminder('1'),
        ).thenAnswer((_) async => const Right(true));
        when(
          () => notificationService.cancelReminderNotification('1'),
        ).thenAnswer((_) async {});
      },
      act: (cubit) async {
        await cubit.getReminders();
        await cubit.removeReminder('1');
      },
      expect: () => [
        isA<RemindersLoading>(),
        isA<LoadedReminders>(),
        isA<EmptyReminders>(),
      ],
      verify: (_) {
        verify(
          () => notificationService.cancelReminderNotification('1'),
        ).called(1);
      },
    );
  });

  group('RemindersCubit filters', () {
    test('getFilteredReminders returns all when no filter set', () {
      final cubit = buildCubit();
      addTearDown(cubit.close);
      final all = [
        const ReminderEntity(
          title: 'A',
          body: '',
          id: '1',
          type: ReminderType.chores,
          dueDate: '',
          repeatRule: 'never',
          status: 'pending',
          createdBy: '',
          createdAt: '',
        ),
      ];
      expect(cubit.getFilteredReminders(all), all);
    });

    test('setFilterTypes filters by selected types', () {
      final cubit = buildCubit();
      addTearDown(cubit.close);
      cubit.setFilterTypes({ReminderType.chores});
      expect(cubit.filterTypes, {ReminderType.chores});
      final all = [
        const ReminderEntity(
          title: 'A',
          body: '',
          id: '1',
          type: ReminderType.chores,
          dueDate: '',
          repeatRule: 'never',
          status: 'pending',
          createdBy: '',
          createdAt: '',
        ),
        const ReminderEntity(
          title: 'B',
          body: '',
          id: '2',
          type: ReminderType.birthday,
          dueDate: '',
          repeatRule: 'never',
          status: 'pending',
          createdBy: '',
          createdAt: '',
        ),
      ];
      expect(cubit.getFilteredReminders(all), hasLength(1));
    });

    blocTest<RemindersCubit, RemindersState>(
      'setFilterTypes re-emits loaded state with filters',
      build: buildCubit,
      seed: () => LoadedReminders(
        reminders: [
          const ReminderEntity(
            title: 'A',
            body: '',
            id: '1',
            type: ReminderType.chores,
            dueDate: '',
            repeatRule: 'never',
            status: 'pending',
            createdBy: '',
            createdAt: '',
          ),
        ],
      ),
      act: (cubit) => cubit.setFilterTypes({ReminderType.chores}),
      expect: () => [
        isA<LoadedReminders>().having(
          (s) => s.filterTypes,
          'filterTypes',
          {ReminderType.chores},
        ),
      ],
    );

    blocTest<RemindersCubit, RemindersState>(
      'setFilterTypes re-emits empty state with filters',
      build: buildCubit,
      seed: EmptyReminders.new,
      act: (cubit) => cubit.setFilterTypes({ReminderType.chores}),
      expect: () => [
        isA<EmptyReminders>().having(
          (s) => s.filterTypes,
          'filterTypes',
          {ReminderType.chores},
        ),
      ],
    );

    blocTest<RemindersCubit, RemindersState>(
      'setFilterTypes re-emits loading state with filters',
      build: buildCubit,
      seed: RemindersLoading.new,
      act: (cubit) => cubit.setFilterTypes({ReminderType.chores}),
      expect: () => [
        isA<RemindersLoading>().having(
          (s) => s.filterTypes,
          'filterTypes',
          {ReminderType.chores},
        ),
      ],
    );

    blocTest<RemindersCubit, RemindersState>(
      'setFilterTypes re-emits error state with filters',
      build: buildCubit,
      seed: ReminderError.new,
      act: (cubit) => cubit.setFilterTypes({ReminderType.chores}),
      expect: () => [
        isA<ReminderError>().having(
          (s) => s.filterTypes,
          'filterTypes',
          {ReminderType.chores},
        ),
      ],
    );
  });

  group('RemindersCubit.toggleViewMode', () {
    test('exposes the initial selection state', () {
      final cubit = buildCubit();
      addTearDown(cubit.close);

      expect(cubit.selectedType, isNull);
      expect(cubit.filterTypes, isEmpty);
      expect(cubit.myRole, isNull);
      expect(cubit.viewMode, RemindersViewMode.list);
    });

    blocTest<RemindersCubit, RemindersState>(
      'preserves empty state when toggling',
      build: buildCubit,
      seed: EmptyReminders.new,
      act: (cubit) => cubit.toggleViewMode(),
      expect: () => [
        isA<EmptyReminders>().having(
          (state) => state.viewMode,
          'viewMode',
          RemindersViewMode.calendar,
        ),
      ],
    );

    blocTest<RemindersCubit, RemindersState>(
      'preserves error state when toggling',
      build: buildCubit,
      seed: ReminderError.new,
      act: (cubit) => cubit.toggleViewMode(),
      expect: () => [
        isA<ReminderError>().having(
          (state) => state.viewMode,
          'viewMode',
          RemindersViewMode.calendar,
        ),
      ],
    );

    blocTest<RemindersCubit, RemindersState>(
      'flips from list to calendar on initial state',
      build: buildCubit,
      act: (cubit) => cubit.toggleViewMode(),
      expect: () => [
        isA<ReminderInitialState>().having(
          (state) => state.viewMode,
          'viewMode',
          RemindersViewMode.calendar,
        ),
      ],
    );

    blocTest<RemindersCubit, RemindersState>(
      'toggles back to list on second call',
      build: buildCubit,
      act: (cubit) {
        cubit
          ..toggleViewMode()
          ..toggleViewMode();
      },
      expect: () => [
        isA<ReminderInitialState>().having(
          (state) => state.viewMode,
          'viewMode',
          RemindersViewMode.calendar,
        ),
        isA<ReminderInitialState>().having(
          (state) => state.viewMode,
          'viewMode',
          RemindersViewMode.list,
        ),
      ],
    );

    blocTest<RemindersCubit, RemindersState>(
      'preserves loaded reminders when toggling',
      build: () {
        when(() => authService.currentUserId).thenReturn('u1');
        when(
          () => peopleRepository.getFamilyIdsForUser('u1'),
        ).thenAnswer((_) async => ['f1']);
        when(
          () => peopleRepository.getMyFamilyRole(),
        ).thenAnswer((_) async => ['admin']);
        when(
          () => peopleRepository.getProfilesWithRoleForFamily('f1'),
        ).thenAnswer((_) async => []);
        const reminder = ReminderEntity(
          title: 'Take meds',
          body: '',
          id: '1',
          type: ReminderType.appointment,
          dueDate: '19/08/2026',
          repeatRule: 'never',
          status: 'pending',
          createdBy: 'Mom',
          createdAt: '',
        );
        when(
          () => getReminderUsecase.call('f1', type: any(named: 'type')),
        ).thenAnswer((_) async => const Right([reminder]));
        return buildCubit();
      },
      act: (cubit) async {
        await cubit.getReminders();
        cubit.toggleViewMode();
      },
      expect: () => [
        isA<RemindersLoading>(),
        isA<LoadedReminders>()
            .having((state) => state.reminders.length, 'reminders.length', 1)
            .having(
              (state) => state.viewMode,
              'viewMode',
              RemindersViewMode.list,
            ),
        isA<LoadedReminders>()
            .having((state) => state.reminders.length, 'reminders.length', 1)
            .having(
              (state) => state.viewMode,
              'viewMode',
              RemindersViewMode.calendar,
            ),
      ],
    );
  });
}

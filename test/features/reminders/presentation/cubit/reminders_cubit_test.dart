import 'package:bloc_test/bloc_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vita_folder_mobile/core/auth/auth_service.dart';
import 'package:vita_folder_mobile/features/people/domain/repository/people_repository.dart';
import 'package:vita_folder_mobile/features/reminders/domain/entities/reminder_entity.dart';
import 'package:vita_folder_mobile/features/reminders/domain/entities/reminder_type.dart';
import 'package:vita_folder_mobile/features/reminders/domain/repository/reminder_repository.dart';
import 'package:vita_folder_mobile/features/reminders/domain/usecase/get_reminder_usecase.dart';
import 'package:vita_folder_mobile/features/reminders/presentation/cubit/reminders_cubit.dart';
import 'package:vita_folder_mobile/features/reminders/presentation/cubit/reminders_state.dart';
import 'package:vita_folder_mobile/features/reminders/presentation/cubit/reminders_view_mode.dart';

class _FakePeopleRepository extends Mock implements PeopleRepository {}

class _FakeAuthService extends Mock implements AuthService {}

class _FakeGetReminderUsecase extends Mock implements GetReminderUsecase {}

class _FakeReminderRepository extends Mock implements ReminderRepository {}

void main() {
  late _FakePeopleRepository peopleRepository;
  late _FakeAuthService authService;
  late _FakeGetReminderUsecase getReminderUsecase;
  late _FakeReminderRepository reminderRepository;

  setUp(() {
    peopleRepository = _FakePeopleRepository();
    authService = _FakeAuthService();
    getReminderUsecase = _FakeGetReminderUsecase();
    reminderRepository = _FakeReminderRepository();
  });

  RemindersCubit buildCubit() => RemindersCubit(
    getReminderUsecase: getReminderUsecase,
    peopleRepository: peopleRepository,
    authService: authService,
    reminderRepository: reminderRepository,
  );

  group('RemindersCubit.toggleViewMode', () {
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
        cubit.toggleViewMode();
        cubit.toggleViewMode();
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
        final reminder = ReminderEntity(
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
        ).thenAnswer((_) async => Right([reminder]));
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

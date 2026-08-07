import 'package:bloc_test/bloc_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vita_folder_mobile/core/auth/auth_service.dart';
import 'package:vita_folder_mobile/core/errors/failure.dart';
import 'package:vita_folder_mobile/features/home/domain/entities/home_entity.dart';
import 'package:vita_folder_mobile/features/home/domain/usecase/get_home_data_usecase.dart';
import 'package:vita_folder_mobile/features/home/presentation/cubit/home_cubit.dart';
import 'package:vita_folder_mobile/features/home/presentation/cubit/home_state.dart';
import 'package:vita_folder_mobile/features/people/domain/repository/people_repository.dart';
import 'package:vita_folder_mobile/features/reminders/domain/entities/reminder_entity.dart';
import 'package:vita_folder_mobile/features/reminders/domain/entities/reminder_type.dart';
import 'package:vita_folder_mobile/features/reminders/domain/repository/reminder_repository.dart';

class _MockGetHomeDataUsecase extends Mock implements GetHomeDataUsecase {}

class _MockReminderRepository extends Mock implements ReminderRepository {}

class _MockPeopleRepository extends Mock implements PeopleRepository {}

class _MockAuthService extends Mock implements AuthService {}

void main() {
  late GetHomeDataUsecase usecase;
  late ReminderRepository reminderRepository;
  late PeopleRepository peopleRepository;
  late AuthService authService;
  late HomeCubit cubit;

  final tEntity = HomeEntity(
    greeting: 'Good morning!',
    date: 'Monday, July 13',
    message: 'You have 3 tasks remaining today.',
    peopleInCircle: [],
  );

  setUp(() {
    usecase = _MockGetHomeDataUsecase();
    reminderRepository = _MockReminderRepository();
    peopleRepository = _MockPeopleRepository();
    authService = _MockAuthService();

    when(() => authService.currentUserId).thenReturn('user-id');
    when(() => peopleRepository.getFamilyIdsForUser('user-id'))
        .thenAnswer((_) async => ['family-id']);
    when(() => reminderRepository.getReminders('family-id'))
        .thenAnswer((_) async => const Right(<ReminderEntity>[]));

    cubit = HomeCubit(
      getHomeDataUsecase: usecase,
      reminderRepository: reminderRepository,
      peopleRepository: peopleRepository,
      authService: authService,
    );
  });

  tearDown(() {
    cubit.close();
  });

  group('HomeCubit', () {
    test('initial state is HomeInitial', () {
      expect(cubit.state, isA<HomeInitial>());
    });

    blocTest<HomeCubit, HomeState>(
      'emits [HomeLoading, HomeLoaded] when getHomeData succeeds',
      setUp: () {
        when(() => usecase()).thenAnswer(
          (_) async => Right(tEntity),
        );
      },
      build: () => cubit,
      act: (cubit) => cubit.getHomeData(),
      expect: () => [
        isA<HomeLoading>(),
        isA<HomeLoaded>().having(
          (s) => s.data.greeting,
          'greeting',
          'Good morning!',
        ),
      ],
    );

    blocTest<HomeCubit, HomeState>(
      'emits [HomeLoading, HomeLoaded] with reminders flag when reminders exist',
      setUp: () {
        when(() => usecase()).thenAnswer(
          (_) async => Right(tEntity),
        );
        when(() => reminderRepository.getReminders('family-id')).thenAnswer(
          (_) async => Right([
            ReminderEntity(
              title: 'Dentist',
              body: 'Appointment',
              id: '1',
              type: ReminderType.appointment,
              dueDate: '2026-08-07',
              repeatRule: 'none',
              status: 'pending',
              createdBy: 'user-id',
              createdAt: '2026-08-06',
            ),
          ]),
        );
      },
      build: () => cubit,
      act: (cubit) => cubit.getHomeData(),
      expect: () => [
        isA<HomeLoading>(),
        isA<HomeLoaded>().having(
          (s) => s.data.hasReminders,
          'hasReminders',
          true,
        ),
      ],
    );

    blocTest<HomeCubit, HomeState>(
      'emits [HomeLoading, HomeEmpty] when NoDataException occurs',
      setUp: () {
        when(() => usecase()).thenAnswer(
          (_) async => Left(NoDataException()),
        );
      },
      build: () => cubit,
      act: (cubit) => cubit.getHomeData(),
      expect: () => [
        isA<HomeLoading>(),
        isA<HomeEmpty>(),
      ],
    );

    blocTest<HomeCubit, HomeState>(
      'emits [HomeLoading, HomeError] when generic exception occurs',
      setUp: () {
        when(() => usecase()).thenAnswer(
          (_) async => Left(Failure()),
        );
      },
      build: () => cubit,
      act: (cubit) => cubit.getHomeData(),
      expect: () => [
        isA<HomeLoading>(),
        isA<HomeError>(),
      ],
    );
  });
}

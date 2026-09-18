import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:house_mira/core/errors/failure.dart';
import 'package:house_mira/features/home/domain/entities/home_entity.dart';
import 'package:house_mira/features/home/domain/usecase/get_home_data_usecase.dart';
import 'package:house_mira/features/home/domain/usecase/has_reminders_usecase.dart';
import 'package:house_mira/features/home/presentation/cubit/home_cubit.dart';
import 'package:house_mira/features/home/presentation/cubit/home_state.dart';
import 'package:mocktail/mocktail.dart';

class _MockGetHomeDataUsecase extends Mock implements GetHomeDataUsecase {}

class _MockHasRemindersUsecase extends Mock implements HasRemindersUsecase {}

void main() {
  late GetHomeDataUsecase usecase;
  late HasRemindersUsecase hasRemindersUsecase;
  late HomeCubit cubit;

  const tEntity = HomeEntity(peopleInCircle: []);

  setUp(() {
    usecase = _MockGetHomeDataUsecase();
    hasRemindersUsecase = _MockHasRemindersUsecase();

    when(
      () => hasRemindersUsecase(),
    ).thenAnswer((_) async => const Right(false));

    cubit = HomeCubit(
      getHomeDataUsecase: usecase,
      hasRemindersUsecase: hasRemindersUsecase,
    );
  });

  tearDown(() async {
    await cubit.close();
  });

  group('HomeCubit', () {
    test('initial state is HomeInitial', () {
      expect(cubit.state, isA<HomeInitial>());
    });

    blocTest<HomeCubit, HomeState>(
      'emits [HomeLoading, HomeLoaded] when getHomeData succeeds',
      setUp: () {
        when(() => usecase()).thenAnswer((_) async => const Right(tEntity));
      },
      build: () => cubit,
      act: (cubit) => cubit.getHomeData(),
      expect: () => [
        isA<HomeLoading>(),
        isA<HomeLoaded>().having(
          (s) => s.data.peopleInCircle,
          'peopleInCircle',
          isEmpty,
        ),
      ],
    );

    blocTest<HomeCubit, HomeState>(
      'emits [HomeLoading, HomeLoaded] with reminders flag '
      'when reminders exist',
      setUp: () {
        when(() => usecase()).thenAnswer((_) async => const Right(tEntity));
        when(
          () => hasRemindersUsecase(),
        ).thenAnswer((_) async => const Right(true));
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
        when(() => usecase()).thenAnswer((_) async => Left(NoDataException()));
      },
      build: () => cubit,
      act: (cubit) => cubit.getHomeData(),
      expect: () => [isA<HomeLoading>(), isA<HomeEmpty>()],
    );

    blocTest<HomeCubit, HomeState>(
      'emits [HomeLoading, HomeError] when generic exception occurs',
      setUp: () {
        when(() => usecase()).thenAnswer((_) async => Left(Failure()));
      },
      build: () => cubit,
      act: (cubit) => cubit.getHomeData(),
      expect: () => [isA<HomeLoading>(), isA<HomeError>()],
    );

    blocTest<HomeCubit, HomeState>(
      'loads without reminders flag when the reminders check fails',
      setUp: () {
        when(() => usecase()).thenAnswer((_) async => const Right(tEntity));
        when(
          () => hasRemindersUsecase(),
        ).thenAnswer((_) async => Left(Failure(message: 'boom')));
      },
      build: () => cubit,
      act: (cubit) => cubit.getHomeData(),
      expect: () => [
        isA<HomeLoading>(),
        isA<HomeLoaded>().having(
          (s) => s.data.hasReminders,
          'hasReminders',
          false,
        ),
      ],
    );

    blocTest<HomeCubit, HomeState>(
      'propagates people repository errors instead of falling back to empty',
      setUp: () {
        when(
          () => usecase(),
        ).thenAnswer((_) async => Left(Exception('people failed')));
      },
      build: () => cubit,
      act: (cubit) => cubit.getHomeData(),
      expect: () => [isA<HomeLoading>(), isA<HomeError>()],
    );
  });
}

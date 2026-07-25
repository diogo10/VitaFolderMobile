import 'package:bloc_test/bloc_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vita_folder_mobile/core/errors/failure.dart';
import 'package:vita_folder_mobile/features/home/domain/entities/home_entity.dart';
import 'package:vita_folder_mobile/features/home/domain/usecase/get_home_data_usecase.dart';
import 'package:vita_folder_mobile/features/home/presentation/cubit/home_cubit.dart';
import 'package:vita_folder_mobile/features/home/presentation/cubit/home_state.dart';

class _MockGetHomeDataUsecase extends Mock implements GetHomeDataUsecase {}

void main() {
  late GetHomeDataUsecase usecase;
  late HomeCubit cubit;

  final tEntity = HomeEntity(
    greeting: 'Good morning!',
    date: 'Monday, July 13',
    message: 'You have 3 tasks remaining today.',
    peopleInCircle: [],
  );

  setUp(() {
    usecase = _MockGetHomeDataUsecase();
    cubit = HomeCubit(getHomeDataUsecase: usecase);
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

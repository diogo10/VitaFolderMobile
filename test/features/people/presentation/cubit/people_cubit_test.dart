import 'package:bloc_test/bloc_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vita_folder_mobile/features/people/domain/entities/family_entity.dart';
import 'package:vita_folder_mobile/features/people/domain/entities/people_data.dart';
import 'package:vita_folder_mobile/features/people/domain/entities/person_entity.dart';
import 'package:vita_folder_mobile/features/people/domain/usecase/create_family_usecase.dart';
import 'package:vita_folder_mobile/features/people/domain/usecase/get_people_usecase.dart';
import 'package:vita_folder_mobile/features/people/domain/usecase/join_family_usecase.dart';
import 'package:vita_folder_mobile/features/people/presentation/cubit/people_cubit.dart';
import 'package:vita_folder_mobile/features/people/presentation/cubit/people_state.dart';

class _MockGetPeopleUsecase extends Mock implements GetPeopleUsecase {}

class _MockCreateFamilyUsecase extends Mock implements CreateFamilyUsecase {}

class _MockJoinFamilyUsecase extends Mock implements JoinFamilyUsecase {}

void main() {
  late GetPeopleUsecase getPeopleUsecase;
  late CreateFamilyUsecase createFamilyUsecase;
  late JoinFamilyUsecase joinFamilyUsecase;
  late PeopleCubit cubit;

  final family = FamilyEntity(name: 'The Smiths', inviteCode: 'ABC123');
  final people = [
    PersonEntity(
      id: '1',
      name: 'John',
      email: 'john@example.com',
      role: 'parent',
    ),
    PersonEntity(
      id: '2',
      name: 'Jane',
      email: 'jane@example.com',
      role: 'member',
    ),
  ];
  final data = PeopleData(family: family, people: people);

  setUp(() {
    getPeopleUsecase = _MockGetPeopleUsecase();
    createFamilyUsecase = _MockCreateFamilyUsecase();
    joinFamilyUsecase = _MockJoinFamilyUsecase();

    cubit = PeopleCubit(
      getPeopleUsecase: getPeopleUsecase,
      createFamilyUsecase: createFamilyUsecase,
      joinFamilyUsecase: joinFamilyUsecase,
    );
  });

  tearDown(() {
    cubit.close();
  });

  group('PeopleCubit', () {
    test('initial state is PeopleInitial', () {
      expect(cubit.state, isA<PeopleInitial>());
    });

    group('getPeople', () {
      blocTest<PeopleCubit, PeopleState>(
        'emits [PeopleLoading, PeopleLoaded] when not a refresh',
        setUp: () {
          when(() => getPeopleUsecase()).thenAnswer((_) async => Right(data));
        },
        build: () => cubit,
        act: (cubit) => cubit.getPeople(),
        expect: () => [
          isA<PeopleLoading>(),
          isA<PeopleLoaded>().having(
            (s) => s.people.length,
            'people length',
            2,
          ),
        ],
      );

      blocTest<PeopleCubit, PeopleState>(
        'emits [PeopleLoaded] on refresh without PeopleLoading',
        setUp: () {
          when(() => getPeopleUsecase()).thenAnswer((_) async => Right(data));
        },
        build: () => cubit,
        act: (cubit) => cubit.getPeople(isRefresh: true),
        expect: () => [
          isA<PeopleLoaded>().having(
            (s) => s.inviteCode,
            'inviteCode',
            'ABC123',
          ),
        ],
      );

      blocTest<PeopleCubit, PeopleState>(
        'keeps PeopleEmpty on refresh when family is missing',
        setUp: () {
          when(() => getPeopleUsecase()).thenAnswer(
            (_) async => Right(
              PeopleData(
                family: FamilyEntity(name: '', inviteCode: ''),
                people: [],
              ),
            ),
          );
        },
        build: () => cubit,
        act: (cubit) => cubit.getPeople(isRefresh: true),
        expect: () => [isA<PeopleEmpty>()],
      );

      blocTest<PeopleCubit, PeopleState>(
        'emits [PeopleLoading, PeopleError] when the usecase fails',
        setUp: () {
          when(
            () => getPeopleUsecase(),
          ).thenAnswer((_) async => Left(Exception('boom')));
        },
        build: () => cubit,
        act: (cubit) => cubit.getPeople(),
        expect: () => [isA<PeopleLoading>(), isA<PeopleError>()],
      );

      blocTest<PeopleCubit, PeopleState>(
        'emits [PeopleError] on refresh failure without PeopleLoading',
        setUp: () {
          when(
            () => getPeopleUsecase(),
          ).thenAnswer((_) async => Left(Exception('boom')));
        },
        build: () => cubit,
        act: (cubit) => cubit.getPeople(isRefresh: true),
        expect: () => [isA<PeopleError>()],
      );
    });
  });
}

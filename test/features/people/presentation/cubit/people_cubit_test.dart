import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:house_mira/core/auth/auth_service.dart';
import 'package:house_mira/features/people/domain/entities/family_entity.dart';
import 'package:house_mira/features/people/domain/entities/people_data.dart';
import 'package:house_mira/features/people/domain/entities/person_entity.dart';
import 'package:house_mira/features/people/domain/usecase/create_family_usecase.dart';
import 'package:house_mira/features/people/domain/usecase/get_people_usecase.dart';
import 'package:house_mira/features/people/domain/usecase/join_family_usecase.dart';
import 'package:house_mira/features/people/presentation/cubit/people_cubit.dart';
import 'package:house_mira/features/people/presentation/cubit/people_state.dart';
import 'package:mocktail/mocktail.dart';

class _MockGetPeopleUsecase extends Mock implements GetPeopleUsecase {}

class _MockCreateFamilyUsecase extends Mock implements CreateFamilyUsecase {}

class _MockJoinFamilyUsecase extends Mock implements JoinFamilyUsecase {}

class _MockAuthService extends Mock implements AuthService {}

void main() {
  late GetPeopleUsecase getPeopleUsecase;
  late CreateFamilyUsecase createFamilyUsecase;
  late JoinFamilyUsecase joinFamilyUsecase;
  late AuthService authService;
  late PeopleCubit cubit;

  final family = FamilyEntity(name: 'The Smiths', inviteCode: 'ABC123');
  final people = [
    const PersonEntity(
      id: '1',
      name: 'John',
      email: 'john@example.com',
      role: 'parent',
    ),
    const PersonEntity(
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
    authService = _MockAuthService();

    cubit = PeopleCubit(
      getPeopleUsecase: getPeopleUsecase,
      createFamilyUsecase: createFamilyUsecase,
      joinFamilyUsecase: joinFamilyUsecase,
      authService: authService,
    );
  });

  tearDown(() async {
    await cubit.close();
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

    group('createFamily', () {
      blocTest<PeopleCubit, PeopleState>(
        'reloads people after a successful creation',
        setUp: () {
          when(
            () => createFamilyUsecase(name: 'Fam'),
          ).thenAnswer((_) async => const Right(true));
          when(() => getPeopleUsecase()).thenAnswer((_) async => Right(data));
        },
        build: () => cubit,
        act: (cubit) => cubit.createFamily(name: 'Fam'),
        wait: const Duration(milliseconds: 100),
        expect: () => [
          isA<PeopleLoading>(),
          isA<PeopleLoading>(),
          isA<PeopleLoaded>(),
        ],
      );

      blocTest<PeopleCubit, PeopleState>(
        'emits [PeopleLoading, PeopleError] when creation fails',
        setUp: () {
          when(
            () => createFamilyUsecase(name: 'Fam'),
          ).thenAnswer((_) async => Left(Exception('boom')));
        },
        build: () => cubit,
        act: (cubit) => cubit.createFamily(name: 'Fam'),
        expect: () => [isA<PeopleLoading>(), isA<PeopleError>()],
      );
    });

    group('joinFamily', () {
      blocTest<PeopleCubit, PeopleState>(
        'reloads people after joining with a valid code',
        setUp: () {
          when(
            () => joinFamilyUsecase(familyCode: 'ABC123'),
          ).thenAnswer((_) async => const Right(true));
          when(() => getPeopleUsecase()).thenAnswer((_) async => Right(data));
        },
        build: () => cubit,
        act: (cubit) => cubit.joinFamily(familyCode: 'ABC123'),
        wait: const Duration(milliseconds: 100),
        expect: () => [
          isA<PeopleLoading>(),
          isA<PeopleLoading>(),
          isA<PeopleLoaded>(),
        ],
      );

      blocTest<PeopleCubit, PeopleState>(
        'emits PeopleInvalidFamilyCode when joining fails',
        setUp: () {
          when(
            () => joinFamilyUsecase(familyCode: 'WRONG'),
          ).thenAnswer((_) async => Left(Exception('Invalid family code')));
        },
        build: () => cubit,
        act: (cubit) => cubit.joinFamily(familyCode: 'WRONG'),
        expect: () => [isA<PeopleLoading>(), isA<PeopleInvalidFamilyCode>()],
      );
    });
  });
}

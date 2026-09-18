import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:house_mira/features/people/domain/entities/family_entity.dart';
import 'package:house_mira/features/people/domain/entities/person_entity.dart';
import 'package:house_mira/features/people/domain/repository/people_repository.dart';
import 'package:house_mira/features/people/domain/usecase/get_people_usecase.dart';
import 'package:mocktail/mocktail.dart';

class _MockPeople extends Mock implements PeopleRepository {}

void main() {
  late _MockPeople repository;

  setUp(() => repository = _MockPeople());

  GetPeopleUsecase build() => GetPeopleUsecase(repository: repository);

  test('returns family and people on success', () async {
    final family = FamilyEntity(name: 'Fam', inviteCode: 'ABC');
    final members = [const PersonEntity(id: 'u1', name: 'Ana')];
    when(() => repository.getPeople()).thenAnswer((_) async => Right(members));
    when(() => repository.getMyFamily()).thenAnswer((_) async => Right(family));

    final result = await build()();

    final data = result.getRight().toNullable()!;
    expect(data.family.name, 'Fam');
    expect(data.people, hasLength(1));
  });

  test('falls back to empty family when family fetch fails', () async {
    when(() => repository.getPeople()).thenAnswer((_) async => const Right([]));
    when(
      () => repository.getMyFamily(),
    ).thenAnswer((_) async => Left(Exception('boom')));

    final result = await build()();

    final data = result.getRight().toNullable()!;
    expect(data.family.name, '');
    expect(data.people, isEmpty);
  });

  test('falls back to empty people when people fetch fails', () async {
    when(
      () => repository.getPeople(),
    ).thenAnswer((_) async => Left(Exception('boom')));
    when(() => repository.getMyFamily()).thenAnswer(
      (_) async => Right(FamilyEntity(name: 'Fam', inviteCode: 'ABC')),
    );

    final result = await build()();

    final data = result.getRight().toNullable()!;
    expect(data.family.name, 'Fam');
    expect(data.people, isEmpty);
  });
}

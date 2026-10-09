import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:house_mira/features/people/domain/repository/people_repository.dart';
import 'package:house_mira/features/people/domain/usecase/join_family_usecase.dart';
import 'package:mocktail/mocktail.dart';

class _MockPeopleRepository extends Mock implements PeopleRepository {}

void main() {
  late _MockPeopleRepository repository;
  late JoinFamilyUsecase usecase;

  setUp(() {
    repository = _MockPeopleRepository();
    usecase = JoinFamilyUsecase(repository: repository);
  });

  test('passes the normalized code to the repository', () async {
    when(
      () => repository.joinFamily(inviteCode: 'AB1234'),
    ).thenAnswer((_) async => const Right(true));

    final result = await usecase(familyCode: ' ab-1234 ');

    expect(result.isRight(), isTrue);
    verify(() => repository.joinFamily(inviteCode: 'AB1234')).called(1);
  });

  test('rejects blank codes without touching the repository', () async {
    final result = await usecase(familyCode: '   ');

    expect(result.isLeft(), isTrue);
    verifyNever(
      () => repository.joinFamily(inviteCode: any(named: 'inviteCode')),
    );
  });

  test('rejects malformed codes without touching the repository', () async {
    for (final code in ['ABC12', 'ABC1234', 'AB!234', 'ab']) {
      final result = await usecase(familyCode: code);

      expect(result.isLeft(), isTrue, reason: code);
    }
    verifyNever(
      () => repository.joinFamily(inviteCode: any(named: 'inviteCode')),
    );
  });

  test('propagates repository failure', () async {
    when(
      () => repository.joinFamily(inviteCode: 'ABC123'),
    ).thenAnswer((_) async => Left(Exception('Family not found')));

    final result = await usecase(familyCode: 'ABC123');

    expect(result.isLeft(), isTrue);
  });
}

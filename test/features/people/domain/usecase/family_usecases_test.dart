import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:house_mira/features/people/domain/repository/people_repository.dart';
import 'package:house_mira/features/people/domain/usecase/create_family_usecase.dart';
import 'package:house_mira/features/people/domain/usecase/delete_family_usecase.dart';
import 'package:house_mira/features/people/domain/usecase/get_my_family_id_usecase.dart';
import 'package:house_mira/features/people/domain/usecase/join_family_usecase.dart';
import 'package:house_mira/features/people/domain/usecase/remove_member_usecase.dart';
import 'package:house_mira/features/people/domain/usecase/update_family_name_usecase.dart';
import 'package:mocktail/mocktail.dart';

class _MockPeople extends Mock implements PeopleRepository {}

void main() {
  late _MockPeople repository;

  setUp(() => repository = _MockPeople());

  group('CreateFamilyUsecase', () {
    test('generates a 6-char invite code and delegates creation', () async {
      var capturedCode = '';
      when(
        () => repository.createFamily(
          name: any(named: 'name'),
          inviteCode: any(named: 'inviteCode'),
        ),
      ).thenAnswer((invocation) async {
        capturedCode =
            invocation.namedArguments[const Symbol('inviteCode')] as String;
        return const Right(true);
      });

      final result = await CreateFamilyUsecase(
        repository: repository,
      )(name: 'Fam');

      expect(result.getRight().toNullable(), isTrue);
      expect(capturedCode, hasLength(6));
      expect(capturedCode, matches(RegExp(r'^[A-Z0-9]{6}$')));
      verify(
        () => repository.createFamily(name: 'Fam', inviteCode: capturedCode),
      ).called(1);
    });

    test(
      'maps repository failure to false instead of surfacing the error',
      () async {
        when(
          () => repository.createFamily(
            name: any(named: 'name'),
            inviteCode: any(named: 'inviteCode'),
          ),
        ).thenAnswer((_) async => Left(Exception('boom')));

        final result = await CreateFamilyUsecase(
          repository: repository,
        )(name: 'Fam');

        expect(result.getRight().toNullable(), isFalse);
      },
    );
  });

  group('JoinFamilyUsecase', () {
    test('rejects empty codes without hitting the repository', () async {
      final result = await JoinFamilyUsecase(
        repository: repository,
      )(familyCode: '');

      expect(result.isLeft(), isTrue);
      verifyNever(
        () => repository.joinFamily(inviteCode: any(named: 'inviteCode')),
      );
    });

    test(
      'rejects codes longer than 6 chars without hitting the repository',
      () async {
        final result = await JoinFamilyUsecase(
          repository: repository,
        )(familyCode: 'TOOLONG');

        expect(result.isLeft(), isTrue);
        verifyNever(
          () => repository.joinFamily(inviteCode: any(named: 'inviteCode')),
        );
      },
    );

    test('delegates valid codes to the repository', () async {
      when(() => repository.joinFamily(inviteCode: 'ABC123')).thenAnswer(
        (_) async => const Right(true),
      );

      final result = await JoinFamilyUsecase(
        repository: repository,
      )(familyCode: 'ABC123');

      expect(result.getRight().toNullable(), isTrue);
    });
  });

  group('DeleteFamilyUsecase', () {
    test('delegates to the repository', () async {
      when(() => repository.deleteFamily(familyId: 'f1')).thenAnswer(
        (_) async => const Right(true),
      );

      final result = await DeleteFamilyUsecase(
        repository: repository,
      )(familyId: 'f1');

      expect(result.getRight().toNullable(), isTrue);
    });
  });

  group('GetMyFamilyIdUsecase', () {
    test('delegates to the repository', () async {
      when(() => repository.getMyFamilyId()).thenAnswer(
        (_) async => const Right('f1'),
      );

      final result = await GetMyFamilyIdUsecase(repository: repository)();

      expect(result.getRight().toNullable(), 'f1');
    });
  });

  group('RemoveMemberUsecase', () {
    test('delegates to the repository', () async {
      when(
        () => repository.removeMember(familyId: 'f1', userId: 'u2'),
      ).thenAnswer((_) async => const Right(true));

      final result = await RemoveMemberUsecase(
        repository: repository,
      )(familyId: 'f1', userId: 'u2');

      expect(result.getRight().toNullable(), isTrue);
    });
  });

  group('UpdateFamilyNameUsecase', () {
    test('delegates to the repository', () async {
      when(
        () => repository.updateFamilyName(familyId: 'f1', name: 'New'),
      ).thenAnswer((_) async => const Right(true));

      final result = await UpdateFamilyNameUsecase(
        repository: repository,
      )(familyId: 'f1', name: 'New');

      expect(result.getRight().toNullable(), isTrue);
    });
  });
}

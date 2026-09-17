import 'package:fpdart/fpdart.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:house_mira/core/auth/auth_service.dart';
import 'package:house_mira/core/errors/failure.dart';
import 'package:house_mira/features/home/domain/entities/home_entity.dart';
import 'package:house_mira/features/home/domain/usecase/get_home_data_usecase.dart';
import 'package:house_mira/features/home/domain/usecase/has_reminders_usecase.dart';
import 'package:house_mira/features/people/domain/entities/family_entity.dart';
import 'package:house_mira/features/people/domain/entities/person_entity.dart';
import 'package:house_mira/features/people/domain/repository/people_repository.dart';
import 'package:house_mira/features/reminders/domain/entities/reminder_entity.dart';
import 'package:house_mira/features/reminders/domain/entities/reminder_type.dart';
import 'package:house_mira/features/reminders/domain/repository/reminder_repository.dart';

class _MockAuth extends Mock implements AuthService {}

class _MockPeople extends Mock implements PeopleRepository {}

class _MockReminders extends Mock implements ReminderRepository {}

PersonEntity _person() => PersonEntity(id: 'u1', name: 'Ana');

ReminderEntity _reminder() => ReminderEntity(
  id: '1',
  title: 'T',
  body: 'B',
  type: ReminderType.custom,
  dueDate: '',
  repeatRule: 'never',
  status: 'pending',
  createdBy: 'u1',
  createdAt: '',
);

void main() {
  group('GetHomeDataUsecase', () {
    late _MockAuth auth;
    late _MockPeople people;
    late _MockReminders reminders;

    setUp(() {
      auth = _MockAuth();
      people = _MockPeople();
      reminders = _MockReminders();
    });

    GetHomeDataUsecase build() => GetHomeDataUsecase(
      peopleRepository: people,
      reminderRepository: reminders,
      authService: auth,
    );

    test('returns NoDataException when logged out', () async {
      when(() => auth.isLoggedIn()).thenReturn(false);

      final result = await build()();

      expect(result.isLeft(), isTrue);
      expect(result.getLeft().toNullable(), isA<NoDataException>());
    });

    test('returns people error without querying family/reminders', () async {
      when(() => auth.isLoggedIn()).thenReturn(true);
      when(
        () => people.getPeople(),
      ).thenAnswer((_) async => Left(Exception('boom')));

      final result = await build()();

      expect(result.isLeft(), isTrue);
      verifyNever(() => people.getMyFamily());
    });

    test('returns home data with reminders', () async {
      when(() => auth.isLoggedIn()).thenReturn(true);
      when(() => auth.currentUserId).thenReturn('u1');
      when(
        () => people.getPeople(),
      ).thenAnswer((_) async => Right([_person()]));
      when(() => people.getMyFamily()).thenAnswer(
        (_) async => Right(FamilyEntity(name: 'Fam', inviteCode: 'ABC')),
      );
      when(() => people.getMyFamilyRole()).thenAnswer((_) async => ['admin']);
      when(
        () => people.getFamilyIdsForUser('u1'),
      ).thenAnswer((_) async => ['f1']);
      when(() => reminders.getReminders('f1')).thenAnswer(
        (_) async => Right<Failure, List<ReminderEntity>>([_reminder()]),
      );

      final result = await build()();

      expect(result.isRight(), isTrue);
      final HomeEntity home = result.getRight().toNullable()!;
      expect(home.familyName, 'Fam');
      expect(home.activeMembers, 1);
      expect(home.hasReminders, isTrue);
      expect(home.reminders, hasLength(1));
    });

    test('falls back to an empty family when the family fetch fails', () async {
      when(() => auth.isLoggedIn()).thenReturn(true);
      when(() => auth.currentUserId).thenReturn('u1');
      when(
        () => people.getPeople(),
      ).thenAnswer((_) async => Right([_person()]));
      when(
        () => people.getMyFamily(),
      ).thenAnswer((_) async => Left(Exception('boom')));
      when(() => people.getMyFamilyRole()).thenAnswer((_) async => []);
      when(
        () => people.getFamilyIdsForUser('u1'),
      ).thenAnswer((_) async => <String>[]);

      final result = await build()();

      final HomeEntity home = result.getRight().toNullable()!;
      expect(home.familyName, '');
      expect(home.reminders, isEmpty);
      expect(home.hasReminders, isFalse);
    });

    test('tolerates reminder fetch failure as empty list', () async {
      when(() => auth.isLoggedIn()).thenReturn(true);
      when(() => auth.currentUserId).thenReturn('u1');
      when(
        () => people.getPeople(),
      ).thenAnswer((_) async => Right([_person()]));
      when(() => people.getMyFamily()).thenAnswer(
        (_) async => Right(FamilyEntity(name: 'Fam', inviteCode: 'ABC')),
      );
      when(() => people.getMyFamilyRole()).thenAnswer((_) async => []);
      when(
        () => people.getFamilyIdsForUser('u1'),
      ).thenAnswer((_) async => ['f1']);
      when(
        () => reminders.getReminders('f1'),
      ).thenAnswer((_) async => Left(Failure(message: 'boom')));

      final result = await build()();

      final HomeEntity home = result.getRight().toNullable()!;
      expect(home.hasReminders, isFalse);
      expect(home.myRole, '');
    });
  });

  group('HasRemindersUsecase', () {
    late _MockAuth auth;
    late _MockPeople people;
    late _MockReminders reminders;

    setUp(() {
      auth = _MockAuth();
      people = _MockPeople();
      reminders = _MockReminders();
    });

    HasRemindersUsecase build() => HasRemindersUsecase(
      authService: auth,
      peopleRepository: people,
      reminderRepository: reminders,
    );

    test('returns false when no user', () async {
      when(() => auth.currentUserId).thenReturn(null);

      expect((await build()()).getRight().toNullable(), isFalse);
    });

    test('returns false when user has no family', () async {
      when(() => auth.currentUserId).thenReturn('u1');
      when(() => people.getFamilyIdsForUser('u1')).thenAnswer((_) async => []);

      expect((await build()()).getRight().toNullable(), isFalse);
    });

    test('maps empty reminders to false and non-empty to true', () async {
      when(() => auth.currentUserId).thenReturn('u1');
      when(
        () => people.getFamilyIdsForUser('u1'),
      ).thenAnswer((_) async => ['f1']);
      when(
        () => reminders.getReminders('f1'),
      ).thenAnswer((_) async => const Right<Failure, List<ReminderEntity>>([]));
      expect((await build()()).getRight().toNullable(), isFalse);

      when(() => reminders.getReminders('f1')).thenAnswer(
        (_) async => Right<Failure, List<ReminderEntity>>([_reminder()]),
      );
      expect((await build()()).getRight().toNullable(), isTrue);
    });
  });
}

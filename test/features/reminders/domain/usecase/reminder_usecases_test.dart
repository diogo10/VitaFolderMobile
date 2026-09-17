import 'package:fpdart/fpdart.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:house_mira/core/errors/failure.dart';
import 'package:house_mira/features/people/domain/entities/person_entity.dart';
import 'package:house_mira/features/people/domain/repository/people_repository.dart';
import 'package:house_mira/features/reminders/data/models/reminder_model.dart';
import 'package:house_mira/features/reminders/domain/entities/reminder_entity.dart';
import 'package:house_mira/features/reminders/domain/entities/reminder_type.dart';
import 'package:house_mira/features/reminders/domain/repository/reminder_repository.dart';
import 'package:house_mira/features/reminders/domain/usecase/create_reminder_usecase.dart';
import 'package:house_mira/features/reminders/domain/usecase/get_reminder_usecase.dart';
import 'package:house_mira/features/reminders/domain/usecase/update_reminder_usecase.dart';

class _MockReminders extends Mock implements ReminderRepository {}

class _MockPeople extends Mock implements PeopleRepository {}

ReminderModel model() => ReminderModel(
  title: 'T',
  body: 'B',
  id: '',
  type: ReminderType.custom,
  dueDate: '',
  repeatRule: 'never',
  status: 'pending',
  createdBy: 'u1',
  createdAt: '',
);

ReminderEntity entity({String id = '1', String createdBy = 'u1'}) =>
    ReminderEntity(
      title: 'T $id',
      body: '',
      id: id,
      type: ReminderType.custom,
      dueDate: '',
      repeatRule: 'never',
      status: 'pending',
      createdBy: createdBy,
      createdAt: '',
    );

void main() {
  late _MockReminders reminders;
  late _MockPeople people;

  setUpAll(() {
    registerFallbackValue(model());
    registerFallbackValue(ReminderType.custom);
  });

  setUp(() {
    reminders = _MockReminders();
    people = _MockPeople();
  });

  group('CreateReminderUsecase', () {
    test('delegates creation and returns the new id', () async {
      when(() => reminders.createReminder(any(), 'f1')).thenAnswer(
        (_) async => const Right('new-id'),
      );

      final result = await CreateReminderUsecase(repository: reminders)(
        model(),
        'f1',
      );

      expect(result.getRight().toNullable(), 'new-id');
    });

    test('propagates repository failures', () async {
      when(() => reminders.createReminder(any(), 'f1')).thenAnswer(
        (_) async => Left(Failure(message: 'boom')),
      );

      final result = await CreateReminderUsecase(repository: reminders)(
        model(),
        'f1',
      );

      expect(result.isLeft(), isTrue);
      expect(result.getLeft().toNullable()?.message, 'boom');
    });
  });

  group('UpdateReminderUsecase', () {
    test('delegates the update', () async {
      when(
        () => reminders.updateReminder(any()),
      ).thenAnswer((_) async => const Right(true));

      final result = await UpdateReminderUsecase(repository: reminders)(
        model(),
      );

      expect(result.getRight().toNullable(), isTrue);
    });

    test('propagates repository failures', () async {
      when(() => reminders.updateReminder(any())).thenAnswer(
        (_) async => Left(Failure(message: 'boom')),
      );

      final result = await UpdateReminderUsecase(repository: reminders)(
        model(),
      );

      expect(result.isLeft(), isTrue);
      expect(result.getLeft().toNullable()?.message, 'boom');
    });
  });

  group('GetReminderUsecase', () {
    void stubPeople(List<PersonEntity> members) {
      when(
        () => people.getProfilesWithRoleForFamily('f1'),
      ).thenAnswer((_) async => members);
    }

    test('fetches unfiltered reminders and resolves creator names', () async {
      when(() => reminders.getReminders('f1')).thenAnswer(
        (_) async => Right<Failure, List<ReminderEntity>>([
          entity(id: '1'),
          entity(id: '2', createdBy: 'unknown'),
        ]),
      );
      stubPeople([PersonEntity(id: 'u1', name: 'Mom')]);

      final result = await GetReminderUsecase(
        repository: reminders,
        peopleRepository: people,
      )('f1');

      final list = result.getRight().toNullable()!;
      expect(list, hasLength(2));
      expect(list.first.createdBy, 'Mom');
      // Unknown creators keep their raw id instead of a fallback name.
      expect(list.last.createdBy, 'unknown');
      verifyNever(
        () => reminders.getRemindersByTypeAndFamily(
          type: any(named: 'type'),
          familyId: any(named: 'familyId'),
        ),
      );
    });

    test('fetches reminders filtered by type', () async {
      when(
        () => reminders.getRemindersByTypeAndFamily(
          type: ReminderType.chores,
          familyId: 'f1',
        ),
      ).thenAnswer(
        (_) async => Right<Failure, List<ReminderEntity>>([entity()]),
      );
      stubPeople(const []);

      final result = await GetReminderUsecase(
        repository: reminders,
        peopleRepository: people,
      )('f1', type: ReminderType.chores);

      expect(result.getRight().toNullable(), hasLength(1));
      verifyNever(() => reminders.getReminders(any()));
    });

    test('maps repository failures to Failure', () async {
      when(() => reminders.getReminders('f1')).thenAnswer(
        (_) async => Left(Failure(message: 'boom')),
      );

      final result = await GetReminderUsecase(
        repository: reminders,
        peopleRepository: people,
      )('f1');

      expect(result.isLeft(), isTrue);
      expect(result.getLeft().toNullable(), isA<Failure>());
    });

    test('maps filtered repository failures to Failure', () async {
      when(
        () => reminders.getRemindersByTypeAndFamily(
          type: ReminderType.chores,
          familyId: 'f1',
        ),
      ).thenAnswer((_) async => Left(Failure(message: 'boom')));

      final result = await GetReminderUsecase(
        repository: reminders,
        peopleRepository: people,
      )('f1', type: ReminderType.chores);

      expect(result.isLeft(), isTrue);
      expect(result.getLeft().toNullable()?.message, 'boom');
    });

    test('keeps reminders whose creator id is missing', () async {
      when(() => reminders.getReminders('f1')).thenAnswer(
        (_) async => Right<Failure, List<ReminderEntity>>([entity()]),
      );
      stubPeople([PersonEntity(name: 'Nameless')]);

      final result = await GetReminderUsecase(
        repository: reminders,
        peopleRepository: people,
      )('f1');

      // A profile without an id never matches: the raw id is preserved.
      expect(result.getRight().toNullable()!.single.createdBy, 'u1');
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:house_mira/core/errors/failure.dart';
import 'package:house_mira/core/subscriptions/subscription_service.dart';
import 'package:house_mira/features/reminders/application/is_at_reminder_limit_usecase.dart';
import 'package:house_mira/features/reminders/domain/entities/reminder_entity.dart';
import 'package:house_mira/features/reminders/domain/entities/reminder_type.dart';
import 'package:house_mira/features/reminders/domain/repository/reminder_repository.dart';
import 'package:mocktail/mocktail.dart';

class _MockSubscriptions extends Mock implements SubscriptionService {}

class _MockReminders extends Mock implements ReminderRepository {}

ReminderEntity row(String id) => ReminderEntity(
  title: 'T',
  body: '',
  id: id,
  type: ReminderType.custom,
  dueDate: '',
  repeatRule: 'never',
  status: 'pending',
  createdBy: 'u1',
  createdAt: '',
);

void main() {
  late _MockSubscriptions subscriptions;
  late _MockReminders reminders;

  setUp(() {
    subscriptions = _MockSubscriptions();
    reminders = _MockReminders();
    when(() => subscriptions.isPro()).thenAnswer((_) async => false);
  });

  IsAtReminderLimitUsecase build() => IsAtReminderLimitUsecase(
    subscriptionService: subscriptions,
    reminderRepository: reminders,
  );

  test('paid users never hit the cap (no count lookup)', () async {
    when(() => subscriptions.isPro()).thenAnswer((_) async => true);
    expect(await build()(familyId: 'f1'), isFalse);
    verifyNever(() => reminders.getReminders(any()));
  });

  test('null familyId fails open', () async {
    expect(await build()(familyId: null), isFalse);
    verifyNever(() => reminders.getReminders(any()));
  });

  test('true at cap, false below cap', () async {
    when(() => reminders.getReminders('f1')).thenAnswer(
      (_) async => Right<Failure, List<ReminderEntity>>(
        List.generate(10, (i) => row('r$i')),
      ),
    );
    expect(await build()(familyId: 'f1'), isTrue);

    when(() => reminders.getReminders('f1')).thenAnswer(
      (_) async => Right<Failure, List<ReminderEntity>>(
        List.generate(9, (i) => row('r$i')),
      ),
    );
    expect(await build()(familyId: 'f1'), isFalse);
  });

  test('count lookup failure fails open', () async {
    when(() => reminders.getReminders('f1')).thenAnswer(
      (_) async => Left(Failure(message: 'boom')),
    );
    expect(await build()(familyId: 'f1'), isFalse);
  });

  test('billing lookup throw fails open', () async {
    when(() => subscriptions.isPro()).thenThrow(Exception('billing down'));
    expect(await build()(familyId: 'f1'), isFalse);
  });

  test('count lookup throw fails open', () async {
    when(() => reminders.getReminders('f1')).thenThrow(Exception('db down'));
    expect(await build()(familyId: 'f1'), isFalse);
  });
}

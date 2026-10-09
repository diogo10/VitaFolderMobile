import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:house_mira/core/errors/failure.dart';
import 'package:house_mira/core/subscriptions/subscription_service.dart';
import 'package:house_mira/features/reminders/application/is_at_reminder_limit_usecase.dart';
import 'package:house_mira/features/reminders/domain/repository/reminder_repository.dart';
import 'package:mocktail/mocktail.dart';

class _MockSubscriptions extends Mock implements SubscriptionService {}

class _MockReminders extends Mock implements ReminderRepository {}

void main() {
  late _MockSubscriptions subscriptions;
  late _MockReminders reminders;

  setUp(() {
    subscriptions = _MockSubscriptions();
    reminders = _MockReminders();
    when(
      () => subscriptions.isPro(userId: any(named: 'userId')),
    ).thenAnswer((_) async => false);
  });

  IsAtReminderLimitUsecase build() => IsAtReminderLimitUsecase(
    subscriptionService: subscriptions,
    reminderRepository: reminders,
  );

  test('paid users never hit the cap (no count lookup)', () async {
    when(
      () => subscriptions.isPro(userId: any(named: 'userId')),
    ).thenAnswer((_) async => true);
    expect(await build()(familyId: 'f1'), isFalse);
    verifyNever(() => reminders.getRemindersCount(any()));
  });

  test('null familyId fails open', () async {
    expect(await build()(familyId: null), isFalse);
    verifyNever(() => reminders.getRemindersCount(any()));
  });

  test('true at cap, false below cap', () async {
    when(() => reminders.getRemindersCount('f1')).thenAnswer(
      (_) async => const Right<Failure, int>(10),
    );
    expect(await build()(familyId: 'f1'), isTrue);

    when(() => reminders.getRemindersCount('f1')).thenAnswer(
      (_) async => const Right<Failure, int>(9),
    );
    expect(await build()(familyId: 'f1'), isFalse);
  });

  test('count lookup failure fails open', () async {
    when(() => reminders.getRemindersCount('f1')).thenAnswer(
      (_) async => Left(Failure(message: 'boom')),
    );
    expect(await build()(familyId: 'f1'), isFalse);
  });

  test('throwing entitlement fake fails open (outer guard)', () async {
    when(
      () => subscriptions.isPro(userId: any(named: 'userId')),
    ).thenThrow(Exception('billing down'));
    expect(await build()(familyId: 'f1'), isFalse);
  });

  test(
    'billing outage fail-closes: uninitialized service applies free limits',
    () async {
      final usecase = IsAtReminderLimitUsecase(
        subscriptionService: SubscriptionService(),
        reminderRepository: reminders,
      );
      when(() => reminders.getRemindersCount('f1')).thenAnswer(
        (_) async => const Right<Failure, int>(10),
      );
      expect(await usecase(familyId: 'f1'), isTrue);
    },
  );

  test('count lookup throw fails open', () async {
    when(
      () => reminders.getRemindersCount('f1'),
    ).thenThrow(Exception('db down'));
    expect(await build()(familyId: 'f1'), isFalse);
  });

  test('forwards the userId to the entitlement lookup', () async {
    when(() => reminders.getRemindersCount('f1')).thenAnswer(
      (_) async => const Right<Failure, int>(0),
    );
    expect(await build()(familyId: 'f1', userId: 'u1'), isFalse);
    verify(() => subscriptions.isPro(userId: 'u1')).called(1);
  });
}

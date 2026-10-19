import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:house_mira_core/config/remote_config_service.dart';
import 'package:house_mira_core/errors/failure.dart';
import 'package:house_mira_core/observability/app_logger.dart';
import 'package:house_mira_core/subscriptions/subscription_service.dart';
import 'package:house_mira_notes/application/is_at_note_limit_usecase.dart';
import 'package:house_mira_notes/domain/repository/notes_repository.dart';
import 'package:mocktail/mocktail.dart';

class _MockRemoteConfig extends Mock implements FirebaseRemoteConfig {}

class _MockSubscriptions extends Mock implements SubscriptionService {}

class _MockNotes extends Mock implements NotesRepository {}

void main() {
  late _MockRemoteConfig remoteConfig;
  late _MockSubscriptions subscriptions;
  late _MockNotes notes;
  late RemoteConfigService configService;

  setUp(() {
    remoteConfig = _MockRemoteConfig();
    subscriptions = _MockSubscriptions();
    notes = _MockNotes();
    when(
      () => subscriptions.isPro(userId: any(named: 'userId')),
    ).thenAnswer((_) async => false);
    configService = RemoteConfigService(
      remoteConfig: remoteConfig,
      logger: AppLogger(),
    );
  });

  IsAtNoteLimitUsecase build({bool enabled = false}) {
    when(
      () => remoteConfig.getBool('enable_limit_and_paywall'),
    ).thenReturn(enabled);
    return IsAtNoteLimitUsecase(
      subscriptionService: subscriptions,
      notesRepository: notes,
      remoteConfigService: configService,
    );
  }

  test('remote flag off: limits disabled, no cap enforced', () async {
    final usecase = build(enabled: false);
    when(
      () => subscriptions.isPro(userId: any(named: 'userId')),
    ).thenAnswer((_) async => false);
    when(
      () => notes.getNotesCount('f1'),
    ).thenAnswer((_) async => const Right<Failure, int>(100));
    expect(await usecase(familyId: 'f1'), isFalse);
    verifyNever(() => subscriptions.isPro(userId: any(named: 'userId')));
    verifyNever(() => notes.getNotesCount(any()));
  });

  test('remote flag off: paid user still no-op', () async {
    final usecase = build(enabled: false);
    when(
      () => subscriptions.isPro(userId: any(named: 'userId')),
    ).thenAnswer((_) async => true);
    expect(await usecase(familyId: 'f1'), isFalse);
  });

  test(
    'remote flag on: paid users never hit the cap (no count lookup)',
    () async {
      final usecase = build(enabled: true);
      when(
        () => subscriptions.isPro(userId: any(named: 'userId')),
      ).thenAnswer((_) async => true);
      expect(await usecase(familyId: 'f1'), isFalse);
      verifyNever(() => notes.getNotesCount(any()));
    },
  );

  test('null familyId fails open without a billing lookup', () async {
    final usecase = build(enabled: true);
    expect(await usecase(familyId: null), isFalse);
    verifyNever(() => notes.getNotesCount(any()));
    verifyNever(() => subscriptions.isPro(userId: any(named: 'userId')));
  });

  test('true at cap, false below cap', () async {
    final usecase = build(enabled: true);
    when(
      () => notes.getNotesCount('f1'),
    ).thenAnswer((_) async => const Right<Failure, int>(3));
    expect(await usecase(familyId: 'f1'), isTrue);

    when(
      () => notes.getNotesCount('f1'),
    ).thenAnswer((_) async => const Right<Failure, int>(2));
    expect(await usecase(familyId: 'f1'), isFalse);
  });

  test('count lookup failure fails open', () async {
    final usecase = build(enabled: true);
    when(
      () => notes.getNotesCount('f1'),
    ).thenAnswer((_) async => Left(Failure(message: 'boom')));
    expect(await usecase(familyId: 'f1'), isFalse);
  });

  test('throwing entitlement fake fails open (outer guard)', () async {
    final usecase = build(enabled: true);
    when(
      () => subscriptions.isPro(userId: any(named: 'userId')),
    ).thenThrow(Exception('billing down'));
    expect(await usecase(familyId: 'f1'), isFalse);
  });

  test(
    'billing outage fail-closes: uninitialized service applies free limits',
    () async {
      final usecase = IsAtNoteLimitUsecase(
        subscriptionService: SubscriptionService(),
        notesRepository: notes,
        remoteConfigService: configService,
      );
      when(
        () => remoteConfig.getBool('enable_limit_and_paywall'),
      ).thenReturn(true);
      when(
        () => notes.getNotesCount('f1'),
      ).thenAnswer((_) async => const Right<Failure, int>(3));
      expect(await usecase(familyId: 'f1'), isTrue);
    },
  );

  test('count lookup throw fails open', () async {
    final usecase = build(enabled: true);
    when(() => notes.getNotesCount('f1')).thenThrow(Exception('db down'));
    expect(await usecase(familyId: 'f1'), isFalse);
  });

  test('forwards the userId to the entitlement lookup', () async {
    final usecase = build(enabled: true);
    when(
      () => notes.getNotesCount('f1'),
    ).thenAnswer((_) async => const Right<Failure, int>(0));
    expect(await usecase(familyId: 'f1', userId: 'u1'), isFalse);
    verify(() => subscriptions.isPro(userId: 'u1')).called(1);
  });
}

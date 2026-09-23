import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:house_mira/core/auth/auth_service.dart';
import 'package:house_mira/core/observability/app_logger.dart';
import 'package:house_mira/core/observability/crash_reporter.dart';
import 'package:house_mira/features/people/domain/repository/people_repository.dart';
import 'package:house_mira/features/reminders/application/reminder_notification_service.dart';
import 'package:house_mira/features/reminders/domain/entities/reminder_entity.dart';
import 'package:house_mira/features/reminders/domain/entities/reminder_type.dart';
import 'package:house_mira/features/reminders/domain/repository/reminder_repository.dart';
import 'package:house_mira/features/reminders/domain/usecase/get_reminder_usecase.dart';
import 'package:house_mira/features/reminders/presentation/cubit/reminders_cubit.dart';
import 'package:house_mira/features/reminders/presentation/cubit/reminders_state.dart';
import 'package:mocktail/mocktail.dart';

class _FakePeopleRepository extends Mock implements PeopleRepository {}

class _FakeAuthService extends Mock implements AuthService {}

class _FakeGetReminderUsecase extends Mock implements GetReminderUsecase {}

class _FakeReminderRepository extends Mock implements ReminderRepository {}

class _FakeNotificationService extends Mock
    implements IReminderNotificationService {}

class _RecordingCrashReporter implements CrashReporter {
  final logs = <String>[];
  final errors = <Object>[];

  @override
  Future<void> log(String message) async {
    logs.add(message);
  }

  @override
  Future<void> recordError(
    Object error,
    StackTrace stackTrace, {
    String? reason,
    Map<String, Object?>? context,
    bool fatal = false,
  }) async {
    errors.add(error);
  }

  @override
  Future<void> setUserId(String? userId) async {}

  @override
  Future<void> setCustomKey(String key, Object value) async {}
}

void main() {
  late _FakePeopleRepository peopleRepository;
  late _FakeAuthService authService;
  late _FakeGetReminderUsecase getReminderUsecase;
  late _FakeReminderRepository reminderRepository;
  late _FakeNotificationService notificationService;
  late _RecordingCrashReporter crash;
  late List<String> lines;

  setUp(() {
    peopleRepository = _FakePeopleRepository();
    authService = _FakeAuthService();
    getReminderUsecase = _FakeGetReminderUsecase();
    reminderRepository = _FakeReminderRepository();
    notificationService = _FakeNotificationService();
    crash = _RecordingCrashReporter();
    lines = <String>[];
  });

  setUpAll(() {
    registerFallbackValue(ReminderType.custom);
    registerFallbackValue(<ReminderEntity>[]);
  });

  RemindersCubit buildCubit() => RemindersCubit(
    getReminderUsecase: getReminderUsecase,
    peopleRepository: peopleRepository,
    authService: authService,
    reminderRepository: reminderRepository,
    notificationService: notificationService,
    crashReporter: crash,
    logger: AppLogger(crashReporter: crash, sink: lines.add),
  );

  ReminderEntity reminder() => ReminderEntity(
    title: 'T',
    body: '',
    id: '1',
    type: ReminderType.custom,
    dueDate: '19/08/2026',
    repeatRule: 'never',
    status: 'pending',
    createdBy: 'Mom',
    createdAt: '',
  );

  group('RemindersCubit resync observability', () {
    blocTest<RemindersCubit, RemindersState>(
      'reports resync failures without disturbing the list',
      build: buildCubit,
      setUp: () {
        when(() => authService.currentUserId).thenReturn('u1');
        when(
          () => peopleRepository.getFamilyIdsForUser('u1'),
        ).thenAnswer((_) async => ['f1']);
        when(
          () => peopleRepository.getMyFamilyRole(),
        ).thenAnswer((_) async => ['member']);
        when(
          () => peopleRepository.getProfilesWithRoleForFamily('f1'),
        ).thenAnswer((_) async => []);
        when(
          () => getReminderUsecase.call('f1', type: any(named: 'type')),
        ).thenAnswer((_) async => Right([reminder()]));
        when(
          () => notificationService.rescheduleAll(any()),
        ).thenThrow(Exception('os alarms denied'));
      },
      act: (cubit) => cubit.getReminders(),
      wait: const Duration(milliseconds: 100),
      expect: () => [isA<RemindersLoading>(), isA<LoadedReminders>()],
      verify: (_) async {
        await Future<void>.delayed(Duration.zero);
        expect(crash.errors.single, isA<Exception>());
        expect(
          crash.logs.single,
          contains('[warning][reminder-resync] reminder resync failed'),
        );
      },
    );
  });
}

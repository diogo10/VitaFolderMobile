import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:house_mira/core/auth/auth_service.dart';
import 'package:house_mira/core/auth/google_sign_in_handler.dart';
import 'package:house_mira/core/errors/failure.dart';
import 'package:house_mira/features/account/presentation/cubit/account_cubit.dart';
import 'package:house_mira/features/account/presentation/cubit/account_state.dart';
import 'package:house_mira/features/home/domain/entities/home_entity.dart';
import 'package:house_mira/features/home/domain/usecase/get_home_data_usecase.dart';
import 'package:house_mira/features/home/domain/usecase/has_reminders_usecase.dart';
import 'package:house_mira/features/home/presentation/cubit/home_cubit.dart';
import 'package:house_mira/features/home/presentation/cubit/home_state.dart';
import 'package:house_mira/features/people/domain/entities/family_entity.dart';
import 'package:house_mira/features/people/domain/entities/people_data.dart';
import 'package:house_mira/features/people/domain/entities/person_entity.dart';
import 'package:house_mira/features/people/domain/usecase/delete_family_usecase.dart';
import 'package:house_mira/features/people/domain/usecase/get_my_family_id_usecase.dart';
import 'package:house_mira/features/people/domain/usecase/get_people_usecase.dart';
import 'package:house_mira/features/people/domain/usecase/remove_member_usecase.dart';
import 'package:house_mira/features/people/domain/usecase/update_family_name_usecase.dart';
import 'package:house_mira/features/people/presentation/cubit/family_settings_cubit.dart';
import 'package:house_mira/features/people/presentation/cubit/family_settings_state.dart';
import 'package:house_mira/features/people/presentation/cubit/people_cubit.dart';
import 'package:house_mira/features/people/presentation/cubit/people_state.dart';
import 'package:house_mira/features/people/domain/repository/people_repository.dart';
import 'package:house_mira/features/people/domain/usecase/create_family_usecase.dart';
import 'package:house_mira/features/people/domain/usecase/join_family_usecase.dart';
import 'package:house_mira/features/reminders/application/reminder_notification_service.dart';
import 'package:house_mira/features/reminders/domain/entities/reminder_entity.dart';
import 'package:house_mira/features/reminders/domain/entities/reminder_lead_time.dart';
import 'package:house_mira/features/reminders/domain/entities/reminder_type.dart';
import 'package:house_mira/features/reminders/domain/repository/reminder_repository.dart';
import 'package:house_mira/features/reminders/domain/usecase/create_reminder_usecase.dart';
import 'package:house_mira/features/reminders/domain/usecase/get_reminder_usecase.dart';
import 'package:house_mira/features/reminders/domain/usecase/update_reminder_usecase.dart';
import 'package:house_mira/features/reminders/presentation/cubit/create_reminder_cubit.dart';
import 'package:house_mira/features/reminders/presentation/cubit/reminders_cubit.dart';
import 'package:house_mira/features/reminders/presentation/cubit/reminders_state.dart';
import 'package:house_mira/features/reminders/presentation/cubit/reminders_view_mode.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _MockSupabaseClient extends Mock implements SupabaseClient {}

class _MockGoogleHandler extends Mock implements IGoogleSignInHandler {}

class _FakeAuthService extends AuthService {
  _FakeAuthService({this.stubUserId})
    : super(
        supabaseClient: _MockSupabaseClient(),
        googleSignInHandler: _MockGoogleHandler(),
      );
  String? stubUserId;
  int signInCalls = 0;

  @override
  String? get currentUserId => stubUserId;

  @override
  bool isLoggedIn() => stubUserId != null;

  @override
  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    signInCalls++;
  }

  @override
  Future<PersonEntity?> getAsPersonEntity() async => null;
}

class _FakeAccountAuth extends AuthService {
  _FakeAccountAuth()
    : super(
        supabaseClient: _MockSupabaseClient(),
        googleSignInHandler: _MockGoogleHandler(),
      );
  int signInCalls = 0;

  @override
  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    signInCalls++;
  }

  @override
  User? get currentUser => null;

  @override
  Future<PersonEntity?> getAsPersonEntity() async => null;
}

class _FakePeopleRepository implements PeopleRepository {
  List<String> familyIds = const ['f1'];
  List<String> roles = const ['member'];
  bool throwOnFamilyIds = false;

  @override
  Future<Either<Exception, List<PersonEntity>>> getPeople() async =>
      const Right([]);
  @override
  Future<Either<Exception, bool>> createFamily({
    required String name,
    required String inviteCode,
  }) async => const Right(true);
  @override
  Future<Either<Exception, FamilyEntity>> getMyFamily() async =>
      Left(Exception('none'));
  @override
  Future<Either<Exception, bool>> joinFamily({
    required String inviteCode,
  }) async => const Right(true);
  @override
  Future<FamilyEntity?> getFamilyBy(String id) async => null;
  @override
  Future<List<String>> getFamilyIdsForUser(String userId) async {
    if (throwOnFamilyIds) throw Exception('boom');
    return familyIds;
  }

  @override
  Future<List<PersonEntity>> getProfilesWithRoleForFamily(
    String familyId,
  ) async => [];
  @override
  Future<List<String>> getMyFamilyRole() async => roles;
  @override
  Future<Either<Exception, bool>> updateFamilyName({
    required String familyId,
    required String name,
  }) async => const Right(true);
  @override
  Future<Either<Exception, bool>> removeMember({
    required String familyId,
    required String userId,
  }) async => const Right(true);
  @override
  Future<Either<Exception, bool>> deleteFamily({
    required String familyId,
  }) async => const Right(true);
  @override
  Future<Either<Exception, String?>> getMyFamilyId() async => const Right('f1');
}

class _MockGetHomeData extends Mock implements GetHomeDataUsecase {}

class _MockHasReminders extends Mock implements HasRemindersUsecase {}

class _MockGetPeople extends Mock implements GetPeopleUsecase {}

class _MockCreateFamily extends Mock implements CreateFamilyUsecase {}

class _MockJoinFamily extends Mock implements JoinFamilyUsecase {}

class _MockGetMyFamilyId extends Mock implements GetMyFamilyIdUsecase {}

class _MockUpdateFamilyName extends Mock implements UpdateFamilyNameUsecase {}

class _MockRemoveMember extends Mock implements RemoveMemberUsecase {}

class _MockDeleteFamily extends Mock implements DeleteFamilyUsecase {}

class _MockGetReminder extends Mock implements GetReminderUsecase {}

class _MockReminderRepository extends Mock implements ReminderRepository {}

class _MockCreateReminder extends Mock implements CreateReminderUsecase {}

class _MockUpdateReminder extends Mock implements UpdateReminderUsecase {}

class _MockNotifications extends Mock implements IReminderNotificationService {}

const _homeEntity = HomeEntity(peopleInCircle: []);

ReminderEntity _reminder(String id) => ReminderEntity(
  title: 'T $id',
  body: '',
  id: id,
  type: ReminderType.custom,
  dueDate: '19/08/2026',
  repeatRule: 'never',
  status: 'pending',
  createdBy: 'Mom',
  createdAt: '',
);

PeopleData _adminData() => PeopleData(
  family: FamilyEntity(name: 'Fam', inviteCode: 'ABC123'),
  people: [
    const PersonEntity(id: 'u1', name: 'Ana', role: 'Admin'),
    const PersonEntity(id: 'u2', name: 'Bob', role: 'member'),
  ],
);

void main() {
  setUpAll(() {
    registerFallbackValue(ReminderType.custom);
    registerFallbackValue(<ReminderEntity>[]);
    registerFallbackValue(ReminderLeadTime.fifteenMinutes);
  });

  group('HomeCubit refresh + cancel-adjacent paths', () {
    late _MockGetHomeData getHomeData;
    late _MockHasReminders hasReminders;

    setUp(() {
      getHomeData = _MockGetHomeData();
      hasReminders = _MockHasReminders();
      when(
        () => hasReminders(),
      ).thenAnswer((_) async => const Right(false));
    });

    HomeCubit build() => HomeCubit(
      getHomeDataUsecase: getHomeData,
      hasRemindersUsecase: hasReminders,
    );

    blocTest<HomeCubit, HomeState>(
      'refresh success emits Loaded without Loading',
      build: build,
      setUp: () {
        when(
          () => getHomeData(),
        ).thenAnswer((_) async => const Right(_homeEntity));
      },
      act: (cubit) => cubit.getHomeData(isRefresh: true),
      expect: () => [isA<HomeLoaded>()],
    );

    blocTest<HomeCubit, HomeState>(
      'refresh with NoData emits Empty without Loading',
      build: build,
      setUp: () {
        when(
          () => getHomeData(),
        ).thenAnswer((_) async => Left(NoDataException()));
      },
      act: (cubit) => cubit.getHomeData(isRefresh: true),
      expect: () => [isA<HomeEmpty>()],
    );

    blocTest<HomeCubit, HomeState>(
      'refresh failure emits Error without Loading',
      build: build,
      setUp: () {
        when(
          () => getHomeData(),
        ).thenAnswer((_) async => Left(Failure(message: 'boom')));
      },
      act: (cubit) => cubit.getHomeData(isRefresh: true),
      expect: () => [isA<HomeError>()],
    );

    blocTest<HomeCubit, HomeState>(
      'empty carries the reminders flag when reminders exist',
      build: build,
      setUp: () {
        when(
          () => getHomeData(),
        ).thenAnswer((_) async => Left(NoDataException()));
        when(
          () => hasReminders(),
        ).thenAnswer((_) async => const Right(true));
      },
      act: (cubit) => cubit.getHomeData(),
      expect: () => [
        isA<HomeLoading>(),
        isA<HomeEmpty>().having((s) => s.hasReminders, 'hasReminders', true),
      ],
    );
  });

  group('PeopleCubit empty + failure paths', () {
    late _MockGetPeople getPeople;
    late _MockCreateFamily createFamily;
    late _MockJoinFamily joinFamily;
    late _FakeAuthService auth;

    setUp(() {
      getPeople = _MockGetPeople();
      createFamily = _MockCreateFamily();
      joinFamily = _MockJoinFamily();
      auth = _FakeAuthService(stubUserId: 'u1');
    });

    PeopleCubit build() => PeopleCubit(
      getPeopleUsecase: getPeople,
      createFamilyUsecase: createFamily,
      joinFamilyUsecase: joinFamily,
      authService: auth,
    );

    blocTest<PeopleCubit, PeopleState>(
      'emits Empty when the family payload is blank',
      build: build,
      setUp: () {
        when(() => getPeople()).thenAnswer(
          (_) async => Right(
            PeopleData(
              family: FamilyEntity(name: '', inviteCode: ''),
              people: [],
            ),
          ),
        );
      },
      act: (cubit) => cubit.getPeople(),
      expect: () => [isA<PeopleLoading>(), isA<PeopleEmpty>()],
    );
  });

  group('AccountCubit validation cancel paths', () {
    test('empty password is a validation cancel, not a failure', () async {
      final auth = _FakeAccountAuth();
      final cubit = AccountCubit(
        authService: auth,
        peopleRepository: _FakePeopleRepository(),
        authStateStream: const Stream.empty(),
      );
      addTearDown(cubit.close);

      await cubit.signIn('user@example.com', '');

      expect(cubit.state, isA<NoAccount>());
      expect(auth.signInCalls, 0);
    });
  });

  group('FamilySettingsCubit failure paths', () {
    late _MockGetPeople getPeople;
    late _MockGetMyFamilyId getFamilyId;
    late _MockUpdateFamilyName updateName;
    late _MockRemoveMember removeMember;
    late _MockDeleteFamily deleteFamily;

    setUp(() {
      getPeople = _MockGetPeople();
      getFamilyId = _MockGetMyFamilyId();
      updateName = _MockUpdateFamilyName();
      removeMember = _MockRemoveMember();
      deleteFamily = _MockDeleteFamily();
      when(
        () => getPeople(),
      ).thenAnswer((_) async => Right<Exception, PeopleData>(_adminData()));
    });

    FamilySettingsCubit build() => FamilySettingsCubit(
      getPeopleUsecase: getPeople,
      getMyFamilyIdUsecase: getFamilyId,
      updateFamilyNameUsecase: updateName,
      removeMemberUsecase: removeMember,
      deleteFamilyUsecase: deleteFamily,
      authService: _FakeAuthService(stubUserId: 'u1'),
    );

    blocTest<FamilySettingsCubit, FamilySettingsState>(
      'saveChanges emits error when resolving the family id throws',
      build: build,
      setUp: () {
        when(() => getFamilyId()).thenThrow(Exception('boom'));
      },
      act: (cubit) async {
        await cubit.loadSettings();
        cubit.queueFamilyNameChange('New');
        await cubit.saveChanges();
      },
      expect: () => [
        isA<FamilySettingsLoading>(),
        isA<FamilySettingsLoaded>(),
        isA<FamilySettingsLoaded>(),
        isA<FamilySettingsSaving>(),
        isA<FamilySettingsError>(),
      ],
    );

    blocTest<FamilySettingsCubit, FamilySettingsState>(
      'deleteFamily emits error when the delete usecase throws',
      build: build,
      setUp: () {
        when(
          () => getFamilyId(),
        ).thenAnswer((_) async => const Right<Exception, String?>('f1'));
        when(
          () => deleteFamily(familyId: 'f1'),
        ).thenThrow(Exception('boom'));
      },
      act: (cubit) async {
        await cubit.loadSettings();
        await cubit.deleteFamily();
      },
      expect: () => [
        isA<FamilySettingsLoading>(),
        isA<FamilySettingsLoaded>(),
        isA<FamilySettingsSaving>(),
        isA<FamilySettingsError>(),
      ],
    );
  });

  group('RemindersCubit cancel/failure paths', () {
    late _FakePeopleRepository people;
    late _FakeAuthService auth;
    late _MockGetReminder getReminders;
    late _MockReminderRepository repository;
    late _MockNotifications notifications;

    setUp(() {
      people = _FakePeopleRepository();
      auth = _FakeAuthService(stubUserId: 'u1');
      getReminders = _MockGetReminder();
      repository = _MockReminderRepository();
      notifications = _MockNotifications();
      when(
        () => notifications.rescheduleAll(any()),
      ).thenAnswer((_) async {});
      when(
        () => notifications.cancelReminderNotification(any()),
      ).thenAnswer((_) async {});
    });

    RemindersCubit build() => RemindersCubit(
      getReminderUsecase: getReminders,
      peopleRepository: people,
      authService: auth,
      reminderRepository: repository,
      notificationService: notifications,
    );

    blocTest<RemindersCubit, RemindersState>(
      'emits Empty when signed out (no user is a neutral cancel)',
      build: () {
        auth.stubUserId = null;
        return build();
      },
      act: (cubit) => cubit.getReminders(),
      expect: () => [isA<RemindersLoading>(), isA<EmptyReminders>()],
    );

    blocTest<RemindersCubit, RemindersState>(
      'emits Error when the fetch fails',
      build: build,
      setUp: () {
        when(
          () => getReminders.call(any(), type: any(named: 'type')),
        ).thenAnswer((_) async => Left(Failure(message: 'boom')));
      },
      act: (cubit) => cubit.getReminders(),
      expect: () => [isA<RemindersLoading>(), isA<ReminderError>()],
    );

    blocTest<RemindersCubit, RemindersState>(
      'removeReminder failure keeps the visible list',
      build: build,
      setUp: () {
        when(
          () => getReminders.call(any(), type: any(named: 'type')),
        ).thenAnswer((_) async => Right([_reminder('1')]));
        when(
          () => repository.removeReminder('1'),
        ).thenAnswer((_) async => Left(Failure(message: 'boom')));
      },
      act: (cubit) async {
        await cubit.getReminders();
        await cubit.removeReminder('1');
      },
      expect: () => [
        isA<RemindersLoading>(),
        isA<LoadedReminders>(),
        isA<LoadedReminders>().having(
          (s) => s.reminders.length,
          'length',
          1,
        ),
      ],
    );

    test('hasFamily is false when signed out or the lookup throws', () async {
      auth.stubUserId = null;
      final signedOut = build();
      addTearDown(signedOut.close);
      expect(await signedOut.hasFamily(), isFalse);

      people.throwOnFamilyIds = true;
      final throwing = build();
      addTearDown(throwing.close);
      expect(await throwing.hasFamily(), isFalse);
    });

    test('hasFamily is false without a family and true with one', () async {
      people.familyIds = [];
      final noFamily = build();
      addTearDown(noFamily.close);
      expect(await noFamily.hasFamily(), isFalse);

      people.familyIds = ['f1'];
      final withFamily = build();
      addTearDown(withFamily.close);
      expect(await withFamily.hasFamily(), isTrue);
    });

    test('toggleViewMode preserves the loaded list', () async {
      final cubit = build();
      addTearDown(cubit.close);
      when(
        () => getReminders.call(any(), type: any(named: 'type')),
      ).thenAnswer((_) async => Right([_reminder('1')]));
      await cubit.getReminders();
      expect(cubit.viewMode, RemindersViewMode.list);

      cubit.toggleViewMode();

      expect(cubit.viewMode, RemindersViewMode.calendar);
      final state = cubit.state as LoadedReminders;
      expect(state.reminders, hasLength(1));
      expect(state.viewMode, RemindersViewMode.calendar);
    });

    test('filter helpers narrow by selected types', () async {
      final cubit = build();
      addTearDown(cubit.close);
      final all = [_reminder('1'), _reminder('2')];

      expect(cubit.getFilteredReminders(all), hasLength(2));

      cubit.setFilterTypes({ReminderType.chores});
      expect(cubit.filterTypes, {ReminderType.chores});
      expect(cubit.getFilteredReminders(all), isEmpty);
    });
  });

  group('CreateReminderCubit notification cancel/failure paths', () {
    late _FakeAuthService auth;
    late _FakePeopleRepository people;
    late _MockCreateReminder createUsecase;
    late _MockUpdateReminder updateUsecase;
    late _MockNotifications notifications;

    setUp(() {
      auth = _FakeAuthService(stubUserId: 'u1');
      people = _FakePeopleRepository();
      createUsecase = _MockCreateReminder();
      updateUsecase = _MockUpdateReminder();
      notifications = _MockNotifications();
      when(
        () => notifications.setReminderNotification(
          reminderId: any(named: 'reminderId'),
          enabled: any(named: 'enabled'),
          leadTime: any(named: 'leadTime'),
          dueDate: any(named: 'dueDate'),
          title: any(named: 'title'),
          body: any(named: 'body'),
          repeatRule: any(named: 'repeatRule'),
        ),
      ).thenAnswer((_) async => true);
      when(
        () => notifications.hasSystemPermission(),
      ).thenAnswer((_) async => true);
      when(
        () => notifications.canScheduleExactAlarms(),
      ).thenAnswer((_) async => true);
    });

    CreateReminderCubit build() => CreateReminderCubit(
      createReminderUsecase: createUsecase,
      updateReminderUsecase: updateUsecase,
      authService: auth,
      peopleRepository: people,
      notificationService: notifications,
    );

    test('permission helpers degrade to safe defaults on throw', () async {
      final cubit = build();
      addTearDown(cubit.close);
      when(
        () => notifications.hasSystemPermission(),
      ).thenThrow(Exception('os'));
      when(
        () => notifications.canScheduleExactAlarms(),
      ).thenThrow(Exception('os'));
      when(
        () => notifications.requestSystemPermission(),
      ).thenThrow(Exception('os'));
      when(
        () => notifications.requestExactAlarmPermission(),
      ).thenThrow(Exception('os'));
      when(
        () => notifications.getReminderNotification(any()),
      ).thenThrow(Exception('db'));

      expect(await cubit.hasSystemPermission(), isFalse);
      expect(await cubit.canScheduleExactAlarms(), isTrue);
      expect(await cubit.requestSystemPermission(), isFalse);
      // Best-effort: never throws even when the OS call fails.
      await cubit.requestExactAlarmPermission();
      expect(
        await cubit.getNotificationPrefs('r1'),
        ReminderNotificationPrefs.disabled,
      );
    });
  });
}

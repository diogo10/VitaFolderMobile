import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:house_mira/core/auth/auth_service.dart';
import 'package:house_mira/core/auth/google_sign_in_handler.dart';
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
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _MockGetPeopleUsecase extends Mock implements GetPeopleUsecase {}

class _MockGetMyFamilyIdUsecase extends Mock implements GetMyFamilyIdUsecase {}

class _MockUpdateFamilyNameUsecase extends Mock
    implements UpdateFamilyNameUsecase {}

class _MockRemoveMemberUsecase extends Mock implements RemoveMemberUsecase {}

class _MockDeleteFamilyUsecase extends Mock implements DeleteFamilyUsecase {}

class _MockSupabaseClient extends Mock implements SupabaseClient {}

class _MockGoogleSignInHandler extends Mock implements IGoogleSignInHandler {}

class _FakeAuthService extends AuthService {
  _FakeAuthService({this.stubUserId})
    : super(
        supabaseClient: _MockSupabaseClient(),
        googleSignInHandler: _MockGoogleSignInHandler(),
      );
  String? stubUserId;

  @override
  String? get currentUserId => stubUserId;
}

PeopleData adminData() => PeopleData(
  family: FamilyEntity(name: 'Fam', inviteCode: 'ABC123'),
  people: [
    const PersonEntity(id: 'u1', name: 'Ana', role: 'Admin'),
    const PersonEntity(id: 'u2', name: 'Bob', role: 'member'),
  ],
);

void main() {
  late _MockGetPeopleUsecase getPeopleUsecase;
  late _MockGetMyFamilyIdUsecase getMyFamilyIdUsecase;
  late _MockUpdateFamilyNameUsecase updateFamilyNameUsecase;
  late _MockRemoveMemberUsecase removeMemberUsecase;
  late _MockDeleteFamilyUsecase deleteFamilyUsecase;

  setUp(() {
    getPeopleUsecase = _MockGetPeopleUsecase();
    getMyFamilyIdUsecase = _MockGetMyFamilyIdUsecase();
    updateFamilyNameUsecase = _MockUpdateFamilyNameUsecase();
    removeMemberUsecase = _MockRemoveMemberUsecase();
    deleteFamilyUsecase = _MockDeleteFamilyUsecase();
  });

  FamilySettingsCubit build({String? userId = 'u1'}) => FamilySettingsCubit(
    getPeopleUsecase: getPeopleUsecase,
    getMyFamilyIdUsecase: getMyFamilyIdUsecase,
    updateFamilyNameUsecase: updateFamilyNameUsecase,
    removeMemberUsecase: removeMemberUsecase,
    deleteFamilyUsecase: deleteFamilyUsecase,
    authService: _FakeAuthService(stubUserId: userId),
  );

  void stubPeople(PeopleData data) {
    when(
      () => getPeopleUsecase(),
    ).thenAnswer((_) async => Right<Exception, PeopleData>(data));
  }

  group('loadSettings', () {
    blocTest<FamilySettingsCubit, FamilySettingsState>(
      'emits loading then loaded for admins',
      build: build,
      setUp: () => stubPeople(adminData()),
      act: (cubit) => cubit.loadSettings(),
      expect: () => [
        isA<FamilySettingsLoading>(),
        isA<FamilySettingsLoaded>()
            .having((s) => s.familyName, 'familyName', 'Fam')
            .having((s) => s.members.length, 'members', 2)
            .having((s) => s.currentUserId, 'currentUserId', 'u1'),
      ],
    );

    blocTest<FamilySettingsCubit, FamilySettingsState>(
      'emits notAdmin error for non-admin members',
      build: () => build(userId: 'u2'),
      setUp: () => stubPeople(adminData()),
      act: (cubit) => cubit.loadSettings(),
      expect: () => [
        isA<FamilySettingsLoading>(),
        isA<FamilySettingsError>().having(
          (s) => s.code,
          'code',
          FamilySettingsErrorCode.notAdmin,
        ),
      ],
    );

    blocTest<FamilySettingsCubit, FamilySettingsState>(
      'emits error when the usecase reports failure',
      build: build,
      setUp: () {
        when(() => getPeopleUsecase()).thenAnswer(
          (_) async => Left<Exception, PeopleData>(Exception('boom')),
        );
      },
      act: (cubit) => cubit.loadSettings(),
      expect: () => [
        isA<FamilySettingsLoading>(),
        isA<FamilySettingsError>().having(
          (s) => s.message,
          'message',
          contains('boom'),
        ),
      ],
    );

    blocTest<FamilySettingsCubit, FamilySettingsState>(
      'emits error when the usecase throws',
      build: build,
      setUp: () {
        when(() => getPeopleUsecase()).thenThrow(Exception('boom'));
      },
      act: (cubit) => cubit.loadSettings(),
      expect: () => [
        isA<FamilySettingsLoading>(),
        isA<FamilySettingsError>(),
      ],
    );
  });

  group('pending edits', () {
    test('queueFamilyNameChange trims and stores the pending name', () async {
      final cubit = build();
      addTearDown(cubit.close);
      stubPeople(adminData());

      await cubit.loadSettings();
      cubit.queueFamilyNameChange('  New Name  ');

      final state = cubit.state as FamilySettingsLoaded;
      expect(state.pendingFamilyName, 'New Name');
      expect(state.hasPendingChanges, isTrue);
    });

    test('queueMemberRemoval and cancelMemberRemoval update the set', () async {
      final cubit = build();
      addTearDown(cubit.close);
      stubPeople(adminData());

      await cubit.loadSettings();
      cubit.queueMemberRemoval('u2');
      expect(
        (cubit.state as FamilySettingsLoaded).pendingRemovals,
        contains('u2'),
      );
      expect(
        (cubit.state as FamilySettingsLoaded).displayMembers,
        hasLength(1),
      );

      cubit.cancelMemberRemoval('u2');
      final state = cubit.state as FamilySettingsLoaded;
      expect(state.pendingRemovals, isEmpty);
      expect(state.hasPendingChanges, isFalse);
      expect(state.displayMembers, hasLength(2));
    });

    test('queue calls are no-ops before settings load', () async {
      final cubit = build();
      addTearDown(cubit.close);

      cubit
        ..queueFamilyNameChange('New')
        ..queueMemberRemoval('u2')
        ..cancelMemberRemoval('u2');

      expect(cubit.state, isA<FamilySettingsInitial>());
    });
  });

  group('saveChanges', () {
    test('is a no-op when settings are not loaded', () async {
      final cubit = build();
      addTearDown(cubit.close);

      await cubit.saveChanges();

      expect(cubit.state, isA<FamilySettingsInitial>());
    });

    blocTest<FamilySettingsCubit, FamilySettingsState>(
      'does nothing without pending changes',
      build: build,
      setUp: () => stubPeople(adminData()),
      act: (cubit) async {
        await cubit.loadSettings();
        await cubit.saveChanges();
      },
      expect: () => [isA<FamilySettingsLoading>(), isA<FamilySettingsLoaded>()],
    );

    blocTest<FamilySettingsCubit, FamilySettingsState>(
      'saves name change and removals then reloads',
      build: build,
      setUp: () {
        stubPeople(adminData());
        when(() => getMyFamilyIdUsecase()).thenAnswer(
          (_) async => const Right<Exception, String?>('f1'),
        );
        when(
          () => updateFamilyNameUsecase(familyId: 'f1', name: 'New'),
        ).thenAnswer((_) async => const Right(true));
        when(
          () => removeMemberUsecase(familyId: 'f1', userId: 'u2'),
        ).thenAnswer((_) async => const Right(true));
      },
      act: (cubit) async {
        await cubit.loadSettings();
        cubit
          ..queueFamilyNameChange('New')
          ..queueMemberRemoval('u2');
        await cubit.saveChanges();
      },
      expect: () => [
        isA<FamilySettingsLoading>(),
        isA<FamilySettingsLoaded>(),
        isA<FamilySettingsLoaded>(),
        isA<FamilySettingsLoaded>(),
        isA<FamilySettingsSaving>(),
        isA<FamilySettingsSaveSuccess>(),
        isA<FamilySettingsLoading>(),
        isA<FamilySettingsLoaded>(),
      ],
      verify: (_) {
        verify(
          () => updateFamilyNameUsecase(familyId: 'f1', name: 'New'),
        ).called(1);
        verify(
          () => removeMemberUsecase(familyId: 'f1', userId: 'u2'),
        ).called(1);
      },
    );

    blocTest<FamilySettingsCubit, FamilySettingsState>(
      'skips the rename when the pending name matches',
      build: build,
      setUp: () {
        stubPeople(adminData());
        when(() => getMyFamilyIdUsecase()).thenAnswer(
          (_) async => const Right<Exception, String?>('f1'),
        );
        when(
          () => removeMemberUsecase(
            familyId: any(named: 'familyId'),
            userId: any(named: 'userId'),
          ),
        ).thenAnswer((_) async => const Right(true));
      },
      act: (cubit) async {
        await cubit.loadSettings();
        cubit
          ..queueFamilyNameChange('Fam')
          ..queueMemberRemoval('u2');
        await cubit.saveChanges();
      },
      expect: () => [
        isA<FamilySettingsLoading>(),
        isA<FamilySettingsLoaded>(),
        isA<FamilySettingsLoaded>(),
        isA<FamilySettingsLoaded>(),
        isA<FamilySettingsSaving>(),
        isA<FamilySettingsSaveSuccess>(),
        isA<FamilySettingsLoading>(),
        isA<FamilySettingsLoaded>(),
      ],
      verify: (_) {
        verifyNever(
          () => updateFamilyNameUsecase(
            familyId: any(named: 'familyId'),
            name: any(named: 'name'),
          ),
        );
      },
    );

    blocTest<FamilySettingsCubit, FamilySettingsState>(
      'emits notFound when there is no family id',
      build: build,
      setUp: () {
        stubPeople(adminData());
        when(() => getMyFamilyIdUsecase()).thenAnswer(
          (_) async => const Right<Exception, String?>(null),
        );
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
        isA<FamilySettingsError>().having(
          (s) => s.code,
          'code',
          FamilySettingsErrorCode.notFound,
        ),
      ],
    );

    blocTest<FamilySettingsCubit, FamilySettingsState>(
      'emits error when resolving the family id fails',
      build: build,
      setUp: () {
        stubPeople(adminData());
        when(() => getMyFamilyIdUsecase()).thenAnswer(
          (_) async => Left<Exception, String?>(Exception('boom')),
        );
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
      'emits error when the rename fails',
      build: build,
      setUp: () {
        stubPeople(adminData());
        when(() => getMyFamilyIdUsecase()).thenAnswer(
          (_) async => const Right<Exception, String?>('f1'),
        );
        when(
          () => updateFamilyNameUsecase(
            familyId: any(named: 'familyId'),
            name: any(named: 'name'),
          ),
        ).thenAnswer((_) async => Left(Exception('boom')));
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
        isA<FamilySettingsError>().having(
          (s) => s.message,
          'message',
          contains('boom'),
        ),
      ],
    );

    blocTest<FamilySettingsCubit, FamilySettingsState>(
      'emits error when a removal fails',
      build: build,
      setUp: () {
        stubPeople(adminData());
        when(() => getMyFamilyIdUsecase()).thenAnswer(
          (_) async => const Right<Exception, String?>('f1'),
        );
        when(
          () => removeMemberUsecase(
            familyId: any(named: 'familyId'),
            userId: any(named: 'userId'),
          ),
        ).thenAnswer((_) async => Left(Exception('boom')));
      },
      act: (cubit) async {
        await cubit.loadSettings();
        cubit.queueMemberRemoval('u2');
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
  });

  group('deleteFamily', () {
    test('is a no-op when settings are not loaded', () async {
      final cubit = build();
      addTearDown(cubit.close);

      await cubit.deleteFamily();

      expect(cubit.state, isA<FamilySettingsInitial>());
      verifyNever(
        () => getMyFamilyIdUsecase(),
      );
    });

    blocTest<FamilySettingsCubit, FamilySettingsState>(
      'emits delete success',
      build: build,
      setUp: () {
        stubPeople(adminData());
        when(() => getMyFamilyIdUsecase()).thenAnswer(
          (_) async => const Right<Exception, String?>('f1'),
        );
        when(() => deleteFamilyUsecase(familyId: 'f1')).thenAnswer(
          (_) async => const Right(true),
        );
      },
      act: (cubit) async {
        await cubit.loadSettings();
        await cubit.deleteFamily();
      },
      expect: () => [
        isA<FamilySettingsLoading>(),
        isA<FamilySettingsLoaded>(),
        isA<FamilySettingsSaving>(),
        isA<FamilySettingsDeleteSuccess>(),
      ],
    );

    blocTest<FamilySettingsCubit, FamilySettingsState>(
      'emits notFound when there is no family id',
      build: build,
      setUp: () {
        stubPeople(adminData());
        when(() => getMyFamilyIdUsecase()).thenAnswer(
          (_) async => const Right<Exception, String?>(null),
        );
      },
      act: (cubit) async {
        await cubit.loadSettings();
        await cubit.deleteFamily();
      },
      expect: () => [
        isA<FamilySettingsLoading>(),
        isA<FamilySettingsLoaded>(),
        isA<FamilySettingsSaving>(),
        isA<FamilySettingsError>().having(
          (s) => s.code,
          'code',
          FamilySettingsErrorCode.notFound,
        ),
      ],
    );

    blocTest<FamilySettingsCubit, FamilySettingsState>(
      'emits error when deletion fails',
      build: build,
      setUp: () {
        stubPeople(adminData());
        when(() => getMyFamilyIdUsecase()).thenAnswer(
          (_) async => const Right<Exception, String?>('f1'),
        );
        when(() => deleteFamilyUsecase(familyId: 'f1')).thenAnswer(
          (_) async => Left(Exception('boom')),
        );
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

    blocTest<FamilySettingsCubit, FamilySettingsState>(
      'emits error when resolving the family id throws',
      build: build,
      setUp: () {
        stubPeople(adminData());
        when(() => getMyFamilyIdUsecase()).thenThrow(Exception('boom'));
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
}

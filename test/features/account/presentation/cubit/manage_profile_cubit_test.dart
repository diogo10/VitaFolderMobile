import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:house_mira/core/auth/auth_service.dart';
import 'package:house_mira/core/auth/google_sign_in_handler.dart';
import 'package:house_mira/features/account/presentation/cubit/manage_profile_cubit.dart';
import 'package:house_mira/features/account/presentation/cubit/manage_profile_state.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _MockSupabaseClient extends Mock implements SupabaseClient {}

class _MockGoogleSignInHandler extends Mock implements IGoogleSignInHandler {}

class _FakeAuthService extends AuthService {
  _FakeAuthService({this.updateError, this.profileName})
    : super(
        supabaseClient: _MockSupabaseClient(),
        googleSignInHandler: _MockGoogleSignInHandler(),
      );
  Exception? updateError;
  String? lastName;
  String? profileName;

  @override
  Future<void> updateName(String name) async {
    lastName = name;
    if (updateError != null) throw updateError!;
  }

  @override
  Future<String?> getProfileName() async => profileName;
}

void main() {
  group('ManageProfileCubit', () {
    test('initial state is ManageProfileInitial', () {
      final cubit = ManageProfileCubit(authService: _FakeAuthService());
      addTearDown(cubit.close);

      expect(cubit.state, isA<ManageProfileInitial>());
    });

    blocTest<ManageProfileCubit, ManageProfileState>(
      'trims the name and emits loading then success',
      build: () => ManageProfileCubit(authService: _FakeAuthService()),
      act: (cubit) => cubit.saveName('  Ana  '),
      expect: () => [
        isA<ManageProfileLoading>(),
        isA<ManageProfileSuccess>(),
      ],
    );

    test('passes the trimmed name to AuthService', () async {
      final auth = _FakeAuthService();
      final cubit = ManageProfileCubit(authService: auth);
      addTearDown(cubit.close);

      await cubit.saveName('  Ana  ');

      expect(auth.lastName, 'Ana');
    });

    test('currentName returns the profile name', () async {
      final cubit = ManageProfileCubit(
        authService: _FakeAuthService(profileName: 'Ana'),
      );
      addTearDown(cubit.close);

      expect(await cubit.currentName(), 'Ana');
    });

    test('currentName returns null when the profile has no name', () async {
      final cubit = ManageProfileCubit(authService: _FakeAuthService());
      addTearDown(cubit.close);

      expect(await cubit.currentName(), isNull);
    });

    blocTest<ManageProfileCubit, ManageProfileState>(
      'emits error when the update throws',
      build: () => ManageProfileCubit(
        authService: _FakeAuthService(updateError: Exception('boom')),
      ),
      act: (cubit) => cubit.saveName('Ana'),
      expect: () => [
        isA<ManageProfileLoading>(),
        isA<ManageProfileError>().having(
          (e) => e.message,
          'message',
          contains('boom'),
        ),
      ],
    );
  });
}

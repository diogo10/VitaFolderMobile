import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:house_mira/core/auth/auth_service.dart';
import 'package:house_mira/features/account/presentation/cubit/manage_profile_cubit.dart';
import 'package:house_mira/features/account/presentation/cubit/manage_profile_state.dart';

class _FakeAuthService extends AuthService {
  Object? updateError;
  String? lastName;

  _FakeAuthService({this.updateError});

  @override
  Future<void> updateName(String name) async {
    lastName = name;
    if (updateError != null) throw updateError!;
  }
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

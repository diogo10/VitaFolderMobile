import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:house_mira/core/auth/auth_service.dart';
import 'package:house_mira/features/login/presentation/cubit/sign_up_cubit.dart';
import 'package:house_mira/features/login/presentation/cubit/sign_up_state.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _MockAuthService extends Mock implements AuthService {}

User _user() => User.fromJson({'id': 'u1', 'email': 'a@b.c'})!;

void main() {
  late _MockAuthService auth;

  setUp(() => auth = _MockAuthService());

  SignUpCubit build() => SignUpCubit(auth);

  group('SignUpCubit', () {
    blocTest<SignUpCubit, SignUpState>(
      'emits loading then success when signUp returns a user',
      build: build,
      setUp: () {
        when(
          () => auth.signUp(
            email: any(named: 'email'),
            password: any(named: 'password'),
            name: any(named: 'name'),
          ),
        ).thenAnswer((_) async => _user());
      },
      act: (cubit) =>
          cubit.signUp(email: 'a@b.c', password: 'secret123', name: 'Ana'),
      expect: () => [isA<SignUpLoading>(), isA<SignUpSuccess>()],
      verify: (_) {
        verify(
          () => auth.signUp(email: 'a@b.c', password: 'secret123', name: 'Ana'),
        ).called(1);
      },
    );

    blocTest<SignUpCubit, SignUpState>(
      'emits unexpected error when signUp returns null',
      build: build,
      setUp: () {
        when(
          () => auth.signUp(
            email: any(named: 'email'),
            password: any(named: 'password'),
            name: any(named: 'name'),
          ),
        ).thenAnswer((_) async => null);
      },
      act: (cubit) =>
          cubit.signUp(email: 'a@b.c', password: 'secret123', name: 'Ana'),
      expect: () => [
        isA<SignUpLoading>(),
        isA<SignUpError>().having(
          (e) => e.code,
          'code',
          SignUpErrorCode.unexpected,
        ),
      ],
    );

    blocTest<SignUpCubit, SignUpState>(
      'emits message from AuthException',
      build: build,
      setUp: () {
        when(
          () => auth.signUp(
            email: any(named: 'email'),
            password: any(named: 'password'),
            name: any(named: 'name'),
          ),
        ).thenThrow(const AuthException('Email taken'));
      },
      act: (cubit) =>
          cubit.signUp(email: 'a@b.c', password: 'secret123', name: 'Ana'),
      expect: () => [
        isA<SignUpLoading>(),
        isA<SignUpError>().having((e) => e.message, 'message', 'Email taken'),
      ],
    );

    blocTest<SignUpCubit, SignUpState>(
      'emits stringified message on unexpected error',
      build: build,
      setUp: () {
        when(
          () => auth.signUp(
            email: any(named: 'email'),
            password: any(named: 'password'),
            name: any(named: 'name'),
          ),
        ).thenThrow(Exception('boom'));
      },
      act: (cubit) =>
          cubit.signUp(email: 'a@b.c', password: 'secret123', name: 'Ana'),
      expect: () => [
        isA<SignUpLoading>(),
        isA<SignUpError>().having(
          (e) => e.message,
          'message',
          contains('boom'),
        ),
      ],
    );
  });
}

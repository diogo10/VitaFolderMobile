import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:house_mira_core/auth/auth_service.dart';
import 'package:house_mira_login/presentation/cubit/sign_up_cubit.dart';
import 'package:house_mira_login/presentation/cubit/sign_up_state.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _MockAuthService extends Mock implements AuthService {}

User _user() => User.fromJson({'id': 'u1', 'email': 'a@b.c'})!;

void main() {
  late _MockAuthService auth;

  setUp(() {
    auth = _MockAuthService();
    // Mirror the real AuthService classification so the cubit can be
    // tested without importing Supabase types itself.
    when(() => auth.isAuthError(any())).thenAnswer(
      (invocation) => invocation.positionalArguments.single is AuthException,
    );
    when(() => auth.isInvalidCredentialsError(any())).thenAnswer(
      (invocation) => invocation.positionalArguments.single is AuthApiException,
    );
    when(() => auth.authErrorMessage(any())).thenAnswer((invocation) {
      final error = invocation.positionalArguments.single;
      return error is AuthException ? error.message : null;
    });
  });

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
        isA<SignUpError>()
            .having((e) => e.code, 'code', SignUpErrorCode.unexpected)
            .having((e) => e.message, 'message', 'Email taken'),
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
        isA<SignUpError>()
            .having((e) => e.code, 'code', SignUpErrorCode.unexpected)
            .having((e) => e.message, 'message', contains('boom')),
      ],
    );

    blocTest<SignUpCubit, SignUpState>(
      'signInWithGoogle emits loading then success',
      build: build,
      setUp: () {
        when(() => auth.signInWithGoogle()).thenAnswer((_) async => _user());
      },
      act: (cubit) => cubit.signInWithGoogle(),
      expect: () => [isA<SignUpLoading>(), isA<SignUpSuccess>()],
      verify: (_) {
        verify(() => auth.signInWithGoogle()).called(1);
      },
    );

    blocTest<SignUpCubit, SignUpState>(
      'signInWithGoogle emits initial when the user cancels',
      build: build,
      setUp: () {
        when(() => auth.signInWithGoogle()).thenAnswer((_) async => null);
      },
      act: (cubit) => cubit.signInWithGoogle(),
      expect: () => [isA<SignUpLoading>(), isA<SignUpInitial>()],
    );

    blocTest<SignUpCubit, SignUpState>(
      'signInWithGoogle emits message from AuthException',
      build: build,
      setUp: () {
        when(
          () => auth.signInWithGoogle(),
        ).thenThrow(const AuthException('Google sign-in failed.'));
      },
      act: (cubit) => cubit.signInWithGoogle(),
      expect: () => [
        isA<SignUpLoading>(),
        isA<SignUpError>()
            .having((e) => e.message, 'message', 'Google sign-in failed.')
            .having((e) => e.code, 'code', SignUpErrorCode.googleSignInFailed),
      ],
    );

    blocTest<SignUpCubit, SignUpState>(
      'signInWithGoogle emits unexpected code on unexpected error',
      build: build,
      setUp: () {
        when(() => auth.signInWithGoogle()).thenThrow(Exception('boom'));
      },
      act: (cubit) => cubit.signInWithGoogle(),
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
      'signInWithApple emits loading then success',
      build: build,
      setUp: () {
        when(() => auth.signInWithApple()).thenAnswer((_) async => _user());
      },
      act: (cubit) => cubit.signInWithApple(),
      expect: () => [isA<SignUpLoading>(), isA<SignUpSuccess>()],
      verify: (_) {
        verify(() => auth.signInWithApple()).called(1);
      },
    );

    blocTest<SignUpCubit, SignUpState>(
      'signInWithApple emits initial when the user cancels',
      build: build,
      setUp: () {
        when(() => auth.signInWithApple()).thenAnswer((_) async => null);
      },
      act: (cubit) => cubit.signInWithApple(),
      expect: () => [isA<SignUpLoading>(), isA<SignUpInitial>()],
    );

    blocTest<SignUpCubit, SignUpState>(
      'signInWithApple emits message from AuthException',
      build: build,
      setUp: () {
        when(
          () => auth.signInWithApple(),
        ).thenThrow(const AuthException('Apple sign-in failed.'));
      },
      act: (cubit) => cubit.signInWithApple(),
      expect: () => [
        isA<SignUpLoading>(),
        isA<SignUpError>()
            .having((e) => e.message, 'message', 'Apple sign-in failed.')
            .having((e) => e.code, 'code', SignUpErrorCode.appleSignInFailed),
      ],
    );

    blocTest<SignUpCubit, SignUpState>(
      'signInWithApple emits unexpected code on unexpected error',
      build: build,
      setUp: () {
        when(() => auth.signInWithApple()).thenThrow(Exception('boom'));
      },
      act: (cubit) => cubit.signInWithApple(),
      expect: () => [
        isA<SignUpLoading>(),
        isA<SignUpError>().having(
          (e) => e.code,
          'code',
          SignUpErrorCode.unexpected,
        ),
      ],
    );
  });

  group('SignUpCubit closed while a sign-in is in flight', () {
    /// Runs [act], closes the cubit while the call is still pending, then
    /// completes the call with [complete].
    ///
    /// The user can leave the sign-up screen while the native flow is up,
    /// which closes the cubit. Emitting into a closed cubit throws
    /// `Bad state: Cannot emit new states after calling close` and crashed
    /// the app (FATAL Crashlytics issue `04df8a6a`).
    Future<List<SignUpState>> closeDuringCall({
      required Future<void> Function(SignUpCubit cubit) act,
      required void Function() complete,
    }) async {
      final cubit = SignUpCubit(auth);
      final states = <SignUpState>[];
      final firstState = Completer<SignUpState>();
      final subscription = cubit.stream.listen((state) {
        if (!firstState.isCompleted) firstState.complete(state);
        states.add(state);
      });

      final pending = act(cubit);
      await firstState.future;
      await cubit.close();
      complete();

      await expectLater(pending, completes);
      await Future<void>.delayed(Duration.zero);
      await subscription.cancel();
      return states;
    }

    test(
      'signInWithGoogle does not emit an error after the cubit is closed',
      () async {
        final completer = Completer<User?>();
        when(() => auth.signInWithGoogle()).thenAnswer((_) => completer.future);

        final states = await closeDuringCall(
          act: (cubit) => cubit.signInWithGoogle(),
          complete: () => completer.completeError(Exception('boom')),
        );

        expect(states, hasLength(1));
        expect(states.single, isA<SignUpLoading>());
      },
    );

    test(
      'signInWithGoogle does not emit success after the cubit is closed',
      () async {
        final completer = Completer<User?>();
        when(() => auth.signInWithGoogle()).thenAnswer((_) => completer.future);

        final states = await closeDuringCall(
          act: (cubit) => cubit.signInWithGoogle(),
          complete: () => completer.complete(_user()),
        );

        expect(states, hasLength(1));
        expect(states.single, isA<SignUpLoading>());
      },
    );

    test(
      'signInWithApple does not emit an error after the cubit is closed',
      () async {
        final completer = Completer<User?>();
        when(() => auth.signInWithApple()).thenAnswer((_) => completer.future);

        final states = await closeDuringCall(
          act: (cubit) => cubit.signInWithApple(),
          complete: () => completer.completeError(Exception('boom')),
        );

        expect(states, hasLength(1));
        expect(states.single, isA<SignUpLoading>());
      },
    );

    test('signUp does not emit an error after the cubit is closed', () async {
      final completer = Completer<User?>();
      when(
        () => auth.signUp(
          email: any(named: 'email'),
          password: any(named: 'password'),
          name: any(named: 'name'),
        ),
      ).thenAnswer((_) => completer.future);

      final states = await closeDuringCall(
        act: (cubit) =>
            cubit.signUp(email: 'a@b.c', password: 'secret123', name: 'Ana'),
        complete: () => completer.completeError(Exception('boom')),
      );

      expect(states, hasLength(1));
      expect(states.single, isA<SignUpLoading>());
    });
  });
}

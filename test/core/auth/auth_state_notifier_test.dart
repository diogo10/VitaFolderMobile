import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:house_mira/core/auth/auth_state_notifier.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _MockSession extends Mock implements Session {}

void main() {
  group('AuthStateNotifier', () {
    test('starts uninitialized and unauthenticated without a session', () {
      final notifier = AuthStateNotifier(
        authStateStream: const Stream<AuthState>.empty(),
      );
      addTearDown(notifier.dispose);

      expect(notifier.isInitialized, isFalse);
      expect(notifier.isAuthenticated, isFalse);
      expect(notifier.session, isNull);
    });

    test('seeds isAuthenticated from the recovered session', () {
      final session = _MockSession();
      final notifier = AuthStateNotifier(
        authStateStream: const Stream<AuthState>.empty(),
        initialSession: session,
      );
      addTearDown(notifier.dispose);

      // The synchronously recovered session is visible immediately, but the
      // notifier is not initialized until onAuthStateChange confirms it, so
      // the router keeps showing the splash gate (no FOUNC).
      expect(notifier.isAuthenticated, isTrue);
      expect(notifier.session, same(session));
      expect(notifier.isInitialized, isFalse);
    });

    test(
      'initialSession event completes initialization (session recovery)',
      () async {
        final controller = StreamController<AuthState>.broadcast();
        final notifier = AuthStateNotifier(authStateStream: controller.stream);
        addTearDown(() async {
          notifier.dispose();
          await controller.close();
        });

        final session = _MockSession();
        controller.add(AuthState(AuthChangeEvent.initialSession, session));
        await Future<void>.delayed(Duration.zero);

        expect(notifier.isInitialized, isTrue);
        expect(notifier.isAuthenticated, isTrue);
        expect(notifier.session, same(session));
      },
    );

    test(
      'initialSession with null session means signed out but initialized',
      () async {
        final controller = StreamController<AuthState>.broadcast();
        final notifier = AuthStateNotifier(authStateStream: controller.stream);
        addTearDown(() async {
          notifier.dispose();
          await controller.close();
        });

        controller.add(const AuthState(AuthChangeEvent.initialSession, null));
        await Future<void>.delayed(Duration.zero);

        expect(notifier.isInitialized, isTrue);
        expect(notifier.isAuthenticated, isFalse);
      },
    );

    test('signedIn then signedOut transitions notify listeners', () async {
      final controller = StreamController<AuthState>.broadcast();
      final notifier = AuthStateNotifier(authStateStream: controller.stream);
      addTearDown(() async {
        notifier.dispose();
        await controller.close();
      });

      var notifications = 0;
      notifier.addListener(() => notifications++);

      final session = _MockSession();
      controller.add(AuthState(AuthChangeEvent.signedIn, session));
      await Future<void>.delayed(Duration.zero);
      expect(notifier.isAuthenticated, isTrue);

      controller.add(const AuthState(AuthChangeEvent.signedOut, null));
      await Future<void>.delayed(Duration.zero);
      expect(notifier.isAuthenticated, isFalse);
      expect(notifier.isInitialized, isTrue);
      expect(notifications, 2);
    });

    test('no stream marks initialized immediately', () {
      final notifier = AuthStateNotifier();
      addTearDown(notifier.dispose);

      expect(notifier.isInitialized, isTrue);
      expect(notifier.isAuthenticated, isFalse);
    });
  });
}

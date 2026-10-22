import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:house_mira_core/config/remote_config_service.dart';
import 'package:house_mira_core/observability/app_logger.dart';
import 'package:mocktail/mocktail.dart';

class _MockRemoteConfig extends Mock implements FirebaseRemoteConfig {}

void main() {
  late _MockRemoteConfig remoteConfig;
  late RemoteConfigService service;

  setUp(() {
    remoteConfig = _MockRemoteConfig();
    when(() => remoteConfig.setDefaults(any())).thenAnswer((_) async {});
    when(
      () => remoteConfig.getBool('enable_limit_and_paywall'),
    ).thenReturn(false);
    when(
      () => remoteConfig.getBool('show_apple_login'),
    ).thenReturn(false);
    service = RemoteConfigService(
      remoteConfig: remoteConfig,
      logger: AppLogger(),
    );
  });

  group('enableLimitAndPaywall', () {
    test('defaults to false when no live config is wired', () {
      final noConfig = RemoteConfigService(logger: AppLogger());
      expect(noConfig.enableLimitAndPaywall, isFalse);
    });

    test('returns false when the flag is off', () {
      when(
        () => remoteConfig.getBool('enable_limit_and_paywall'),
      ).thenReturn(false);
      expect(service.enableLimitAndPaywall, isFalse);
    });

    test('returns true when the flag is on', () {
      when(
        () => remoteConfig.getBool('enable_limit_and_paywall'),
      ).thenReturn(true);
      expect(service.enableLimitAndPaywall, isTrue);
    });
  });

  group('showAppleLogin', () {
    test('defaults to false when no live config is wired', () {
      final noConfig = RemoteConfigService(logger: AppLogger());
      expect(noConfig.showAppleLogin, isFalse);
    });

    test('returns false when the flag is off', () {
      when(() => remoteConfig.getBool('show_apple_login')).thenReturn(false);
      expect(service.showAppleLogin, isFalse);
    });

    test('returns true when the flag is on', () {
      when(() => remoteConfig.getBool('show_apple_login')).thenReturn(true);
      expect(service.showAppleLogin, isTrue);
    });
  });

  group('initialize', () {
    test('sets the flag defaults to false and activates', () async {
      when(() => remoteConfig.fetchAndActivate()).thenAnswer((_) async => true);
      await service.initialize();
      verify(
        () => remoteConfig.setDefaults(
          {'enable_limit_and_paywall': false, 'show_apple_login': false},
        ),
      ).called(1);
      verify(() => remoteConfig.fetchAndActivate()).called(1);
    });

    test('falls back to defaults when fetch fails', () async {
      when(
        () => remoteConfig.fetchAndActivate(),
      ).thenThrow(Exception('network down'));
      // Should not throw; defaults keep the flag off.
      await service.initialize();
      expect(service.enableLimitAndPaywall, isFalse);
      expect(service.showAppleLogin, isFalse);
    });
  });
}

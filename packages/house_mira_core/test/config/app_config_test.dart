import 'package:flutter_test/flutter_test.dart';
import 'package:house_mira_core/config/app_config.dart';
import 'package:house_mira_core/config/app_flavor.dart';

void main() {
  const validUrl = 'https://example.supabase.co';
  const validKey = 'test-publishable-key';

  group('AppConfig.fromDefines', () {
    test('builds config from valid defines', () {
      final config = AppConfig.fromDefines(
        flavorRaw: 'dev',
        supabaseUrl: validUrl,
        supabasePublishableKey: validKey,
        revenueCatAppleApiKey: '',
        revenueCatGoogleApiKey: '',
      );

      expect(config.flavor, AppFlavor.dev);
      expect(config.supabaseUrl, validUrl);
      expect(config.supabasePublishableKey, validKey);
      expect(config.revenueCatAppleApiKey, isEmpty);
      expect(config.revenueCatGoogleApiKey, isEmpty);
    });

    test('resolves each flavor', () {
      for (final flavor in AppFlavor.values) {
        final config = AppConfig.fromDefines(
          flavorRaw: flavor.name,
          supabaseUrl: validUrl,
          supabasePublishableKey: validKey,
          revenueCatAppleApiKey: '',
          revenueCatGoogleApiKey: '',
        );
        expect(config.flavor, flavor);
      }
    });

    test('throws StateError on missing or invalid flavor', () {
      expect(
        () => AppConfig.fromDefines(
          flavorRaw: '',
          supabaseUrl: validUrl,
          supabasePublishableKey: validKey,
          revenueCatAppleApiKey: '',
          revenueCatGoogleApiKey: '',
        ),
        throwsStateError,
      );
      expect(
        () => AppConfig.fromDefines(
          flavorRaw: 'production',
          supabaseUrl: validUrl,
          supabasePublishableKey: validKey,
          revenueCatAppleApiKey: '',
          revenueCatGoogleApiKey: '',
        ),
        throwsStateError,
      );
    });

    test('throws StateError on missing or non-https URL', () {
      for (final badUrl in [
        '',
        'not-a-url',
        'http://example.supabase.co',
        'https://',
        'ftp://example.supabase.co',
      ]) {
        expect(
          () => AppConfig.fromDefines(
            flavorRaw: 'staging',
            supabaseUrl: badUrl,
            supabasePublishableKey: validKey,
            revenueCatAppleApiKey: '',
            revenueCatGoogleApiKey: '',
          ),
          throwsStateError,
          reason: 'URL: "$badUrl"',
        );
      }
    });

    test('throws StateError on missing publishable key', () {
      expect(
        () => AppConfig.fromDefines(
          flavorRaw: 'prod',
          supabaseUrl: validUrl,
          supabasePublishableKey: '',
          revenueCatAppleApiKey: '',
          revenueCatGoogleApiKey: '',
        ),
        throwsStateError,
      );
    });

    test('stores RevenueCat keys from defines', () {
      final config = AppConfig.fromDefines(
        flavorRaw: 'prod',
        supabaseUrl: validUrl,
        supabasePublishableKey: validKey,
        revenueCatAppleApiKey: 'fake-apple-key',
        revenueCatGoogleApiKey: 'fake-google-key',
      );

      expect(config.revenueCatAppleApiKey, 'fake-apple-key');
      expect(config.revenueCatGoogleApiKey, 'fake-google-key');
    });
  });
}

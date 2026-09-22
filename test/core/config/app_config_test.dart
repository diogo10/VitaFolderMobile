import 'package:flutter_test/flutter_test.dart';
import 'package:house_mira/core/config/app_config.dart';
import 'package:house_mira/core/config/app_flavor.dart';

void main() {
  const validUrl = 'https://example.supabase.co';
  const validKey = 'test-publishable-key';

  group('AppConfig.fromDefines', () {
    test('builds config from valid defines', () {
      final config = AppConfig.fromDefines(
        flavorRaw: 'dev',
        supabaseUrl: validUrl,
        supabasePublishableKey: validKey,
      );

      expect(config.flavor, AppFlavor.dev);
      expect(config.supabaseUrl, validUrl);
      expect(config.supabasePublishableKey, validKey);
    });

    test('resolves each flavor', () {
      for (final flavor in AppFlavor.values) {
        final config = AppConfig.fromDefines(
          flavorRaw: flavor.name,
          supabaseUrl: validUrl,
          supabasePublishableKey: validKey,
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
        ),
        throwsStateError,
      );
      expect(
        () => AppConfig.fromDefines(
          flavorRaw: 'production',
          supabaseUrl: validUrl,
          supabasePublishableKey: validKey,
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
        ),
        throwsStateError,
      );
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:house_mira/features/reminders/application/time_zone_provider.dart';
import 'package:timezone/timezone.dart' as tz;

void main() {
  setUp(DeviceTimeZoneProvider.resetForTest);

  tearDown(DeviceTimeZoneProvider.resetForTest);

  group('DeviceTimeZoneProvider', () {
    test('configures the device time zone', () async {
      final provider = DeviceTimeZoneProvider(
        localTimeZoneName: () async => 'America/New_York',
      );

      await provider.configureLocal();

      expect(tz.local.name, 'America/New_York');
      expect(
        provider.fromLocal(DateTime(2030, 5, 4, 9)),
        tz.TZDateTime(tz.local, 2030, 5, 4, 9),
      );
    });

    test('initializes the database only once', () async {
      final provider = DeviceTimeZoneProvider(
        localTimeZoneName: () async => 'Europe/Lisbon',
      );

      await provider.configureLocal();
      await provider.configureLocal();

      expect(tz.local.name, 'Europe/Lisbon');
    });

    test('falls back silently when the lookup fails', () async {
      final provider = DeviceTimeZoneProvider(
        localTimeZoneName: () async => throw Exception('no platform'),
      );

      await provider.configureLocal();

      // No throw; wall-clock times still convert.
      expect(
        provider.fromLocal(DateTime(2030, 5, 4, 9)).year,
        2030,
      );
    });

    test('uses the platform lookup without an override', () async {
      // No platform channel in unit tests: FlutterTimezone throws and the
      // provider degrades silently instead of crashing.
      await DeviceTimeZoneProvider().configureLocal();
    });
  });
}

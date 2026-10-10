import 'package:flutter/foundation.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// Resolves the device time zone for local notification scheduling.
///
/// Extracted so the reminder notification service configures `tz.local` on
/// every schedule (not just `init()`), and so tests can substitute a fake.
abstract interface class TimeZoneProvider {
  /// Ensures the tz database is initialized and `tz.local` matches the
  /// device. Never throws.
  Future<void> configureLocal();

  /// Interprets a wall-clock [dateTime] in `tz.local`.
  tz.TZDateTime fromLocal(DateTime dateTime);
}

class DeviceTimeZoneProvider implements TimeZoneProvider {
  DeviceTimeZoneProvider({Future<String> Function()? localTimeZoneName})
    : _localTimeZoneName = localTimeZoneName;
  static bool _initialized = false;

  final Future<String> Function()? _localTimeZoneName;

  @visibleForTesting
  static void resetForTest() => _initialized = false;

  @override
  Future<void> configureLocal() async {
    try {
      if (!_initialized) {
        tz.initializeTimeZones();
        _initialized = true;
      }
      final String name;
      final override = _localTimeZoneName;
      if (override != null) {
        name = await override();
      } else {
        name = (await FlutterTimezone.getLocalTimezone()).identifier;
      }
      tz.setLocalLocation(tz.getLocation(name));
    } on Object catch (_) {
      debugPrint('TimeZoneProvider: using default time zone.');
    }
  }

  @override
  tz.TZDateTime fromLocal(DateTime dateTime) => tz.TZDateTime(
    tz.local,
    dateTime.year,
    dateTime.month,
    dateTime.day,
    dateTime.hour,
    dateTime.minute,
    dateTime.second,
    dateTime.millisecond,
    dateTime.microsecond,
  );
}

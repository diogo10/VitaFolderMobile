import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:house_mira/features/account/application/notification_permission_service.dart';

const _channel = MethodChannel('flutter.baseflow.com/permissions/methods');

// permission_handler_platform_interface value mapping:
// denied=0, granted=1, restricted=2, limited=3, permanentlyDenied=4,
// provisional=5. Notification permission id = 17.
void mockPermissionResponses({
  int checkStatus = 1,
  Map<int, int>? requestResult,
  bool throwOnRequest = false,
}) {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(_channel, (call) async {
        switch (call.method) {
          case 'checkPermissionStatus':
            return checkStatus;
          case 'requestPermissions':
            if (throwOnRequest) {
              throw PlatformException(code: 'unavailable');
            }
            final requested = (call.arguments as List<dynamic>).cast<int>();
            return {
              for (final permission in requested)
                permission: requestResult?[permission] ?? 1,
            };
          default:
            return null;
        }
      });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, null);
  });

  final service = NotificationPermissionService();

  group('requestNotificationPermission', () {
    test('maps granted status to granted', () async {
      mockPermissionResponses(requestResult: {17: 1});

      expect(
        await service.requestNotificationPermission(),
        NotificationPermissionResult.granted,
      );
    });

    test('maps limited and provisional to granted', () async {
      mockPermissionResponses(requestResult: {17: 3});
      expect(
        await service.requestNotificationPermission(),
        NotificationPermissionResult.granted,
      );

      mockPermissionResponses(requestResult: {17: 5});
      expect(
        await service.requestNotificationPermission(),
        NotificationPermissionResult.granted,
      );
    });

    test('maps permanently denied status', () async {
      mockPermissionResponses(requestResult: {17: 4});

      expect(
        await service.requestNotificationPermission(),
        NotificationPermissionResult.permanentlyDenied,
      );
    });

    test('maps denied status to denied', () async {
      mockPermissionResponses(requestResult: {17: 0});

      expect(
        await service.requestNotificationPermission(),
        NotificationPermissionResult.denied,
      );
    });

    test('degrades to denied when the platform channel throws', () async {
      mockPermissionResponses(throwOnRequest: true);

      expect(
        await service.requestNotificationPermission(),
        NotificationPermissionResult.denied,
      );
    });
  });

  group('hasNotificationPermission', () {
    test('returns true when granted', () async {
      mockPermissionResponses();

      expect(await service.hasNotificationPermission(), isTrue);
    });

    test('returns false when denied', () async {
      mockPermissionResponses(checkStatus: 0);

      expect(await service.hasNotificationPermission(), isFalse);
    });
  });
}

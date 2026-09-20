import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:house_mira/core/local_storage/local_storage_datasource.dart';
import 'package:house_mira/features/account/application/notification_permission_service.dart';
import 'package:house_mira/features/account/presentation/cubit/notification_settings_cubit.dart';
import 'package:house_mira/features/account/presentation/cubit/notification_settings_state.dart';
import 'package:house_mira/features/reminders/application/reminder_notification_service.dart';
import 'package:mocktail/mocktail.dart';

class _FakePermissionService extends NotificationPermissionService {
  _FakePermissionService(
    this.result,
  );
  NotificationPermissionResult result;

  @override
  Future<NotificationPermissionResult> requestNotificationPermission() async =>
      result;
}

class _MockStorage extends Mock implements LocalStorageDatasource {}

class _MockNotificationService extends Mock
    implements IReminderNotificationService {}

void main() {
  late _MockStorage storage;
  late _MockNotificationService notificationService;

  setUp(() {
    storage = _MockStorage();
    notificationService = _MockNotificationService();
    when(
      () => storage.setBool(any(), value: any(named: 'value')),
    ).thenAnswer((_) async {});
    when(
      () => notificationService.showTestNotification(
        title: any(named: 'title'),
        body: any(named: 'body'),
      ),
    ).thenAnswer((_) async => true);
  });

  NotificationSettingsCubit build({
    NotificationPermissionResult permissionResult =
        NotificationPermissionResult.granted,
  }) => NotificationSettingsCubit(
    permissionService: _FakePermissionService(permissionResult),
    storage: storage,
    notificationService: notificationService,
  );

  group('loadSettings', () {
    blocTest<NotificationSettingsCubit, NotificationSettingsState>(
      'emits loaded with the stored flag',
      build: build,
      setUp: () {
        when(
          () => storage.getBool('notifications_enabled'),
        ).thenAnswer((_) async => true);
      },
      act: (cubit) => cubit.loadSettings(),
      expect: () => [
        isA<NotificationSettingsLoaded>().having(
          (s) => s.notificationsEnabled,
          'notificationsEnabled',
          isTrue,
        ),
      ],
    );

    blocTest<NotificationSettingsCubit, NotificationSettingsState>(
      'emits error when storage throws',
      build: build,
      setUp: () {
        when(
          () => storage.getBool(any()),
        ).thenThrow(Exception('boom'));
      },
      act: (cubit) => cubit.loadSettings(),
      expect: () => [isA<NotificationSettingsError>()],
    );
  });

  group('setNotificationsEnabled', () {
    blocTest<NotificationSettingsCubit, NotificationSettingsState>(
      'enables and persists when permission is granted (from loading)',
      build: build,
      act: (cubit) => cubit.setNotificationsEnabled(enabled: true),
      expect: () => [
        isA<NotificationSettingsLoaded>()
            .having((s) => s.notificationsEnabled, 'enabled', isTrue)
            .having((s) => s.permissionDenied, 'denied', isNull),
      ],
      verify: (_) {
        verify(
          () => storage.setBool('notifications_enabled', value: true),
        ).called(1);
      },
    );

    blocTest<NotificationSettingsCubit, NotificationSettingsState>(
      'keeps current flag when enabling from a loaded state',
      build: build,
      setUp: () {
        when(
          () => storage.getBool('notifications_enabled'),
        ).thenAnswer((_) async => false);
      },
      act: (cubit) async {
        await cubit.loadSettings();
        await cubit.setNotificationsEnabled(enabled: true);
      },
      expect: () => [
        isA<NotificationSettingsLoaded>().having(
          (s) => s.notificationsEnabled,
          'enabled',
          isFalse,
        ),
        isA<NotificationSettingsLoaded>().having(
          (s) => s.notificationsEnabled,
          'enabled',
          isTrue,
        ),
      ],
    );

    blocTest<NotificationSettingsCubit, NotificationSettingsState>(
      'reports permanently denied without persisting',
      build: () => build(
        permissionResult: NotificationPermissionResult.permanentlyDenied,
      ),
      act: (cubit) => cubit.setNotificationsEnabled(enabled: true),
      expect: () => [
        isA<NotificationSettingsLoaded>()
            .having((s) => s.notificationsEnabled, 'enabled', isFalse)
            .having(
              (s) => s.permissionDenied,
              'denied',
              NotificationPermissionDenied.permanentlyDenied,
            ),
      ],
      verify: (_) {
        verifyNever(
          () => storage.setBool(any(), value: any(named: 'value')),
        );
      },
    );

    blocTest<NotificationSettingsCubit, NotificationSettingsState>(
      'reports denied without persisting',
      build: () => build(permissionResult: NotificationPermissionResult.denied),
      act: (cubit) => cubit.setNotificationsEnabled(enabled: true),
      expect: () => [
        isA<NotificationSettingsLoaded>()
            .having((s) => s.notificationsEnabled, 'enabled', isFalse)
            .having(
              (s) => s.permissionDenied,
              'denied',
              NotificationPermissionDenied.denied,
            ),
      ],
      verify: (_) {
        verifyNever(
          () => storage.setBool(any(), value: any(named: 'value')),
        );
      },
    );

    blocTest<NotificationSettingsCubit, NotificationSettingsState>(
      'disables and persists when switched off',
      build: build,
      act: (cubit) => cubit.setNotificationsEnabled(enabled: false),
      expect: () => [
        isA<NotificationSettingsLoaded>().having(
          (s) => s.notificationsEnabled,
          'enabled',
          isFalse,
        ),
      ],
      verify: (_) {
        verify(
          () => storage.setBool('notifications_enabled', value: false),
        ).called(1);
      },
    );
  });

  group('sendTestNotification', () {
    blocTest<NotificationSettingsCubit, NotificationSettingsState>(
      'emits sent when the test notification posts',
      build: build,
      act: (cubit) => cubit.sendTestNotification(title: 'T', body: 'B'),
      expect: () => [
        isA<NotificationSettingsLoaded>().having(
          (s) => s.testResult,
          'testResult',
          NotificationTestResult.sent,
        ),
      ],
      verify: (_) {
        verify(
          () => notificationService.showTestNotification(
            title: 'T',
            body: 'B',
          ),
        ).called(1);
      },
    );

    blocTest<NotificationSettingsCubit, NotificationSettingsState>(
      'emits failed when posting returns false',
      build: build,
      setUp: () {
        when(
          () => notificationService.showTestNotification(
            title: any(named: 'title'),
            body: any(named: 'body'),
          ),
        ).thenAnswer((_) async => false);
      },
      act: (cubit) => cubit.sendTestNotification(title: 'T', body: 'B'),
      expect: () => [
        isA<NotificationSettingsLoaded>().having(
          (s) => s.testResult,
          'testResult',
          NotificationTestResult.failed,
        ),
      ],
    );

    blocTest<NotificationSettingsCubit, NotificationSettingsState>(
      'emits failed when posting throws',
      build: build,
      setUp: () {
        when(
          () => notificationService.showTestNotification(
            title: any(named: 'title'),
            body: any(named: 'body'),
          ),
        ).thenThrow(Exception('os'));
      },
      act: (cubit) => cubit.sendTestNotification(title: 'T', body: 'B'),
      expect: () => [
        isA<NotificationSettingsLoaded>().having(
          (s) => s.testResult,
          'testResult',
          NotificationTestResult.failed,
        ),
      ],
    );
  });
}

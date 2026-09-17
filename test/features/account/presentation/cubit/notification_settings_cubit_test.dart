import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:house_mira/core/local_storage/local_storage_datasource.dart';
import 'package:house_mira/features/account/application/notification_permission_service.dart';
import 'package:house_mira/features/account/presentation/cubit/notification_settings_cubit.dart';
import 'package:house_mira/features/account/presentation/cubit/notification_settings_state.dart';

class _FakePermissionService extends NotificationPermissionService {
  NotificationPermissionResult result;

  _FakePermissionService(
    this.result,
  );

  @override
  Future<NotificationPermissionResult> requestNotificationPermission() async =>
      result;
}

class _MockStorage extends Mock implements LocalStorageDatasource {}

void main() {
  late _MockStorage storage;

  setUp(() {
    storage = _MockStorage();
    when(
      () => storage.setBool(any(), any()),
    ).thenAnswer((_) async {});
  });

  NotificationSettingsCubit build({
    NotificationPermissionResult permissionResult =
        NotificationPermissionResult.granted,
  }) => NotificationSettingsCubit(
    permissionService: _FakePermissionService(permissionResult),
    storage: storage,
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
      act: (cubit) => cubit.setNotificationsEnabled(true),
      expect: () => [
        isA<NotificationSettingsLoaded>()
            .having((s) => s.notificationsEnabled, 'enabled', isTrue)
            .having((s) => s.permissionDenied, 'denied', isNull),
      ],
      verify: (_) {
        verify(() => storage.setBool('notifications_enabled', true)).called(1);
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
        await cubit.setNotificationsEnabled(true);
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
      act: (cubit) => cubit.setNotificationsEnabled(true),
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
        verifyNever(() => storage.setBool(any(), any()));
      },
    );

    blocTest<NotificationSettingsCubit, NotificationSettingsState>(
      'reports denied without persisting',
      build: () => build(permissionResult: NotificationPermissionResult.denied),
      act: (cubit) => cubit.setNotificationsEnabled(true),
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
        verifyNever(() => storage.setBool(any(), any()));
      },
    );

    blocTest<NotificationSettingsCubit, NotificationSettingsState>(
      'disables and persists when switched off',
      build: build,
      act: (cubit) => cubit.setNotificationsEnabled(false),
      expect: () => [
        isA<NotificationSettingsLoaded>().having(
          (s) => s.notificationsEnabled,
          'enabled',
          isFalse,
        ),
      ],
      verify: (_) {
        verify(() => storage.setBool('notifications_enabled', false)).called(1);
      },
    );
  });
}

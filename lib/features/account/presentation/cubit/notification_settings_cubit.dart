import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:house_mira/core/local_storage/local_storage_datasource.dart';
import 'package:house_mira/features/account/application/notification_permission_service.dart';
import 'package:house_mira/features/account/presentation/cubit/notification_settings_state.dart';
import 'package:house_mira/features/reminders/application/reminder_notification_service.dart';

class NotificationSettingsCubit extends Cubit<NotificationSettingsState> {
  NotificationSettingsCubit({
    required NotificationPermissionService permissionService,
    required LocalStorageDatasource storage,
    required IReminderNotificationService notificationService,
  }) : _permissionService = permissionService,
       _storage = storage,
       _notificationService = notificationService,
       super(NotificationSettingsLoading());
  final NotificationPermissionService _permissionService;
  final LocalStorageDatasource _storage;
  final IReminderNotificationService _notificationService;

  static const _notificationsEnabledKey = 'notifications_enabled';

  Future<void> loadSettings() async {
    try {
      final notificationsEnabled = await _storage.getBool(
        _notificationsEnabledKey,
      );
      emit(
        NotificationSettingsLoaded(notificationsEnabled: notificationsEnabled),
      );
    } on Object catch (_) {
      emit(NotificationSettingsError());
    }
  }

  Future<void> setNotificationsEnabled({required bool enabled}) async {
    if (enabled) {
      final result = await _permissionService.requestNotificationPermission();
      switch (result) {
        case NotificationPermissionResult.granted:
          await _storage.setBool(_notificationsEnabledKey, value: true);
          emit(_currentLoaded(notificationsEnabled: true));
        case NotificationPermissionResult.permanentlyDenied:
          emit(
            _currentLoaded(
              notificationsEnabled: false,
              permissionDenied: NotificationPermissionDenied.permanentlyDenied,
            ),
          );
        case NotificationPermissionResult.denied:
          emit(
            _currentLoaded(
              notificationsEnabled: false,
              permissionDenied: NotificationPermissionDenied.denied,
            ),
          );
      }
      return;
    }

    await _storage.setBool(_notificationsEnabledKey, value: false);
    emit(_currentLoaded(notificationsEnabled: false));
  }

  NotificationSettingsLoaded _currentLoaded({
    bool? notificationsEnabled,
    NotificationPermissionDenied? permissionDenied,
    NotificationTestResult? testResult,
  }) {
    if (state is NotificationSettingsLoaded) {
      final current = state as NotificationSettingsLoaded;
      return NotificationSettingsLoaded(
        notificationsEnabled:
            notificationsEnabled ?? current.notificationsEnabled,
        permissionDenied: permissionDenied,
        testResult: testResult,
      );
    }
    return NotificationSettingsLoaded(
      notificationsEnabled: notificationsEnabled ?? false,
      permissionDenied: permissionDenied,
      testResult: testResult,
    );
  }

  /// Posts an immediate test notification (no scheduling involved) so a
  /// missing reminder alert can be blamed on delivery vs. AlarmManager.
  /// Emits the outcome on the current loaded state; never throws.
  Future<void> sendTestNotification({
    required String title,
    required String body,
  }) async {
    bool sent;
    try {
      sent = await _notificationService.showTestNotification(
        title: title,
        body: body,
      );
    } on Object catch (_) {
      sent = false;
    }
    emit(
      _currentLoaded(
        testResult: sent
            ? NotificationTestResult.sent
            : NotificationTestResult.failed,
      ),
    );
  }
}

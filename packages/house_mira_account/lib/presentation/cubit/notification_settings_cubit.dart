import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:house_mira_core/local_storage/local_storage_datasource.dart';
import 'package:house_mira_core/notifications/notification_sender.dart';
import 'package:house_mira_account/application/notification_permission_service.dart';
import 'package:house_mira_account/presentation/cubit/notification_settings_state.dart';

class NotificationSettingsCubit extends Cubit<NotificationSettingsState> {
  NotificationSettingsCubit({
    required NotificationPermissionService permissionService,
    required LocalStorageDatasource storage,
    required NotificationSender notificationService,
  }) : _permissionService = permissionService,
       _storage = storage,
       _notificationService = notificationService,
       super(NotificationSettingsLoading());
  final NotificationPermissionService _permissionService;
  final LocalStorageDatasource _storage;
  final NotificationSender _notificationService;

  static const _notificationsEnabledKey = 'notifications_enabled';

  /// Emits [state] only while the cubit is still open.
  ///
  /// The screen owns this cubit through `BlocProvider(create:)`, so
  /// leaving it closes the cubit while the permission dialog or the
  /// storage write is still in flight. Emitting into a closed cubit
  /// throws `Bad state: Cannot emit new states after calling close` and
  /// crashes the app (FATAL Crashlytics issue `04df8a6a`).
  void _emitIfOpen(NotificationSettingsState state) {
    if (isClosed) return;
    emit(state);
  }

  Future<void> loadSettings() async {
    try {
      final notificationsEnabled = await _storage.getBool(
        _notificationsEnabledKey,
      );
      _emitIfOpen(
        NotificationSettingsLoaded(notificationsEnabled: notificationsEnabled),
      );
    } on Object catch (_) {
      _emitIfOpen(NotificationSettingsError());
    }
  }

  Future<void> setNotificationsEnabled({required bool enabled}) async {
    if (enabled) {
      final result = await _permissionService.requestNotificationPermission();
      switch (result) {
        case NotificationPermissionResult.granted:
          await _storage.setBool(_notificationsEnabledKey, value: true);
          _emitIfOpen(_currentLoaded(notificationsEnabled: true));
        case NotificationPermissionResult.permanentlyDenied:
          _emitIfOpen(
            _currentLoaded(
              notificationsEnabled: false,
              permissionDenied: NotificationPermissionDenied.permanentlyDenied,
            ),
          );
        case NotificationPermissionResult.denied:
          _emitIfOpen(
            _currentLoaded(
              notificationsEnabled: false,
              permissionDenied: NotificationPermissionDenied.denied,
            ),
          );
      }
      return;
    }

    await _storage.setBool(_notificationsEnabledKey, value: false);
    _emitIfOpen(_currentLoaded(notificationsEnabled: false));
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
    _emitIfOpen(
      _currentLoaded(
        testResult: sent
            ? NotificationTestResult.sent
            : NotificationTestResult.failed,
      ),
    );
  }
}

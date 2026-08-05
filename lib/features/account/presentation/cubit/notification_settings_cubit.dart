import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vita_folder_mobile/core/local_storage/local_storage_datasource.dart';
import 'package:vita_folder_mobile/features/account/application/notification_permission_service.dart';
import 'package:vita_folder_mobile/features/account/presentation/cubit/notification_settings_state.dart';

class NotificationSettingsCubit extends Cubit<NotificationSettingsState> {
  final NotificationPermissionService _permissionService;
  final LocalStorageDatasource _storage;

  static const _notificationsEnabledKey = 'notifications_enabled';
  static const _emailUpdatesEnabledKey = 'email_updates_enabled';

  NotificationSettingsCubit({
    required NotificationPermissionService permissionService,
    required LocalStorageDatasource storage,
  })  : _permissionService = permissionService,
        _storage = storage,
        super(NotificationSettingsLoading());

  Future<void> loadSettings() async {
    try {
      final notificationsEnabled =
          await _storage.getBool(_notificationsEnabledKey);
      final emailUpdatesEnabled =
          await _storage.getBool(_emailUpdatesEnabledKey);
      emit(
        NotificationSettingsLoaded(
          notificationsEnabled: notificationsEnabled,
          emailUpdatesEnabled: emailUpdatesEnabled,
        ),
      );
    } catch (_) {
      emit(NotificationSettingsError());
    }
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    if (enabled) {
      final result = await _permissionService.requestNotificationPermission();
      switch (result) {
        case NotificationPermissionResult.granted:
          await _storage.setBool(_notificationsEnabledKey, true);
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

    await _storage.setBool(_notificationsEnabledKey, false);
    emit(_currentLoaded(notificationsEnabled: false));
  }

  Future<void> setEmailUpdatesEnabled(bool enabled) async {
    await _storage.setBool(_emailUpdatesEnabledKey, enabled);
    emit(_currentLoaded(emailUpdatesEnabled: enabled));
  }

  NotificationSettingsLoaded _currentLoaded({
    bool? notificationsEnabled,
    bool? emailUpdatesEnabled,
    NotificationPermissionDenied? permissionDenied,
  }) {
    if (state is NotificationSettingsLoaded) {
      final current = state as NotificationSettingsLoaded;
      return NotificationSettingsLoaded(
        notificationsEnabled:
            notificationsEnabled ?? current.notificationsEnabled,
        emailUpdatesEnabled: emailUpdatesEnabled ?? current.emailUpdatesEnabled,
        permissionDenied: permissionDenied,
      );
    }
    return NotificationSettingsLoaded(
      notificationsEnabled: notificationsEnabled ?? false,
      emailUpdatesEnabled: emailUpdatesEnabled ?? false,
      permissionDenied: permissionDenied,
    );
  }
}

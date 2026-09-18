import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:house_mira/core/local_storage/local_storage_datasource.dart';
import 'package:house_mira/features/account/application/notification_permission_service.dart';
import 'package:house_mira/features/account/presentation/cubit/notification_settings_state.dart';

class NotificationSettingsCubit extends Cubit<NotificationSettingsState> {
  NotificationSettingsCubit({
    required NotificationPermissionService permissionService,
    required LocalStorageDatasource storage,
  }) : _permissionService = permissionService,
       _storage = storage,
       super(NotificationSettingsLoading());
  final NotificationPermissionService _permissionService;
  final LocalStorageDatasource _storage;

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
  }) {
    if (state is NotificationSettingsLoaded) {
      final current = state as NotificationSettingsLoaded;
      return NotificationSettingsLoaded(
        notificationsEnabled:
            notificationsEnabled ?? current.notificationsEnabled,
        permissionDenied: permissionDenied,
      );
    }
    return NotificationSettingsLoaded(
      notificationsEnabled: notificationsEnabled ?? false,
      permissionDenied: permissionDenied,
    );
  }
}

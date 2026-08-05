import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

enum NotificationPermissionResult { granted, denied, permanentlyDenied }

class NotificationPermissionService {
  Future<NotificationPermissionResult> requestNotificationPermission() async {
    try {
      final status = await Permission.notification.request();
      return _mapStatus(status);
    } on Exception {
      debugPrint('Failed to request notification permission.');
      return NotificationPermissionResult.denied;
    }
  }

  Future<bool> hasNotificationPermission() async {
    final status = await Permission.notification.status;
    return _mapStatus(status) == NotificationPermissionResult.granted;
  }

  NotificationPermissionResult _mapStatus(PermissionStatus status) {
    if (status.isGranted || status.isLimited || status.isProvisional) {
      return NotificationPermissionResult.granted;
    }
    if (status.isPermanentlyDenied) {
      return NotificationPermissionResult.permanentlyDenied;
    }
    return NotificationPermissionResult.denied;
  }
}

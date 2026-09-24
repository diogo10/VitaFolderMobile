import 'package:flutter_test/flutter_test.dart';
import 'package:house_mira/core/router/tab_refresh_coordinator.dart';

void main() {
  group('TabRefreshCoordinator', () {
    test('refreshAll is a no-op until tabs are visited', () {
      final coordinator = TabRefreshCoordinator();
      // Unvisited tabs stay unbuilt: no callbacks, no throw.
      coordinator.refreshAll();
      coordinator.refreshAfterReminderSave();
    });

    test('refreshAll calls only visited tabs', () {
      final coordinator = TabRefreshCoordinator();
      final calls = <String>[];
      coordinator.refreshHome = () => calls.add('home');
      coordinator.refreshReminders = () => calls.add('reminders');

      coordinator.refreshAll();

      expect(calls, ['home', 'reminders']);
    });

    test('refreshAfterReminderSave touches reminders and home only', () {
      final coordinator = TabRefreshCoordinator();
      final calls = <String>[];
      coordinator.refreshHome = () => calls.add('home');
      coordinator.refreshPeople = () => calls.add('people');
      coordinator.refreshReminders = () => calls.add('reminders');

      coordinator.refreshAfterReminderSave();

      expect(calls, ['reminders', 'home']);
    });

    test('resync stays null until the reminders tab builds', () {
      final coordinator = TabRefreshCoordinator();
      expect(coordinator.resyncReminderNotifications, isNull);

      var resynced = false;
      coordinator.resyncReminderNotifications = () => resynced = true;
      coordinator.resyncReminderNotifications?.call();

      expect(resynced, isTrue);
    });
  });
}

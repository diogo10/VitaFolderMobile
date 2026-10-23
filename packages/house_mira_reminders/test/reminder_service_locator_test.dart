import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:house_mira_core/config/remote_config_service.dart';
import 'package:house_mira_core/local_storage/local_storage_datasource.dart';
import 'package:house_mira_core/notifications/notification_sender.dart';
import 'package:house_mira_core/subscriptions/subscription_service.dart';
import 'package:house_mira_people/domain/repository/people_repository.dart';
import 'package:house_mira_reminders/application/reminder_notification_service.dart';
import 'package:house_mira_reminders/reminder_service_locator.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _MockStorage extends Mock implements LocalStorageDatasource {}

class _MockPeople extends Mock implements PeopleRepository {}

class _MockSubscriptions extends Mock implements SubscriptionService {}

class _MockRemoteConfig extends Mock implements RemoteConfigService {}

void main() {
  group('ReminderServiceLocator', () {
    late GetIt sl;

    setUpAll(() async {
      // The locator builds `ReminderRepositoryImpl`, which reads
      // `Supabase.instance` while the graph is assembled.
      TestWidgetsFlutterBinding.ensureInitialized();
      SharedPreferences.setMockInitialValues({});
      await Supabase.initialize(
        url: 'https://mock.supabase.co',
        publishableKey: 'mock-anon-key',
      );
    });

    setUp(() {
      sl = GetIt.asNewInstance()
        ..registerSingleton<LocalStorageDatasource>(
          _MockStorage(),
          instanceName: 'localStorageDatasource',
        )
        ..registerSingleton<PeopleRepository>(
          _MockPeople(),
          instanceName: 'peopleRepositoryImpl',
        )
        ..registerSingleton<SubscriptionService>(
          _MockSubscriptions(),
          instanceName: 'subscriptionService',
        )
        ..registerSingleton<RemoteConfigService>(
          _MockRemoteConfig(),
          instanceName: 'remoteConfigService',
        );
      ReminderServiceLocator(sl).init();
    });

    tearDown(() => sl.reset());

    test('the notification service resolves through the core seam too', () {
      // `/notification-settings` builds its cubit from a `NotificationSender`
      // parameter. GetIt keys registrations by the exact requested type, so
      // registering the instance only as `IReminderNotificationService` made
      // that lookup throw "not registered" the first time the screen opened
      // (Crashlytics `6ec637b0`). Both types must resolve to one singleton.
      final featureType = sl<IReminderNotificationService>(
        instanceName: 'reminderNotificationService',
      );
      final seamType = sl<NotificationSender>(
        instanceName: 'reminderNotificationService',
      );

      expect(identical(featureType, seamType), isTrue);
    });
  });
}

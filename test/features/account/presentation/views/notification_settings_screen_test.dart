import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:house_mira/core/local_storage/local_storage_datasource.dart';
import 'package:house_mira/features/account/application/notification_permission_service.dart';
import 'package:house_mira/features/account/presentation/cubit/notification_settings_cubit.dart';
import 'package:house_mira/features/account/presentation/views/notification_settings_screen.dart';
import 'package:house_mira/features/reminders/application/reminder_notification_service.dart';
import 'package:house_mira/generated/app_localizations.dart';
import 'package:mocktail/mocktail.dart';

class _MockStorage extends Mock implements LocalStorageDatasource {}

class _MockNotificationService extends Mock
    implements IReminderNotificationService {}

class _FakePermissionService extends NotificationPermissionService {
  @override
  Future<NotificationPermissionResult> requestNotificationPermission() async =>
      NotificationPermissionResult.granted;
}

void main() {
  late _MockStorage storage;
  late _MockNotificationService notificationService;

  setUp(() {
    storage = _MockStorage();
    notificationService = _MockNotificationService();
    when(() => storage.getBool(any())).thenAnswer((_) async => true);
    when(
      () => notificationService.showTestNotification(
        title: any(named: 'title'),
        body: any(named: 'body'),
      ),
    ).thenAnswer((_) async => true);
  });

  Widget pumpScreen(NotificationSettingsScreen screen) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: BlocProvider<NotificationSettingsCubit>(
        create: (_) => NotificationSettingsCubit(
          permissionService: _FakePermissionService(),
          storage: storage,
          notificationService: notificationService,
        ),
        child: screen,
      ),
    );
  }

  Widget pumpApp({bool showTestAction = false}) => pumpScreen(
    NotificationSettingsScreen(showTestAction: showTestAction),
  );

  AppLocalizations l10n(WidgetTester tester) => AppLocalizations.of(
    tester.element(find.byType(NotificationSettingsScreen)),
  )!;

  group('NotificationSettingsScreen test action visibility', () {
    testWidgets('hides the test action by default', (tester) async {
      await tester.pumpWidget(pumpScreen(const NotificationSettingsScreen()));
      await tester.pumpAndSettle();
      final l = l10n(tester);

      expect(find.text(l.notificationSettingsTestAction), findsNothing);
      expect(find.text(l.notificationSettingsTestSubtitle), findsNothing);
    });

    testWidgets('hides the test action when explicitly disabled', (
      tester,
    ) async {
      await tester.pumpWidget(pumpApp());
      await tester.pumpAndSettle();
      final l = l10n(tester);

      expect(find.text(l.notificationSettingsTestAction), findsNothing);
    });

    testWidgets('shows the test action when enabled', (tester) async {
      await tester.pumpWidget(pumpApp(showTestAction: true));
      await tester.pumpAndSettle();
      final l = l10n(tester);

      expect(find.text(l.notificationSettingsTestAction), findsOneWidget);
    });
  });

  group('NotificationSettingsScreen test notification', () {
    testWidgets('tapping sends a test notification and confirms', (
      tester,
    ) async {
      await tester.pumpWidget(pumpApp(showTestAction: true));
      await tester.pumpAndSettle();
      final l = l10n(tester);

      await tester.tap(find.text(l.notificationSettingsTestAction));
      await tester.pumpAndSettle();

      verify(
        () => notificationService.showTestNotification(
          title: l.notificationSettingsTestNotificationTitle,
          body: l.notificationSettingsTestNotificationBody,
        ),
      ).called(1);
      expect(find.text(l.notificationSettingsTestSent), findsOneWidget);
    });

    testWidgets('shows an error message when posting fails', (tester) async {
      when(
        () => notificationService.showTestNotification(
          title: any(named: 'title'),
          body: any(named: 'body'),
        ),
      ).thenAnswer((_) async => false);

      await tester.pumpWidget(pumpApp(showTestAction: true));
      await tester.pumpAndSettle();
      final l = l10n(tester);

      await tester.tap(find.text(l.notificationSettingsTestAction));
      await tester.pumpAndSettle();

      expect(find.text(l.notificationSettingsTestFailed), findsOneWidget);
    });
  });
}

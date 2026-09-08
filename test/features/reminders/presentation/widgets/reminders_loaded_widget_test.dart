import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:house_mira/core/auth/auth_service.dart';
import 'package:house_mira/features/people/domain/repository/people_repository.dart';
import 'package:house_mira/features/reminders/domain/entities/reminder_entity.dart';
import 'package:house_mira/features/reminders/domain/entities/reminder_type.dart';
import 'package:house_mira/features/reminders/domain/repository/reminder_repository.dart';
import 'package:house_mira/features/reminders/domain/usecase/get_reminder_usecase.dart';
import 'package:house_mira/features/reminders/presentation/cubit/reminders_cubit.dart';
import 'package:house_mira/features/reminders/presentation/widgets/reminders_loaded_widget.dart';
import 'package:house_mira/generated/app_localizations.dart';

class _FakePeopleRepository extends Mock implements PeopleRepository {}

class _FakeAuthService extends Mock implements AuthService {}

class _FakeGetReminderUsecase extends Mock implements GetReminderUsecase {}

class _FakeReminderRepository extends Mock implements ReminderRepository {}

void main() {
  late RemindersCubit cubit;

  setUp(() {
    cubit = RemindersCubit(
      getReminderUsecase: _FakeGetReminderUsecase(),
      peopleRepository: _FakePeopleRepository(),
      authService: _FakeAuthService(),
      reminderRepository: _FakeReminderRepository(),
    );
  });

  tearDown(() {
    cubit.close();
  });

  Widget pumpApp(List<ReminderEntity> reminders) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: BlocProvider.value(
          value: cubit,
          child: CustomScrollView(
            slivers: [RemindersLoadedWidget(reminders: reminders)],
          ),
        ),
      ),
    );
  }

  String fmt(DateTime d) {
    final day = d.day.toString().padLeft(2, '0');
    final month = d.month.toString().padLeft(2, '0');
    return '$day/$month/${d.year}';
  }

  ReminderEntity makeReminder(String id, String dueDate) => ReminderEntity(
    title: 'Reminder $id',
    body: '',
    id: id,
    type: ReminderType.appointment,
    dueDate: dueDate,
    repeatRule: 'never',
    status: 'pending',
    createdBy: 'Mom',
    createdAt: '',
  );

  group('RemindersLoadedWidget', () {
    testWidgets('groups reminders under Today and Tomorrow headers', (
      tester,
    ) async {
      final now = DateTime.now();
      final today = fmt(now);
      final tomorrow = fmt(now.add(const Duration(days: 1)));

      await tester.pumpWidget(
        pumpApp([makeReminder('1', today), makeReminder('2', tomorrow)]),
      );
      final l = AppLocalizations.of(
        tester.element(find.byType(RemindersLoadedWidget)),
      )!;

      expect(
        find.text('${l.remindersLoadedSectionToday} · ${_monthDay(now)}'),
        findsOneWidget,
      );
      expect(
        find.text(
          '${l.remindersLoadedSectionTomorrow} · ${_monthDay(now.add(const Duration(days: 1)))}',
        ),
        findsOneWidget,
      );
      expect(find.text('Reminder 1'), findsOneWidget);
      expect(find.text('Reminder 2'), findsOneWidget);
    });

    testWidgets('groups later reminders under weekday header', (tester) async {
      final later = now().add(const Duration(days: 3));
      await tester.pumpWidget(pumpApp([makeReminder('1', fmt(later))]));

      final weekday = const [
        'Monday',
        'Tuesday',
        'Wednesday',
        'Thursday',
        'Friday',
        'Saturday',
        'Sunday',
      ][later.weekday - 1];
      expect(find.textContaining(weekday), findsOneWidget);
      expect(find.text('Reminder 1'), findsOneWidget);
    });

    testWidgets('shows dateless reminders under No date header on top', (
      tester,
    ) async {
      final nowDt = DateTime.now();
      final today = fmt(nowDt);

      await tester.pumpWidget(
        pumpApp([makeReminder('1', today), makeReminder('2', '')]),
      );
      final l = AppLocalizations.of(
        tester.element(find.byType(RemindersLoadedWidget)),
      )!;

      // Header + trailing No-date chip share the same label.
      expect(find.text(l.remindersLoadedSectionNoDate), findsNWidgets(2));
      expect(find.text('Reminder 2'), findsOneWidget);
      expect(find.text('Reminder 1'), findsOneWidget);

      // No-date section renders before Today section: dateless
      // reminder sits above the dated one.
      final datelessOffset = tester.getTopLeft(find.text('Reminder 2'));
      final datedOffset = tester.getTopLeft(find.text('Reminder 1'));
      expect(datelessOffset.dy, lessThan(datedOffset.dy));
      expect(
        find.text('${l.remindersLoadedSectionToday} · ${_monthDay(nowDt)}'),
        findsOneWidget,
      );
    });

    testWidgets('shows only dateless reminder with No date chip', (
      tester,
    ) async {
      await tester.pumpWidget(pumpApp([makeReminder('1', '')]));
      final l = AppLocalizations.of(
        tester.element(find.byType(RemindersLoadedWidget)),
      )!;

      expect(find.text('Reminder 1'), findsOneWidget);
      // Trailing chip + header both show the No date label.
      expect(find.text(l.remindersLoadedSectionNoDate), findsNWidgets(2));
    });

    testWidgets('parses display format with time into Today group', (
      tester,
    ) async {
      final nowDt = DateTime.now();
      final day = nowDt.day.toString().padLeft(2, '0');
      final month = nowDt.month.toString().padLeft(2, '0');
      final withTime = '$day/$month/${nowDt.year} 09:30';

      await tester.pumpWidget(pumpApp([makeReminder('1', withTime)]));
      final l = AppLocalizations.of(
        tester.element(find.byType(RemindersLoadedWidget)),
      )!;

      expect(
        find.text('${l.remindersLoadedSectionToday} · ${_monthDay(nowDt)}'),
        findsOneWidget,
      );
      expect(find.text('Reminder 1'), findsOneWidget);
    });
  });
}

DateTime now() => DateTime.now();

String _monthDay(DateTime d) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${months[d.month - 1]} ${d.day}';
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vita_folder_mobile/core/auth/auth_service.dart';
import 'package:vita_folder_mobile/features/people/domain/repository/people_repository.dart';
import 'package:vita_folder_mobile/features/reminders/domain/entities/reminder_entity.dart';
import 'package:vita_folder_mobile/features/reminders/domain/entities/reminder_type.dart';
import 'package:vita_folder_mobile/features/reminders/domain/repository/reminder_repository.dart';
import 'package:vita_folder_mobile/features/reminders/domain/usecase/get_reminder_usecase.dart';
import 'package:vita_folder_mobile/features/reminders/presentation/cubit/reminders_cubit.dart';
import 'package:vita_folder_mobile/features/reminders/presentation/widgets/reminders_loaded_widget.dart';
import 'package:vita_folder_mobile/generated/app_localizations.dart';

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

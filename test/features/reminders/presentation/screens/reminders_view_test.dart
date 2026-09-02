import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:house_mira/core/auth/auth_service.dart';
import 'package:house_mira/features/people/domain/entities/person_entity.dart';
import 'package:house_mira/features/people/domain/repository/people_repository.dart';
import 'package:house_mira/features/reminders/domain/entities/reminder_entity.dart';
import 'package:house_mira/features/reminders/domain/entities/reminder_type.dart';
import 'package:house_mira/features/reminders/domain/repository/reminder_repository.dart';
import 'package:house_mira/features/reminders/domain/usecase/get_reminder_usecase.dart';
import 'package:house_mira/features/reminders/presentation/cubit/reminders_cubit.dart';
import 'package:house_mira/features/reminders/presentation/screens/reminders_view.dart';
import 'package:house_mira/features/reminders/presentation/widgets/reminder_widget.dart';
import 'package:house_mira/features/reminders/presentation/widgets/reminders_empty_widget.dart';
import 'package:house_mira/generated/app_localizations.dart';

class _FakeAuthService extends Mock implements AuthService {}

class _FakePeopleRepository extends Mock implements PeopleRepository {}

class _FakeReminderRepository extends Mock implements ReminderRepository {}

class _FakeGetReminderUsecase extends Mock implements GetReminderUsecase {}

void main() {
  late _FakeAuthService authService;
  late _FakePeopleRepository peopleRepository;
  late _FakeGetReminderUsecase getReminderUsecase;

  setUp(() {
    authService = _FakeAuthService();
    peopleRepository = _FakePeopleRepository();
    getReminderUsecase = _FakeGetReminderUsecase();
    registerFallbackValue(ReminderType.appointment);
  });

  Widget pumpView() {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: BlocProvider<RemindersCubit>(
        create: (_) => RemindersCubit(
          getReminderUsecase: getReminderUsecase,
          peopleRepository: peopleRepository,
          authService: authService,
          reminderRepository: _FakeReminderRepository(),
        ),
        child: const RemindersView(),
      ),
    );
  }

  group('RemindersView', () {
    testWidgets(
      'shows RemindersEmptyWidget and skips fetch when not logged in',
      (tester) async {
        when(() => authService.isLoggedIn()).thenReturn(false);

        await tester.pumpWidget(pumpView());
        await tester.pump();

        expect(find.byType(RemindersEmptyWidget), findsOneWidget);
        expect(find.byType(ReminderWidget), findsNothing);
        verifyNever(() => getReminderUsecase(any(), type: any(named: 'type')));
      },
    );

    testWidgets('loads reminders when logged in', (tester) async {
      when(() => authService.isLoggedIn()).thenReturn(true);
      when(() => authService.currentUserId).thenReturn('user-1');
      when(
        () => peopleRepository.getMyFamilyRole(),
      ).thenAnswer((_) async => <String>[]);
      when(
        () => peopleRepository.getFamilyIdsForUser('user-1'),
      ).thenAnswer((_) async => ['fam-1']);
      when(
        () => getReminderUsecase('fam-1', type: any(named: 'type')),
      ).thenAnswer(
        (_) async => Right([
          ReminderEntity(
            id: '1',
            title: 'Test Title',
            body: 'Test Body',
            type: ReminderType.appointment,
            dueDate: '22/08/2026 15:00',
            repeatRule: 'never',
            status: 'pending',
            createdBy: 'Mom',
            createdAt: '2026-08-01',
          ),
        ]),
      );
      when(
        () => peopleRepository.getProfilesWithRoleForFamily('fam-1'),
      ).thenAnswer((_) async => <PersonEntity>[]);

      await tester.pumpWidget(pumpView());
      await tester.pump();

      expect(find.byType(RemindersEmptyWidget), findsNothing);
      expect(find.text('Test Title'), findsOneWidget);
      verify(
        () => getReminderUsecase('fam-1', type: any(named: 'type')),
      ).called(1);
    });
  });
}

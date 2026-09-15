import 'package:bloc_test/bloc_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:house_mira/core/auth/auth_service.dart';
import 'package:house_mira/core/errors/failure.dart';
import 'package:house_mira/features/people/domain/repository/people_repository.dart';
import 'package:house_mira/features/reminders/data/models/reminder_model.dart';
import 'package:house_mira/features/reminders/domain/entities/reminder_entity.dart';
import 'package:house_mira/features/reminders/domain/entities/reminder_type.dart';
import 'package:house_mira/features/reminders/domain/usecase/create_reminder_usecase.dart';
import 'package:house_mira/features/reminders/domain/usecase/update_reminder_usecase.dart';
import 'package:house_mira/features/reminders/presentation/cubit/create_reminder_cubit.dart';
import 'package:house_mira/features/reminders/presentation/cubit/create_reminder_state.dart';

class _FakeAuthService extends Mock implements AuthService {}

class _FakePeopleRepository extends Mock implements PeopleRepository {}

class _FakeCreateReminderUsecase extends Mock
    implements CreateReminderUsecase {}

class _FakeUpdateReminderUsecase extends Mock
    implements UpdateReminderUsecase {}

void main() {
  late _FakeAuthService authService;
  late _FakePeopleRepository peopleRepository;
  late _FakeCreateReminderUsecase createReminderUsecase;
  late _FakeUpdateReminderUsecase updateReminderUsecase;

  setUp(() {
    authService = _FakeAuthService();
    peopleRepository = _FakePeopleRepository();
    createReminderUsecase = _FakeCreateReminderUsecase();
    updateReminderUsecase = _FakeUpdateReminderUsecase();
  });

  setUpAll(() {
    registerFallbackValue(
      ReminderModel(
        title: '',
        body: '',
        id: '',
        type: ReminderType.custom,
        dueDate: '',
        repeatRule: 'never',
        status: '',
        createdBy: '',
        createdAt: '',
      ),
    );
  });

  CreateReminderCubit buildCubit() => CreateReminderCubit(
    createReminderUsecase: createReminderUsecase,
    updateReminderUsecase: updateReminderUsecase,
    authService: authService,
    peopleRepository: peopleRepository,
  );

  final reminder = ReminderEntity(
    id: '1',
    title: 'Old title',
    body: 'Old body',
    type: ReminderType.appointment,
    dueDate: '22/08/2026 15:00',
    repeatRule: 'weekly',
    status: 'pending',
    createdBy: 'Mom',
    createdAt: '2026-08-01',
  );

  group('CreateReminderCubit.createReminder', () {
    void stubFamily(String? familyId, {String userId = 'u1'}) {
      when(() => authService.currentUserId).thenReturn(userId);
      when(
        () => peopleRepository.getFamilyIdsForUser(userId),
      ).thenAnswer((_) async => familyId == null ? [] : [familyId]);
    }

    blocTest<CreateReminderCubit, CreateReminderState>(
      'emits loading then success when create succeeds',
      build: buildCubit,
      setUp: () {
        stubFamily('f1');
        when(
          () => createReminderUsecase.call(any(), any()),
        ).thenAnswer((_) async => Right('new-id'));
      },
      act: (cubit) => cubit.createReminder(
        title: 'T',
        body: 'B',
        type: ReminderType.chores,
        dueDate: DateTime(2026, 9, 1, 10, 30),
        repeatRule: 'never',
      ),
      expect: () => [
        isA<CreateReminderLoading>(),
        isA<CreateReminderSuccess>().having(
          (s) => s.reminderId,
          'reminderId',
          'new-id',
        ),
      ],
      verify: (_) {
        final captured = verify(
          () => createReminderUsecase.call(captureAny(), captureAny()),
        ).captured;
        expect((captured[0] as ReminderModel).title, 'T');
        expect(captured[1] as String, 'f1');
      },
    );

    blocTest<CreateReminderCubit, CreateReminderState>(
      'emits noFamily when user has no family',
      build: buildCubit,
      setUp: () => stubFamily(null),
      act: (cubit) => cubit.createReminder(
        title: 'T',
        body: 'B',
        type: ReminderType.chores,
        dueDate: null,
        repeatRule: 'never',
      ),
      expect: () => [
        isA<CreateReminderLoading>(),
        isA<CreateReminderError>().having(
          (e) => e.code,
          'code',
          CreateReminderErrorCode.noFamily,
        ),
      ],
    );

    blocTest<CreateReminderCubit, CreateReminderState>(
      'emits noFamily when there is no logged-in user',
      build: buildCubit,
      setUp: () {
        when(() => authService.currentUserId).thenReturn(null);
      },
      act: (cubit) => cubit.createReminder(
        title: 'T',
        body: 'B',
        type: ReminderType.chores,
        dueDate: null,
        repeatRule: 'never',
      ),
      expect: () => [
        isA<CreateReminderLoading>(),
        isA<CreateReminderError>().having(
          (e) => e.code,
          'code',
          CreateReminderErrorCode.noFamily,
        ),
      ],
    );

    blocTest<CreateReminderCubit, CreateReminderState>(
      'emits error message when create fails',
      build: buildCubit,
      setUp: () {
        stubFamily('f1');
        when(
          () => createReminderUsecase.call(any(), any()),
        ).thenAnswer((_) async => Left(Failure(message: 'boom')));
      },
      act: (cubit) => cubit.createReminder(
        title: 'T',
        body: 'B',
        type: ReminderType.chores,
        dueDate: null,
        repeatRule: 'never',
      ),
      expect: () => [
        isA<CreateReminderLoading>(),
        isA<CreateReminderError>().having((e) => e.message, 'message', 'boom'),
      ],
    );
  });

  group('CreateReminderCubit.updateReminder', () {
    blocTest<CreateReminderCubit, CreateReminderState>(
      'emits loading then success when update succeeds',
      build: buildCubit,
      setUp: () {
        when(
          () => updateReminderUsecase.call(any()),
        ).thenAnswer((_) async => Right(true));
      },
      act: (cubit) => cubit.updateReminder(
        reminder: reminder,
        title: 'New title',
        body: 'New body',
        type: ReminderType.chores,
        dueDate: DateTime(2026, 9, 1, 10, 30),
        repeatRule: 'daily',
      ),
      expect: () => [
        isA<CreateReminderLoading>(),
        isA<UpdatedReminderSuccess>(),
      ],
      verify: (_) {
        final captured =
            verify(
                  () => updateReminderUsecase.call(captureAny()),
                ).captured.single
                as ReminderModel;
        expect(captured.id, '1');
        expect(captured.title, 'New title');
        expect(captured.type, ReminderType.chores);
        expect(captured.status, 'pending');
        expect(captured.createdBy, 'Mom');
        expect(captured.createdAt, '2026-08-01');
      },
    );

    blocTest<CreateReminderCubit, CreateReminderState>(
      'emits error when update fails',
      build: buildCubit,
      setUp: () {
        when(
          () => updateReminderUsecase.call(any()),
        ).thenAnswer((_) async => Left(Failure(message: 'boom')));
      },
      act: (cubit) => cubit.updateReminder(
        reminder: reminder,
        title: 'New title',
        body: 'New body',
        type: ReminderType.chores,
        dueDate: DateTime(2026, 9, 1, 10, 30),
        repeatRule: 'daily',
      ),
      expect: () => [
        isA<CreateReminderLoading>(),
        isA<CreateReminderError>().having(
          (state) => state.message,
          'message',
          'boom',
        ),
      ],
    );
  });
}

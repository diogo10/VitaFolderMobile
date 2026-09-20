import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:house_mira/core/auth/auth_service.dart';
import 'package:house_mira/features/people/domain/repository/people_repository.dart';
import 'package:house_mira/features/reminders/application/reminder_notification_service.dart';
import 'package:house_mira/features/reminders/data/models/reminder_model.dart';
import 'package:house_mira/features/reminders/domain/entities/reminder_entity.dart';
import 'package:house_mira/features/reminders/domain/entities/reminder_lead_time.dart';
import 'package:house_mira/features/reminders/domain/entities/reminder_type.dart';
import 'package:house_mira/features/reminders/domain/usecase/create_reminder_usecase.dart';
import 'package:house_mira/features/reminders/domain/usecase/update_reminder_usecase.dart';
import 'package:house_mira/features/reminders/presentation/cubit/create_reminder_state.dart';

class CreateReminderCubit extends Cubit<CreateReminderState> {
  CreateReminderCubit({
    required CreateReminderUsecase createReminderUsecase,
    required UpdateReminderUsecase updateReminderUsecase,
    required this.authService,
    required PeopleRepository peopleRepository,
    required IReminderNotificationService notificationService,
  }) : _createReminderUsecase = createReminderUsecase,
       _updateReminderUsecase = updateReminderUsecase,
       _peopleRepository = peopleRepository,
       _notificationService = notificationService,
       super(CreateReminderInitial());
  final CreateReminderUsecase _createReminderUsecase;
  final UpdateReminderUsecase _updateReminderUsecase;
  final AuthService authService;
  final PeopleRepository _peopleRepository;
  final IReminderNotificationService _notificationService;

  /// Exposed so the editor can read prefs/permissions without touching
  /// GetIt directly.
  IReminderNotificationService get notificationService => _notificationService;

  Future<void> createReminder({
    required String title,
    required String body,
    required ReminderType type,
    required DateTime? dueDate,
    required String repeatRule,
    bool notifyEnabled = false,
    ReminderLeadTime leadTime = ReminderLeadTime.defaultLeadTime,
  }) async {
    emit(CreateReminderLoading());

    final familyId = await _resolveFamilyId();
    if (familyId == null) {
      emit(CreateReminderError(code: CreateReminderErrorCode.noFamily));
      return;
    }

    final userId = authService.currentUserId;
    if (userId == null) {
      emit(CreateReminderError(code: CreateReminderErrorCode.authRequired));
      return;
    }

    final reminder = ReminderModel(
      title: title,
      body: body,
      id: '',
      type: type,
      dueDate: dueDate?.toIso8601String() ?? '',
      repeatRule: repeatRule,
      status: 'pending',
      createdBy: userId,
      createdAt: DateTime.now().toIso8601String(),
    );

    final result = await _createReminderUsecase(reminder, familyId);

    await result.fold(
      (err) async => emit(CreateReminderError(message: err.message)),
      (reminderId) async {
        final sync = await _syncNotification(
          reminderId: reminderId,
          notifyEnabled: notifyEnabled,
          leadTime: leadTime,
          dueDate: dueDate,
          title: title,
          body: body,
          repeatRule: repeatRule,
        );
        emit(
          CreateReminderSuccess(
            reminderId: reminderId,
            notificationArmed: sync.armed,
            notificationTimePassed: sync.timePassed,
            notificationInexact: sync.inexact,
          ),
        );
      },
    );
  }

  Future<void> updateReminder({
    required ReminderEntity reminder,
    required String title,
    required String body,
    required ReminderType type,
    required DateTime? dueDate,
    required String repeatRule,
    bool notifyEnabled = false,
    ReminderLeadTime leadTime = ReminderLeadTime.defaultLeadTime,
  }) async {
    emit(CreateReminderLoading());

    final reminderModel = ReminderModel(
      title: title,
      body: body,
      id: reminder.id,
      type: type,
      dueDate: dueDate?.toIso8601String() ?? '',
      repeatRule: repeatRule,
      status: reminder.status,
      createdBy: reminder.createdBy,
      createdAt: reminder.createdAt,
    );

    final result = await _updateReminderUsecase(reminderModel);

    await result.fold(
      (err) async => emit(CreateReminderError(message: err.message)),
      (_) async {
        final sync = await _syncNotification(
          reminderId: reminder.id,
          notifyEnabled: notifyEnabled,
          leadTime: leadTime,
          dueDate: dueDate,
          title: title,
          body: body,
          repeatRule: repeatRule,
        );
        emit(
          UpdatedReminderSuccess(
            notificationArmed: sync.armed,
            notificationTimePassed: sync.timePassed,
            notificationInexact: sync.inexact,
          ),
        );
      },
    );
  }

  /// Persists/schedules the notification choice. Best-effort: never throws.
  /// Returns whether alerts will actually fire (or nothing was requested),
  /// whether a requested alert was skipped because the time passed, and
  /// whether an armed alert may be delayed (inexact fallback).
  Future<({bool armed, bool timePassed, bool inexact})> _syncNotification({
    required String reminderId,
    required bool notifyEnabled,
    required ReminderLeadTime leadTime,
    required DateTime? dueDate,
    required String title,
    required String body,
    required String repeatRule,
  }) async {
    bool scheduled;
    try {
      scheduled = await _notificationService.setReminderNotification(
        reminderId: reminderId,
        enabled: notifyEnabled,
        leadTime: leadTime,
        dueDate: dueDate,
        title: title,
        body: body,
        repeatRule: repeatRule,
      );
    } on Object catch (_) {
      // Notifications are best-effort; the reminder itself was saved.
      return (armed: false, timePassed: false, inexact: false);
    }
    if (!notifyEnabled) {
      return (armed: true, timePassed: false, inexact: false);
    }
    if (!scheduled) {
      return (armed: false, timePassed: true, inexact: false);
    }
    try {
      final armed =
          dueDate != null && await _notificationService.hasSystemPermission();
      final inexact =
          armed && !await _notificationService.canScheduleExactAlarms();
      return (armed: armed, timePassed: false, inexact: inexact);
    } on Object catch (_) {
      return (armed: false, timePassed: false, inexact: false);
    }
  }

  Future<ReminderNotificationPrefs> getNotificationPrefs(
    String reminderId,
  ) async {
    try {
      return await _notificationService.getReminderNotification(reminderId);
    } on Object catch (_) {
      return ReminderNotificationPrefs.disabled;
    }
  }

  Future<bool> hasSystemPermission() async {
    try {
      return await _notificationService.hasSystemPermission();
    } on Object catch (_) {
      return false;
    }
  }

  Future<bool> requestSystemPermission() async {
    try {
      return await _notificationService.requestSystemPermission();
    } on Object catch (_) {
      return false;
    }
  }

  Future<bool> canScheduleExactAlarms() async {
    try {
      return await _notificationService.canScheduleExactAlarms();
    } on Object catch (_) {
      return true;
    }
  }

  Future<void> requestExactAlarmPermission() async {
    try {
      await _notificationService.requestExactAlarmPermission();
    } on Object catch (_) {
      // Best-effort only.
    }
  }

  Future<String?> _resolveFamilyId() async {
    final userId = authService.currentUserId;
    if (userId == null) {
      return null;
    }
    final familyIds = await _peopleRepository.getFamilyIdsForUser(userId);
    return familyIds.isEmpty ? null : familyIds.first;
  }
}

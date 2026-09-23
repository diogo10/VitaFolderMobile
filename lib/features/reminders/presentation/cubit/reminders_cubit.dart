import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:house_mira/core/auth/auth_service.dart';
import 'package:house_mira/core/observability/app_logger.dart';
import 'package:house_mira/core/observability/crash_reporter.dart';
import 'package:house_mira/features/people/domain/repository/people_repository.dart';
import 'package:house_mira/features/reminders/application/reminder_notification_service.dart';
import 'package:house_mira/features/reminders/domain/entities/reminder_entity.dart';
import 'package:house_mira/features/reminders/domain/entities/reminder_type.dart';
import 'package:house_mira/features/reminders/domain/repository/reminder_repository.dart';
import 'package:house_mira/features/reminders/domain/usecase/get_reminder_usecase.dart';
import 'package:house_mira/features/reminders/presentation/cubit/reminders_state.dart';
import 'package:house_mira/features/reminders/presentation/cubit/reminders_view_mode.dart';

class RemindersCubit extends Cubit<RemindersState> {
  RemindersCubit({
    required this.getReminderUsecase,
    required this.peopleRepository,
    required this.authService,
    required this.reminderRepository,
    required IReminderNotificationService notificationService,
    CrashReporter? crashReporter,
    AppLogger? logger,
  }) : _notificationService = notificationService,
       _logger = logger ?? AppLogger(crashReporter: crashReporter),
       super(ReminderInitialState());
  GetReminderUsecase getReminderUsecase;
  PeopleRepository peopleRepository;
  AuthService authService;
  ReminderRepository reminderRepository;
  final IReminderNotificationService _notificationService;
  final AppLogger _logger;

  /// Exposed for views that need notification prefs without GetIt.
  IReminderNotificationService get notificationService => _notificationService;

  ReminderType? _selectedType;
  ReminderType? get selectedType => _selectedType;

  Set<ReminderType> _filterTypes = {};
  Set<ReminderType> get filterTypes => _filterTypes;

  String? _myRole;
  String? get myRole => _myRole;

  RemindersViewMode _viewMode = RemindersViewMode.list;
  RemindersViewMode get viewMode => _viewMode;

  Future<void> getReminders({String? familyId, ReminderType? type}) async {
    _selectedType = type;
    await _loadMyRole();

    final current = state;
    if (current is LoadedReminders) {
      emit(
        LoadedReminders(
          reminders: current.reminders,
          type: type,
          isLoading: true,
          viewMode: _viewMode,
        ),
      );
    } else if (current is EmptyReminders) {
      emit(EmptyReminders(type: type, isLoading: true, viewMode: _viewMode));
    } else {
      emit(RemindersLoading(viewMode: _viewMode));
    }

    final resolvedFamilyId = familyId ?? await _resolveFamilyId();
    if (resolvedFamilyId == null) {
      emit(EmptyReminders(type: type, viewMode: _viewMode));
      return;
    }

    final result = await getReminderUsecase(resolvedFamilyId, type: type);

    result.fold((err) => emit(ReminderError(viewMode: _viewMode)), (reminders) {
      if (reminders.isEmpty) {
        emit(EmptyReminders(type: type, viewMode: _viewMode));
      } else {
        emit(
          LoadedReminders(
            reminders: reminders,
            type: type,
            viewMode: _viewMode,
          ),
        );
        unawaited(_resyncNotifications(reminders));
      }
    });
  }

  Future<String?> _resolveFamilyId() async {
    final userId = authService.currentUserId;
    if (userId == null) {
      return null;
    }
    final familyIds = await peopleRepository.getFamilyIdsForUser(userId);
    return familyIds.isEmpty ? null : familyIds.first;
  }

  /// Whether the current user belongs to a family.
  ///
  /// Views use this to gate creation flows: a logged-in user without a
  /// family sees the same empty state as a logged-out user, and tapping
  /// create routes them to `/people` instead of the editor.
  Future<bool> hasFamily() async {
    try {
      return await _resolveFamilyId() != null;
    } on Object catch (_) {
      return false;
    }
  }

  Future<void> removeReminder(String id) async {
    final current = state;
    final currentReminders = current is LoadedReminders
        ? current.reminders
        : null;
    final currentType = _selectedType;

    final result = await reminderRepository.removeReminder(id);
    result.fold(
      (err) {
        if (current is LoadedReminders) {
          emit(
            LoadedReminders(
              reminders: current.reminders,
              type: currentType,
              viewMode: _viewMode,
            ),
          );
        }
      },
      (_) {
        unawaited(_notificationService.cancelReminderNotification(id));
        if (currentReminders == null) {
          unawaited(getReminders(type: currentType));
          return;
        }
        final updated = currentReminders.where((r) => r.id != id).toList();
        if (updated.isEmpty) {
          emit(EmptyReminders(type: currentType, viewMode: _viewMode));
        } else {
          emit(
            LoadedReminders(
              reminders: updated,
              type: currentType,
              viewMode: _viewMode,
            ),
          );
        }
      },
    );
  }

  void toggleViewMode() {
    _viewMode = _viewMode == RemindersViewMode.list
        ? RemindersViewMode.calendar
        : RemindersViewMode.list;
    emit(switch (state) {
      ReminderInitialState() => ReminderInitialState(viewMode: _viewMode),
      RemindersLoading() => RemindersLoading(viewMode: _viewMode),
      LoadedReminders(:final reminders, :final type, :final isLoading) =>
        LoadedReminders(
          reminders: reminders,
          type: type,
          isLoading: isLoading,
          viewMode: _viewMode,
        ),
      EmptyReminders(:final type, :final isLoading) => EmptyReminders(
        type: type,
        isLoading: isLoading,
        viewMode: _viewMode,
      ),
      ReminderError() => ReminderError(viewMode: _viewMode),
    });
  }

  /// Re-arms OS alarms without touching the visible list: reschedules from
  /// currently loaded reminders, or reloads (which resyncs after fetch)
  /// when nothing is loaded yet. Best-effort: never throws.
  Future<void> resyncNotifications() async {
    final current = state;
    if (current is LoadedReminders) {
      await _resyncNotifications(current.reminders);
    } else {
      await getReminders(type: _selectedType);
    }
  }

  Future<void> _loadMyRole() async {
    final roles = await peopleRepository.getMyFamilyRole();
    _myRole = roles.isEmpty ? null : roles.first;
  }

  /// Rebuilds OS alarms from persisted prefs. Best-effort: never throws,
  /// never blocks the list render. Failures are reported (not swallowed)
  /// so silent alarm loss stays visible in Crashlytics.
  Future<void> _resyncNotifications(List<ReminderEntity> reminders) async {
    try {
      await _notificationService.rescheduleAll(reminders);
    } on Object catch (error, stackTrace) {
      _logger.warning(
        'reminder resync failed',
        tag: 'reminder-resync',
        context: {'count': reminders.length},
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  void setFilterTypes(Set<ReminderType> types) {
    _filterTypes = types;
    // Re-emit current state to notify listeners of filter change
    final current = state;
    if (current is LoadedReminders) {
      emit(
        LoadedReminders(
          reminders: current.reminders,
          type: current.type,
          isLoading: current.isLoading,
          viewMode: current.viewMode,
          filterTypes: _filterTypes,
        ),
      );
    } else if (current is EmptyReminders) {
      emit(
        EmptyReminders(
          type: current.type,
          isLoading: current.isLoading,
          viewMode: current.viewMode,
          filterTypes: _filterTypes,
        ),
      );
    } else if (current is RemindersLoading) {
      emit(
        RemindersLoading(viewMode: current.viewMode, filterTypes: _filterTypes),
      );
    } else if (current is ReminderError) {
      emit(
        ReminderError(viewMode: current.viewMode, filterTypes: _filterTypes),
      );
    } else if (current is ReminderInitialState) {
      emit(
        ReminderInitialState(
          viewMode: current.viewMode,
          filterTypes: _filterTypes,
        ),
      );
    }
  }

  List<ReminderEntity> getFilteredReminders(List<ReminderEntity> reminders) {
    if (_filterTypes.isEmpty) return reminders;
    return reminders.where((r) => _filterTypes.contains(r.type)).toList();
  }
}

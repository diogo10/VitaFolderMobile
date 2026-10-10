import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:house_mira_core/router/app_routes.dart';
import 'package:house_mira_reminders/domain/entities/reminder_entity.dart';
import 'package:house_mira_reminders/domain/entities/reminder_type.dart';
import 'package:meta/meta.dart';

/// Typed wrapper for the create/edit reminder screen.
///
/// Editing an existing reminder travels via `extra` ([ReminderEntity]);
/// pre-selecting a type travels via `extra` ([ReminderType]) or the `type`
/// query parameter so it survives deep links. Unknown extras are ignored
/// (fresh create form) instead of crashing.
@immutable
class CreateReminderRoute {
  const CreateReminderRoute({this.reminder, this.initialType});

  const CreateReminderRoute.create() : reminder = null, initialType = null;

  const CreateReminderRoute.forEdit(this.reminder) : initialType = null;

  const CreateReminderRoute.forType(this.initialType) : reminder = null;

  factory CreateReminderRoute.fromState(GoRouterState state) {
    final extra = state.extra;
    if (extra is ReminderEntity) return CreateReminderRoute.forEdit(extra);
    if (extra is ReminderType) return CreateReminderRoute.forType(extra);
    final type = ReminderType.fromString(
      state.uri.queryParameters[AppRoutes.reminderTypeParam],
    );
    if (type != null) return CreateReminderRoute.forType(type);
    return const CreateReminderRoute.create();
  }

  final ReminderEntity? reminder;
  final ReminderType? initialType;

  String get location {
    final type = initialType;
    if (reminder != null || type == null) return AppRoutes.createReminder;
    return '${AppRoutes.createReminder}?'
        '${AppRoutes.reminderTypeParam}=${type.value}';
  }

  Object? get extra => reminder ?? initialType;

  Future<T?> push<T extends Object?>(BuildContext context) =>
      context.push<T>(location, extra: extra);
}

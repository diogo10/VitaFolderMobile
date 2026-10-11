// Composition-root re-export: the route table lives in `house_mira_core`.
// Feature packages import `package:house_mira_core/router/app_routes.dart`
// directly; app code and tests may keep importing this path.
export 'package:house_mira_core/router/app_routes.dart';
export 'package:house_mira_reminders/navigation/create_reminder_route.dart';

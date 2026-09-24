/// Coordinates cross-tab refresh without instantiating unbuilt tabs.
///
/// Tab cubits live in their own `StatefulShellBranch` subtrees, so sibling
/// views cannot `context.read` them. The previous approach fell back to
/// `slInstance.get()` on a `registerLazySingleton`, which constructs the
/// cubit on first `get()` and therefore eagerly built every unvisited tab
/// graph on logout/login/save/resync — defeating route-scoped laziness.
///
/// Instead, each tab route builder registers a refresh closure here when it
/// actually builds. Until a tab has been visited its callback stays `null`,
/// so refreshAll/refreshAfterReminderSave/resyncReminderNotifications
/// are strict no-ops and unbuilt tabs stay unbuilt.
///
/// Views receive plain callbacks (onAuthChanged, onSaved, onProfileSaved)
/// wired by the route builders, so presentation never imports GetIt and
/// dependencies stay visible and testable.
class TabRefreshCoordinator {
  /// Set by the home tab builder on first visit.
  void Function()? refreshHome;

  /// Set by the people tab builder on first visit.
  void Function()? refreshPeople;

  /// Set by the reminders tab builder on first visit.
  void Function()? refreshReminders;

  /// Set by the account tab builder on first visit.
  void Function()? refreshAccount;

  /// Reads the current account display name for the manage-profile form.
  /// Set by the account tab builder; `null` until the account tab is built
  /// (manage-profile is only reachable from there, so this is set).
  String? Function()? readAccountName;

  /// Re-arms OS alarms without building the reminders graph when the tab
  /// was never visited. Set by the reminders tab builder on first visit.
  /// Returns a future so `MyApp` can await it inside a performance trace;
  /// resync failures then reach the resume-resync error report instead of
  /// escaping as unhandled async errors.
  Future<void> Function()? resyncReminderNotifications;

  /// Refreshes every visited tab. Unvisited tabs stay unbuilt.
  ///
  /// The account tab is deliberately excluded: it originates auth changes
  /// (its cubit just signed in/out or deleted the account and already
  /// holds the post-auth state), so reloading it from its own callback
  /// would be redundant.
  void refreshAll() {
    refreshHome?.call();
    refreshPeople?.call();
    refreshReminders?.call();
  }

  /// Refreshes the lists affected by a reminder save. Unvisited tabs stay
  /// unbuilt and load fresh on first visit instead.
  void refreshAfterReminderSave() {
    refreshReminders?.call();
    refreshHome?.call();
  }
}

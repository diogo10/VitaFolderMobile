/// Compile-time switches that change how a build behaves.
///
/// These are `--dart-define` values, not secrets, so they belong in the build
/// command (or `env/<flavor>.json`) and never in `lib/`.
abstract final class BuildFlags {
  /// True for builds compiled with `--dart-define=E2E_MODE=true`.
  ///
  /// The e2e suite (e2e.com, see `.agents/plans/e2e-onboarding.md`) drives an
  /// installed release build from the outside. A permanently animating screen
  /// races every snapshot and can wedge the iOS XCUITest runner, so e2e builds
  /// drop the infinite hero animations and the page-transition animation.
  ///
  /// Only presentation timing changes: persistence, routing and validation
  /// stay identical to a shipped build. Defaults to `false`, so `flutter test`
  /// and every store build are unaffected.
  static const e2eMode = bool.fromEnvironment('E2E_MODE');
}

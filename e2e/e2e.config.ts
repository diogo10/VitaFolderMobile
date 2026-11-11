import type { E2EConfig } from 'e2e';
import { mobile } from '@e2e-dev/mobile';

// The installed build: `applicationId` in android/app/build.gradle.kts and
// `PRODUCT_BUNDLE_IDENTIFIER` in ios/Runner.xcodeproj. The suite never builds
// the app; it drives whatever is installed under this id.
//
// Builds must carry `--dart-define=E2E_MODE=true` (see
// `.agents/plans/e2e-onboarding.md`): it drops the infinite onboarding hero
// animations and page transitions, which otherwise race every snapshot and can
// wedge the iOS automation runner. Persistence, routing and validation are
// identical to a shipped build.
const app = {
  bundleId: 'com.housemira.app',
  // main.dart requests notification permission in a post-frame callback, so a
  // fresh install raises the system dialog on top of onboarding and every tap
  // lands on the dialog. Permissions are applied before launch, so granting up
  // front means no prompt. `deny` is not enough on Android: it revokes, and the
  // OS asks again.
  permissions: { notifications: 'grant' as const },
};

export default {
  targets: [
    { name: 'android', engine: mobile({ platform: 'android' }), app },
    // Enabled by phase 3 of the plan; harmless until then because a run only
    // touches the targets it is asked for with --target.
    { name: 'ios', engine: mobile({ platform: 'ios' }), app },
  ],
  // One emulator/simulator per run: the suite is short and the onboarding flag
  // is device-global state, so parallel workers would fight over it.
  workers: 1,
} satisfies E2EConfig;

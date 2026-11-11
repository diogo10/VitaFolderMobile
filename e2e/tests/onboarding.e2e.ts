import { test } from '@e2e-dev/mobile';
import { expect } from 'e2e';

/**
 * Onboarding: the first screen of a fresh install and the only pre-auth flow.
 *
 * The completion flag lives in shared_preferences (`onboarding_completed`, see
 * OnboardingLocalDatasource), so every test starts from a device with no app
 * data — that is what makes "first launch" real rather than assumed.
 */
test.beforeEach(async ({ app }) => {
  await app.clearState();
  await app.open();
});

/**
 * Cold start goes splash -> session recovery -> landing route, all over the
 * network (Supabase, Remote Config), so the first assertion gets headroom.
 */
const COLD_START = 20_000;

/**
 * The shell's bottom bar is the post-onboarding anchor: the home tab's content
 * needs a backend, the onboarding gate does not. Flutter exposes each tab as a
 * single node named `Home\nTab 1 of 5`, so match the role and the leading word
 * instead of an exact text.
 */
const HOME_TAB = /^Home/;

test('first launch shows slide 1 with skip and a next CTA', async ({ screen }) => {
  await expect(screen.getByTestId('onboarding-slide-1')).toBeVisible({ timeout: COLD_START });
  await expect(screen.getByTestId('onboarding-skip')).toBeVisible();
  await expect(screen.getByTestId('onboarding-cta-next')).toBeVisible();
  // The final CTA must not exist yet: it is the state marker for slide 3.
  await expect(screen.getByTestId('onboarding-cta-finish')).toHaveCount(0);
});

test('next walks all three slides and the CTA becomes Get Started', async ({ screen }) => {
  await expect(screen.getByTestId('onboarding-slide-1')).toBeVisible({ timeout: COLD_START });

  await screen.getByTestId('onboarding-cta-next').tap();
  await expect(screen.getByTestId('onboarding-slide-2')).toBeVisible();
  await expect(screen.getByTestId('onboarding-cta-next')).toBeVisible();

  await screen.getByTestId('onboarding-cta-next').tap();
  await expect(screen.getByTestId('onboarding-slide-3')).toBeVisible();
  await expect(screen.getByTestId('onboarding-cta-finish')).toBeVisible();
  await expect(screen.getByTestId('onboarding-cta-next')).toHaveCount(0);
});

test('skip jumps to the last slide', async ({ screen }) => {
  await expect(screen.getByTestId('onboarding-slide-1')).toBeVisible({ timeout: COLD_START });

  await screen.getByTestId('onboarding-skip').tap();

  await expect(screen.getByTestId('onboarding-slide-3')).toBeVisible();
  await expect(screen.getByTestId('onboarding-cta-finish')).toBeVisible();
});

test('get started completes onboarding and lands on home', async ({ screen }) => {
  await expect(screen.getByTestId('onboarding-slide-1')).toBeVisible({ timeout: COLD_START });

  await screen.getByTestId('onboarding-skip').tap();
  await expect(screen.getByTestId('onboarding-cta-finish')).toBeVisible();
  await screen.getByTestId('onboarding-cta-finish').tap();

  // The shell's bottom bar is the post-onboarding anchor: the home tab's
  // content needs a backend, the onboarding gate does not.
  await expect(screen.getByRole('button', HOME_TAB)).toBeVisible({ timeout: COLD_START });
  await expect(screen.getByTestId('onboarding-slide-3')).toHaveCount(0);
});

test('completion survives a cold restart', async ({ app, screen }) => {
  await expect(screen.getByTestId('onboarding-slide-1')).toBeVisible({ timeout: COLD_START });

  await screen.getByTestId('onboarding-skip').tap();
  await screen.getByTestId('onboarding-cta-finish').tap();
  await expect(screen.getByRole('button', HOME_TAB)).toBeVisible({ timeout: COLD_START });

  // The point of the suite: the flag was written, not just navigated away from.
  await app.restart();
  await expect(screen.getByRole('button', HOME_TAB)).toBeVisible({ timeout: COLD_START });
  await expect(screen.getByTestId('onboarding-slide-1')).toHaveCount(0);
});

test('skip does not persist completion', async ({ app, screen }) => {
  await expect(screen.getByTestId('onboarding-slide-1')).toBeVisible({ timeout: COLD_START });

  await screen.getByTestId('onboarding-skip').tap();
  await expect(screen.getByTestId('onboarding-slide-3')).toBeVisible();

  // Only "Get Started" completes onboarding. Skipping to the last slide must
  // not write the flag, or the gate silently opens for anyone who bails out.
  await app.restart();
  await expect(screen.getByTestId('onboarding-slide-1')).toBeVisible({ timeout: COLD_START });
});

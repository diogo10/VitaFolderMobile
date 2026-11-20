import { credentials, expect } from 'e2e';
import type { App, Screen, Secret } from 'e2e';
import type { Device } from '@e2e-dev/mobile';
import { test } from '@e2e-dev/mobile';

/**
 * Sign-in from the account tab (the app has no standalone login route: a
 * signed-out account tab is the login screen).
 *
 * The valid account comes from E2E_LOGIN_EMAIL / E2E_LOGIN_PASSWORD through
 * e2e.config.ts `credentials`, so the password is an opaque handle that the
 * runner fills and redacts. The identifier contract is pinned by
 * `packages/house_mira_account/test/presentation/views/account_login_semantics_test.dart`.
 */
const COLD_START = 20_000;
const HOME_TAB = /^Home/;
const ACCOUNT_TAB = /^Account/;

const hasLoginCredentials =
  (process.env.E2E_LOGIN_EMAIL ?? '').trim() !== '' &&
  (process.env.E2E_LOGIN_PASSWORD ?? '') !== '';

/**
 * Every test starts from a clean install: complete onboarding (it is the
 * cold-start gate) and open the account tab's signed-out form.
 */
async function openLoginForm(app: App, screen: Screen): Promise<void> {
  await app.clearState();
  await app.open();

  await expect(screen.getByTestId('onboarding-slide-1')).toBeVisible({
    timeout: COLD_START,
  });
  await screen.getByTestId('onboarding-skip').tap();
  await expect(screen.getByTestId('onboarding-cta-finish')).toBeVisible();
  await screen.getByTestId('onboarding-cta-finish').tap();

  await expect(screen.getByRole('button', HOME_TAB)).toBeVisible({
    timeout: COLD_START,
  });
  await screen.getByRole('button', ACCOUNT_TAB).tap();
  // AccountCubit resolves the profile over the network before it can decide
  // signed-out vs signed-in, so this needs the cold-start budget too.
  await expect(screen.getByTestId('account-email-field')).toBeVisible({
    timeout: COLD_START,
  });
}

async function fillAndSubmit(
  device: Device,
  screen: Screen,
  email: string,
  password: string | Secret,
): Promise<void> {
  await screen.getByTestId('account-email-field').fill(email);
  await screen.getByTestId('account-password-field').fill(password);
  await device.dismissKeyboard();
  await screen.getByTestId('account-sign-in-button').tap();
}

test('invalid email shows the login error and stays on the form', async ({
  app,
  device,
  screen,
}) => {
  await openLoginForm(app, screen);

  await fillAndSubmit(device, screen, 'not-an-email', 'irrelevant-password');

  await expect(screen.getByTestId('account-login-error')).toBeVisible({
    timeout: 15_000,
  });
  await expect(screen.getByTestId('account-sign-in-button')).toBeVisible();
  await expect(screen.getByTestId('account-loaded')).toHaveCount(0);
});

test('valid email with a wrong password shows the login error', async ({
  app,
  device,
  screen,
}) => {
  test.skip(
    !hasLoginCredentials,
    'E2E_LOGIN_EMAIL / E2E_LOGIN_PASSWORD are not set',
  );

  await openLoginForm(app, screen);

  const login = credentials.user('login');
  await fillAndSubmit(device, screen, login.username, 'WrongPassword123!');

  await expect(screen.getByTestId('account-login-error')).toBeVisible({
    timeout: 15_000,
  });
  await expect(screen.getByTestId('account-sign-in-button')).toBeVisible();
  await expect(screen.getByTestId('account-loaded')).toHaveCount(0);
});

test('valid credentials sign in and load the account', async ({
  app,
  device,
  screen,
}) => {
  test.skip(
    !hasLoginCredentials,
    'E2E_LOGIN_EMAIL / E2E_LOGIN_PASSWORD are not set',
  );

  await openLoginForm(app, screen);

  const login = credentials.user('login');
  await fillAndSubmit(device, screen, login.username, login.password);

  // The signed-in tree is the success anchor; the form must be gone.
  await expect(screen.getByTestId('account-loaded')).toBeVisible({
    timeout: COLD_START,
  });
  await expect(screen.getByTestId('account-sign-in-button')).toHaveCount(0);
});

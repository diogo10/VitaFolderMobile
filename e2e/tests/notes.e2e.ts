import { credentials, expect } from 'e2e';
import type { App, Screen, Secret } from 'e2e';
import type { Device } from '@e2e-dev/mobile';
import { test } from '@e2e-dev/mobile';

/**
 * Note lifecycle: create, edit and delete from the Notes tab.
 *
 * This is the first *write* suite in the device e2e run, so it is gated: it
 * runs only when a login account is configured AND `E2E_ALLOW_WRITES=1`.
 * `.github/workflows/e2e-daily.yml` sets that flag only when a dedicated
 * Supabase e2e project is configured, so a prod-aliased job never writes to
 * prod. See e2e/README.md ("Notes suite").
 *
 * Prerequisites for the account:
 * - it belongs to a family (a family-less account is redirected to People when
 *   the add button is tapped), and
 * - that family is below the free note cap (3), or the account is Pro. The
 *   suite deletes every note it creates, and it clears leftovers from a
 *   crashed run before each test, so the cap only matters for the first run.
 *
 * The identifiers are pinned by
 * `packages/house_mira_notes/test/presentation/notes_semantics_test.dart`.
 */
const COLD_START = 20_000;
const EDITOR_OPEN = 15_000;
const HOME_TAB = /^Home/;
const ACCOUNT_TAB = /^Account/;
const NOTES_TAB = /^Notes/;

/**
 * Every note this suite creates starts with this marker, so leftovers from a
 * failed attempt are identifiable and removable before the next test. It is
 * only ever used inside the dedicated e2e account's family.
 */
const TEST_MARKER = 'E2E note';

/** Per-run suffix: two runs against the same family never collide. */
const RUN = `${Date.now().toString(36)}${Math.random().toString(36).slice(2, 6)}`;

const hasLoginCredentials =
  (process.env.E2E_LOGIN_EMAIL ?? '').trim() !== '' &&
  (process.env.E2E_LOGIN_PASSWORD ?? '') !== '';
const writesAllowed = process.env.E2E_ALLOW_WRITES === '1';

/**
 * Collection-time skip reason. It has to be a test option, not a `test.skip()`
 * call in the body: `beforeEach` signs in, so a body-level skip would already
 * have run the whole login flow (and failed without credentials).
 */
const skipReason = !hasLoginCredentials
  ? 'E2E_LOGIN_EMAIL / E2E_LOGIN_PASSWORD are not set'
  : !writesAllowed
    ? 'E2E_ALLOW_WRITES is not 1: note writes need a dedicated e2e project'
    : false;

function noteTitle(label: string): string {
  return `${TEST_MARKER} ${RUN} ${label}`;
}

function escapeRegExp(value: string): string {
  return value.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
}

/**
 * The card is one merged semantics node (MergeSemantics in NoteCardWidget), so
 * its accessible name is the card text: timestamp, title, body and author.
 * Matching the unique title inside that name is stable across locales.
 */
function noteCard(screen: Screen, title: string) {
  return screen.getByRole('button', { name: new RegExp(escapeRegExp(title)) });
}

async function fillLogin(
  device: Device,
  screen: Screen,
  email: string,
  password: string | Secret,
): Promise<void> {
  await screen.getByTestId('account-email-field').fill(email);
  // The keyboard shrinks the scroll view; dismiss it between fields and scroll
  // each remaining control into view (same dance as login.e2e.ts).
  await device.dismissKeyboard();
  await screen.scrollUntilVisible(
    screen.getByTestId('account-password-field'),
  );
  await screen.getByTestId('account-password-field').fill(password);
  await device.dismissKeyboard();
  await screen.scrollUntilVisible(
    screen.getByTestId('account-sign-in-button'),
  );
  await screen.getByTestId('account-sign-in-button').tap();
}

/**
 * Cold start -> onboarding -> sign in. Every test starts signed out because
 * `app.clearState()` wipes the stored session, so a test never inherits state
 * from the one before it.
 */
async function signIn(
  app: App,
  device: Device,
  screen: Screen,
): Promise<void> {
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
  // The signed-out tab opens on the marketing header; the form starts below
  // the fold on the emulator viewport, so scroll before filling.
  await screen.scrollUntilVisible(
    screen.getByTestId('account-sign-in-button'),
    { timeout: COLD_START },
  );
  const login = credentials.user('login');
  await fillLogin(device, screen, login.username, login.password);
  await expect(screen.getByTestId('account-loaded')).toBeVisible({
    timeout: COLD_START,
  });
}

async function openNotes(screen: Screen): Promise<void> {
  await screen.getByRole('button', NOTES_TAB).tap();
  await expect(screen.getByTestId('notes-loaded')).toBeVisible({
    timeout: COLD_START,
  });
}

/**
 * Opens the editor from the add button.
 *
 * Fails here, with a screenshot, when the tap showed a snackbar instead:
 * either the account has no family (redirect to People) or the family hit the
 * free note cap.
 */
async function openEditor(screen: Screen): Promise<void> {
  await screen.getByTestId('notes-add-button').tap();
  await expect(screen.getByTestId('note-editor-title')).toBeVisible({
    timeout: EDITOR_OPEN,
  });
}

/** Dismisses the keyboard, saves, and waits for the editor to pop. */
async function saveEditor(device: Device, screen: Screen): Promise<void> {
  await device.dismissKeyboard();
  await screen.getByTestId('note-editor-save').tap();
  await expect(screen.getByTestId('note-editor-title')).toHaveCount(0, {
    timeout: COLD_START,
  });
}

async function createNote(
  device: Device,
  screen: Screen,
  title: string,
  content: string,
): Promise<void> {
  await openEditor(screen);
  await screen.getByTestId('note-editor-title').fill(title);
  await device.dismissKeyboard();
  await screen.scrollUntilVisible(screen.getByTestId('note-editor-content'));
  await screen.getByTestId('note-editor-content').fill(content);
  await saveEditor(device, screen);
  await expect(noteCard(screen, title)).toBeVisible({ timeout: COLD_START });
}

/** Card -> Remove -> confirm. Used for cleanup and by the delete test. */
async function removeNote(screen: Screen, title: string): Promise<void> {
  await noteCard(screen, title).tap();
  await screen.getByTestId('note-menu-remove').tap();
  await screen.getByTestId('note-delete-confirm').tap();
  await expect(noteCard(screen, title)).toHaveCount(0, {
    timeout: COLD_START,
  });
}

/**
 * Removes notes left behind by a failed attempt. Bounded: the free cap is 3,
 * so a family cannot hold many leftovers, and an unbounded loop would hang if
 * a card never disappears.
 */
async function removeLeftovers(screen: Screen): Promise<void> {
  for (let attempt = 0; attempt < 10; attempt += 1) {
    const leftovers = await screen
      .getByRole('button', { name: new RegExp(TEST_MARKER) })
      .all();
    if (leftovers.length === 0) return;
    await leftovers[0].tap();
    await screen.getByTestId('note-menu-remove').tap();
    await screen.getByTestId('note-delete-confirm').tap();
    await expect(screen.getByTestId('note-delete-confirm')).toHaveCount(0);
  }
}

test.beforeEach(async ({ app, device, screen }) => {
  await signIn(app, device, screen);
  await openNotes(screen);
  await removeLeftovers(screen);
});

test(
  'creating a note shows it in the list',
  { skip: skipReason, timeout: 180_000 },
  async ({ device, screen }) => {
    const title = noteTitle('create');
    const content = `Created by the e2e suite ${RUN}`;

    await createNote(device, screen, title, content);

    await expect(noteCard(screen, title)).toBeVisible();

    // Leave the family as it was found.
    await removeNote(screen, title);
  },
);

test(
  'editing a note saves the new title',
  { skip: skipReason, timeout: 240_000 },
  async ({ device, screen }) => {
    const original = noteTitle('update-before');
    const updated = noteTitle('update-after');

    await createNote(device, screen, original, 'Body before the edit');

    await noteCard(screen, original).tap();
    await screen.getByTestId('note-menu-edit').tap();
    // Edit pre-fills the form from the tapped note; a fresh form would mean
    // the tap opened create instead of edit.
    await expect(screen.getByTestId('note-editor-title')).toHaveValue(
      original,
      { timeout: EDITOR_OPEN },
    );

    await screen.getByTestId('note-editor-title').fill(updated);
    await saveEditor(device, screen);

    await expect(noteCard(screen, updated)).toBeVisible({
      timeout: COLD_START,
    });
    await expect(noteCard(screen, original)).toHaveCount(0);

    await removeNote(screen, updated);
  },
);

test(
  'deleting a note removes it from the list',
  { skip: skipReason, timeout: 180_000 },
  async ({ device, screen }) => {
    const title = noteTitle('delete');

    await createNote(device, screen, title, 'Delete me');

    await noteCard(screen, title).tap();
    await screen.getByTestId('note-menu-remove').tap();
    // The confirmation dialog is a separate step: tapping Remove in the sheet
    // must not delete on its own.
    await expect(screen.getByTestId('note-delete-confirm')).toBeVisible();
    await screen.getByTestId('note-delete-confirm').tap();

    await expect(noteCard(screen, title)).toHaveCount(0, {
      timeout: COLD_START,
    });
  },
);

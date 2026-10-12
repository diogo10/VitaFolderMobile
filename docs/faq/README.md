# HouseMira FAQ

User-facing answers to common questions about HouseMira, synthesized from
the app source code. All UI wording quoted here comes from
`packages/house_mira_core/lib/l10n/app_en.arb` (Portuguese equivalents in
`app_pt.arb`); navigation paths come from
`packages/house_mira_core/lib/router/app_routes.dart`; plan/limit behavior
from `packages/house_mira_core/lib/subscriptions/usage_limits.dart`; and
account/invite behavior from the Supabase edge functions in
`supabase/functions/` and the Play Store listing in
`docs/stores/android/description-playstore.md`.

> Last synced with the codebase: October 2026. If UI copy changes in the
> `.arb` files, update this FAQ to match.

## Contents

- [General](#general)
- [Getting started](#getting-started)
- [Account and sign-in](#account-and-sign-in)
- [Family circle and invites](#family-circle-and-invites)
- [Roles and permissions](#roles-and-permissions)
- [Reminders](#reminders)
- [Notes](#notes)
- [Notifications](#notifications)
- [HouseMira Pro and free limits](#housemira-pro-and-free-limits)
- [Privacy and deleting your account](#privacy-and-deleting-your-account)
- [Troubleshooting](#troubleshooting)

## General

### What is HouseMira?

HouseMira ("Your family, organised together") is a family management app.
Each family gets a private **circle** where members share **reminders**
(chores, appointments, birthdays, medicine, vaccines, renewals) and
**notes** (grocery lists, family info), with timely on-device
notifications. Only your family circle can see your data.

### Which platforms are supported?

HouseMira is a Flutter mobile app shipping on **Android** (Google Play,
plus Firebase App Distribution test builds) and **iOS**. Sign-in options
include email, Google, and Apple.

### Is HouseMira free?

Yes — HouseMira is **free to start**: create a family, invite members, and
create reminders and notes for free. Free families share a cap of **10
reminders** and **3 notes**; **HouseMira Pro** removes those caps and adds
priority sync. See
[HouseMira Pro and free limits](#housemira-pro-and-free-limits).

### Is my data private?

Yes. Your circle is private by design: only people who join via your
family invite code, shareable link, or a direct email invite can see your
family's reminders and notes. You can manage members, roles, and family
settings at any time, and delete your account from within the app.

## Getting started

### How do I get started?

1. Open the app and swipe through the short onboarding ("Your Family, In
   One Place").
2. Tap **Get Started**, then **Create a free account** (email + name +
   password) or continue with Google/Apple.
3. On the Home tab, follow the setup cards: **Add people to your Circle**,
   **Set up a Reminder**, and **Complete your Account**.

### Can I look around before creating an account?

Yes. The main tabs (Home, People, Notes, Reminders, Account) are browsable
as a guest. Some actions — creating reminders or notes, joining a family —
ask you to sign in first ("You need to be logged in to perform this
action").

### How is the app organized?

Five bottom tabs:

| Tab | What it is for |
| --- | --- |
| Home | Greeting, today's activity, upcoming reminders, circle summary |
| People | Family members, invite code/link, pending invites, roles |
| Reminders | Full reminder list, calendar view, filters |
| Notes | Shared family notes |
| Account | Profile, notifications, family settings, help, danger zone |

One-off screens branch off these tabs: creating a reminder
(`/create-reminder`), editing a note (`/notes/edit`), inviting people
(`/invite-people`), family settings (`/family-settings`), editing your
profile (`/manage-profile`), notification settings
(`/notification-settings`), and the paywall (`/paywall`).

## Account and sign-in

### How do I create an account?

Go to Account (or open `/sign-up`): enter your **full name**, a valid
**email address**, and a **password of at least 8 characters** (a mix of
letters and numbers works best), then tap **Create Account**. By creating
an account you agree to the Terms of Service and Privacy Policy linked on
that screen.

### Can I sign in with Google or Apple?

Yes. The sign-in screen offers **Continue with Google** and **Continue
with Apple** alongside email sign-in. If a social sign-in fails, check
your connection and try again; cancelling the Google prompt simply returns
you to the sign-in screen without an error.

### I forgot my password. What do I do?

Tap **Forgot password?** on the sign-in screen, enter your email address,
and check your inbox for the reset link ("We've sent a link to your email
to reset your password."). If no email arrives, verify the address and try
again.

### How do I update my profile?

Account → **Edit Profile** (`/manage-profile`): change your display name
(and photo/contact details where offered), then tap **Save**. A name is
required — saving with an empty name shows "Please enter your name".

### How do I sign out?

Account → **Sign Out**. This logs you out on the current device only; your
account, family memberships, and shared data are untouched.

## Family circle and invites

### How do I create a family?

Open the People tab and tap **Create Family**, then enter a family name.
You become the family's first member (and admin) and can start inviting
others.

### How do I invite someone to my family?

Three equivalent ways, all managed from People → **Invite Members** /
**Invite People** (`/invite-people`):

1. **Family invite code** — share the short code shown on the "Family
   Invite Code" card. The recipient opens People, taps **Join Family**,
   and enters the code.
2. **Shareable link** — tap **Share Link** to copy/send the invite link
   (`https://vitafolder.app/invite/<code>`). Opening it takes the
   recipient straight to the join flow; an invalid or expired link falls
   back to the People tab so they can enter a code manually.
3. **Email invite** — enter the person's email address (and their
   relationship: spouse, child, parent, other) and tap **Send Invite**.
   They receive a localized invite email with a join button ("Invite
   sent!" confirms it on your side).

Only share codes/links with people you trust — anyone holding a valid
code can request to join.

### Do invite codes expire?

Yes — the invite card shows when the current code expires ("Code expires
in …"). You can tap **Refresh Code** at any time to invalidate the old
code and issue a new one, and copy or resend pending email invites from
the pending-invite card.

### I received an invite. How do I join?

- **Link:** tap it; the app opens the join flow for that code.
- **Code:** open People → **Enter Invite Code** → **Join Family**, and
  type the code exactly as shared.
- **Email:** tap the join button in the email, or enter the code from the
  email manually.

An invalid code shows "Invalid family code. Please try again." — ask the
sender for a fresh code or link.

### How do I manage my family?

Admins open **Family Settings** (`/family-settings`) from People or
Account: rename the family, review the member count, change roles, and
remove members (removal asks for confirmation naming the person and
family). Only family admins can open Family Settings.

### How do I leave a family?

Family Settings → **Leave Family**. Leaving removes you from the circle
and **permanently deletes the notes and reminders you created in that
family**; the shared data other members created stays with them. If you
are the last admin, transfer admin to someone else first; if you are the
only member left, delete the circle instead of leaving.

### How do I delete a family circle?

An admin opens Family Settings → **Delete Circle**. This is permanent:
all of the circle's data, tasks, and memberships are removed. Individual
members who only want out should **Leave Family** instead.

## Roles and permissions

### What roles exist?

| Role | What they can do |
| --- | --- |
| Admin | Manage all members, roles, invites, and family settings |
| Parent | Add tasks/reminders and collaborate |
| Member | Collaborate in the circle |
| Child | View-only access |

The People tab shows each member's role badge, and the Roles card
summarizes: "Admins can manage all members. Parents can add tasks.
Children have view-only access."

### How do I change someone's role or remove them?

In Family Settings → Manage Members, use the member row (role control /
remove action). Removing asks "Remove {name} from {familyName}?" before
it takes effect.

## Reminders

### What can I track with reminders?

Reminder types in the app: **Chores, Appointments, Birthdays, Renewal,
Vaccine, Reimbursement,** and **Custom**. The empty state suggests the
same starter ideas: recurring chores, doctor/school appointments, and
birthdays.

### How do I create a reminder?

Reminders → **Create First Reminder** (or Home → Add Task), which opens
**New Reminder** (`/create-reminder`):

1. Enter a **title** (required, e.g. "Weekly Grocery Run").
2. Optionally add **details**, a **type**, a **due date**, and a **time**.
3. Choose a **repeat** rule: Never, Daily, Weekly, Monthly, or Yearly.
4. Toggle **Notify me on this device** and pick when to be alerted.
5. Tap **Create Reminder**.

"Reminder created successfully" confirms it; the reminder appears grouped
under Today / Tomorrow / a date section, or "No date" for dateless items.

### Can I edit or delete a reminder?

Yes. Open the reminder to edit (same screen, titled **Edit Reminder**,
saving with **Save Changes** shows "Reminder updated successfully"), or
use its delete action: "Remove reminder — Are you sure you want to remove
…?" → **Remove**.

### What do the reminder statuses mean?

Reminders move through **Pending → Sent** (notification fired) **→ Done**,
or end as **Dismissed** / **Cancelled**. The Reminders list and Home's
"members active · reminders pending" line summarize what still needs
attention ("You're all caught up 🎉" when nothing is pending).

### Can I filter or view reminders as a calendar?

Yes. The Reminders tab offers a list/calendar toggle ("View as calendar"),
type filters (Chores, Appointments, Birthdays, Renewal, Vaccine,
Reimbursement, Custom) behind **Filter Reminders → Apply Filters**, and
pulls notification taps back to the reminders list.

## Notes

### What are shared notes for?

Notes are short shared texts — grocery lists, family info, anything the
whole circle should see. Each note shows who it is shared with ("Shared
with your family") and a relative timestamp (e.g. "5 min ago", "2h ago",
"Yesterday").

### How do I create or edit a note?

Notes → **Create Your First Note** (or **+**), which opens the editor
(`/notes/edit`): add a **title** (required, max 100 characters) and
**content** (required, max 300 characters), pick a **note color** (Yellow,
Pink, Blue, Green, Orange), then **Save**. Reopen any note to edit it;
deleting asks "Are you sure you want to remove this note?" first.

### Why can't I create a note?

- **Not signed in:** the Notes tab shows "Sign in to create, share, and
  organize notes with your family circle."
- **No family yet:** "No family found. Join or create a family first."
- **Free limit reached:** "You've reached the free limit of 3 notes.
  Upgrade to create more." — see the paywall section below.

## Notifications

### How do reminder notifications work?

When creating a reminder with a due date, enable **Notify me on this
device** and choose a lead time: **At time, 15 min before, 1 hour before,**
or **1 day before**. Notifications are delivered on-device; tapping one
opens the Reminders list.

### How do I manage notification preferences?

Account → **Notifications** (`/notification-settings`):

- **Enable notifications** — master switch for reminder/family alerts.
- **Email updates** — periodic summary by email.
- **Send test notification** — posts one immediately ("If you see this,
  reminders can reach you.") to verify delivery.

If the OS permission was denied, the app explains how to re-enable it in
system settings rather than failing silently.

### Why did my reminder save "without notifications"?

The app tells you instead of pretending: **notifications disabled** (turn
them on in Notification Settings / system settings), the **selected time
already passed** (pick a future time), or — on Android — **exact alarms
not allowed** ("alerts may be delayed. Allow exact alarms for on-time
reminders"), which you fix via the offered Settings shortcut.

## HouseMira Pro and free limits

### What are the free limits?

- **Reminders:** 10 per family for free users.
- **Notes:** 3 per family for free users.

Hitting a cap shows "You've reached the free limit of … Upgrade to
create more." with an **Upgrade** action that opens the paywall
(`/paywall`). HouseMira Pro removes both caps (unlimited reminders and
notes) plus priority sync.

### Is the limit per person or per family?

Counts are **shared per family**: every member's reminders/notes count
toward the same cap, so you can be blocked even if you personally created
nothing. The Pro entitlement itself is **per user** (tied to the buyer's
account/purchase on the current device).

### What does HouseMira Pro include?

From the paywall (`HouseMira Pro — Unlock your house's full potential.`):

- **Unlimited Everything** — no more limits on notes or reminders.
- **Smart Auto-Sorting** — automatic categorization of activity.
- **Priority Sync** — faster updates across all devices.

### How does billing work?

Plans are sold through the App Store / Google Play via RevenueCat with
**Monthly Access** (flexible, cancel anytime) and **Annual Access**
(billed yearly, with a computed SAVE % badge). Prices shown are the live
store prices; new subscriptions start with a **7-day free trial** where
offered, and the trial renews automatically unless cancelled. Monthly and
annual wording, totals, and per-month labels all come from the store —
what you see on the paywall is what you pay.

### How do I restore a purchase or cancel?

- **Restore:** tap **RESTORE PURCHASES** on the paywall to re-apply a
  previous purchase on a new/reinstalled device.
- **Cancel:** subscriptions are managed in the store (Play Store →
  Payments & subscriptions → Subscriptions, or iPhone Settings → Apple
  ID → Subscriptions), not inside HouseMira. Cancelling stops renewal;
  you keep Pro until the period ends.

### What if prices won't load?

The paywall shows "Couldn't load plans. Try again." with a retry button —
real prices are never faked in production. (On internal Test Store builds
the app may show a mocked catalog so development isn't blocked.)

## Privacy and deleting your account

### How do I delete my account?

Account → **Delete Account** (in the Danger Zone) → confirm **Delete**.
The confirmation warns: "This cannot be undone. Your profile, family
memberships and login will be permanently removed. Your family's shared
data stays with the other members." Success shows "Your account has been
deleted."

### What exactly happens on deletion?

The app calls the `delete-account` edge function, which verifies your
sign-in server-side and deletes your auth user. Database cascades then
remove your profile, family memberships, and notification tokens/logs.
The `families` row itself is kept (ownership set to null) so remaining
members keep their shared reminders and notes. You are signed out on the
device as part of the flow.

### Why am I blocked from deleting my account?

If you are the **last remaining owner of a family circle**, deletion is
refused ("You are the last owner of your family circle. Transfer
ownership or delete the circle in Family Settings first.") so the circle
is never orphaned. Transfer ownership (or delete the circle) and try
again. Other failures show "We could not delete your account. Please try
again."

## Troubleshooting

### "Something went wrong / Could not load …"

Each tab has a retry action (**Try again**). If it persists: check your
connection ("You appear to be offline" for notes), force-close and reopen
the app, and confirm you are signed in — signed-out sessions see limited
data.

### "You need to be logged in to perform this action"

You tapped something that requires an account as a guest. Sign in (or
create an account) and retry — your pre-sign-in place is preserved where
possible.

### Invite link doesn't work

Ask the sender for a fresh code or link: links expire when the code is
refreshed, and mistyped/short codes are rejected. As a fallback, open
People → **Join Family** and enter the code by hand.

### Test notification never arrives

Account → Notifications → **Send test notification**. If it fails, allow
notifications for HouseMira in system settings (and exact alarms on
Android), then retry.

### Where do I get more help?

Account → **Help & FAQ** for answers and support contact, **Privacy
Policy** for data handling, and **Terms of Use** (linked from sign-up and
the paywall) for subscription terms.

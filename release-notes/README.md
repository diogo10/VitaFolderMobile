# Release notes

One file per app version, named after the public version (`MAJOR.MINOR.PATCH`).
The build number (`+N`) lives inside the file because a version can be rebuilt
without changing its name.

```
release-notes/
  1.0.7.md   # next release (pubspec.yaml 1.0.7+8)
  1.0.6.md   # internal testing only
  1.0.5.md   # in production
```

## What each file holds

| Section | Use |
| --- | --- |
| Header | Version, build number, date, channel (internal / production), Play upload run |
| Play Store — What's new | The text pasted into Play Console, English and Portuguese, **≤ 500 characters each** (Play's hard limit) |
| Full changelog | Everything user-visible in the build, grouped by area |
| Crashlytics | Issues the build closes or fixes (ids match the Crashlytics console and `.agents/skills/firebase-crashlytics/references/triage.md`) |
| Notes | Anything a reviewer or the release engineer must know (internal-only, skipped build, config requirement) |

## Rules

- Write for a user, not for `git log`: describe what changed for them, not the
  commit type. Internal work (CI, refactors, docs) belongs in Notes or nowhere.
- Keep the Play text within 500 characters per language. Count before pasting —
  Play truncates silently.
- Name the build that carries the change. `1.0.6+7` was uploaded to the
  internal track only, so its fixes ship to production with `1.0.7+8`: the
  1.0.7 Play text has to cover both.
- A release that is only internal gets its own file; do not fold it into the
  next one.
- Fixes shipped for a Crashlytics issue stay listed until the fixed build is
  the one in the field (`lastSeenVersion` ≥ that build).
- Never invent a version that was not uploaded. The source of truth is the
  `aab-release-<version>+<build>` artifact of
  `Actions → Build AAB (Production Release)`.

## Index

| Version | Build | Date | Channel | Notes |
| --- | --- | --- | --- | --- |
| [1.0.7](1.0.7.md) | 8 | 2026-10-28 | next | First production build since 1.0.5; carries the 1.0.6 fixes |
| [1.0.6](1.0.6.md) | 7 | 2026-10-27 | internal | Never promoted; superseded by 1.0.7 |
| [1.0.5](1.0.5.md) | 6 | 2026-10-22 | production | Sign in with Apple |

Versions before 1.0.5 predate this folder. Their commits are the history of
`pubspec.yaml`'s `version:` line:

```bash
git log -S "version: 1.0.4+5" -- pubspec.yaml
```

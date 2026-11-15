#!/usr/bin/env bash
#
# Android device e2e, as run by .github/workflows/e2e-daily.yml and by anyone
# reproducing a red nightly locally.
#
# Why a script instead of an inline `script:` block: the emulator action runs
# every *line* of its `script:` input in its own `/usr/bin/sh -c`. A `cd e2e` on
# one line therefore does not apply to the next one, so the 2026-11-12..15
# nightlies ran `e2e doctor` at the repo root, found no config, and died with
# CONFIG_NOT_FOUND (exit 2) before a single test executed. One
# `bash e2e/ci-android.sh` line keeps one shell, one cwd, and one fail-fast path.
#
# Fail fast: every pre-condition below is checked in seconds and reports a
# `::error::` annotation instead of an opaque exit code deep inside a run.
#
# Usage (from the repo root, with the emulator booted and the APK built):
#   bash e2e/ci-android.sh
set -euo pipefail

# Locate the repo from this file, so the script does not depend on the caller's
# cwd (which is exactly the bug this script exists to avoid).
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "$script_dir/.." && pwd)"
apk="$repo_root/build/app/outputs/flutter-apk/app-release.apk"
config="$script_dir/e2e.config.ts"
# The CLI installed by `npm ci` from e2e/package-lock.json. Never `npx e2e`:
# with no local install npx silently downloads the latest release, so a broken
# install turns into an unreviewed CLI upgrade instead of a failure.
cli="$script_dir/node_modules/.bin/e2e"

die() {
  echo "::error::$*" >&2
  exit 1
}

# --- Pre-conditions -----------------------------------------------------------
[ -x "$cli" ] || die "e2e CLI missing at $cli - run 'npm ci' in e2e/ first."
[ -f "$config" ] || die "e2e.config.ts missing from $script_dir."
[ -f "$apk" ] || die "APK missing at $apk - build it with 'flutter build apk --release --dart-define=E2E_MODE=true ...' first."
command -v adb >/dev/null 2>&1 || die "adb is not on PATH."
adb wait-for-device
boot_completed="$(adb shell getprop sys.boot_completed 2>/dev/null | tr -d '\r')"
[ "$boot_completed" = "1" ] || die "device is not booted (sys.boot_completed='$boot_completed')."

cd "$script_dir"

# --- Discovery ---------------------------------------------------------------
# Loading the suite proves the config resolves from this directory, the
# TypeScript compiles and the tests are discovered - all before the run spends
# the device's time on them.
echo "== e2e test discovery"
discovery="$("$cli" list --target android)"
printf '%s\n' "$discovery"
discovered="$(printf '%s\n' "$discovery" | grep -c '\[android\]' || true)"
[ "$discovered" -gt 0 ] || die "no android tests discovered - check e2e.config.ts targets and tests/*.e2e.ts."
echo "discovered $discovered android test(s)"

# --- Install -----------------------------------------------------------------
# Installed here rather than via config `app.appPath` so the artifact under test
# is the one this job built. `doctor` then verifies the bundle id is present.
echo "== install $apk"
adb install -r "$apk"

# --- Environment check -------------------------------------------------------
# Validates the node runtime, the config, the mobile engine and the installed
# app. A failure here is an environment problem, not a product regression.
# --target is not optional: doctor checks every configured target by default,
# and the iOS target cannot pass on an ubuntu runner (no simulator), which
# would turn a healthy Android run red.
echo "== e2e doctor"
"$cli" doctor --target android

# --- Run ---------------------------------------------------------------------
# junit.xml + report.json + results/ land in .e2e/ for the workflow artifact.
echo "== e2e run"
"$cli" run --target android --reporter list,junit --max-failures 3

#!/usr/bin/env bash
# Enforces startup/APK performance budgets from tool/performance_budgets.json.
#
# Checks (all best-effort, hard-fail only when a measured artifact is over budget):
#   1. The host-side startup constant in test/integration/critical_path_test.dart
#      and integration_test/critical_path_test.dart matches test_host_startup_s.
#   2. Every APK under build/app/outputs/flutter-apk/ is under the matching
#      budget (debug -> apk_debug_mb_max, profile/release -> apk_profile_mb_max).
#   3. Writes a markdown report to stdout (CI redirects it to $GITHUB_STEP_SUMMARY).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUDGETS="$ROOT/tool/performance_budgets.json"

fail=0
say() { printf '%s\n' "$*"; }

if [[ ! -f "$BUDGETS" ]]; then
  say "::error::Budgets file not found: tool/performance_budgets.json"
  exit 1
fi

host_budget=$(python3 -c "import json;print(json.load(open('$BUDGETS'))['test_host_startup_s'])")
debug_max=$(python3 -c "import json;print(json.load(open('$BUDGETS'))['apk_debug_mb_max'])")
profile_max=$(python3 -c "import json;print(json.load(open('$BUDGETS'))['apk_profile_mb_max'])")

say "## Performance budgets"
say ""
say "| Budget | Value |"
say "| --- | --- |"
say "| Host startup (integration asserts) | ${host_budget}s |"
say "| APK debug max | ${debug_max} MB |"
say "| APK profile/release max | ${profile_max} MB |"
say ""

# 1. Startup constant sync.
for f in test/integration/critical_path_test.dart integration_test/critical_path_test.dart; do
  if [[ -f "$ROOT/$f" ]]; then
    if grep -q "startupBudget = Duration(seconds: $host_budget)" "$ROOT/$f"; then
      say "- ✅ \`$f\` startupBudget matches ${host_budget}s"
    else
      say "::error::\`$f\` startupBudget drifts from budgets file (${host_budget}s)"
      fail=1
    fi
  else
    say "::error::Missing critical-path test: $f"
    fail=1
  fi
done
say ""

# 2. APK sizes.
shopt -s nullglob
apks=( "$ROOT"/build/app/outputs/flutter-apk/*.apk )
if [[ ${#apks[@]} -eq 0 ]]; then
  say "_No APK built in this job; size check skipped (build jobs report it)._"
else
  say "| APK | Size | Budget | Status |"
  say "| --- | --- | --- | --- |"
  for apk in "${apks[@]}"; do
    name=$(basename "$apk")
    bytes=$(stat -c%s "$apk")
    mb=$(python3 -c 'import sys; print(f"{int(sys.argv[1]) / 1024 / 1024:.1f}")' "$bytes")
    if [[ "$name" == *debug* ]]; then max="$debug_max"; else max="$profile_max"; fi
    over=$(python3 -c 'import sys; print("yes" if int(sys.argv[1]) > float(sys.argv[2]) * 1024 * 1024 else "no")' "$bytes" "$max")
    if [[ "$over" == "yes" ]]; then
      say "| \`$name\` | ${mb} MB | ${max} MB | ❌ OVER |"
      say "::error::APK over budget: $name is ${mb} MB (max ${max} MB)"
      fail=1
    else
      say "| \`$name\` | ${mb} MB | ${max} MB | ✅ |"
    fi
  done
fi

exit "$fail"

#!/usr/bin/env bash
# Fails CI when backend secrets are hardcoded in the client.
# Run locally: bash tool/check_no_hardcoded_secrets.sh
set -euo pipefail

fail=0

# 1. Real Supabase publishable/secret keys must never appear in Dart source.
#    (Tests use the literal 'mock-anon-key', which contains no key material.)
if grep -rEn --include='*.dart' 'sb_(publishable|secret)_' lib/ test/; then
  echo "::error::Hardcoded Supabase key found. Inject keys via --dart-define / env/<flavor>.json instead."
  fail=1
fi

# 2. Hardcoded Supabase project URLs must not appear in lib/.
#    test/ may reference https://mock.supabase.co as a fake.
if grep -rEn --include='*.dart' 'https://[A-Za-z0-9-]+\.supabase\.co' lib/ | grep -v 'your-[a-z-]*\.supabase\.co'; then
  echo "::error::Hardcoded Supabase URL found in lib/. Use AppConfig (--dart-define) instead."
  fail=1
fi

# 3. Service-role keys are server-only and must never ship in the client.
if grep -rEni --include='*.dart' 'service.role|SERVICE_ROLE' lib/; then
  echo "::error::Service-role key reference found in lib/. Service-role keys are server-only."
  fail=1
fi

# 4. Real env files (env/*.json) must not be committed; only *.example.json.
tracked=$(git ls-files 'env/*.json' | grep -v '\.example\.json' || true)
if [ -n "$tracked" ]; then
  echo "::error::Real env files must not be committed (only *.example.json): $tracked"
  fail=1
fi

if [ "$fail" -eq 0 ]; then
  echo 'No hardcoded secrets detected.'
fi
exit "$fail"

#!/usr/bin/env bash
# Phase 06 PII sweep — fails CI if a raw bearer token, Stripe identifier,
# secret key, or unredacted print/debugPrint slips into mobile/lib.
#
# The redaction layer (`mobile/lib/core/logging/redact.dart`) is the only
# file allowed to mention these patterns, so we exclude it from the search.
#
# Run locally before merging any logging-plan PR:
#   ./mobile/docs/logging-plan/check_pii.sh
#
# Exit codes:
#   0 — clean
#   1 — tooling missing
#   2 — at least one suspicious match found

set -u

# Locate the mobile/lib root from the script's path so the check works from
# any cwd (CI, local, IDE).
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
mobile_root="$(cd "$script_dir/../.." && pwd)"
lib_dir="$mobile_root/lib"

if [ ! -d "$lib_dir" ]; then
  echo "PII sweep: mobile/lib not found at $lib_dir"
  exit 1
fi

# Prefer ripgrep; fall back to grep -r if rg is missing.
if command -v rg >/dev/null 2>&1; then
  search() {
    rg -n --color=never \
       --glob '!**/logging/redact.dart' \
       --glob '!**/logging/check_pii_test.dart' \
       "$1" "$lib_dir"
  }
else
  search() {
    grep -rnE \
      --include='*.dart' \
      --exclude='redact.dart' \
      "$1" "$lib_dir"
  }
fi

fail=0

echo "PII sweep: scanning $lib_dir"

# 1. Bearer tokens, Stripe payment / setup intents, secret keys.
secrets='\bBearer\s+[A-Za-z0-9._-]{20,}|pi_[A-Za-z0-9]{24,}|seti_[A-Za-z0-9]{24,}|sk_(live|test)_[A-Za-z0-9]+'
matches="$(search "$secrets" || true)"
if [ -n "$matches" ]; then
  echo "PII sweep: secret-shaped strings found"
  echo "$matches"
  fail=1
fi

# 2. Direct prints (analyzer already has `avoid_print: error` — defence in
# depth so a `// ignore` cannot silently re-introduce one).
prints='\b(print|debugPrint)\('
matches="$(search "$prints" || true)"
if [ -n "$matches" ]; then
  echo "PII sweep: raw print/debugPrint found"
  echo "$matches"
  fail=1
fi

if [ "$fail" -eq 0 ]; then
  echo "PII sweep: ok"
  exit 0
else
  echo "PII sweep: fail"
  exit 2
fi

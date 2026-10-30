#!/bin/sh
# Scenario tests for check.sh symbols and check.sh env.
# Usage: sh test-symbols.sh <scratch dir> <check.sh path>
SCR=$1; CHK=$2; F="$SCR/symfx"; P="$F/proj"
rm -rf "$F"; mkdir -p "$P/docs/migration" "$F/snap/src"
PASS=0; FAIL=0

expect() { # <label> <expected substring> <actual output>
  if printf '%s' "$3" | grep -qF -- "$2"; then PASS=$((PASS + 1)); echo "ok    $1"
  else FAIL=$((FAIL + 1)); echo "FAIL  $1: expected [$2]"; printf '%s\n' "$3" | sed 's/^/      | /'; fi
}
absent() { # <label> <unexpected substring> <actual output>
  if printf '%s' "$3" | grep -qF -- "$2"; then FAIL=$((FAIL + 1)); echo "FAIL  $1: unexpected [$2]"; printf '%s\n' "$3" | sed 's/^/      | /'
  else PASS=$((PASS + 1)); echo "ok    $1"; fi
}

cat > "$F/snap/src/pricing.py" <<'PY'
import os
def round_price(amount):
    return amount
DB_URL = os.environ.get("DB_URL")
KEY = os.getenv("API_KEY")
PY
cat > "$F/snap/src/app.js" <<'JS'
const port = process.env.APP_PORT;
JS
printf 'SECRET_TOKEN=abc123value\nexport REGION=us-east-1\n' > "$F/snap/.env.sample"

cat > "$P/docs/migration/MIGRATION.md" <<EOF
---
source_sha: 0000000000000000000000000000000000000000
source_snapshot: ../snap
source_root: .
---
# Migration
EOF

cat > "$P/doc.md" <<'EOF'
- Rule: `round_price` returns the amount, `src/pricing.py:2-3 @0000000`.
- Literal: `true` and `null` are skipped, `src/pricing.py:2 @0000000`.
- No citation here, so `ghost_symbol` is not checked.
EOF
out=$(cd "$P" && sh "$CHK" symbols doc.md 2>&1)
expect "1 symbol present in the cited file is OK" "symbols OK doc.md" "$out"

cat > "$P/bad.md" <<'EOF'
- Rule: `ghost_symbol` is validated, `src/pricing.py:2-3 @0000000`.
- Dotted: `PricingService.round_price` is called, `src/pricing.py:2 @0000000`.
EOF
out=$(cd "$P" && sh "$CHK" symbols bad.md 2>&1)
expect "2 symbol missing from the cited file is INVALID" "symbols INVALID bad.md" "$out"
expect "2 names the missing symbol" "symbol=ghost_symbol:src/pricing.py:not-in-cited-files" "$out"
absent "2 dotted name matches on its last segment" "symbol=PricingService.round_price" "$out"

out=$(cd "$P" && sh "$CHK" symbols nofile.md 2>&1)
expect "3 missing file is reported" "symbols MISSING nofile.md" "$out"

out=$(cd "$P" && sh "$CHK" env 2>&1)
expect "4 python environ.get name" "env=DB_URL src/pricing.py:4" "$out"
expect "4 python getenv name" "env=API_KEY src/pricing.py:5" "$out"
expect "4 node process.env name" "env=APP_PORT src/app.js:1" "$out"
expect "4 env file name" "env=SECRET_TOKEN .env.sample:1" "$out"
expect "4 env file export name" "env=REGION .env.sample:2" "$out"
absent "4 env file value is never printed" "abc123value" "$out"
absent "4 env file second value is never printed" "us-east-1" "$out"

echo "----"
echo "pass=$PASS fail=$FAIL"
[ "$FAIL" -eq 0 ]

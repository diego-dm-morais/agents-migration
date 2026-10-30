#!/bin/sh
# Scenario tests for check.sh. Usage: sh test-check.sh <scratch dir> <check.sh path>
SCR=$1; CHK=$2; F="$SCR/fx"
rm -rf "$F"; mkdir -p "$F/srcrepo/src"
cat > "$F/srcrepo/src/pricing.py" <<'PY'
from decimal import Decimal, ROUND_HALF_EVEN

def round_price(amount):
    if amount < 0:
        raise ValueError("negative")
    return amount.quantize(Decimal("0.01"), rounding=ROUND_HALF_EVEN)
PY
( cd "$F/srcrepo" && git init -q && git add -A && git -c user.email=t@t -c user.name=t commit -qm init )
SHA=$(git -C "$F/srcrepo" rev-parse HEAD)
SHA7=$(printf '%s' "$SHA" | cut -c1-7)
git clone -q "$F/srcrepo" "$F/snap"

gen() {
  D=$1; P="$F/proj"
  rm -rf "$P"; mkdir -p "$P/docs/migration/round-price" "$P/src" "$P/test" "$P/docs"
  SHA_USED=$SHA; [ "$D" = pin-bad ] && SHA_USED=0000000000000000000000000000000000000000
  S7=$SHA7; [ "$D" = badcite-sha ] && S7=abcdef1
  cat > "$P/docs/migration/MIGRATION.md" <<EOF
---
source_language: python
source_version: 3.12
source_repo: $F/srcrepo
source_ref: main
source_sha: $SHA_USED
source_snapshot: ../snap
source_root: .
target_language: nodejs
target_version: 22
target_root: .
doc_root: docs
unit_kind: module
artifact_language: pt-BR
doc_language: pt-BR
limit_dispatch: 2
limit_review_rounds: 3
limit_fix_rounds: 2
---
# Migração

## Backlog
- round-price
EOF
  printf 'export function roundPrice(a) { return a }\n' > "$P/src/round.js"
  printf 'console.log("test")\n' > "$P/test/round.test.js"
  L6=6; [ "$D" = badcite-line ] && L6=99
  EX="$P/docs/migration/round-price/extraction.md"
  cat > "$EX" <<EOF
---
unit: round-price
stage: extract
status: ok
---
# round-price

## Entry points
- \`src/pricing.py:3 @$S7\` round_price

### BR-ROUND-001 Negative amounts are rejected
- Statement: negative amounts raise ValueError. Evidence: \`src/pricing.py:4-5 @$S7\`.

### BR-ROUND-002 Half-even rounding to cents
- Statement: quantize to 0.01 with ROUND_HALF_EVEN. Evidence: \`src/pricing.py:$L6 @$S7\`.

## Legacy decisions contrary to best practice
- none found: searched src/pricing.py for overrides
EOF
  EHASH=$(sh "$CHK" hash "$EX")
  PEND_BLK=no; PEND_RES="- resolution: EUR only"
  [ "$D" = pend ] && { PEND_BLK=yes; PEND_RES="- resolution:"; }
  FR2="### FR-002 Round half-even to cents
- Source: BR-ROUND-002"
  [ "$D" = uncovered ] && FR2="### FR-002 Round half-even to cents
- Source: none"
  SP="$P/docs/migration/round-price/spec.md"
  cat > "$SP" <<EOF
---
unit: round-price
stage: spec
status: ok
upstream_extraction: $EHASH
---
# Spec

### FR-001 Reject negative amounts
- Source: BR-ROUND-001

$FR2

## Pending

### PEND-001 Currency
- blocking: $PEND_BLK
$PEND_RES
EOF
  [ "$D" = extract-edit ] && printf '\nNote added after the spec.\n' >> "$EX"
  SHASH=$(sh "$CHK" hash "$SP")
  PL="$P/docs/migration/round-price/plan.md"
  cat > "$PL" <<EOF
---
unit: round-price
stage: plan
status: ok
upstream_spec: $SHASH
---
# Plan

### ID-001 Decimal handling
- status: accepted
- Trace: FR-001 -> T-001; FR-002 -> T-002
EOF
  PHASH=$(sh "$CHK" hash "$PL")
  T2_STATUS=done; T2_EV="node --test: pass"
  [ "$D" = blocked-task ] && T2_STATUS=blocked
  [ "$D" = done-noev ] && T2_EV=""
  TK="$P/docs/migration/round-price/tasks.md"
  cat > "$TK" <<EOF
---
unit: round-price
stage: tasks
status: ok
upstream_spec: $SHASH
upstream_plan: $PHASH
---
# Tasks

### T-001 Reject negative amounts
status: done
kind: test
depends: none
files: test/round.test.js
spec: FR-001
validation: node --test
evidence: node --test: pass

### T-002 Half-even rounding
status: $T2_STATUS
kind: impl
depends: T-001
files: src/round.js
spec: FR-002
validation: node --test
evidence: $T2_EV
EOF
  if [ "$T2_STATUS" = done ]; then
    SC=$( { printf '== src/round.js\n'; cat "$P/src/round.js"; printf '== test/round.test.js\n'; cat "$P/test/round.test.js"; } | cksum | awk '{ print $1 }')
  else
    SC=$( { printf '== test/round.test.js\n'; cat "$P/test/round.test.js"; } | cksum | awk '{ print $1 }')
  fi
  RVF=fixed; [ "$D" = review-open-ok ] && RVF=open
  RV="$P/docs/migration/round-price/review.md"
  cat > "$RV" <<EOF
---
unit: round-price
stage: review
status: ok
round: 1
scope_hash: $SC
---
# Review

### RV-001 Example finding
status: $RVF
EOF
  DOC="$P/docs/round-price.md"
  XH=$(sh "$CHK" hash "$EX"); SH=$(sh "$CHK" hash "$SP"); PH=$(sh "$CHK" hash "$PL"); TH=$(sh "$CHK" hash "$TK")
  cat > "$DOC" <<EOF
---
unit: round-price
stage: doc
status: ok
scope_hash: $SC
---
# round-price

## Fontes
| Fonte | cksum |
|---|---|
| extraction | $XH |
| spec | $SH |
| plan | $PH |
| tasks | $TH |
EOF
  [ "$D" = missing-extract ] && rm -f "$EX"
  if [ "$D" = crlf ]; then
    for f in "$P/docs/migration/MIGRATION.md" "$EX" "$SP" "$PL" "$TK" "$RV" "$DOC"; do
      [ -f "$f" ] && sed 's/$/\r/' "$f" > "$f.tmp" && mv "$f.tmp" "$f"
    done
  fi
}

run() { echo "=== $1"; cd "$F/proj" && sh "$CHK" status round-price; cd "$F" || exit 1; }
gen none; run "valid unit (must be all OK)"
gen none; EX="$F/proj/docs/migration/round-price/extraction.md"; sed -i 's/quantize to 0.01 with ROUND_HALF_EVEN. Evidence: .*$/quantize to 0.01 with ROUND_HALF_EVEN. Evidence: none./' "$EX"; run "BR without citation (expect extract INVALID no-evidence-BR-ROUND-002)"
gen none; SP="$F/proj/docs/migration/round-price/spec.md"; sed -i 's/- Source: BR-ROUND-002/- Note: see BR-ROUND-002/' "$SP"; run "FR without Source line (expect spec INVALID no-source-FR-002)"

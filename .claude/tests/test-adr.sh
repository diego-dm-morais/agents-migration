#!/bin/sh
# Scenario tests for rule 10: DEC section, ADR files (check.sh adr), plan and doc states.
# Usage: sh test-adr.sh <scratch dir> <check.sh path>
SCR=$1; CHK=$2; F="$SCR/adrfx"; P="$F/proj"
rm -rf "$F"; mkdir -p "$F/srcrepo/src"
printf 'def round_price(x):\n    return x\n' > "$F/srcrepo/src/pricing.py"
( cd "$F/srcrepo" && git init -q && git add -A && git -c user.email=t@t -c user.name=t commit -qm init >/dev/null 2>&1 )
SHA=$(git -C "$F/srcrepo" rev-parse HEAD)
S7=$(printf '%s' "$SHA" | cut -c1-7)
git clone -q "$F/srcrepo" "$F/snap" >/dev/null 2>&1
CITE="src/pricing.py:2 @$S7"
URL="https://docs.python.org/3/library/decimal.html"
PASS=0; FAIL=0

expect() { # <label> <expected substring> <actual output>
  if printf '%s' "$3" | grep -qF -- "$2"; then PASS=$((PASS + 1)); echo "ok    $1"
  else FAIL=$((FAIL + 1)); echo "FAIL  $1: expected [$2]"; printf '%s\n' "$3" | sed 's/^/      | /'; fi
}
absent() { # <label> <unexpected substring> <actual output>
  if printf '%s' "$3" | grep -qF -- "$2"; then FAIL=$((FAIL + 1)); echo "FAIL  $1: unexpected [$2]"; printf '%s\n' "$3" | sed 's/^/      | /'
  else PASS=$((PASS + 1)); echo "ok    $1"; fi
}

new_project() {
  rm -rf "$P"; mkdir -p "$P/docs/migration/round-price" "$P/docs/migration/adr"
  cat > "$P/docs/migration/MIGRATION.md" <<EOF
---
source_language: python
source_version: 3.12
source_repo: $F/srcrepo
source_ref: main
source_sha: $SHA
source_snapshot: $F/snap
source_root: .
target_language: nodejs
target_version: 22
target_root: .
doc_root: docs
unit_kind: module
artifact_language: pt-BR
doc_language: pt-BR
limit_dispatch: 3
limit_review_rounds: 3
limit_fix_rounds: 2
---
EOF
}

# write_extraction <body of the legacy decision section>
write_extraction() {
  cat > "$P/docs/migration/round-price/extraction.md" <<EOF
---
unit: round-price
stage: extract
status: ok
---

# round-price

### BR-ROUND-001 rounds to cents
- Statement: returns the input.
- Evidence: \`src/pricing.py:2 @$S7\`

## Legacy decisions contrary to best practice
$1

## Gaps
- none
EOF
}

# write_adr <file> <id> <candidate> <legacy evidence line> <practice line> [section to omit]
write_adr() {
  name=$1; id=$2; cand=$3; ev=$4; pr=$5; omit=${6:-}
  {
    printf -- '---\nid: %s\nstatus: accepted\nunit: round-price\ncandidate: %s\nsource_sha: %s\n---\n\n# %s decision\n\n' "$id" "$cand" "$SHA" "$id"
    for h in "Decision" "Legacy evidence" "Reason to keep the legacy behavior" "Best practice contradicted" "Justification" "Consequences"; do
      [ "$h" = "$omit" ] && continue
      printf '## %s\n' "$h"
      case "$h" in
        "Legacy evidence") printf '%s\n' "$ev" ;;
        "Best practice contradicted") printf '%s\n' "$pr" ;;
        *) printf 'Text.\n' ;;
      esac
      printf '\n'
    done
  } > "$P/docs/migration/adr/$name"
}

DEC1="- DEC-001: keeps float money; contrary to: Decimal for money; source: $URL; \`$CITE\`"
EV="- \`$CITE\` returns the input unchanged."
PR="- Decimal for money ($URL)."

# 1. no decision: the section says none found
new_project; write_extraction "- none found: searched src/pricing.py for overrides and money handling"
out=$(cd "$P" && sh "$CHK" adr round-price 2>&1)
expect "1 none found, no ADR" "round-price adr OK n=0" "$out"

# 2. one decision with a valid ADR
new_project; write_extraction "$DEC1"
write_adr ADR-001-float-money.md ADR-001 DEC-001 "$EV" "$PR"
out=$(cd "$P" && sh "$CHK" adr round-price 2>&1)
expect "2 DEC with a valid ADR" "round-price adr OK n=1" "$out"

# 3. decision without an ADR
new_project; write_extraction "$DEC1"
out=$(cd "$P" && sh "$CHK" adr round-price 2>&1)
expect "3 DEC without ADR" "missing-adr-DEC-001" "$out"
expect "3 result is INVALID" "round-price adr INVALID" "$out"

# 4. ADR citation with a wrong sha
new_project; write_extraction "$DEC1"
write_adr ADR-001-float-money.md ADR-001 DEC-001 "- \`src/pricing.py:2 @abcdef1\` returns the input." "$PR"
out=$(cd "$P" && sh "$CHK" adr round-price 2>&1)
expect "4 bad sha in ADR evidence" "cite=src/pricing.py:2:sha-mismatch" "$out"

# 5. ADR without the Justification section
new_project; write_extraction "$DEC1"
write_adr ADR-001-float-money.md ADR-001 DEC-001 "$EV" "$PR" "Justification"
out=$(cd "$P" && sh "$CHK" adr round-price 2>&1)
expect "5 missing Justification section" "sec-Justification" "$out"

# 6. file name and id disagree
new_project; write_extraction "$DEC1"
write_adr ADR-002-float-money.md ADR-001 DEC-001 "$EV" "$PR"
out=$(cd "$P" && sh "$CHK" adr round-price 2>&1)
expect "6 id does not match file name" "id-mismatch" "$out"

# 7. two files with the same id
new_project; write_extraction "$DEC1"
write_adr ADR-001-a.md ADR-001 DEC-001 "$EV" "$PR"
write_adr ADR-001-b.md ADR-001 DEC-001 "$EV" "$PR"
out=$(cd "$P" && sh "$CHK" adr round-price 2>&1)
expect "7 duplicate ADR id" "dup-ADR-001" "$out"

# 8. an ADR whose candidate the extraction does not list
new_project; write_extraction "$DEC1"
write_adr ADR-001-float-money.md ADR-001 DEC-001 "$EV" "$PR"
write_adr ADR-003-orphan.md ADR-003 DEC-009 "$EV" "$PR"
out=$(cd "$P" && sh "$CHK" adr round-price 2>&1)
expect "8 orphan ADR" "orphan-ADR-003" "$out"

# 9. ADR evidence without a citation
new_project; write_extraction "$DEC1"
write_adr ADR-001-float-money.md ADR-001 DEC-001 "- the line returns the input." "$PR"
out=$(cd "$P" && sh "$CHK" adr round-price 2>&1)
expect "9 evidence without citation" "no-legacy-cite" "$out"

# 10. practice without a source
new_project; write_extraction "$DEC1"
write_adr ADR-001-float-money.md ADR-001 DEC-001 "$EV" "- Decimal for money."
out=$(cd "$P" && sh "$CHK" adr round-price 2>&1)
expect "10 practice without source" "no-practice-source" "$out"

# 11. ADR without a candidate key
new_project; write_extraction "$DEC1"
write_adr ADR-001-float-money.md ADR-001 "" "$EV" "$PR"
out=$(cd "$P" && sh "$CHK" adr round-price 2>&1)
expect "11 candidate key empty" "key-candidate" "$out"

# 12. extraction DEC line without citation (checked by the extract state)
new_project; write_extraction "- DEC-001: keeps float money; contrary to: Decimal for money; source: $URL"
out=$(cd "$P" && sh "$CHK" status round-price 2>&1)
expect "12 DEC line without citation" "no-evidence-DEC-001" "$out"

# 13. extraction without the DEC section (checked by the extract state)
new_project
cat > "$P/docs/migration/round-price/extraction.md" <<EOF
---
unit: round-price
stage: extract
status: ok
---

# round-price

### BR-ROUND-001 rounds to cents
- Evidence: \`src/pricing.py:2 @$S7\`
EOF
out=$(cd "$P" && sh "$CHK" status round-price 2>&1)
expect "13 extraction without DEC section" "round-price extract INVALID" "$out"
expect "13 reason is dec-section-absent" "dec-section-absent" "$out"

# 14. plan state follows the ADR check
new_project; write_extraction "$DEC1"
cat > "$P/docs/migration/round-price/spec.md" <<EOF
---
unit: round-price
stage: spec
status: ok
upstream_extraction: $(cd "$P" && sh "$CHK" hash docs/migration/round-price/extraction.md)
---

# round-price specification

### FR-001 returns the cents
- Source: BR-ROUND-001
- Acceptance: the input comes back with two decimal places.
EOF
SPEC_HASH=$(cd "$P" && sh "$CHK" hash docs/migration/round-price/spec.md)
cat > "$P/docs/migration/round-price/plan.md" <<EOF
---
unit: round-price
stage: plan
status: ok
upstream_spec: $SPEC_HASH
---

# round-price plan

## Trace
- FR-001 -> construct rows
EOF
out=$(cd "$P" && sh "$CHK" status round-price 2>&1)
expect "14a plan INVALID without ADR" "round-price plan INVALID" "$out"
expect "14a plan reason names the DEC" "missing-adr-DEC-001" "$out"
write_adr ADR-001-float-money.md ADR-001 DEC-001 "$EV" "$PR"
out=$(cd "$P" && sh "$CHK" status round-price 2>&1)
expect "14b plan OK with a valid ADR" "round-price plan OK" "$out"

# 15. doc sources table: ADR rows with hashes
new_project; write_extraction "$DEC1"
write_adr ADR-001-float-money.md ADR-001 DEC-001 "$EV" "$PR"
cat > "$P/docs/migration/round-price/spec.md" <<EOF
---
unit: round-price
stage: spec
status: ok
upstream_extraction: $(cd "$P" && sh "$CHK" hash docs/migration/round-price/extraction.md)
---

# round-price specification

### FR-001 returns the cents
- Source: BR-ROUND-001
- Acceptance: the input comes back with two decimal places.
EOF
SPEC_HASH=$(cd "$P" && sh "$CHK" hash docs/migration/round-price/spec.md)
cat > "$P/docs/migration/round-price/plan.md" <<EOF
---
unit: round-price
stage: plan
status: ok
upstream_spec: $SPEC_HASH
---

# round-price plan

## Trace
- FR-001 -> construct rows
EOF
SCOPE=$(cd "$P" && sh "$CHK" scope round-price)
H_EX=$(cd "$P" && sh "$CHK" hash docs/migration/round-price/extraction.md)
H_SP=$(cd "$P" && sh "$CHK" hash docs/migration/round-price/spec.md)
H_PL=$(cd "$P" && sh "$CHK" hash docs/migration/round-price/plan.md)
H_AD=$(cd "$P" && sh "$CHK" hash docs/migration/adr/ADR-001-float-money.md)
doc_rows() { printf '| extraction | %s |\n| spec | %s |\n| plan | %s |\n| ADR-001 | %s |\n' "$H_EX" "$H_SP" "$H_PL" "$1"; }
mkdoc() { # <status> <adr row hash>
  cat > "$P/docs/round-price.md" <<EOF
---
unit: round-price
stage: doc
status: $1
scope_hash: $SCOPE
---

# round-price

## Sources
| Source | cksum |
|---|---|
$(doc_rows "$2")
EOF
}
mkdoc ok "$H_AD"
out=$(cd "$P" && sh "$CHK" status round-price 2>&1)
expect "15a doc OK with current ADR hash" "round-price doc OK" "$out"
mkdoc ok "0000000"
out=$(cd "$P" && sh "$CHK" status round-price 2>&1)
expect "15b doc STALE when ADR hash differs" "round-price doc STALE" "$out"
expect "15b names the ADR source" "source:ADR-001" "$out"
mkdoc ok "$H_AD"
grep -v '| ADR-001 |' "$P/docs/round-price.md" > "$P/docs/round-price.tmp" && mv "$P/docs/round-price.tmp" "$P/docs/round-price.md"
out=$(cd "$P" && sh "$CHK" status round-price 2>&1)
expect "15c doc INVALID without ADR row" "row:ADR-001-absent" "$out"

# 16. the whole check runs without a problem on a clean unit
new_project; write_extraction "- none found: searched src/pricing.py"
out=$(cd "$P" && sh "$CHK" adr 2>&1)
expect "16 global form with no ADR" "adr adr OK n=0" "$out"

# 17. the same DEC id listed twice (checked by the extract state)
new_project; write_extraction "$DEC1
$DEC1"
out=$(cd "$P" && sh "$CHK" status round-price 2>&1)
expect "17 duplicate DEC id in extraction" "dup-DEC-001" "$out"

echo "----"
echo "pass=$PASS fail=$FAIL"
[ "$FAIL" -eq 0 ]

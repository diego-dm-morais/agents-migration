#!/bin/sh
# Assertions for the contract hash, show, quoted snippets, the rule quote gate, and preflight.
# Usage: sh test-contract.sh <scratch dir> <check.sh path>
SCR=$1; CHK=$2; F="$SCR/contractfx"; P="$F/proj"; SNAP="$F/snap"
rm -rf "$F"; mkdir -p "$P/docs/migration/demo" "$SNAP/src"
PASS=0; FAIL=0

expect() { # <label> <expected substring> <actual output>
  if printf '%s' "$3" | grep -qF -- "$2"; then PASS=$((PASS + 1)); echo "ok    $1"
  else FAIL=$((FAIL + 1)); echo "FAIL  $1: expected [$2]"; printf '%s\n' "$3" | sed 's/^/      | /'; fi
}
absent() { # <label> <unexpected substring> <actual output>
  if printf '%s' "$3" | grep -qF -- "$2"; then FAIL=$((FAIL + 1)); echo "FAIL  $1: unexpected [$2]"; printf '%s\n' "$3" | sed 's/^/      | /'
  else PASS=$((PASS + 1)); echo "ok    $1"; fi
}
same() { # <label> <value a> <value b>
  if [ "$2" = "$3" ]; then PASS=$((PASS + 1)); echo "ok    $1"
  else FAIL=$((FAIL + 1)); echo "FAIL  $1: [$2] != [$3]"; fi
}

# source snapshot: three lines, a go.mod and a Dockerfile (no git needed for these checks)
printf 'import os\ndef run(x):\n    return x + 1\n' > "$SNAP/src/app.py"
printf 'module demo\n\ngo 1.21\n' > "$SNAP/go.mod"
printf 'FROM example/source-runtime:1.0\n' > "$SNAP/Dockerfile"

ZERO=0000000000000000000000000000000000000000
mig() { # <extra lines>: MIGRATION.md with the keys the checks read
  {
    echo '---'
    echo "source_sha: $ZERO"
    echo 'source_snapshot: ../snap'
    echo 'source_root: .'
    echo 'target_language: nodejs'
    echo 'target_version: 22'
    echo 'doc_root: docs'
    echo '---'
    echo '# Migration'
    printf '%s\n' "$1"
  } > "$P/docs/migration/MIGRATION.md"
}
EX="$P/docs/migration/demo/extraction.md"
SP="$P/docs/migration/demo/spec.md"
extraction() { # <evidence tail> <gaps line> <checklist mark>
  cat > "$EX" <<EOF
---
unit: demo
stage: extract
status: ok
source_sha: $ZERO
---
# demo

## Entry points
- \`src/app.py:2 @0000000\` run

### BR-DEMO-001 Adds one
- Class: none
- Statement: run returns x plus one.
- Evidence: \`src/app.py:3 @0000000\` $1

## Legacy decisions contrary to best practice
- none found: searched src/app.py

## Gaps
- deferred-capture GAP-1: $2

## Closure checklist
- [$3] every entry point traced
EOF
}
spec() { # <upstream stamp>
  cat > "$SP" <<EOF
---
unit: demo
stage: spec
status: ok
upstream_extraction: $1
---
# demo

### FR-001 Adds one
- Source: BR-DEMO-001
EOF
}
st() { (cd "$P" && sh "$CHK" status demo 2>&1); }

mig ""
extraction '"return x + 1"' "stack of the 404 body" " "
ORIG_FULL=$(cd "$P" && sh "$CHK" hash-full "docs/migration/demo/extraction.md")
ORIG_CHASH=$(cd "$P" && sh "$CHK" hash "docs/migration/demo/extraction.md")

# 1. contract hash: Gaps and checklist are outside it, a rule is inside it
extraction '"return x + 1"' "a different note on the 404 body" "x"
CH_NOTE=$(cd "$P" && sh "$CHK" hash "docs/migration/demo/extraction.md")
same "1 contract hash ignores Gaps and checklist" "$ORIG_CHASH" "$CH_NOTE"
FULL_NOTE=$(cd "$P" && sh "$CHK" hash-full "docs/migration/demo/extraction.md")
if [ "$FULL_NOTE" != "$ORIG_FULL" ]; then PASS=$((PASS + 1)); echo "ok    1 full-body hash still sees the Gaps change"
else FAIL=$((FAIL + 1)); echo "FAIL  1 full-body hash did not change"; fi

extraction '"return x + 1"' "stack of the 404 body" " "
sed -i 's/Statement: run returns x plus one./Statement: run returns x plus two./' "$EX"
CH_RULE=$(cd "$P" && sh "$CHK" hash "docs/migration/demo/extraction.md")
if [ "$CH_RULE" != "$ORIG_CHASH" ]; then PASS=$((PASS + 1)); echo "ok    1 contract hash changes when a rule statement changes"
else FAIL=$((FAIL + 1)); echo "FAIL  1 contract hash unchanged after a rule change"; fi
sed -i 's/Statement: run returns x plus two./Statement: run returns x plus one./' "$EX"

# 2. spec stamped with the contract hash: OK, then OK after a notes-only change, STALE after a rule change
extraction '"return x + 1"' "stack of the 404 body" " "
ST=$(cd "$P" && sh "$CHK" hash "docs/migration/demo/extraction.md")
spec "$ST"
expect "2 spec OK when stamped with the contract hash" "spec OK" "$(st)"
extraction '"return x + 1"' "a note added later" "x"
expect "2 spec stays OK after a notes-only change" "spec OK" "$(st)"
sed -i 's/Statement: run returns x plus one./Statement: run returns x plus two./' "$EX"
expect "2 spec STALE after a rule change" "spec STALE upstream_extraction" "$(st)"
sed -i 's/Statement: run returns x plus two./Statement: run returns x plus one./' "$EX"

# 3. legacy stamp (full-body hash) is accepted while the body is unchanged
extraction '"return x + 1"' "stack of the 404 body" " "
FULL=$(cd "$P" && sh "$CHK" hash-full "docs/migration/demo/extraction.md")
spec "$FULL"
expect "3 spec OK with a legacy full-body stamp" "spec OK" "$(st)"

# 4. show prints only the named blocks
extraction '"return x + 1"' "stack of the 404 body" " "
OUT=$(cd "$P" && sh "$CHK" show demo extraction BR-DEMO-001)
expect "4 show prints the named rule" "### BR-DEMO-001" "$OUT"
expect "4 show prints the rule statement" "Statement: run returns x plus one." "$OUT"
absent "4 show leaves out the other sections" "## Gaps" "$OUT"
OUT=$(cd "$P" && sh "$CHK" show demo extraction BR-NOPE-009)
expect "4 show reports an id that is not there" "show MISSING-ID BR-NOPE-009" "$OUT"
OUT=$(cd "$P" && sh "$CHK" show demo extraction BR-DEMO-001 2>&1 | head -n 1)
expect "4 show first line is the rule heading" "### BR-DEMO-001" "$OUT"

# 5. quoted snippets: the snippet must be inside the cited range
OUT=$(cd "$P" && sh "$CHK" cites "docs/migration/demo/extraction.md")
expect "5 cites OK with a correct quote" "cites OK 2 docs/migration/demo/extraction.md quotes=1" "$OUT"
extraction '"return x - 1"' "stack of the 404 body" " "
OUT=$(cd "$P" && sh "$CHK" cites "docs/migration/demo/extraction.md")
expect "5 cites INVALID with a quote that is not in the range" "quote=src/app.py:3:not-in-range" "$OUT"
expect "5 cites INVALID is reported" "cites INVALID" "$OUT"
extraction '(see "import os" in the header)' "stack of the 404 body" " "
OUT=$(cd "$P" && sh "$CHK" cites "docs/migration/demo/extraction.md")
expect "5 prose quotes after a citation are not snippets" "quotes=0" "$OUT"
absent "5 prose quotes are not checked against the range" "quote=" "$OUT"

# 6. a rule without a quote is INVALID for the extraction
extraction "" "stack of the 404 body" " "
expect "6 rule without a quote fails the extraction" "no-quote-BR-DEMO-001" "$(st)"
extraction '"return x + 1"' "stack of the 404 body" " "
absent "6 rule with a quote passes the quote gate" "no-quote" "$(st)"

# 7. preflight: source runtime from go.mod, image from the Dockerfile, target runtime line
mig ""
OUT=$(cd "$P" && sh "$CHK" preflight 2>&1)
expect "7 source runtime read from go.mod" "preflight source-runtime OK go 1.21 go.mod" "$OUT"
expect "7 image read from the Dockerfile" "preflight image:example/source-runtime:1.0 " "$OUT"
expect "7 docker item present" "preflight docker " "$OUT"
expect "7 target runtime item present" "preflight target-runtime " "$OUT"

# 8. a waiver turns a missing item into WAIVED, and only that item
mig "## Environment
- waived: image:example/source-runtime:1.0 by user 2026-10-30"
OUT=$(cd "$P" && sh "$CHK" preflight 2>&1)
absent "8 waived image is not MISSING" "preflight image:example/source-runtime:1.0 MISSING" "$OUT"
case "$OUT" in
  *"preflight image:example/source-runtime:1.0 WAIVED"*|*"preflight image:example/source-runtime:1.0 OK"*)
    PASS=$((PASS + 1)); echo "ok    8 waived image is WAIVED or OK" ;;
  *) FAIL=$((FAIL + 1)); echo "FAIL  8 waived image is neither WAIVED nor OK"; printf '%s\n' "$OUT" | sed 's/^/      | /' ;;
esac

# 9. contract hook (SubagentStop): valid message passes; a broken one is blocked with the reason
GOOD='{"agent_type": "spec-writer", "last_assistant_message": "Result: OK\nWritten: docs/x/spec.md\nChecks: check.sh status -> exit 0\nSkills: none\nNEEDS: none", "stop_hook_active": false}'
NOKEY='{"agent_type": "spec-writer", "last_assistant_message": "Result: OK\nChecks: check.sh status -> exit 0\nSkills: none", "stop_hook_active": false}'
LONG='{"agent_type": "spec-writer", "last_assistant_message": "1\n2\n3\n4\n5\n6\n7\n8\n9\n10\n11\n12\n13\nResult: OK\nChecks: x\nSkills: none\nNEEDS: none", "stop_hook_active": false}'
OTHER='{"agent_type": "Explore", "last_assistant_message": "no keys at all", "stop_hook_active": false}'
LOOP='{"agent_type": "spec-writer", "last_assistant_message": "no keys", "stop_hook_active": true}'
expect_empty() { # <label> <actual output>
  if [ -z "$2" ]; then PASS=$((PASS + 1)); echo "ok    $1"
  else FAIL=$((FAIL + 1)); echo "FAIL  $1: expected no output"; printf '%s\n' "$2" | sed 's/^/      | /'; fi
}
expect_empty "9 valid final message passes" "$(printf '%s' "$GOOD" | sh "$CHK" contract 2>&1)"
OUT=$(printf '%s' "$NOKEY" | sh "$CHK" contract 2>&1)
expect "9 missing NEEDS blocks with the reason" '"decision": "block"' "$OUT"
expect "9 the block names the missing key" "missing-NEEDS:" "$OUT"
OUT=$(printf '%s' "$LONG" | sh "$CHK" contract 2>&1)
expect "9 more than 12 lines blocks" "more-than-12-lines" "$OUT"
expect_empty "9 other agent types are not checked" "$(printf '%s' "$OTHER" | sh "$CHK" contract 2>&1)"
expect_empty "9 a stop after a block is allowed" "$(printf '%s' "$LOOP" | sh "$CHK" contract 2>&1)"

# 10. probes: a rule declared numeric needs a Probe line with its output; a rule with Class none does not
cat > "$EX" <<EOF
---
unit: demo
stage: extract
status: ok
source_sha: $ZERO
---
# demo

## Entry points
- \`src/app.py:2 @0000000\` run

### BR-DEMO-001 Adds one
- Class: none
- Class: numeric
- Statement: run returns x plus one.
- Evidence: \`src/app.py:3 @0000000\` "return x + 1"

## Legacy decisions contrary to best practice
- none found: searched src/app.py

## Gaps
- none
EOF
OUT=$(cd "$P" && sh "$CHK" probes demo 2>&1)
expect "10 numeric rule without a Probe line is INVALID" "demo probes INVALID no-probe-BR-DEMO-001" "$OUT"
expect "10 status extract flags the missing Probe" "no-probe-BR-DEMO-001" "$(st)"
sed -i 's/^- Class: numeric$/- Class: numeric\n- Probe: x=1; print(x+1) on CPython 3.12 -> 2/' "$EX"
OUT=$(cd "$P" && sh "$CHK" probes demo 2>&1)
expect "10 numeric rule with a Probe line and its output is OK" "demo probes OK" "$OUT"
expect "10 status extract OK with the Probe" "demo extract OK" "$(st)"
sed -i 's/^- Class: numeric$/- Class: none/' "$EX"
OUT=$(cd "$P" && sh "$CHK" probes demo 2>&1)
expect "10 rule with Class none needs no Probe" "demo probes OK" "$OUT"
sed -i '/^- Class:/d' "$EX"
OUT=$(cd "$P" && sh "$CHK" probes demo 2>&1)
expect "10 rule without any Class line is INVALID" "demo probes INVALID no-class-BR-DEMO-001" "$OUT"

echo "----"
echo "pass=$PASS fail=$FAIL"
[ "$FAIL" -eq 0 ]

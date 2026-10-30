#!/bin/sh
# Runs the format gate, the vocabulary linter, the consistency and rules checks, and the check.sh suites. Usage: sh .claude/tests/run-tests.sh
# test-adr.sh and test-deadline.sh assert their own results and set the exit status.
# test-check.sh and test-rules.sh print the state of each scenario; read them against the
# expected states named in their headers. Their output goes to the scratch folder printed below.
HERE=$(cd "$(dirname "$0")" && pwd)
CLAUDE_DIR="$HERE/.."
CHK="$CLAUDE_DIR/skills/migrate/scripts/check.sh"
TMP=$(mktemp -d)
rc=0
python -I "$HERE/gate_format.py" "$CLAUDE_DIR" || rc=1
python -I "$HERE/lint_vocab.py" "$CLAUDE_DIR" || rc=1
python -I "$HERE/check_consistency.py" "$CLAUDE_DIR" || rc=1
python -I "$HERE/check_rules.py" "$CLAUDE_DIR" || rc=1
sh "$HERE/test-adr.sh" "$TMP" "$CHK" || rc=1
sh "$HERE/test-deadline.sh" "$TMP" "$CHK" || rc=1
sh "$HERE/test-symbols.sh" "$TMP" "$CHK" || rc=1
sh "$HERE/test-contract.sh" "$TMP" "$CHK" || rc=1
sh "$HERE/test-check.sh" "$TMP" "$CHK" > "$TMP/check-states.txt" 2>&1
sh "$HERE/test-rules.sh" "$TMP" "$CHK" > "$TMP/rules-states.txt" 2>&1
echo "run-tests exit=$rc outputs=$TMP"
exit $rc

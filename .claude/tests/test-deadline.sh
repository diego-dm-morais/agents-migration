#!/bin/sh
# Scenario tests for the project deadline: check.sh deadline and the deadline line of status.
# Usage: sh test-deadline.sh <scratch dir> <check.sh path>
# CHECK_TODAY fixes "today" so that the day counts are exact.
SCR=$1; CHK=$2; F="$SCR/deadfx"; P="$F/proj"
rm -rf "$F"; mkdir -p "$P/docs/migration"
PASS=0; FAIL=0

expect() { # <label> <expected substring> <actual output>
  if printf '%s' "$3" | grep -qF -- "$2"; then PASS=$((PASS + 1)); echo "ok    $1"
  else FAIL=$((FAIL + 1)); echo "FAIL  $1: expected [$2]"; printf '%s\n' "$3" | sed 's/^/      | /'; fi
}
absent() { # <label> <unexpected substring> <actual output>
  if printf '%s' "$3" | grep -qF -- "$2"; then FAIL=$((FAIL + 1)); echo "FAIL  $1: unexpected [$2]"; printf '%s\n' "$3" | sed 's/^/      | /'
  else PASS=$((PASS + 1)); echo "ok    $1"; fi
}

# mig <deadline line, or empty for no key>: MIGRATION.md with only the keys the deadline reads
mig() {
  {
    echo '---'
    echo 'source_sha: 0000000000000000000000000000000000000000'
    echo 'source_snapshot: ../snap'
    [ -n "$1" ] && printf '%s\n' "$1"
    echo '---'
    echo '# Migration'
  } > "$P/docs/migration/MIGRATION.md"
}
# dl <today> : the deadline line of check.sh deadline in the project
dl() { (cd "$P" && CHECK_TODAY="$1" sh "$CHK" deadline 2>&1); }

mig ""
expect "1 no deadline key is none" "deadline none days=-" "$(dl 2026-10-29)"
mig "deadline: none"
expect "2 deadline none is none" "deadline none days=-" "$(dl 2026-10-29)"
mig "deadline:"
expect "3 empty deadline is none" "deadline none days=-" "$(dl 2026-10-29)"

mig "deadline: 2026-12-31"
out=$(dl 2026-10-29)
expect "4 future date gives the days left" "deadline 2026-12-31 days=63" "$out"
absent "4 future date is not overdue" "OVERDUE" "$out"

mig "deadline: 2026-10-01"
out=$(dl 2026-10-29)
expect "5 past date is negative and OVERDUE" "deadline 2026-10-01 days=-28 OVERDUE" "$out"

mig "deadline: 2026-10-29"
out=$(dl 2026-10-29)
expect "6 deadline today is day 0" "deadline 2026-10-29 days=0" "$out"
absent "6 deadline today is not overdue" "OVERDUE" "$out"

mig "deadline: 2028-02-29"
expect "7 leap day is a real date" "deadline 2028-02-29 days=1" "$(dl 2028-02-28)"

mig "deadline: 2026-02-30"
expect "8 impossible date is INVALID" "deadline INVALID value=2026-02-30" "$(dl 2026-10-29)"

mig "deadline: 31/12/2026"
expect "9 other format is INVALID" "deadline INVALID value=31/12/2026" "$(dl 2026-10-29)"

mig "deadline: tomorrow"
expect "10 word is INVALID" "deadline INVALID value=tomorrow" "$(dl 2026-10-29)"

mig "deadline: 2026-12-31"
out=$(cd "$P" && CHECK_TODAY=2026-10-29 sh "$CHK" status 2>&1)
expect "11 status prints the deadline line" "deadline 2026-12-31 days=63" "$out"
mig "deadline: 2026-10-01"
out=$(cd "$P" && CHECK_TODAY=2026-10-29 sh "$CHK" status 2>&1)
expect "12 status flags an overdue deadline" "deadline 2026-10-01 days=-28 OVERDUE" "$out"

echo "----"
echo "pass=$PASS fail=$FAIL"
[ "$FAIL" -eq 0 ]

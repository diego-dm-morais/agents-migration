#!/bin/sh
# check.sh: state of the migration artifacts of one project.
# POSIX sh, LF line endings. Run from the target project root.
# The output is the result; the exit status is 0 when the check ran, 2 on misuse.
#
#   sh check.sh status [unit]   one line per stage, then "<unit> ready YES|NO"
#   sh check.sh pin             snapshot HEAD must equal source_sha
#   sh check.sh deadline        project deadline of MIGRATION.md: none, or the days left (OVERDUE when passed)
#   sh check.sh cites <file>    each path:line @sha7 resolves in the snapshot
#   sh check.sh ids [unit]      duplicate ids; BR->spec and FR->tasks coverage
#   sh check.sh adr [unit]      ADR files: keys, sections, citations, unique ids; DEC->ADR coverage of the unit
#   sh check.sh hash <file>     cksum of the body (no frontmatter), LF only
#   sh check.sh scope <unit>    cksum of the files of the done tasks (review and doc stamp it)
#
# Frontmatter is read as flat "key: value" lines between the first two "---".
# Files must be UTF-8 without BOM. A unit is a directory under docs/migration/.

MIG=docs/migration/MIGRATION.md

# fm <file> <key>: value of a frontmatter key
fm() {
  [ -f "$1" ] || return 0
  tr -d '\r' < "$1" | awk -v k="$2" '
    NR == 1 { if ($0 != "---") exit; infm = 1; next }
    infm && $0 == "---" { exit }
    infm && index($0, k ":") == 1 {
      v = substr($0, length(k) + 2)
      sub(/^[ \t]+/, "", v); sub(/[ \t]+$/, "", v)
      print v; exit
    }'
}

# body <file>: the text after the closing "---", LF only
body() {
  tr -d '\r' < "$1" | awk '
    NR == 1 && $0 == "---" { s = 1; next }
    s == 1 && $0 == "---" { s = 2; next }
    s == 1 { next }
    { print }'
}

# bhash <file>: cksum of the body
bhash() {
  [ -f "$1" ] || return 0
  body "$1" | cksum | awk '{ print $1 }'
}

sha7() { printf '%s' "$1" | cut -c1-7; }

line() {
  d=${4:--}; d=${d# }
  printf '%s %s %s %s\n' "$1" "$2" "$3" "$d"
}

valid_unit() {
  case "$1" in
    ''|*[!a-z0-9-]*|-*|*-|*--*) return 1 ;;
  esac
  return 0
}

# units: one unit id per line, from the directories under docs/migration/
units() {
  for d in docs/migration/*/; do
    [ -d "$d" ] || continue
    u=$(basename "$d")
    [ "$u" = adr ] && continue
    if valid_unit "$u"; then echo "$u"; else echo "check: ignored directory $u" >&2; fi
  done
}

# has_id <file> <id>: the id appears as a whole token
has_id() {
  [ -f "$1" ] && grep -Eq "(^|[^A-Za-z0-9-])$2([^A-Za-z0-9-]|\$)" "$1"
}

# ids_of <file> <heading id regex>: ids of "### <id>" headings
ids_of() {
  [ -f "$1" ] || return 0
  tr -d '\r' < "$1" | grep -E "^### $2" | awk '{ sub(/:$/, "", $2); print $2 }'
}

# dup_ids <file>: " dup=<id>" for every repeated id heading
dup_ids() {
  [ -f "$1" ] || return 0
  tr -d '\r' < "$1" | grep -E '^### (BR|FR|TS|PEND|ID|T|RV)-' \
    | awk '{ sub(/:$/, "", $2); print $2 }' | sort | uniq -d \
    | while IFS= read -r i; do printf ' dup=%s' "$i"; done
}

# open_blocking_pend <spec>: ids of PEND blocks with "blocking: yes" and no resolution
open_blocking_pend() {
  [ -f "$1" ] || return 0
  tr -d '\r' < "$1" | awk '
    function emit() { if (id != "" && blk && !res) print id }
    /^### PEND-/ { emit(); id = $2; sub(/:$/, "", id); blk = 0; res = 0; next }
    /^### / { emit(); id = ""; next }
    /^- blocking: yes/ { blk = 1; next }
    /^- resolution:/ { v = $0; sub(/^- resolution:[ \t]*/, "", v); if (v != "") res = 1; next }
    END { emit() }'
}

# tasks_tsv <tasks>: id, status, kind, depends, files, evidence (tab separated)
tasks_tsv() {
  [ -f "$1" ] || return 0
  tr -d '\r' < "$1" | awk '
    function val(s) { sub(/^[a-z_]+:[ \t]*/, "", s); sub(/[ \t]+$/, "", s); return s }
    function flush() { if (id != "") printf "%s\t%s\t%s\t%s\t%s\t%s\n", id, st, kd, dp, fl, ev }
    /^### T-[0-9]+/ { flush(); id = $2; sub(/:$/, "", id); st = kd = dp = fl = ev = ""; next }
    /^status:/ { st = val($0); next }
    /^kind:/ { kd = val($0); next }
    /^depends:/ { dp = val($0); next }
    /^files:/ { fl = val($0); next }
    /^evidence:/ { ev = val($0); next }
    END { flush() }'
}

# task_issues <tasks>: " task=<id>:<problem>" tokens
task_issues() {
  tasks_tsv "$1" | awk -F '\t' '
    NF == 0 { next }
    { n++; id[n] = $1; st[n] = $2; kd[n] = $3; dp[n] = $4; known[$1] = 1 }
    END {
      for (i = 1; i <= n; i++) {
        if (st[i] !~ /^(pending|in_progress|done|blocked)$/) printf " task=%s:bad-status", id[i]
        if (kd[i] !~ /^(setup|capture|test|impl|verify)$/) printf " task=%s:bad-kind", id[i]
        m = split(dp[i], parts, ",")
        for (j = 1; j <= m; j++) {
          d = parts[j]; gsub(/[ \t]/, "", d)
          if (d != "" && d != "none" && !(d in known)) printf " task=%s:unknown-dep-%s", id[i], d
        }
      }
    }'
}

# cites_bad <file>: "cite=<path>:<lines>:<reason>" for each bad citation
cites_bad() {
  [ -f "$1" ] || return 0
  s7=$(sha7 "$(fm "$MIG" source_sha)")
  sroot=$(fm "$MIG" source_root); sroot=${sroot:-.}
  snap=$(fm "$MIG" source_snapshot)
  tr -d '\r' < "$1" | grep -Eo '[A-Za-z0-9_./-]+:[0-9]+(-[0-9]+)? @[0-9a-f]{7}' | sort -u \
  | while IFS= read -r c; do
      p=${c%%:*}; rest=${c#*:}; lp=${rest%% *}; cs=${c##* @}
      if [ "$cs" != "$s7" ]; then printf 'cite=%s:%s:sha-mismatch\n' "$p" "$lp"; continue; fi
      f="$snap/$sroot/$p"
      if [ ! -f "$f" ]; then printf 'cite=%s:%s:missing-file\n' "$p" "$lp"; continue; fi
      start=${lp%%-*}; end=${lp#*-}; [ "$end" = "$lp" ] && end=$start
      total=$(awk 'END { print NR }' "$f")
      if [ "$end" -lt "$start" ] || [ "$start" -lt 1 ] || [ "$end" -gt "$total" ]; then
        printf 'cite=%s:%s:out-of-range\n' "$p" "$lp"
      fi
    done
}

cites_tokens() { cites_bad "$1" | while IFS= read -r t; do printf ' %s' "$t"; done; }

ADR_DIR=docs/migration/adr

# section <file> <heading>: body of "## <heading>", up to the next "## " heading
section() {
  tr -d '\r' < "$1" | awk -v h="## $2" '
    $0 == h { on = 1; next }
    /^## / { on = 0 }
    on { print }'
}

# dec_issues <extraction>: " dec-section-absent" or " no-evidence-<DEC id>" for the legacy decision section
dec_issues() {
  [ -f "$1" ] || return 0
  tr -d '\r' < "$1" | awk '
    /^## Legacy decisions contrary to best practice/ { sec = 1; seen = 1; next }
    /^## / { sec = 0 }
    sec && /^- DEC-[0-9][0-9][0-9]:/ {
      id = $2; sub(/:$/, "", id)
      cnt[id]++
      if (cnt[id] == 2) printf " dup-%s", id
      if ($0 !~ /[A-Za-z0-9_.\/-]+:[0-9]+(-[0-9]+)? @[0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f]/)
        printf " no-evidence-%s", id
    }
    END { if (!seen) printf " dec-section-absent" }'
}

# adr_file_issues <file>: " <problem>" tokens for one ADR file
adr_file_issues() {
  f=$1; b=$(basename "$f" .md); out=""
  case "$b" in
    ADR-[0-9][0-9][0-9]-*) pre=$(printf '%s' "$b" | cut -c1-7) ;;
    *) printf ' name-invalid'; return ;;
  esac
  [ "$(fm "$f" id)" = "$pre" ] || out="$out id-mismatch"
  for k in status unit candidate source_sha; do
    [ -n "$(fm "$f" "$k")" ] || out="$out key-$k"
  done
  case "$(fm "$f" status)" in accepted|superseded) ;; *) out="$out status-invalid" ;; esac
  for h in "Decision" "Legacy evidence" "Reason to keep the legacy behavior" "Best practice contradicted" "Justification" "Consequences"; do
    tr -d '\r' < "$f" | grep -qxF "## $h" || out="$out sec-$(printf '%s' "$h" | tr ' ' '_')"
  done
  section "$f" "Legacy evidence" | grep -Eq '[A-Za-z0-9_./-]+:[0-9]+(-[0-9]+)? @[0-9a-f]{7}' || out="$out no-legacy-cite"
  section "$f" "Best practice contradicted" | grep -Eq 'https?://|@[0-9a-f]{7}' || out="$out no-practice-source"
  bad=$(cites_bad "$f" | tr '\n' ' ')
  [ -n "$bad" ] && out="$out $bad"
  printf '%s' "$out"
}

# dec_coverage <unit>: " missing-adr-<DEC id>" for each DEC without an ADR, " orphan-<ADR>" for each ADR without a DEC
dec_coverage() {
  ex="docs/migration/$1/extraction.md"; out=""
  [ -f "$ex" ] || { printf ' extraction-absent'; return; }
  tr -d '\r' < "$ex" | grep -qxF '## Legacy decisions contrary to best practice' || { printf ' dec-section-absent'; return; }
  decs=$(section "$ex" "Legacy decisions contrary to best practice" | grep -Eo '^- DEC-[0-9]{3}' | sed 's/^- //' | sort -u)
  for d in $decs; do
    found=0
    for af in "$ADR_DIR"/ADR-*.md; do
      [ -f "$af" ] || continue
      if [ "$(fm "$af" unit)" = "$1" ] && [ "$(fm "$af" candidate)" = "$d" ]; then found=1; break; fi
    done
    [ "$found" = 1 ] || out="$out missing-adr-$d"
  done
  for af in "$ADR_DIR"/ADR-*.md; do
    [ -f "$af" ] || continue
    [ "$(fm "$af" unit)" = "$1" ] || continue
    c=$(fm "$af" candidate)
    printf '%s\n' "$decs" | grep -qx "$c" || out="$out orphan-$(basename "$af" .md)"
  done
  printf '%s' "$out"
}

# adr_issues [unit]: problems of the ADR files (the unit's own when a unit is given), duplicate ids, DEC coverage
adr_issues() {
  u=$1; out=""
  for af in "$ADR_DIR"/ADR-*.md; do
    [ -f "$af" ] || continue
    if [ -n "$u" ] && [ "$(fm "$af" unit)" != "$u" ]; then continue; fi
    p=$(adr_file_issues "$af")
    [ -n "$p" ] && out="$out $(basename "$af" .md):$p"
  done
  for d in $(for af in "$ADR_DIR"/ADR-*.md; do [ -f "$af" ] && fm "$af" id; done | sort | uniq -d); do
    out="$out dup-$d"
  done
  [ -n "$u" ] && out="$out$(dec_coverage "$u")"
  printf '%s' "$out"
}

# adr_cmd [unit]: one line, "<unit|adr> adr OK|INVALID n=<count>"
adr_cmd() {
  u=${1:-}
  if [ -n "$u" ]; then valid_unit "$u" || { echo "unit INVALID $u"; return; }; fi
  n=$(ls "$ADR_DIR"/ADR-*.md 2>/dev/null | wc -l | tr -d ' ')
  bad=$(adr_issues "$u")
  label=${u:-adr}
  if [ -z "$bad" ]; then echo "$label adr OK n=$n"; else echo "$label adr INVALID n=$n$bad"; fi
}

# rules_without_evidence <extraction>: " no-evidence-<BR id>" for each rule block without a citation
rules_without_evidence() {
  [ -f "$1" ] || return 0
  tr -d '\r' < "$1" | awk '
    function flush() { if (cur != "" && !ok) printf " no-evidence-%s", cur; cur = ""; ok = 0 }
    /^### BR-/ { flush(); cur = $2; sub(/:$/, "", cur); next }
    /^### / { flush(); next }
    cur != "" && /[A-Za-z0-9_.\/-]+:[0-9]+(-[0-9]+)? @[0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f]/ { ok = 1 }
    END { flush() }'
}

# frs_without_source <spec>: " no-source-<FR id>" for each FR block without "Source: BR-"
frs_without_source() {
  [ -f "$1" ] || return 0
  tr -d '\r' < "$1" | awk '
    function flush() { if (cur != "" && !ok) printf " no-source-%s", cur; cur = ""; ok = 0 }
    /^### FR-/ { flush(); cur = $2; sub(/:$/, "", cur); next }
    /^### / { flush(); next }
    cur != "" && /Source:[ \t]*BR-[A-Z0-9-]+-[0-9][0-9][0-9]/ { ok = 1 }
    END { flush() }'
}

# deadline_line: the project deadline. "none" when MIGRATION.md sets no date; a date gives the
# days left, negative and marked OVERDUE once it has passed. CHECK_TODAY (YYYY-MM-DD) replaces
# today's date; the tests use it.
deadline_line() {
  d=$(fm "$MIG" deadline)
  case "$d" in
    ''|none) echo "deadline none days=-"; return ;;
  esac
  case "$d" in
    [0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]) ;;
    *) echo "deadline INVALID value=$d"; return ;;
  esac
  [ "$(date -u -d "$d" +%Y-%m-%d 2>/dev/null)" = "$d" ] || { echo "deadline INVALID value=$d"; return; }
  today=${CHECK_TODAY:-$(date -u +%Y-%m-%d)}
  days=$(( ( $(date -u -d "$d" +%s) - $(date -u -d "$today" +%s) ) / 86400 ))
  if [ "$days" -lt 0 ]; then echo "deadline $d days=$days OVERDUE"
  else echo "deadline $d days=$days"; fi
}

pin_line() {
  sha=$(fm "$MIG" source_sha); snap=$(fm "$MIG" source_snapshot)
  if [ -z "$snap" ] || [ ! -d "$snap" ]; then echo "pin MISSING snapshot=${snap:-absent}"; return; fi
  if [ -z "$sha" ]; then echo "pin INVALID source_sha-absent"; return; fi
  head=$(git -C "$snap" rev-parse HEAD 2>/dev/null)
  if [ -z "$head" ]; then echo "pin INVALID snapshot-not-a-git-checkout"; return; fi
  if [ "$head" = "$sha" ]; then echo "pin OK $(sha7 "$sha")"
  else echo "pin INVALID head=$(sha7 "$head") source_sha=$(sha7 "$sha")"; fi
}

# scope_hash <unit>: cksum over the files of the done tasks, LF-normalized
scope_hash() {
  troot=$(fm "$MIG" target_root); troot=${troot:-.}
  tasks_tsv "docs/migration/$1/tasks.md" | awk -F '\t' '$2 == "done" { print $5 }' \
    | tr ',' '\n' | sed 's/^[[:space:]]*//; s/[[:space:]]*$//' | grep -v '^$' | sort -u \
    | while IFS= read -r p; do
        if [ -f "$troot/$p" ]; then printf '== %s\n' "$p"; tr -d '\r' < "$troot/$p"
        else printf '== %s MISSING\n' "$p"; fi
      done | cksum | awk '{ print $1 }'
}

req_up() {
  case "$1" in
    spec) echo extraction ;;
    plan) echo spec ;;
    tasks) echo "spec plan" ;;
  esac
}

# check_artifact <unit> <stage> <file>: extraction, spec, plan, tasks
check_artifact() {
  u=$1; s=$2; f=$3; state=""; bad=""; stale=""; info=""
  [ -f "$f" ] || { line "$u" "$s" MISSING; return; }
  st=$(fm "$f" status)
  case "$st" in
    draft) state=DRAFT ;;
    ok) state=OK ;;
    blocked) state=BLOCKED ;;
    *) line "$u" "$s" INVALID "status=${st:-absent}"; return ;;
  esac
  [ "$(fm "$f" unit)" = "$u" ] || bad="$bad unit-key"
  [ "$(fm "$f" stage)" = "$s" ] || bad="$bad stage-key"
  for x in $(req_up "$s"); do
    v=$(fm "$f" "upstream_$x")
    if [ -z "$v" ]; then bad="$bad upstream_$x-absent"
    elif [ ! -f "docs/migration/$u/$x.md" ]; then bad="$bad upstream_$x-file-missing"
    elif [ "$(bhash "docs/migration/$u/$x.md")" != "$v" ]; then stale="$stale upstream_$x"
    fi
  done
  case "$s" in
    extract)
      bad="$bad$(dup_ids "$f")$(cites_tokens "$f")$(rules_without_evidence "$f")$(dec_issues "$f")" ;;
    spec)
      for id in $(ids_of "docs/migration/$u/extraction.md" 'BR-[A-Z0-9-]+-[0-9]{3}'); do
        has_id "$f" "$id" || bad="$bad uncovered-$id"
      done
      bad="$bad$(dup_ids "$f")$(frs_without_source "$f")"
      pend=$(open_blocking_pend "$f" | tr '\n' ' ')
      if [ -n "$pend" ]; then state=BLOCKED; info="open-blocking: $pend"; fi ;;
    plan)
      for id in $(ids_of "docs/migration/$u/spec.md" 'FR-[0-9]{3}'); do
        has_id "$f" "$id" || bad="$bad plan-misses-$id"
      done
      bad="$bad$(dup_ids "$f")$(adr_issues "$u")" ;;
    tasks)
      bad="$bad$(dup_ids "$f")$(task_issues "$f")"
      for id in $(ids_of "docs/migration/$u/spec.md" 'FR-[0-9]{3}'); do
        has_id "$f" "$id" || bad="$bad uncovered-$id"
      done ;;
  esac
  if [ -n "$bad" ]; then line "$u" "$s" INVALID "$bad"; return; fi
  if [ -n "$stale" ]; then line "$u" "$s" STALE "$stale"; return; fi
  line "$u" "$s" "$state" "${info:--}"
}

# build_line <unit>: derived from the task statuses
build_line() {
  f="docs/migration/$1/tasks.md"
  [ -f "$f" ] || { line "$1" build MISSING; return; }
  troot=$(fm "$MIG" target_root); troot=${troot:-.}
  res=$(tasks_tsv "$f" | awk -F '\t' -v root="$troot" '
    NF == 0 { next }
    { n++ }
    $2 == "done" {
      d++
      if ($6 == "") bad = bad " evidence:" $1
      m = split($5, fs, ",")
      for (k = 1; k <= m; k++) {
        p = fs[k]; gsub(/^[ \t]+|[ \t]+$/, "", p)
        if (p != "" && system("test -f \"" root "/" p "\"") != 0) bad = bad " missing:" p
      }
    }
    $2 == "blocked" { b++; blocked = blocked " " $1 }
    $2 == "pending" || $2 == "in_progress" { o++ }
    END {
      if (n == 0) print "DRAFT no-tasks"
      else if (bad != "") print "INVALID" bad
      else if (b > 0) print "BLOCKED" blocked
      else if (o > 0) print "DRAFT done=" d + 0 "/" n
      else print "OK done=" d + 0 "/" n
    }')
  st=${res%% *}; det=${res#* }
  line "$1" build "$st" "$det"
}

# review_line <unit>
review_line() {
  u=$1; f="docs/migration/$u/review.md"
  [ -f "$f" ] || { line "$u" review MISSING; return; }
  st=$(fm "$f" status); rd=$(fm "$f" round); rh=$(fm "$f" scope_hash)
  case "$st" in draft|ok|blocked) ;; *) line "$u" review INVALID "status=${st:-absent}"; return ;; esac
  case "$rd" in ''|*[!0-9]*) line "$u" review INVALID "round=${rd:-absent}"; return ;; esac
  rv=$(tr -d '\r' < "$f" | awk '/^### RV-/ { rv = 1 } rv && /^status:/ { print $2 }')
  open=$(printf '%s\n' "$rv" | grep -c '^open$')
  blk=$(printf '%s\n' "$rv" | grep -c '^blocked$')
  if [ "$st" = ok ] && { [ "$open" -gt 0 ] || [ "$blk" -gt 0 ]; }; then
    line "$u" review INVALID "open=$open blocked=$blk with status ok"; return
  fi
  if [ "$rh" != "$(scope_hash "$u")" ]; then line "$u" review STALE "scope_hash"; return; fi
  case "$st" in ok) rs=OK ;; draft) rs=DRAFT ;; blocked) rs=BLOCKED ;; esac
  line "$u" review "$rs" "round=$rd open=$open"
}

# doc_line <unit>: documentation of the unit, with the fonts table
doc_line() {
  u=$1; dr=$(fm "$MIG" doc_root); dr=${dr:-docs}; f="$dr/$u.md"
  [ -f "$f" ] || { line "$u" doc MISSING; return; }
  st=$(fm "$f" status)
  case "$st" in draft|ok) ;; *) line "$u" doc INVALID "status=${st:-absent}"; return ;; esac
  bad=""; stale=""
  for x in extraction spec plan tasks; do
    sf="docs/migration/$u/$x.md"
    [ -f "$sf" ] || continue
    row=$(tr -d '\r' < "$f" | grep -E "^\|[[:space:]]*$x[[:space:]]*\|" | head -n 1)
    if [ -z "$row" ]; then bad="$bad row:$x-absent"; continue; fi
    rec=$(printf '%s\n' "$row" | awk -F '|' '{ v = $3; gsub(/[[:space:]]/, "", v); print v }')
    [ "$rec" = "$(bhash "$sf")" ] || stale="$stale source:$x"
  done
  for af in "$ADR_DIR"/ADR-*.md; do
    [ -f "$af" ] || continue
    [ "$(fm "$af" unit)" = "$u" ] || continue
    aid=$(fm "$af" id)
    row=$(tr -d '\r' < "$f" | grep -E "^\|[[:space:]]*$aid[[:space:]]*\|" | head -n 1)
    if [ -z "$row" ]; then bad="$bad row:$aid-absent"; continue; fi
    rec=$(printf '%s\n' "$row" | awk -F '|' '{ v = $3; gsub(/[[:space:]]/, "", v); print v }')
    [ "$rec" = "$(bhash "$af")" ] || stale="$stale source:$aid"
  done
  [ "$(fm "$f" scope_hash)" = "$(scope_hash "$u")" ] || stale="$stale scope_hash"
  if [ -n "$bad" ]; then line "$u" doc INVALID "$bad"; return; fi
  if [ -n "$stale" ]; then line "$u" doc STALE "$stale"; return; fi
  case "$st" in ok) rs=OK ;; draft) rs=DRAFT ;; esac
  line "$u" doc "$rs" "-"
}

unit_report() {
  u=$1
  o_ex=$(check_artifact "$u" extract "docs/migration/$u/extraction.md")
  o_sp=$(check_artifact "$u" spec "docs/migration/$u/spec.md")
  o_pl=$(check_artifact "$u" plan "docs/migration/$u/plan.md")
  o_tk=$(check_artifact "$u" tasks "docs/migration/$u/tasks.md")
  printf '%s\n%s\n%s\n%s\n' "$o_ex" "$o_sp" "$o_pl" "$o_tk"
  build_line "$u"
  review_line "$u"
  doc_line "$u"
  ready=YES
  for r in "$o_ex" "$o_sp" "$o_pl" "$o_tk"; do
    printf '%s\n' "$r" | awk '{ exit ($3 == "OK" ? 0 : 1) }' || ready=NO
  done
  echo "$u ready $ready"
}

ids_report() {
  u=$1; bad=""
  for x in extraction spec plan tasks review; do
    f="docs/migration/$u/$x.md"
    [ -f "$f" ] && bad="$bad$(dup_ids "$f")"
  done
  ex="docs/migration/$u/extraction.md"; sp="docs/migration/$u/spec.md"; tk="docs/migration/$u/tasks.md"
  for id in $(ids_of "$ex" 'BR-[A-Z0-9-]+-[0-9]{3}'); do
    has_id "$sp" "$id" || bad="$bad no-spec-$id"
  done
  for id in $(ids_of "$sp" 'FR-[0-9]{3}'); do
    has_id "$tk" "$id" || bad="$bad no-task-$id"
  done
  if [ -n "$bad" ]; then echo "$u ids INVALID$bad"; else echo "$u ids OK -"; fi
}

do_cites() {
  [ -f "$1" ] || { echo "cites MISSING $1"; return; }
  n=$(tr -d '\r' < "$1" | grep -Eo '[A-Za-z0-9_./-]+:[0-9]+(-[0-9]+)? @[0-9a-f]{7}' | sort -u | wc -l | tr -d ' ')
  bad=$(cites_bad "$1" | tr '\n' ' ')
  if [ -z "$bad" ]; then echo "cites OK $n $1"; else echo "cites INVALID $n $1 $bad"; fi
}

usage() {
  echo "usage: sh check.sh status [unit] | pin | deadline | cites <file> | ids [unit] | adr [unit] | hash <file> | scope <unit>" >&2
  exit 2
}

[ $# -ge 1 ] || usage
cmd=$1; shift
case "$cmd" in
  status)
    if [ ! -f "$MIG" ]; then echo "project MISSING $MIG"; exit 0; fi
    pin_line
    deadline_line
    if [ $# -ge 1 ]; then
      valid_unit "$1" || { echo "unit INVALID $1"; exit 0; }
      unit_report "$1"
    else
      us=$(units)
      [ -n "$us" ] || { echo "units NONE"; exit 0; }
      for u in $us; do unit_report "$u"; done
    fi ;;
  pin) pin_line ;;
  deadline) deadline_line ;;
  cites) [ $# -eq 1 ] || usage; do_cites "$1" ;;
  ids)
    if [ $# -ge 1 ]; then
      valid_unit "$1" || { echo "unit INVALID $1"; exit 0; }
      ids_report "$1"
    else
      for u in $(units); do ids_report "$u"; done
    fi ;;
  adr) adr_cmd "$@" ;;
  hash) [ $# -eq 1 ] || usage; if [ -f "$1" ]; then bhash "$1"; else echo "hash MISSING $1"; fi ;;
  scope)
    [ $# -eq 1 ] || usage
    valid_unit "$1" || { echo "unit INVALID $1"; exit 0; }
    scope_hash "$1" ;;
  *) usage ;;
esac
exit 0

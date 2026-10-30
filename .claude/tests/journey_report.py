#!/usr/bin/env python3
"""Journey report of one Claude Code session: subagent dispatches, minutes, tokens, artifact reads and
full-file writes, read from the session transcripts. Read-only; it prints a summary, it does not classify
rework (that needs a reading of each run). Usage: journey_report.py <session .jsonl> [more ...]
The subagents are read from <session>/subagents/*.jsonl with their .meta.json. Token usage is counted once
per assistant message id (the transcript repeats a message while it streams)."""
import glob, json, os, re, sys
from collections import Counter
from datetime import datetime

ARTIFACT = re.compile(r"docs/migration/(?:[\w-]+/)?(extraction|spec|plan|tasks|review)\.md")


def load(path):
    rows = []
    with open(path, encoding="utf-8", errors="replace") as fh:
        for line in fh:
            if line.strip():
                try:
                    rows.append(json.loads(line))
                except json.JSONDecodeError:
                    pass
    return rows


def stamp(text):
    return datetime.fromisoformat(text.replace("Z", "+00:00"))


def usage_of(rows):
    """Token totals with one record per assistant message id (the largest output count wins)."""
    best = {}
    for r in rows:
        if r.get("type") != "assistant":
            continue
        msg = r.get("message") or {}
        mid = msg.get("id") or r.get("uuid")
        u = msg.get("usage") or {}
        cur = best.get(mid)
        if cur is None or u.get("output_tokens", 0) >= cur.get("output_tokens", 0):
            best[mid] = u
    total = Counter()
    for u in best.values():
        for k in ("input_tokens", "output_tokens", "cache_read_input_tokens", "cache_creation_input_tokens"):
            total[k] += u.get(k, 0)
    return len(best), total


def tool_uses(rows):
    for r in rows:
        if r.get("type") == "assistant":
            content = (r.get("message") or {}).get("content")
            if isinstance(content, list):
                for x in content:
                    if isinstance(x, dict) and x.get("type") == "tool_use":
                        yield x


def report(session):
    base = os.path.splitext(session)[0]
    main = load(session)
    print(f"== {os.path.basename(session)}")
    dispatches = Counter()
    for u in tool_uses(main):
        if u.get("name") == "Agent":
            dispatches[(u.get("input") or {}).get("subagent_type", "?")] += 1
    print(f"main dispatches: {sum(dispatches.values())} {dict(dispatches)}")
    n_main, tot_main = usage_of(main)
    print(f"main calls: {n_main} output={tot_main['output_tokens']} cache_read={tot_main['cache_read_input_tokens']}")

    minutes = 0.0
    sub_total = Counter()
    reads = Counter()
    full_writes = []
    per_type = Counter()
    for meta_path in sorted(glob.glob(os.path.join(base, "subagents", "*.meta.json"))):
        with open(meta_path, encoding="utf-8") as fh:
            meta = json.load(fh)
        jsonl = meta_path[: -len(".meta.json")] + ".jsonl"
        if not os.path.exists(jsonl):
            continue
        rows = load(jsonl)
        stamps = [stamp(r["timestamp"]) for r in rows if r.get("timestamp")]
        if stamps:
            minutes += (max(stamps) - min(stamps)).total_seconds() / 60
        n, tot = usage_of(rows)
        sub_total.update(tot)
        agent = meta.get("agentType", "?")
        per_type[agent] += 1
        for u in tool_uses(rows):
            inp = u.get("input") or {}
            path = (inp.get("file_path") or "").replace("\\", "/")
            m = ARTIFACT.search(path)
            if u.get("name") == "Read" and m:
                reads[m.group(1)] += 1
            if u.get("name") == "Write" and m:
                full_writes.append(os.path.basename(path))
    print(f"subagent runs: {sum(per_type.values())} {dict(per_type)}")
    print(f"subagent minutes (first to last stamp, summed): {minutes:.1f}")
    print(f"subagent calls output={sub_total['output_tokens']} cache_read={sub_total['cache_read_input_tokens']}")
    print(f"artifact reads: {dict(reads)}")
    print(f"full-file writes of artifacts: {len(full_writes)} {full_writes}")
    print()


def main(argv):
    if not argv:
        print(__doc__)
        return 2
    for session in argv:
        report(session)
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))

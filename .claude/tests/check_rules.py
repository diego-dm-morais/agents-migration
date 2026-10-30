#!/usr/bin/env python3
"""Rules matrix: each prompt of the toolkit carries the evidence of the conduct rules that apply to its role.
Usage: check_rules.py <claude dir>. Exit 0 when every applicable rule has its evidence, 1 otherwise.
A rule is applied when the file holds one of the listed phrases (case-insensitive). Phrases are the
wording the prompts use, so a missing phrase means the prompt does not state the rule."""
import glob, os, sys

root = sys.argv[1]
AG = ["behavior-extractor", "spec-writer", "migration-planner", "task-decomposer",
      "implementer", "parity-reviewer", "doc-writer"]
# Agents that may end with NEEDS: user (routing.md, "Allowed NEEDS owners by worker").
# parity-reviewer never asks the user directly, so it is outside rules 6 to 9.
ASK = ["behavior-extractor", "spec-writer", "migration-planner", "task-decomposer",
       "implementer", "doc-writer"]
CODE_READERS = ["behavior-extractor", "spec-writer", "implementer", "parity-reviewer", "doc-writer"]
CITERS = ["behavior-extractor", "migration-planner", "task-decomposer", "implementer",
          "parity-reviewer", "doc-writer"]
MATRIX = {
    1: {**{a: ["@sha7", "path:line"] for a in CITERS}, "spec-writer": ["BR-"]},
    2: {"spec-writer": ["Source: BR-"], "behavior-extractor": ["BR-"]},
    3: {a: ["known-issue"] for a in ["behavior-extractor", "task-decomposer", "implementer",
                                     "parity-reviewer", "doc-writer"]},
    4: {a: ["implemented", "source code", "source behavior", "source at"] for a in CODE_READERS},
    5: {"doc-writer": ["hash"], "parity-reviewer": ["scope_hash"]},
    6: {a: ["verified:"] for a in ASK},
    7: {a: ["blocking: no", "default"] for a in ASK},
    8: {a: ["verified:"] for a in ASK},
    9: {a: ["NEEDS: user"] for a in ASK},
    10: {a: ["rule 10", "Legacy fidelity"] for a in AG},
}
LANG = ["golang", "java", "python", "nodejs", "typescript", "javascript", "dotnet", "rust", "flutter"]

gaps = []
print("rule  " + " ".join(f"{a[:9]:>9}" for a in AG))
for rule, per in MATRIX.items():
    cells = []
    for a in AG:
        need = per.get(a)
        if need is None:
            cells.append("-"); continue
        path = os.path.join(root, "agents", a + ".md")
        text = open(path, encoding="utf-8").read().lower() if os.path.exists(path) else ""
        if any(n.lower() in text for n in need):
            cells.append("ok")
        else:
            cells.append("FAIL"); gaps.append(f"rule {rule} {a}: none of {need}")
    print(f"R{rule:<4} " + " ".join(f"{c:>9}" for c in cells))

# Rule 1 for language skills: each one states its sources with at least three URLs.
for s in LANG:
    path = os.path.join(root, "skills", s, "SKILL.md")
    text = open(path, encoding="utf-8").read() if os.path.exists(path) else ""
    urls = text.count("https://")
    if "## Sources" not in text or urls < 3:
        gaps.append(f"rule 1 skill {s}: needs '## Sources' with at least three https URLs (has {urls})")
print(f"language skills: {len(LANG)} checked for rule 1 (Sources with URLs)")

for g in gaps:
    print("GAP", g)
print("rules:", "PASS" if not gaps else f"FAIL ({len(gaps)})")
sys.exit(0 if not gaps else 1)

#!/usr/bin/env python3
"""Rules matrix: each prompt of the toolkit carries the evidence of the conduct rules that apply to its role.
Usage: check_rules.py <claude dir>. Exit 0 when every applicable rule has its evidence, 1 otherwise.
A rule is applied when the file holds one of the listed phrases (case-insensitive). Phrases are the
wording the prompts use, so a missing phrase means the prompt does not state the rule."""
import glob, os, sys

root = sys.argv[1]


def agent_text(name):
    """The prompt of an agent plus the rules it reads first (skills/migrate/references/agent-rules/<name>.md)."""
    parts = [os.path.join(root, "agents", name + ".md"),
             os.path.join(root, "skills", "migrate", "references", "agent-rules", name + ".md")]
    return "".join(open(p, encoding="utf-8").read() for p in parts if os.path.exists(p))


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
    12: {a: ["rule 12", "Productivity"] for a in AG},
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
        text = agent_text(a).lower()
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

# Library research: each language skill names its registry, and the agents that add libraries
# point to the shared procedure in migration-conduct/references/library-research.md.
REGISTRY = ["pkg.go.dev", "pypi.org", "npmjs.com", "central.sonatype.com", "nuget.org", "crates.io", "pub.dev"]
for s in LANG:
    path = os.path.join(root, "skills", s, "SKILL.md")
    text = open(path, encoding="utf-8").read() if os.path.exists(path) else ""
    if "## Library registry" not in text or not any(r in text for r in REGISTRY):
        gaps.append(f"library research skill {s}: needs '## Library registry' with its registry URL")
for a in ["migration-planner"]:
    if "library-research" not in agent_text(a):
        gaps.append(f"library research agent {a}: must point to references/library-research.md")
# The implementer gets the rule from migration-conduct, which it preloads (section 10).
conduct = os.path.join(root, "skills", "migration-conduct", "SKILL.md")
text = open(conduct, encoding="utf-8").read() if os.path.exists(conduct) else ""
if "library-research" not in text:
    gaps.append("library research: migration-conduct section 10 must point to references/library-research.md")

for g in gaps:
    print("GAP", g)
print("rules:", "PASS" if not gaps else f"FAIL ({len(gaps)})")
sys.exit(0 if not gaps else 1)

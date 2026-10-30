#!/usr/bin/env python3
"""Cross-file consistency of the toolkit: agent names and aliases, owner permissions, stage names,
the final-message keys, language skill names, id prefixes, the numbered mandatory rules, and paths cited in the docs.
Usage: check_consistency.py <claude dir>. Exit 0 when every check passes, 1 otherwise."""
import glob, os, re, sys

root = sys.argv[1]
project = os.path.dirname(os.path.abspath(root))
fails = []


def read(*parts):
    p = os.path.join(root, *parts)
    return open(p, encoding="utf-8").read() if os.path.exists(p) else ""


def agent_text(name):
    """The prompt of an agent plus the rules it reads first (skills/migrate/references/agent-rules/<name>.md)."""
    return read("agents", name + ".md") + read("skills", "migrate", "references", "agent-rules", name + ".md")


def check(label, ok, detail=""):
    if not ok:
        fails.append(f"{label}: {detail}".rstrip(": "))
    print(("ok    " if ok else "FAIL  ") + label + ("" if ok else f" - {detail}"))


AGENTS = {  # name: alias, as CLAUDE.md lists them
    "behavior-extractor": "Eduardo", "spec-writer": "Sofia", "migration-planner": "Paula",
    "task-decomposer": "Tiago", "implementer": "Isabela", "parity-reviewer": "Rafael",
    "doc-writer": "Daniela",
}
claude_md = read("CLAUDE.md")
routing = read("skills", "migrate", "references", "routing.md")
conduct = read("skills", "migration-conduct", "SKILL.md")

# 1. agent names: frontmatter name equals the file name, and the routing tables use the same names
for name, alias in AGENTS.items():
    text = read("agents", name + ".md")
    m = re.search(r"^name:\s*(\S+)", text, re.M)
    check(f"agent {name}: frontmatter name", bool(m) and m.group(1) == name,
          f"found {m.group(1) if m else 'none'}")
    check(f"agent {name}: in routing.md", name in routing, "not named in routing.md")

# 2. aliases: CLAUDE.md pairs each agent with its alias, and the agent description says the same
for name, alias in AGENTS.items():
    check(f"alias {name} = {alias}: CLAUDE.md", f"{name} ({alias})" in claude_md, "pair missing in CLAUDE.md")
    check(f"alias {name} = {alias}: description", f"Alias: {alias}" in read("agents", name + ".md"),
          "description has no 'Alias:' line with this name")

# 3. owner permissions: routing.md allows 'user' for a worker exactly when its prompt ends with NEEDS: user
allowed = routing.split("## Allowed `NEEDS` owners by worker")[1].split("##")[0] if "## Allowed" in routing else ""
for name in AGENTS:
    row = next((l for l in allowed.split("\n") if l.startswith(f"| {name} |")), "")
    may_ask = "user" in row
    prompt_asks = "NEEDS: user" in agent_text(name)
    check(f"owner {name}: routing 'user' matches the prompt",
          may_ask == prompt_asks,
          f"routing lists user={may_ask}, prompt has 'NEEDS: user'={prompt_asks}")

# 4. stage names in stages.md, routing.md and check.sh
STAGES = ["extract", "spec", "plan", "tasks", "build", "review", "doc"]
stages_md = read("skills", "migrate", "references", "stages.md")
check_sh = read("skills", "migrate", "scripts", "check.sh")
for s in STAGES:
    word = re.compile(r"\b%s\b" % s)
    check(f"stage {s}: stages.md, routing.md, check.sh",
          bool(word.search(stages_md)) and bool(word.search(routing)) and bool(word.search(check_sh)),
          "missing in one of the three files")

# 5. final-message keys: the migration-conduct contract (section 12) names all six
sec12 = conduct.split("## 12.")[1].split("## 13.")[0] if "## 12." in conduct else ""
for key in ["Result", "Written", "Checks", "Skills", "Open", "NEEDS"]:
    check(f"message key {key}: section 12", f"{key}:" in sec12 or f"`{key}:`" in sec12, "absent from section 12")

# 6. language skills: CLAUDE.md lists nine, each folder has a SKILL.md named after the folder
LANG = ["golang", "java", "python", "nodejs", "typescript", "javascript", "dotnet", "rust", "flutter"]
for s in LANG:
    text = read("skills", s, "SKILL.md")
    m = re.search(r"^name:\s*(\S+)", text, re.M)
    check(f"language skill {s}: folder and name", bool(m) and m.group(1) == s,
          f"name {m.group(1) if m else 'none'}")
    check(f"language skill {s}: in CLAUDE.md", s in claude_md, "not listed in CLAUDE.md")

# 7. id prefixes of conduct section 7 each have an example in templates.md
templates = read("skills", "migrate", "references", "templates.md")
for p in ["BR", "FR", "TS", "NG", "AG", "PEND", "ID", "T", "RV", "DEC", "ADR"]:
    check(f"id prefix {p}: in templates.md", bool(re.search(r"\b%s-" % p, templates)), "no example id")

# 8. paths cited in the docs and in CLAUDE.md exist (relative to .claude/ or to the project root)
for doc in sorted(glob.glob(os.path.join(root, "docs", "*.md"))) + [os.path.join(root, "CLAUDE.md")]:
    text = open(doc, encoding="utf-8").read()
    for p in sorted(set(re.findall(r"`([A-Za-z0-9_.<>*{}~/-]+(?:/[A-Za-z0-9_.<>*{}~-]+)+\.(?:md|sh|py|json))`", text))):
        if any(c in p for c in "*<{~") or p.startswith("docs/migration"):
            continue
        ok = os.path.exists(os.path.join(root, p)) or os.path.exists(os.path.join(project, p))
        check(f"path {p} cited in {os.path.basename(doc)}", ok, "does not exist")

# 9. mandatory rules: CLAUDE.md and the conduct section 0 carry the same numbers and the same titles
def rule_titles(text):
    """Number and first two words of each numbered rule in a rules list."""
    return {int(n): " ".join(w.strip("*.(") for w in (a, b))
            for n, a, b in re.findall(r"(?m)^(\d+)\. \**(\S+) (\S+)", text)}


mandatory = claude_md.split("## Mandatory rules", 1)[-1].split("## Project memory", 1)[0]
section0 = conduct.split("## 0. Mandatory rules", 1)[-1].split("## 1. Goal", 1)[0]
claude_rules, conduct_rules = rule_titles(mandatory), rule_titles(section0)
check("mandatory rules: CLAUDE.md and conduct section 0 agree on numbers and titles",
      sorted(claude_rules) == list(range(1, 14)) and claude_rules == conduct_rules,
      f"CLAUDE.md {claude_rules} / conduct {conduct_rules}")

print("consistency:", "PASS" if not fails else f"FAIL ({len(fails)})")
sys.exit(0 if not fails else 1)

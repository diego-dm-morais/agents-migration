#!/usr/bin/env python3
"""Format gate for the migration toolkit. Usage: gate.py <claude dir>
Exit 0 when every check passes, 1 when any file fails. Prints one line per failure."""
import glob, os, re, sys
import yaml

root = sys.argv[1]
SKILL_KEYS = {"name", "description", "when_to_use", "argument-hint", "arguments",
              "disable-model-invocation", "user-invocable", "allowed-tools",
              "disallowed-tools", "model", "effort", "context", "agent", "background",
              "hooks", "paths", "shell", "metadata", "license", "compatibility"}
AGENT_KEYS = {"name", "description", "tools", "disallowedTools", "model", "permissionMode",
              "maxTurns", "skills", "mcpServers", "hooks", "memory", "background",
              "omitClaudeMd", "effort", "isolation", "color", "initialPrompt",
              "experimental", "autoCompactWindow"}
COLORS = {"red", "blue", "green", "yellow", "purple", "orange", "pink", "cyan"}
EFFORTS = {"low", "medium", "high", "xhigh", "max"}
NAME_RE = re.compile(r"^[a-z0-9]+(-[a-z0-9]+)*$")
fails = 0
# Prompt budget per agent (lines, bytes) and for the seven agents together. A larger prompt needs
# these limits changed, with the reason recorded in docs/convencoes.md (section Tamanhos).
AGENT_MAX_LINES = 100
AGENT_MAX_BYTES = 7 * 1024
TOTAL_AGENT_BYTES = 43 * 1024
total_agent_bytes = 0


def fail(path, msg):
    global fails
    fails += 1
    print(f"FAIL {path}: {msg}")


def frontmatter(path):
    raw = open(path, "rb").read()
    if raw.startswith(b"\xef\xbb\xbf"):
        fail(path, "BOM present")
    if b"\r" in raw:
        fail(path, "CR (CRLF) line endings")
    text = raw.decode("utf-8", "replace").replace("\r\n", "\n")
    m = re.match(r"^---\n(.*?)\n---\n", text, re.S)
    if not m:
        fail(path, "no frontmatter at the first line")
        return None, text
    try:
        data = yaml.safe_load(m.group(1))
    except yaml.YAMLError as e:
        fail(path, "strict YAML error: " + str(e).splitlines()[0])
        return None, text
    if not isinstance(data, dict):
        fail(path, "frontmatter is not a mapping")
        return None, text
    return data, text


skill_names = set()
for sk in glob.glob(os.path.join(root, "skills", "*", "SKILL.md")):
    skill_names.add(os.path.basename(os.path.dirname(sk)))

for sk in sorted(glob.glob(os.path.join(root, "skills", "*", "SKILL.md"))):
    dirname = os.path.basename(os.path.dirname(sk))
    data, text = frontmatter(sk)
    if data is None:
        continue
    name = data.get("name")
    desc = data.get("description")
    if not name:
        fail(sk, "name missing")
    elif name != dirname:
        fail(sk, f"name '{name}' differs from directory '{dirname}'")
    elif not NAME_RE.match(name) or len(name) > 64:
        fail(sk, f"name '{name}' violates the charset or length rule")
    if not desc or not isinstance(desc, str):
        fail(sk, "description missing")
    else:
        if len(desc) > 1024:
            fail(sk, f"description has {len(desc)} chars (max 1024)")
        if "<" in desc or ">" in desc:
            fail(sk, "description has < or > (renders escaped)")
    unknown = set(data) - SKILL_KEYS
    if unknown:
        fail(sk, f"unknown frontmatter keys: {sorted(unknown)}")
    meta = data.get("metadata")
    if isinstance(meta, dict):
        for k, v in meta.items():
            if not isinstance(v, str):
                fail(sk, f"metadata.{k} must be a string, got {type(v).__name__}")
    if dirname != "migrate" and re.search(r"(?m)(^|\s)!`[^`\n]+`", text):
        fail(sk, "shell injection !`...` outside migrate (a failing command aborts the skill)")
    if dirname != "migrate" and re.search(r"\$ARGUMENTS|\$\d", text):
        fail(sk, "$ARGUMENTS or $N placeholder outside migrate")
    if text.count("\n") >= 500:
        fail(sk, "SKILL.md has 500 or more lines")

for ag in sorted(glob.glob(os.path.join(root, "agents", "*.md"))):
    data, text = frontmatter(ag)
    size = os.path.getsize(ag)
    total_agent_bytes += size
    if size > AGENT_MAX_BYTES:
        fail(ag, f"{size} bytes (budget {AGENT_MAX_BYTES})")
    if open(ag, "rb").read().count(b"\n") > AGENT_MAX_LINES:
        fail(ag, f"more than {AGENT_MAX_LINES} lines")
    if data is None:
        continue
    name = data.get("name")
    desc = data.get("description")
    if not name or ":" in name or len(name) > 256:
        fail(ag, "name missing, contains ':' or is longer than 256")
    elif name != os.path.splitext(os.path.basename(ag))[0]:
        fail(ag, f"name '{name}' differs from the file name")
    if not desc:
        fail(ag, "description missing")
    elif len(desc) > 350:
        fail(ag, f"description has {len(desc)} chars (budget 350)")
    unknown = set(data) - AGENT_KEYS
    if unknown:
        fail(ag, f"unknown frontmatter keys: {sorted(unknown)}")
    if "color" in data and data["color"] not in COLORS:
        fail(ag, f"color '{data['color']}' is not allowed")
    if "effort" in data and data["effort"] not in EFFORTS:
        fail(ag, f"effort '{data['effort']}' is not allowed")
    if "model" in data:
        fail(ag, "model is pinned (must be omitted so the session model applies)")
    for ref in data.get("skills", []) or []:
        if ref not in skill_names:
            fail(ag, f"skills: '{ref}' has no skill directory")
    tools = data.get("tools", "")
    if isinstance(tools, str):
        tools = [t.strip() for t in tools.split(",") if t.strip()]
    for t in tools:
        if t.startswith("mcp__") or t in ("AskUserQuestion", "Agent"):
            fail(ag, f"tool '{t}' is forbidden for this toolkit")

# Plain-text files the checks above do not reach: LF endings, no BOM.
TEXT_FILES = (glob.glob(os.path.join(root, "docs", "*.md"))
              + [os.path.join(root, "CLAUDE.md"), os.path.join(root, "skills", "migrate", "scripts", "check.sh")]
              + glob.glob(os.path.join(root, "tests", "*.py")) + glob.glob(os.path.join(root, "tests", "*.sh")))
for f in sorted(TEXT_FILES):
    raw = open(f, "rb").read()
    if raw.startswith(b"\xef\xbb\xbf"):
        fail(f, "BOM present")
    if b"\r" in raw:
        fail(f, "CR (CRLF) line endings")

if total_agent_bytes > TOTAL_AGENT_BYTES:
    fail(os.path.join(root, "agents"), f"{total_agent_bytes} bytes in total (budget {TOTAL_AGENT_BYTES})")

print("gate:", "PASS" if fails == 0 else f"FAIL ({fails})")
sys.exit(0 if fails == 0 else 1)

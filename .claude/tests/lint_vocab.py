#!/usr/bin/env python3
"""Vocabulary linter for the core of the toolkit: agents, the migrate skill, the migration skills,
tdd, doc-writing and CLAUDE.md. Framework, library and build-tool names belong to the language
skills only. Inline code spans and fenced blocks are removed before matching, so a name written as
an example in code is allowed. Generic construct categories (JSON, XML, HTTP, CLI, SQL) are not
forbidden: they name what to search for in a source, in any language.
Usage: lint_vocab.py <claude dir>. Exit 0 when clean, 1 otherwise."""
import glob, os, re, sys

root = sys.argv[1]
FORBIDDEN = [
    r"Spring", r"Jackson", r"Maven", r"Gradle", r"pom\.xml", r"go\.mod", r"go\.sum",
    r"package\.json", r"Cargo\.toml", r"pyproject\.toml", r"pubspec\.yaml", r"\.csproj",
    r"pytest", r"junit", r"go test", r"pinned tag", r"golangci-lint", r"goimports", r"gofmt",
    r"\bruff\b", r"\bmypy\b", r"\btsc\b", r"\bnpm\b", r"\bpnpm\b", r"\byarn\b",
    r"@RequestMapping", r"\bendpoints?\b",
]
PAT = re.compile(r"\b(" + "|".join(FORBIDDEN) + r")", re.IGNORECASE)

files = (glob.glob(os.path.join(root, "agents", "*.md"))
         + glob.glob(os.path.join(root, "skills", "migrate", "**", "*.md"), recursive=True)
         + [os.path.join(root, "skills", s, "SKILL.md")
            for s in ("migration-conduct", "migration-patterns", "tdd", "doc-writing")]
         + glob.glob(os.path.join(root, "skills", "migration-patterns", "references", "*.md"))
         + [os.path.join(root, "CLAUDE.md")])

hits = []
for f in sorted(set(files)):
    if not os.path.exists(f):
        continue
    text = open(f, encoding="utf-8").read()
    text = re.sub(r"```.*?```", "", text, flags=re.S)       # fenced blocks
    lines = text.split("\n")
    for n, line in enumerate(lines, 1):
        stripped = re.sub(r"`[^`]*`", "", line)              # inline code spans
        for m in PAT.finditer(stripped):
            rel = os.path.relpath(f, root)
            hits.append(f"{rel}:{n}: '{m.group(0)}' outside a code span")

for h in hits:
    print("FAIL", h)
print("vocab:", "PASS" if not hits else f"FAIL ({len(hits)})")
sys.exit(0 if not hits else 1)

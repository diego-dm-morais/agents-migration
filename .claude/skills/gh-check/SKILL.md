---
name: gh-check
description: "Checks that the GitHub CLI (gh) is installed and authenticated, and alerts the user when it is not. Use at the start of a session with no migration in progress, and before any step that needs GitHub (clone, PR, issue, gh api)."
allowed-tools: "Bash(sh ${CLAUDE_SKILL_DIR}/scripts/check-gh.sh)"
---

# gh-check

Validates the GitHub connection through `gh`.

1. Run `sh ${CLAUDE_SKILL_DIR}/scripts/check-gh.sh` from the project root.
2. Read the single status line and the exit code:
   - `gh OK account=<login>` (exit 0): connected. Say nothing more than the account, in one short line.
   - `gh MISSING` (exit 1): alert the user that `gh` is not installed. Point to https://cli.github.com and tell them to install it, then type `gh auth login`.
   - `gh NOT_AUTHENTICATED` (exit 2): alert the user that `gh` is not logged in. Tell them to type `! gh auth login` in the prompt (interactive, so they must run it themselves).
3. When not connected, stop any step that needs GitHub and wait for the user. Do not try to log in, create tokens or work around it.
4. Report the real output. If the script did not run, say so; never assume connected.

#!/bin/sh
# Prints one status line for the GitHub CLI connection.
# Exit codes: 0 connected, 1 gh not installed, 2 not authenticated.

if ! command -v gh >/dev/null 2>&1; then
  echo "gh MISSING"
  exit 1
fi

if gh auth status >/dev/null 2>&1; then
  account=$(gh api user --jq .login 2>/dev/null)
  echo "gh OK account=${account:-unknown}"
  exit 0
fi

echo "gh NOT_AUTHENTICATED"
exit 2

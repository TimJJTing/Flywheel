#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BASE="${1:-HEAD}"

changed="$(git -C "$ROOT" diff --name-only "$BASE" -- \
  adapters/claude-code/agents \
  adapters/claude-code/settings.json.merge \
  adapters/antigravity/agents \
  adapters/antigravity/hooks.json.merge)"

if [ -n "$changed" ]; then
  echo "FAIL: Codex repair changed protected Claude/Agy agent or hook assets:" >&2
  echo "$changed" >&2
  exit 1
fi

echo "PASS adapter isolation path scope"

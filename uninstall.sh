#!/usr/bin/env bash
# uninstall.sh — remove the flywheel framework from a project, leaving user content intact.
# Usage: ./uninstall.sh <target-dir> [--yes]
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

TARGET="${1:-}"
if [ -z "$TARGET" ]; then
  echo "Usage: $0 <target-dir> [--yes]" >&2
  exit 1
fi
shift

ASSUME_YES=0
while [ $# -gt 0 ]; do
  case "$1" in
    --yes) ASSUME_YES=1; shift ;;
    *) echo "Unknown argument: $1" >&2; exit 1 ;;
  esac
done

if [ ! -d "$TARGET" ]; then
  echo "error: target dir does not exist: $TARGET" >&2
  exit 1
fi
TARGET="$(cd "$TARGET" && pwd)"

if [ ! -d "$TARGET/flywheel" ]; then
  echo "error: $TARGET/flywheel not found — nothing to uninstall" >&2
  exit 1
fi

RUNNER=""
if command -v python3 >/dev/null 2>&1; then RUNNER=python3
elif command -v node >/dev/null 2>&1; then RUNNER=node
fi

# --- 1. archive state if there's anything worth keeping --------------------
HAS_STATE=0
if [ -d "$TARGET/flywheel/state" ]; then
  for sf in "$TARGET"/flywheel/state/*.json; do
    [ -e "$sf" ] || continue
    if [ "$(tr -d '[:space:]' < "$sf")" != "[]" ]; then
      HAS_STATE=1
      break
    fi
  done
fi
HAS_LESSONS=0
if [ -f "$TARGET/flywheel/LESSONS.md" ] && [ "$(wc -l < "$TARGET/flywheel/LESSONS.md")" -gt 1 ]; then
  HAS_LESSONS=1
fi

if [ "$HAS_STATE" = 1 ] || [ "$HAS_LESSONS" = 1 ]; then
  DO_ARCHIVE=1
  if [ "$ASSUME_YES" != 1 ]; then
    read -r -p "Archive state to $TARGET/flywheel-archive/ before removing? [Y/n] " ans || ans=""
    case "$ans" in
      [nN]*) DO_ARCHIVE=0 ;;
      *) DO_ARCHIVE=1 ;;
    esac
  fi
  if [ "$DO_ARCHIVE" = 1 ]; then
    mkdir -p "$TARGET/flywheel-archive/state"
    [ -d "$TARGET/flywheel/state" ] && cp -Rf "$TARGET/flywheel/state/." "$TARGET/flywheel-archive/state/"
    for f in STATUS.md LESSONS.md FACTS.md config.json; do
      [ -f "$TARGET/flywheel/$f" ] && cp -f "$TARGET/flywheel/$f" "$TARGET/flywheel-archive/$f"
    done
    echo "  archived: $TARGET/flywheel-archive/"
  fi
fi

# --- 2. strip flywheel marker blocks from CLAUDE.md / AGENTS.md ------------
strip_block() { # $1 = file
  local file="$1"
  [ -f "$file" ] || return 0
  if [ -n "$RUNNER" ] && [ "$RUNNER" = python3 ]; then
    python3 - "$file" <<'PYEOF'
import sys, re
path = sys.argv[1]
BEGIN, END = "<!-- flywheel:begin -->", "<!-- flywheel:end -->"
with open(path, encoding="utf-8") as f:
    content = f.read()
if BEGIN in content and END in content:
    pattern = re.compile(re.escape(BEGIN) + r"[\s\S]*?" + re.escape(END))
    content = pattern.sub("", content, count=1)
    # collapse the blank-line seam install.sh leaves behind (it always
    # inserts exactly one blank line before an appended block)
    content = re.sub(r"\n{3,}", "\n\n", content)
    content = content.rstrip("\n")
if content.strip() == "":
    import os
    os.remove(path)
else:
    with open(path, "w", encoding="utf-8") as f:
        f.write(content + "\n")
PYEOF
  elif [ -n "$RUNNER" ]; then
    node - "$file" <<'NODEEOF'
const fs = require('fs');
const path = process.argv[2];
const BEGIN = '<!-- flywheel:begin -->', END = '<!-- flywheel:end -->';
let content = fs.readFileSync(path, 'utf8');
if (content.includes(BEGIN) && content.includes(END)) {
  const esc = s => s.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
  const re = new RegExp(esc(BEGIN) + '[\\s\\S]*?' + esc(END));
  content = content.replace(re, '');
  content = content.replace(/\n{3,}/g, '\n\n').replace(/\n+$/, '');
}
if (content.trim() === '') {
  fs.unlinkSync(path);
} else {
  fs.writeFileSync(path, content + '\n');
}
NODEEOF
  else
    echo "error: python3 or node required to strip markers from $file" >&2
    exit 1
  fi
  echo "  stripped: ${file#"$TARGET"/}"
}
strip_block "$TARGET/CLAUDE.md"
strip_block "$TARGET/AGENTS.md"

# --- 3. remove flywheel-managed agents/skills -------------------------------
if [ -d "$TARGET/.claude/agents" ]; then
  for af in "$TARGET"/.claude/agents/*.md; do
    [ -e "$af" ] || continue
    if grep -q 'flywheel-managed' "$af" 2>/dev/null; then
      rm -f "$af"
      echo "  removed: .claude/agents/$(basename "$af")"
    fi
  done
  rmdir "$TARGET/.claude/agents" 2>/dev/null || true
fi
if [ -d "$TARGET/.claude/skills" ]; then
  for sd in "$TARGET"/.claude/skills/*/; do
    [ -d "$sd" ] || continue
    sf="$sd/SKILL.md"
    if [ -f "$sf" ] && grep -q 'flywheel-managed' "$sf" 2>/dev/null; then
      rm -f "$sf"
      echo "  removed: .claude/skills/$(basename "$sd")/SKILL.md"
      rmdir "$sd" 2>/dev/null || true
    fi
  done
  rmdir "$TARGET/.claude/skills" 2>/dev/null || true
fi

if [ -d "$TARGET/.agents/agents" ]; then
  for ad in "$TARGET"/.agents/agents/*/; do
    [ -d "$ad" ] || continue
    if [ -f "$ad/agent.json" ]; then
      rm -f "$ad/agent.json"
      echo "  removed: .agents/agents/$(basename "$ad")/agent.json"
      rmdir "$ad" 2>/dev/null || true
    fi
  done
  rmdir "$TARGET/.agents/agents" 2>/dev/null || true
fi
if [ -d "$TARGET/.agents/skills" ]; then
  for sd in "$TARGET"/.agents/skills/*/; do
    [ -d "$sd" ] || continue
    sf="$sd/SKILL.md"
    if [ -f "$sf" ] && grep -q 'flywheel-managed' "$sf" 2>/dev/null; then
      rm -f "$sf"
      echo "  removed: .agents/skills/$(basename "$sd")/SKILL.md"
      rmdir "$sd" 2>/dev/null || true
    fi
  done
  rmdir "$TARGET/.agents/skills" 2>/dev/null || true
fi
if [ -f "$TARGET/.agents/hooks.json" ]; then
  rm -f "$TARGET/.agents/hooks.json"
  echo "  removed: .agents/hooks.json"
fi
rmdir "$TARGET/.agents" 2>/dev/null || true

# --- 4. restore opencode.json -----------------------------------------------
if [ -f "$TARGET/opencode.json.flywheel-bak" ]; then
  mv -f "$TARGET/opencode.json.flywheel-bak" "$TARGET/opencode.json"
  echo "  restored: opencode.json (from backup)"
elif [ -f "$TARGET/opencode.json" ]; then
  MERGE_FILE="$SCRIPT_DIR/adapters/opencode/opencode.json.merge"
  REMOVED=0
  if [ -f "$MERGE_FILE" ] && [ -n "$RUNNER" ]; then
    if [ "$RUNNER" = python3 ]; then
      SAME=$(python3 - "$MERGE_FILE" "$TARGET/opencode.json" <<'PYEOF'
import json, sys
merge_path, dest_path = sys.argv[1], sys.argv[2]
with open(merge_path, encoding="utf-8") as f:
    merge_doc = json.load(f)
with open(dest_path, encoding="utf-8") as f:
    dest_doc = json.load(f)
merge_agents = set(merge_doc.get("agent", {}).keys())
dest_agents = set(dest_doc.get("agent", {}).keys())
extra_keys = set(dest_doc.keys()) - {"$schema", "agent"}
print("yes" if (dest_agents == merge_agents and not extra_keys) else "no")
PYEOF
)
    else
      SAME=$(node - "$MERGE_FILE" "$TARGET/opencode.json" <<'NODEEOF'
const fs = require('fs');
const mergeDoc = JSON.parse(fs.readFileSync(process.argv[2], 'utf8'));
const destDoc = JSON.parse(fs.readFileSync(process.argv[3], 'utf8'));
const mergeAgents = new Set(Object.keys(mergeDoc.agent || {}));
const destAgents = new Set(Object.keys(destDoc.agent || {}));
const extraKeys = Object.keys(destDoc).filter(k => k !== '$schema' && k !== 'agent');
const same = mergeAgents.size === destAgents.size &&
  [...mergeAgents].every(k => destAgents.has(k)) && extraKeys.length === 0;
console.log(same ? 'yes' : 'no');
NODEEOF
)
    fi
    if [ "$SAME" = "yes" ]; then
      rm -f "$TARGET/opencode.json"
      echo "  removed: opencode.json (flywheel-created, no backup needed)"
      REMOVED=1
    fi
  fi
  if [ "$REMOVED" = 0 ]; then
    echo "  note: opencode.json present with no backup and does not look flywheel-only — left untouched"
  fi
fi

# --- 5. remove architecture docs if present ---------------------------------
if [ -f "$TARGET/docs/ARCHITECTURE.md" ]; then
  rm -f "$TARGET/docs/ARCHITECTURE.md"
  echo "  removed: docs/ARCHITECTURE.md"
  rmdir "$TARGET/docs" 2>/dev/null || true
fi

# --- 6. remove flywheel/ ----------------------------------------------------
rm -rf "$TARGET/flywheel"
echo ""
echo "flywheel uninstalled from $TARGET."

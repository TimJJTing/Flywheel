#!/usr/bin/env bash
# install.sh — adopt the flywheel framework into any project (greenfield or legacy).
# Usage: ./install.sh <target-dir> [--adapters claude-code,codex,opencode]
#
# Safety property: legacy files are never clobbered. flywheel/ payload files are
# split into MANAGED (always overwritten — flywheel owns these) and
# OWNED-BY-TARGET (created once, never touched again — the project owns these).
# Existing CLAUDE.md/AGENTS.md content outside the <!-- flywheel:begin/end -->
# markers is never modified. Re-running is a no-op (idempotent).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PAYLOAD="$SCRIPT_DIR/flywheel"
ADAPTERS_DIR="$SCRIPT_DIR/adapters"

TARGET="${1:-}"
if [ -z "$TARGET" ] || [ "$TARGET" = "--adapters" ]; then
  echo "Usage: $0 <target-dir> [--adapters claude-code,codex,opencode]" >&2
  exit 1
fi
shift

ADAPTERS_ARG="claude-code"
while [ $# -gt 0 ]; do
  case "$1" in
    --adapters) ADAPTERS_ARG="${2:-}"; shift 2 ;;
    --adapters=*) ADAPTERS_ARG="${1#*=}"; shift ;;
    *) echo "Unknown argument: $1" >&2; exit 1 ;;
  esac
done

# --- preflight -----------------------------------------------------------
if [ ! -d "$TARGET" ]; then
  echo "error: target dir does not exist: $TARGET" >&2
  exit 1
fi
TARGET="$(cd "$TARGET" && pwd)"

if ! git -C "$TARGET" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "warning: $TARGET is not a git repo — no version-control safety net for this install" >&2
fi

RUNNER=""
if command -v python3 >/dev/null 2>&1; then RUNNER=python3
elif command -v node >/dev/null 2>&1; then RUNNER=node
fi
if [ -z "$RUNNER" ]; then
  echo "warning: neither python3 nor node found — dashboard build and marker wiring will fail" >&2
fi

echo "Installing flywheel into $TARGET"

# --- marker-aware block wiring (core safety property) ---------------------
# block doesn't exist -> create target with block content.
# markers present      -> replace only the text between+including markers.
# markers absent       -> append a blank line + the block. Never touch anything else.
wire_block() { # $1 = block file, $2 = target file
  local block_file="$1" target_file="$2"
  if [ -z "$RUNNER" ]; then
    echo "error: python3 or node required to wire $target_file" >&2
    exit 1
  fi
  if [ "$RUNNER" = python3 ]; then
    python3 - "$block_file" "$target_file" <<'PYEOF'
import sys, re, os
block_path, target_path = sys.argv[1], sys.argv[2]
BEGIN, END = "<!-- flywheel:begin -->", "<!-- flywheel:end -->"
with open(block_path, encoding="utf-8") as f:
    block = f.read()
content = None
if os.path.exists(target_path):
    with open(target_path, encoding="utf-8") as f:
        content = f.read()
if content is None:
    out = block
elif BEGIN in content and END in content:
    pattern = re.compile(re.escape(BEGIN) + r"[\s\S]*?" + re.escape(END))
    out = pattern.sub(lambda m: block.strip(), content, count=1)
else:
    out = content.rstrip("\n") + "\n\n" + block.strip() + "\n"
with open(target_path, "w", encoding="utf-8") as f:
    f.write(out)
PYEOF
  else
    node - "$block_file" "$target_file" <<'NODEEOF'
const fs = require('fs');
const [,, blockPath, targetPath] = process.argv;
const BEGIN = '<!-- flywheel:begin -->', END = '<!-- flywheel:end -->';
const block = fs.readFileSync(blockPath, 'utf8');
let content = null;
try { content = fs.readFileSync(targetPath, 'utf8'); } catch (e) { /* absent */ }
const esc = s => s.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
let out;
if (content === null) {
  out = block;
} else if (content.includes(BEGIN) && content.includes(END)) {
  const re = new RegExp(esc(BEGIN) + '[\\s\\S]*?' + esc(END));
  out = content.replace(re, block.trim());
} else {
  out = content.replace(/\n+$/, '') + '\n\n' + block.trim() + '\n';
}
fs.writeFileSync(targetPath, out);
NODEEOF
  fi
}

# --- agent/skill copy rule --------------------------------------------------
# overwrite only if destination absent OR already flywheel-managed; otherwise
# warn and leave the user's unmanaged file alone.
copy_managed_if_ok() { # $1 = src, $2 = dest
  local src="$1" dest="$2"
  mkdir -p "$(dirname "$dest")"
  if [ ! -e "$dest" ] || grep -q 'flywheel-managed' "$dest" 2>/dev/null; then
    cp -f "$src" "$dest"
    echo "  updated: ${dest#"$TARGET"/}"
  else
    echo "warning: ${dest#"$TARGET"/} exists and is not flywheel-managed — skipped" >&2
    echo "  skipped (unmanaged): ${dest#"$TARGET"/}"
  fi
}

# --- 1. flywheel/ payload: MANAGED (always overwrite) ----------------------
mkdir -p "$TARGET/flywheel/state" "$TARGET/flywheel/dashboard"
for f in INDEX.md ORCHESTRATION.md JUDGMENT.md AUTONOMY.md DIAGNOSIS.md \
         TEMPLATES.md MAINTENANCE.md GIT.md IMPROVE.md ADAPTERS.md check.sh \
         wrapup.sh compact.py state/SCHEMAS.md; do
  if [ -f "$PAYLOAD/$f" ]; then
    cp -f "$PAYLOAD/$f" "$TARGET/flywheel/$f"
    echo "  managed: flywheel/$f"
  fi
done
if [ -d "$PAYLOAD/dashboard" ] && [ -n "$(ls -A "$PAYLOAD/dashboard" 2>/dev/null)" ]; then
  cp -Rf "$PAYLOAD/dashboard/." "$TARGET/flywheel/dashboard/"
  echo "  managed: flywheel/dashboard/*"
fi

# --- 1b. OWNED-BY-TARGET (create only if absent) ----------------------------
# Sourced from defaults/ (pristine templates), never from the live payload — the
# flywheel repo dogfoods its own payload, so payload state carries ITS project data.
DEFAULTS="$SCRIPT_DIR/defaults"
for f in config.json FACTS.md STATUS.md LESSONS.md; do
  src="$DEFAULTS/$f"; [ -f "$src" ] || src="$PAYLOAD/$f"
  if [ -f "$src" ]; then
    if [ ! -f "$TARGET/flywheel/$f" ]; then
      cp -f "$src" "$TARGET/flywheel/$f"
      echo "  created: flywheel/$f"
    else
      echo "  kept: flywheel/$f (already present)"
    fi
  fi
done
for b in projects.json issues.json decisions.json activity.json spawns.json; do
  if [ ! -f "$TARGET/flywheel/state/$b" ]; then
    if [ -f "$DEFAULTS/state/$b" ]; then
      cp -f "$DEFAULTS/state/$b" "$TARGET/flywheel/state/$b"
    else
      printf '[]\n' > "$TARGET/flywheel/state/$b"
    fi
    echo "  created: flywheel/state/$b"
  else
    echo "  kept: flywheel/state/$b (already present)"
  fi
done

# --- 2. adapters -------------------------------------------------------------
IFS=',' read -ra ADAPTER_LIST <<< "$ADAPTERS_ARG"
want() { local x; for x in "${ADAPTER_LIST[@]}"; do [ "$x" = "$1" ] && return 0; done; return 1; }
DO_CLAUDE=0; DO_CODEX=0; DO_OPENCODE=0
want claude-code && DO_CLAUDE=1
want codex && DO_CODEX=1
want opencode && DO_OPENCODE=1

# AGENTS.md is shared by codex + opencode; only one flywheel block may exist —
# prefer opencode's when both are selected.
if [ "$DO_CODEX" = 1 ] || [ "$DO_OPENCODE" = 1 ]; then
  if [ "$DO_OPENCODE" = 1 ]; then
    AGENTS_BLOCK="$ADAPTERS_DIR/opencode/AGENTS.md.block"
    [ "$DO_CODEX" = 1 ] && echo "  note: both codex and opencode selected — AGENTS.md uses opencode's block"
  else
    AGENTS_BLOCK="$ADAPTERS_DIR/codex/AGENTS.md.block"
  fi
  wire_block "$AGENTS_BLOCK" "$TARGET/AGENTS.md"
  echo "  wired: AGENTS.md"
fi

if [ "$DO_CLAUDE" = 1 ]; then
  wire_block "$ADAPTERS_DIR/claude-code/CLAUDE.md.block" "$TARGET/CLAUDE.md"
  echo "  wired: CLAUDE.md"

  mkdir -p "$TARGET/.claude/agents"
  for af in "$ADAPTERS_DIR"/claude-code/agents/*.md; do
    [ -e "$af" ] || continue
    copy_managed_if_ok "$af" "$TARGET/.claude/agents/$(basename "$af")"
  done

  for sd in "$ADAPTERS_DIR"/claude-code/skills/*/; do
    [ -d "$sd" ] || continue
    name="$(basename "$sd")"
    copy_managed_if_ok "$sd/SKILL.md" "$TARGET/.claude/skills/$name/SKILL.md"
  done
fi

if [ "$DO_OPENCODE" = 1 ]; then
  MERGE_FILE="$ADAPTERS_DIR/opencode/opencode.json.merge"
  DEST="$TARGET/opencode.json"
  if [ -f "$MERGE_FILE" ]; then
    if [ ! -f "$DEST" ]; then
      cp -f "$MERGE_FILE" "$DEST"
      echo "  created: opencode.json"
    else
      if [ ! -f "$DEST.flywheel-bak" ]; then
        cp -f "$DEST" "$DEST.flywheel-bak"
        echo "  backed up: opencode.json -> opencode.json.flywheel-bak"
      fi
      if [ -z "$RUNNER" ]; then
        echo "error: python3 or node required to merge opencode.json" >&2
        exit 1
      fi
      if [ "$RUNNER" = python3 ]; then
        RESULT=$(python3 - "$MERGE_FILE" "$DEST" <<'PYEOF'
import json, sys
merge_path, dest_path = sys.argv[1], sys.argv[2]
with open(merge_path, encoding="utf-8") as f:
    merge_doc = json.load(f)
merge_agents = merge_doc.get("agent", {})
with open(dest_path, encoding="utf-8") as f:
    target_doc = json.load(f)
target_agents = target_doc.setdefault("agent", {})
changed = False
for k, v in merge_agents.items():
    if k not in target_agents:
        target_agents[k] = v
        changed = True
    elif target_agents[k] != v:
        print(f"  skip (differs): agent.{k}", file=sys.stderr)
if changed:
    with open(dest_path, "w", encoding="utf-8") as f:
        json.dump(target_doc, f, indent=2)
        f.write("\n")
print("merged" if changed else "already-merged")
PYEOF
)
      else
        RESULT=$(node - "$MERGE_FILE" "$DEST" <<'NODEEOF'
const fs = require('fs');
const [,, mergePath, destPath] = process.argv;
const mergeDoc = JSON.parse(fs.readFileSync(mergePath, 'utf8'));
const mergeAgents = mergeDoc.agent || {};
const targetDoc = JSON.parse(fs.readFileSync(destPath, 'utf8'));
if (!targetDoc.agent) targetDoc.agent = {};
let changed = false;
for (const [k, v] of Object.entries(mergeAgents)) {
  if (!(k in targetDoc.agent)) { targetDoc.agent[k] = v; changed = true; }
  else if (JSON.stringify(targetDoc.agent[k]) !== JSON.stringify(v)) {
    console.error(`  skip (differs): agent.${k}`);
  }
}
if (changed) {
  fs.writeFileSync(destPath, JSON.stringify(targetDoc, null, 2) + '\n');
}
console.log(changed ? 'merged' : 'already-merged');
NODEEOF
)
      fi
      echo "  opencode.json: $RESULT"
    fi
  fi
fi

echo ""
echo "flywheel install into $TARGET done (adapters: $ADAPTERS_ARG)."
echo "Next: open your adapter in $TARGET and paste docs/SEED-PROMPT.md (from the flywheel repo)."

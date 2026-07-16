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

# --- helper: restore_or_unmerge_json ----------------------------------------
# Reverse of install.sh's merge_json. If $1.flywheel-bak exists (the merge
# case), restore it verbatim and drop the backup. Otherwise, if $1 exists
# (created fresh by install, no backup — or hand-edited since), strip out
# exactly the entries flywheel added: the top-level "flywheel-spawn-log" key
# (antigravity), or any hook-block whose command EXACTLY EQUALS one of
# flywheel's known hook commands (codex .hooks.<event>[] / claude-code
# .hooks.PostToolUse[]) — see the FLYWHEEL_COMMANDS list below, sourced from
# adapters/{claude-code/settings.json.merge, codex/hooks.json.merge,
# antigravity/hooks.json.merge}. Exact match only, never substring — a user
# hook whose command merely mentions "resolve-spawn.py" (e.g. in an echo or
# comment) must NOT be treated as flywheel's. Deletes the file if nothing but
# empty structure is left ({} or {"hooks":{}}); leaves it untouched if no
# flywheel entries are found at all (not a flywheel file).
restore_or_unmerge_json() { # $1 = dest_file
  local dest_file="$1"
  if [ -f "$dest_file.flywheel-bak" ]; then
    # Compare against the post-merge snapshot (.flywheel-merged), not the
    # pre-merge .flywheel-bak — the merge itself always changes dest, so
    # diffing against the pre-merge backup would flag every install as
    # "edited" even with zero user changes. Installs from before
    # .flywheel-merged existed have no reliable post-merge baseline to diff
    # against — skip edit-detection entirely and restore silently, exactly
    # the pre-fix behavior (ponytail: no snapshot, no comparison, not a guess).
    if [ -f "$dest_file.flywheel-merged" ] && [ -f "$dest_file" ] && ! cmp -s "$dest_file" "$dest_file.flywheel-merged"; then
      cp -f "$dest_file" "$dest_file.flywheel-uninstalled"
      echo "  warning: ${dest_file#"$TARGET"/} was edited after install — saved as ${dest_file#"$TARGET"/}.flywheel-uninstalled" >&2
    fi
    mv -f "$dest_file.flywheel-bak" "$dest_file"
    rm -f "$dest_file.flywheel-merged"
    echo "  restored: ${dest_file#"$TARGET"/} (from backup)"
    return 0
  fi
  [ -f "$dest_file" ] || return 0
  if [ -z "$RUNNER" ]; then
    echo "warning: python3 or node required to un-merge ${dest_file#"$TARGET"/} — left untouched" >&2
    return 0
  fi
  local result
  if [ "$RUNNER" = python3 ]; then
    result=$(python3 - "$dest_file" <<'PYEOF'
import json, os, sys

# Exact command strings flywheel installs (see adapters/*/*.merge). Exact
# equality only — a user hook that merely mentions "resolve-spawn.py" in its
# own command string (e.g. an unrelated echo) must not match.
FLYWHEEL_COMMANDS = {
    "python3 flywheel/resolve-spawn.py",              # adapters/claude-code/settings.json.merge
    "python3 flywheel/resolve-spawn.py codex",         # adapters/codex/hooks.json.merge
    "python3 flywheel/resolve-spawn.py antigravity",   # adapters/antigravity/hooks.json.merge
}

def is_flywheel_item(item):
    if not isinstance(item, dict):
        return False
    hooks_list = item.get("hooks")
    if isinstance(hooks_list, list):
        for h in hooks_list:
            if isinstance(h, dict) and str(h.get("command", "")) in FLYWHEEL_COMMANDS:
                return True
    return False

def is_empty(v):  # shallow — used to decide whether to drop a just-emptied key
    return v == {} or v == []

def is_effectively_empty(v):  # deep — used only for the final whole-file check
    if isinstance(v, dict):
        return all(is_effectively_empty(x) for x in v.values())
    if isinstance(v, list):
        return len(v) == 0
    return False

def clean(node):
    if isinstance(node, dict):
        out = {}
        any_removed = False
        for k, v in node.items():
            if k == "flywheel-spawn-log":
                any_removed = True
                continue
            new_v, removed = clean(v)
            any_removed = any_removed or removed
            if removed and is_empty(new_v):
                continue  # this key was emptied by our removal — drop it
            out[k] = new_v
        return out, any_removed
    elif isinstance(node, list):
        out = []
        any_removed = False
        for item in node:
            if is_flywheel_item(item):
                any_removed = True
                continue
            new_item, removed = clean(item)
            any_removed = any_removed or removed
            out.append(new_item)
        return out, any_removed
    else:
        return node, False

path = sys.argv[1]
with open(path, encoding="utf-8") as f:
    doc = json.load(f)
new_doc, removed = clean(doc)
if not removed:
    print("no-flywheel-entries-found")
elif is_effectively_empty(new_doc):
    os.remove(path)
    print("removed (empty after unmerge)")
else:
    with open(path, "w", encoding="utf-8") as f:
        json.dump(new_doc, f, indent=2)
        f.write("\n")
    print("unmerged")
PYEOF
)
  else
    result=$(node - "$dest_file" <<'NODEEOF'
const fs = require('fs');
const path = process.argv[2];

// Exact command strings flywheel installs (see adapters/*/*.merge). Exact
// equality only — a user hook that merely mentions "resolve-spawn.py" in its
// own command string (e.g. an unrelated echo) must not match.
const FLYWHEEL_COMMANDS = new Set([
  'python3 flywheel/resolve-spawn.py',              // adapters/claude-code/settings.json.merge
  'python3 flywheel/resolve-spawn.py codex',         // adapters/codex/hooks.json.merge
  'python3 flywheel/resolve-spawn.py antigravity',   // adapters/antigravity/hooks.json.merge
]);

function isFlywheelItem(item) {
  if (!item || typeof item !== 'object' || Array.isArray(item)) return false;
  const hooksList = item.hooks;
  if (Array.isArray(hooksList)) {
    return hooksList.some(h => h && typeof h === 'object' && FLYWHEEL_COMMANDS.has(String(h.command || '')));
  }
  return false;
}

function isEmpty(v) { // shallow
  if (Array.isArray(v)) return v.length === 0;
  if (v && typeof v === 'object') return Object.keys(v).length === 0;
  return false;
}

function isEffectivelyEmpty(v) { // deep — final whole-file check only
  if (Array.isArray(v)) return v.length === 0;
  if (v && typeof v === 'object') return Object.values(v).every(isEffectivelyEmpty);
  return false;
}

function clean(node) {
  if (Array.isArray(node)) {
    let anyRemoved = false;
    const out = [];
    for (const item of node) {
      if (isFlywheelItem(item)) { anyRemoved = true; continue; }
      const [newItem, removed] = clean(item);
      anyRemoved = anyRemoved || removed;
      out.push(newItem);
    }
    return [out, anyRemoved];
  } else if (node && typeof node === 'object') {
    let anyRemoved = false;
    const out = {};
    for (const k of Object.keys(node)) {
      if (k === 'flywheel-spawn-log') { anyRemoved = true; continue; }
      const [newV, removed] = clean(node[k]);
      anyRemoved = anyRemoved || removed;
      if (removed && isEmpty(newV)) continue;
      out[k] = newV;
    }
    return [out, anyRemoved];
  }
  return [node, false];
}

const doc = JSON.parse(fs.readFileSync(path, 'utf8'));
const [newDoc, removed] = clean(doc);
if (!removed) {
  console.log('no-flywheel-entries-found');
} else if (isEffectivelyEmpty(newDoc)) {
  fs.unlinkSync(path);
  console.log('removed (empty after unmerge)');
} else {
  fs.writeFileSync(path, JSON.stringify(newDoc, null, 2) + '\n');
  console.log('unmerged');
}
NODEEOF
)
  fi
  echo "  ${dest_file#"$TARGET"/}: $result"
}

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
restore_or_unmerge_json "$TARGET/.claude/settings.json"
rmdir "$TARGET/.claude" 2>/dev/null || true

if [ -d "$TARGET/.codex/agents" ]; then
  for af in "$TARGET"/.codex/agents/*.toml; do
    [ -e "$af" ] || continue
    if grep -q 'flywheel-managed' "$af" 2>/dev/null; then
      rm -f "$af"
      echo "  removed: .codex/agents/$(basename "$af")"
    fi
  done
  rmdir "$TARGET/.codex/agents" 2>/dev/null || true
fi
if [ -d "$TARGET/.codex/skills" ]; then
  for sd in "$TARGET"/.codex/skills/*/; do
    [ -d "$sd" ] || continue
    sf="$sd/SKILL.md"
    if [ -f "$sf" ] && grep -q 'flywheel-managed' "$sf" 2>/dev/null; then
      rm -f "$sf"
      echo "  removed: .codex/skills/$(basename "$sd")/SKILL.md"
      rmdir "$sd" 2>/dev/null || true
    fi
  done
  rmdir "$TARGET/.codex/skills" 2>/dev/null || true
fi
restore_or_unmerge_json "$TARGET/.codex/hooks.json"
rmdir "$TARGET/.codex" 2>/dev/null || true

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
restore_or_unmerge_json "$TARGET/.agents/hooks.json"
rmdir "$TARGET/.agents" 2>/dev/null || true

# --- 4. restore opencode.json -----------------------------------------------
if [ -f "$TARGET/opencode.json.flywheel-bak" ]; then
  # See restore_or_unmerge_json above: diff against the post-merge snapshot,
  # not the pre-merge backup, or every install reads as "edited". No snapshot
  # (pre-fix install) -> no reliable baseline -> skip detection, restore silently.
  if [ -f "$TARGET/opencode.json.flywheel-merged" ] && [ -f "$TARGET/opencode.json" ] && ! cmp -s "$TARGET/opencode.json" "$TARGET/opencode.json.flywheel-merged"; then
    cp -f "$TARGET/opencode.json" "$TARGET/opencode.json.flywheel-uninstalled"
    echo "  warning: opencode.json was edited after install — saved as opencode.json.flywheel-uninstalled" >&2
  fi
  mv -f "$TARGET/opencode.json.flywheel-bak" "$TARGET/opencode.json"
  rm -f "$TARGET/opencode.json.flywheel-merged"
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

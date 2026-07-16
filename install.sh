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
if [ -n "${FLYWHEEL_RUNNER:-}" ]; then RUNNER="$FLYWHEEL_RUNNER"
elif command -v python3 >/dev/null 2>&1; then RUNNER=python3
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

# --- shared JSON validity check (merge_json + the opencode.json merge block) --
is_valid_json() { # $1 = file
  if [ "$RUNNER" = python3 ]; then
    python3 -c "import json,sys; json.load(open(sys.argv[1], encoding='utf-8'))" "$1" 2>/dev/null
  else
    node -e "JSON.parse(require('fs').readFileSync(process.argv[1],'utf8'))" "$1" 2>/dev/null
  fi
}

# --- generic JSON deep-merge (hook files: codex, antigravity, claude-code) --
# dict+dict -> recurse key-by-key; list+list -> append src items not already
# present in dest (structural equality via sorted-key JSON comparison), so
# re-running is idempotent; scalar/type-mismatch -> keep dest's value, warn.
# Ownership sidecars:
#   .flywheel-created = Flywheel created this JSON; uninstall exact-unmerges commands
#                       so post-install user additions survive.
#   .flywheel-bak     = user pre-existing JSON; uninstall restores this backup.
#   .flywheel-merged  = post-merge snapshot used to detect post-install edits.
# An unmarked file structurally equal to the merge source is treated as a legacy
# Flywheel-created file. An unmarked file with any additions is conservatively
# treated as user-owned: it gets a backup, and uninstall restores that backup after
# removing only exact Flywheel commands from any created-file state.
merge_json() { # $1 = merge_file $2 = dest_file
  local merge_file="$1" dest_file="$2"
  if [ -z "$RUNNER" ]; then
    echo "error: python3 or node required to merge $dest_file" >&2
    exit 1
  fi
  mkdir -p "$(dirname "$dest_file")"
  if [ ! -f "$dest_file" ]; then
    cp -f "$merge_file" "$dest_file"
    : > "$dest_file.flywheel-created"
    cp -f "$dest_file" "$dest_file.flywheel-merged"
    echo "  created: ${dest_file#"$TARGET"/} (flywheel-owned JSON)"
    return 0
  fi
  # Malformed dest JSON must not crash install or clobber the user's file —
  # warn and skip the merge, leaving dest untouched (no backup either).
  if ! is_valid_json "$dest_file"; then
    echo "  warning: ${dest_file#"$TARGET"/} is not valid JSON — skipping flywheel merge, file left untouched" >&2
    return 0
  fi
  local same_as_merge="no"
  if [ "$RUNNER" = python3 ]; then
    same_as_merge=$(python3 - "$merge_file" "$dest_file" <<'PYEOF'
import json, sys
try:
    a = json.load(open(sys.argv[1], encoding="utf-8"))
    b = json.load(open(sys.argv[2], encoding="utf-8"))
    print("yes" if a == b else "no")
except Exception:
    print("no")
PYEOF
)
  else
    same_as_merge=$(node - "$merge_file" "$dest_file" <<'NODEEOF'
const fs = require('fs');
try {
  const a = JSON.parse(fs.readFileSync(process.argv[2], 'utf8'));
  const b = JSON.parse(fs.readFileSync(process.argv[3], 'utf8'));
  function stable(v) {
    if (Array.isArray(v)) return '[' + v.map(stable).join(',') + ']';
    if (v && typeof v === 'object') return '{' + Object.keys(v).sort().map(k => JSON.stringify(k) + ':' + stable(v[k])).join(',') + '}';
    return JSON.stringify(v);
  }
  console.log(stable(a) === stable(b) ? 'yes' : 'no');
} catch (e) {
  console.log('no');
}
NODEEOF
)
  fi
  if [ -f "$dest_file.flywheel-created" ] || [ "$same_as_merge" = "yes" ]; then
    if [ ! -f "$dest_file.flywheel-created" ]; then
      : > "$dest_file.flywheel-created"
      echo "  marked: ${dest_file#"$TARGET"/} (legacy flywheel-owned JSON)"
    fi
  elif [ ! -f "$dest_file.flywheel-bak" ]; then
    cp -f "$dest_file" "$dest_file.flywheel-bak"
    echo "  backed up: ${dest_file#"$TARGET"/} -> ${dest_file#"$TARGET"/}.flywheel-bak"
  fi
  local result
  if [ "$RUNNER" = python3 ]; then
    result=$(python3 - "$merge_file" "$dest_file" <<'PYEOF'
import json, sys

def structurally_equal(a, b):
    return json.dumps(a, sort_keys=True) == json.dumps(b, sort_keys=True)

def merge(dest, src, path=""):
    changed = False
    if isinstance(dest, dict) and isinstance(src, dict):
        for k, v in src.items():
            p = f"{path}.{k}" if path else k
            if k not in dest:
                dest[k] = v
                changed = True
            else:
                sub_changed, dest[k] = merge(dest[k], v, p)
                changed = changed or sub_changed
        return changed, dest
    elif isinstance(dest, list) and isinstance(src, list):
        for item in src:
            if not any(structurally_equal(item, existing) for existing in dest):
                dest.append(item)
                changed = True
        return changed, dest
    else:
        if dest != src:
            print(f"  skip (differs): {path}", file=sys.stderr)
        return False, dest

merge_path, dest_path = sys.argv[1], sys.argv[2]
with open(merge_path, encoding="utf-8") as f:
    merge_doc = json.load(f)
with open(dest_path, encoding="utf-8") as f:
    dest_doc = json.load(f)
changed, result_doc = merge(dest_doc, merge_doc)
if changed:
    with open(dest_path, "w", encoding="utf-8") as f:
        json.dump(result_doc, f, indent=2)
        f.write("\n")
print("merged" if changed else "already-merged")
PYEOF
)
  else
    result=$(node - "$merge_file" "$dest_file" <<'NODEEOF'
const fs = require('fs');
const [,, mergePath, destPath] = process.argv;

function stableStringify(v) {
  if (Array.isArray(v)) return '[' + v.map(stableStringify).join(',') + ']';
  if (v && typeof v === 'object') {
    return '{' + Object.keys(v).sort().map(k => JSON.stringify(k) + ':' + stableStringify(v[k])).join(',') + '}';
  }
  return JSON.stringify(v);
}

function merge(dest, src, path) {
  let changed = false;
  if (dest && src && typeof dest === 'object' && typeof src === 'object' &&
      !Array.isArray(dest) && !Array.isArray(src)) {
    for (const k of Object.keys(src)) {
      const p = path ? `${path}.${k}` : k;
      if (!(k in dest)) {
        dest[k] = src[k];
        changed = true;
      } else {
        const [subChanged, subResult] = merge(dest[k], src[k], p);
        dest[k] = subResult;
        changed = changed || subChanged;
      }
    }
    return [changed, dest];
  } else if (Array.isArray(dest) && Array.isArray(src)) {
    for (const item of src) {
      if (!dest.some(existing => stableStringify(existing) === stableStringify(item))) {
        dest.push(item);
        changed = true;
      }
    }
    return [changed, dest];
  } else {
    if (JSON.stringify(dest) !== JSON.stringify(src)) {
      console.error(`  skip (differs): ${path}`);
    }
    return [false, dest];
  }
}

const mergeDoc = JSON.parse(fs.readFileSync(mergePath, 'utf8'));
const destDoc = JSON.parse(fs.readFileSync(destPath, 'utf8'));
const [changed, resultDoc] = merge(destDoc, mergeDoc, '');
if (changed) {
  fs.writeFileSync(destPath, JSON.stringify(resultDoc, null, 2) + '\n');
}
console.log(changed ? 'merged' : 'already-merged');
NODEEOF
)
  fi
  # Snapshot of the post-merge result, so uninstall can tell a genuine
  # post-install user edit (dest != this snapshot) apart from the merge
  # itself (dest always differs from the pre-merge .flywheel-bak).
  cp -f "$dest_file" "$dest_file.flywheel-merged"
  echo "  ${dest_file#"$TARGET"/}: $result"
}

# --- 1. flywheel/ payload: MANAGED (always overwrite) ----------------------
if [ "$TARGET" != "$SCRIPT_DIR" ]; then
  mkdir -p "$TARGET/flywheel/state" "$TARGET/flywheel/dashboard"
  for f in INDEX.md ORCHESTRATION.md JUDGMENT.md AUTONOMY.md DIAGNOSIS.md \
           TEMPLATES.md MAINTENANCE.md GIT.md IMPROVE.md ADAPTERS.md check.sh \
           wrapup.sh compact.py resolve-spawn.py sync.py state/SCHEMAS.md; do
    if [ -f "$PAYLOAD/$f" ]; then
      cp -f "$PAYLOAD/$f" "$TARGET/flywheel/$f"
      echo "  managed: flywheel/$f"
    fi
  done
  if [ -d "$PAYLOAD/dashboard" ] && [ -n "$(ls -A "$PAYLOAD/dashboard" 2>/dev/null)" ]; then
    cp -Rf "$PAYLOAD/dashboard/." "$TARGET/flywheel/dashboard/"
    # dashboard.html is a BUILT artifact carrying the flywheel repo's own
    # ledger data — drop it here and rebuild from the target's own (fresh)
    # config/state below, once those exist.
    rm -f "$TARGET/flywheel/dashboard/dashboard.html"
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

  if [ -f "$TARGET/flywheel/dashboard/build.py" ]; then
    if [ "$RUNNER" = python3 ]; then
      python3 "$TARGET/flywheel/dashboard/build.py" >/dev/null 2>&1 && echo "  built: flywheel/dashboard/dashboard.html" || echo "  warning: dashboard.html build failed — first wrapup will build it" >&2
    elif [ "$RUNNER" = node ] && [ -f "$TARGET/flywheel/dashboard/build.mjs" ]; then
      node "$TARGET/flywheel/dashboard/build.mjs" >/dev/null 2>&1 && echo "  built: flywheel/dashboard/dashboard.html" || echo "  warning: dashboard.html build failed — first wrapup will build it" >&2
    else
      echo "  note: no python3/node — flywheel/dashboard/dashboard.html not built yet (first wrapup will build it)"
    fi
  fi
fi

# --- 2. adapters -------------------------------------------------------------
IFS=',' read -ra ADAPTER_LIST <<< "$ADAPTERS_ARG"
want() { local x; for x in "${ADAPTER_LIST[@]}"; do [ "$x" = "$1" ] && return 0; done; return 1; }
DO_CLAUDE=0; DO_CODEX=0; DO_OPENCODE=0; DO_ANTIGRAVITY=0
want claude-code && DO_CLAUDE=1
want codex && DO_CODEX=1
want opencode && DO_OPENCODE=1
want antigravity && DO_ANTIGRAVITY=1

# AGENTS.md is shared by codex + opencode + antigravity; only one flywheel block may exist —
# prefer opencode's then codex's then antigravity's.
if [ "$DO_CODEX" = 1 ] || [ "$DO_OPENCODE" = 1 ] || [ "$DO_ANTIGRAVITY" = 1 ]; then
  if [ "$DO_OPENCODE" = 1 ]; then
    AGENTS_BLOCK="$ADAPTERS_DIR/opencode/AGENTS.md.block"
    ( [ "$DO_CODEX" = 1 ] || [ "$DO_ANTIGRAVITY" = 1 ] ) && echo "  note: multiple adapters selected — AGENTS.md uses opencode's block"
  elif [ "$DO_CODEX" = 1 ]; then
    AGENTS_BLOCK="$ADAPTERS_DIR/codex/AGENTS.md.block"
    [ "$DO_ANTIGRAVITY" = 1 ] && echo "  note: both codex and antigravity selected — AGENTS.md uses codex's block"
  else
    AGENTS_BLOCK="$ADAPTERS_DIR/antigravity/AGENTS.md.block"
  fi
  wire_block "$AGENTS_BLOCK" "$TARGET/AGENTS.md"
  echo "  wired: AGENTS.md"
fi

if [ "$DO_CODEX" = 1 ]; then
  mkdir -p "$TARGET/.codex/agents"
  for af in "$ADAPTERS_DIR"/codex/agents/*.toml; do
    [ -e "$af" ] || continue
    copy_managed_if_ok "$af" "$TARGET/.codex/agents/$(basename "$af")"
  done
  for sd in "$ADAPTERS_DIR"/codex/skills/*/; do
    [ -d "$sd" ] || continue
    name="$(basename "$sd")"
    dest="$TARGET/.agents/skills/$name/SKILL.md"
    copy_managed_if_ok "$sd/SKILL.md" "$dest"
    legacy="$TARGET/.codex/skills/$name/SKILL.md"
    if [ -f "$dest" ] && grep -q 'flywheel-managed' "$dest" 2>/dev/null &&
       [ -f "$legacy" ] && grep -q 'flywheel-managed' "$legacy" 2>/dev/null; then
      rm -f "$legacy"
      echo "  migrated: .codex/skills/$name/SKILL.md -> .agents/skills/$name/SKILL.md"
      rmdir "$TARGET/.codex/skills/$name" 2>/dev/null || true
    fi
  done
  rmdir "$TARGET/.codex/skills" 2>/dev/null || true
  merge_json "$ADAPTERS_DIR/codex/hooks.json.merge" "$TARGET/.codex/hooks.json"
fi

if [ "$DO_ANTIGRAVITY" = 1 ]; then
  mkdir -p "$TARGET/.agents/agents"
  for af in "$ADAPTERS_DIR"/antigravity/agents/*; do
    [ -d "$af" ] || continue
    name="$(basename "$af")"
    mkdir -p "$TARGET/.agents/agents/$name"
    copy_managed_if_ok "$af/agent.json" "$TARGET/.agents/agents/$name/agent.json"
  done
  for sd in "$ADAPTERS_DIR"/antigravity/skills/*/; do
    [ -d "$sd" ] || continue
    name="$(basename "$sd")"
    copy_managed_if_ok "$sd/SKILL.md" "$TARGET/.agents/skills/$name/SKILL.md"
  done
  merge_json "$ADAPTERS_DIR/antigravity/hooks.json.merge" "$TARGET/.agents/hooks.json"
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

  mkdir -p "$TARGET/.claude"
  merge_json "$ADAPTERS_DIR/claude-code/settings.json.merge" "$TARGET/.claude/settings.json"
fi

if [ "$DO_OPENCODE" = 1 ]; then
  MERGE_FILE="$ADAPTERS_DIR/opencode/opencode.json.merge"
  DEST="$TARGET/opencode.json"
  if [ -f "$MERGE_FILE" ]; then
    if [ ! -f "$DEST" ]; then
      cp -f "$MERGE_FILE" "$DEST"
      echo "  created: opencode.json"
    elif ! is_valid_json "$DEST"; then
      echo "  warning: ${DEST#"$TARGET"/} is not valid JSON — skipping flywheel merge, file left untouched" >&2
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
      cp -f "$DEST" "$DEST.flywheel-merged"
      echo "  opencode.json: $RESULT"
    fi
  fi
fi

# Bootstrap docs/ARCHITECTURE.md
mkdir -p "$TARGET/docs"
if command -v python3 >/dev/null 2>&1; then
  python3 "$TARGET/flywheel/dashboard/gen_architecture.py" "$TARGET" >/dev/null 2>&1 || echo "  warning: initial docs/ARCHITECTURE.md generation failed"
fi

echo ""
echo "flywheel install into $TARGET done (adapters: $ADAPTERS_ARG)."
echo "Next: open your adapter in $TARGET and paste docs/SEED-PROMPT.md (from the flywheel repo)."

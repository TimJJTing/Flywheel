#!/usr/bin/env bash
# Shared lifecycle safety, ownership, marker, and JSON helpers.

LIFECYCLE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

select_runner() {
  RUNNER=""
  if [ -n "${FLYWHEEL_RUNNER:-}" ]; then RUNNER="$FLYWHEEL_RUNNER"
  elif command -v python3 >/dev/null 2>&1; then RUNNER=python3
  elif command -v node >/dev/null 2>&1; then RUNNER=node
  fi
}

run_json() {
  if [ "$RUNNER" = python3 ]; then
    python3 "$LIFECYCLE_DIR/lifecycle_json.py" "$@"
  elif [ "$RUNNER" = node ]; then
    node "$LIFECYCLE_DIR/json.mjs" "$@"
  else
    return 1
  fi
}

is_valid_json() { run_json valid "$1" >/dev/null 2>&1; }

wire_block() {
  local block_file="$1" target_file="$2"
  if [ -z "$RUNNER" ]; then
    echo "error: python3 or node required to wire $target_file" >&2
    exit 1
  fi
  if [ "$RUNNER" = python3 ]; then
    python3 - "$block_file" "$target_file" <<'PYEOF'
import os, re, sys
block_path, target_path = sys.argv[1:3]
begin, end = "<!-- flywheel:begin -->", "<!-- flywheel:end -->"
block = open(block_path, encoding="utf-8").read()
content = open(target_path, encoding="utf-8").read() if os.path.exists(target_path) else None
if content is None:
    out = block
elif begin in content and end in content:
    region_re = re.compile(re.escape(begin) + r"[\s\S]*?" + re.escape(end))
    old_region = region_re.search(content).group(0)
    new_block = block.strip()
    old_project = re.search(r"^Project: .*$", old_region, re.MULTILINE)
    if old_project and not old_project.group(0)[len("Project: "):].startswith("(one line"):
        preserved = old_project.group(0)
        new_block = re.sub(r"^Project: .*$", lambda _: preserved, new_block, count=1, flags=re.MULTILINE)
    out = region_re.sub(lambda _: new_block, content, count=1)
else:
    out = content.rstrip("\n") + "\n\n" + block.strip() + "\n"
open(target_path, "w", encoding="utf-8").write(out)
PYEOF
  else
    node - "$block_file" "$target_file" <<'NODEEOF'
const fs = require('fs');
const [,, blockPath, targetPath] = process.argv;
const begin = '<!-- flywheel:begin -->', end = '<!-- flywheel:end -->';
const block = fs.readFileSync(blockPath, 'utf8');
let content = null;
try { content = fs.readFileSync(targetPath, 'utf8'); } catch (_) {}
const esc = value => value.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
let out;
if (content === null) out = block;
else if (content.includes(begin) && content.includes(end)) {
  const regionRe = new RegExp(esc(begin) + '[\\s\\S]*?' + esc(end));
  const oldRegion = content.match(regionRe)[0];
  let newBlock = block.trim();
  const oldProject = oldRegion.match(/^Project: .*$/m);
  if (oldProject && !oldProject[0].slice('Project: '.length).startsWith('(one line')) {
    const preserved = oldProject[0];
    newBlock = newBlock.replace(/^Project: .*$/m, () => preserved);
  }
  out = content.replace(regionRe, () => newBlock);
} else out = content.replace(/\n+$/, '') + '\n\n' + block.trim() + '\n';
fs.writeFileSync(targetPath, out);
NODEEOF
  fi
}

strip_block() {
  local file="$1"
  [ -f "$file" ] || return 0
  if [ -z "$RUNNER" ]; then
    echo "error: python3 or node required to strip markers from $file" >&2
    exit 1
  fi
  if [ "$RUNNER" = python3 ]; then
    python3 - "$file" <<'PYEOF'
import os, re, sys
path = sys.argv[1]
begin, end = "<!-- flywheel:begin -->", "<!-- flywheel:end -->"
content = open(path, encoding="utf-8").read()
if begin in content and end in content:
    content = re.sub(re.escape(begin) + r"[\s\S]*?" + re.escape(end), "", content, count=1)
    content = re.sub(r"\n{3,}", "\n\n", content).rstrip("\n")
if content.strip(): open(path, "w", encoding="utf-8").write(content + "\n")
else: os.remove(path)
PYEOF
  else
    node - "$file" <<'NODEEOF'
const fs = require('fs');
const path = process.argv[2], begin = '<!-- flywheel:begin -->', end = '<!-- flywheel:end -->';
let content = fs.readFileSync(path, 'utf8');
const esc = value => value.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
if (content.includes(begin) && content.includes(end)) {
  content = content.replace(new RegExp(esc(begin) + '[\\s\\S]*?' + esc(end)), '');
  content = content.replace(/\n{3,}/g, '\n\n').replace(/\n+$/, '');
}
if (content.trim()) fs.writeFileSync(path, content + '\n');
else fs.unlinkSync(path);
NODEEOF
  fi
  echo "  stripped: ${file#"$TARGET"/}"
}

copy_managed_if_ok() {
  local src="$1" dest="$2"
  mkdir -p "$(dirname "$dest")"
  if [ ! -e "$dest" ] || grep -q 'flywheel-managed' "$dest" 2>/dev/null ||
     { grep -q '"displayName": "Flywheel ' "$src" 2>/dev/null &&
       grep -q '"displayName": "Flywheel ' "$dest" 2>/dev/null; }; then
    cp -f "$src" "$dest"
    echo "  updated: ${dest#"$TARGET"/}"
  else
    echo "warning: ${dest#"$TARGET"/} exists and is not flywheel-managed — skipped" >&2
    echo "  skipped (unmanaged): ${dest#"$TARGET"/}"
  fi
}

copy_managed_tree() {
  local src="$1" dest="$2" entry
  [ -d "$src" ] || return 0
  if [ -L "$dest" ] || { [ -e "$dest" ] && [ ! -d "$dest" ]; }; then
    echo "warning: ${dest#"$TARGET"/} blocks a managed skill directory — skipped" >&2
    echo "  skipped (unmanaged): ${dest#"$TARGET"/}"
    return 0
  fi
  mkdir -p "$dest"
  for entry in "$src"/*; do
    [ -e "$entry" ] || continue
    if [ -d "$entry" ]; then
      copy_managed_tree "$entry" "$dest/$(basename "$entry")"
    else
      copy_managed_if_ok "$entry" "$dest/$(basename "$entry")"
    fi
  done
}

remove_managed_tree_files() {
  local dir="$1" entry
  [ -d "$dir" ] || return 0
  [ ! -L "$dir" ] || return 0
  for entry in "$dir"/*; do
    [ -e "$entry" ] || continue
    if [ -d "$entry" ] && [ ! -L "$entry" ]; then
      remove_managed_tree_files "$entry"
    elif grep -q 'flywheel-managed' "$entry" 2>/dev/null; then
      rm -f "$entry"
      echo "  removed: ${entry#"$TARGET"/}"
    fi
  done
  rmdir "$dir" 2>/dev/null || true
}

remove_managed_files() {
  local dir="$1" pattern="$2" file
  [ -d "$dir" ] || return 0
  for file in "$dir"/$pattern; do
    [ -e "$file" ] || continue
    if grep -q 'flywheel-managed' "$file" 2>/dev/null; then
      rm -f "$file"
      echo "  removed: ${file#"$TARGET"/}"
    fi
  done
  rmdir "$dir" 2>/dev/null || true
}

merge_json() {
  local merge_file="$1" dest_file="$2" same_as_merge="no" result
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
  if ! is_valid_json "$dest_file"; then
    echo "  warning: ${dest_file#"$TARGET"/} is not valid JSON — skipping flywheel merge, file left untouched" >&2
    return 0
  fi
  same_as_merge="$(run_json equal "$merge_file" "$dest_file")"
  if [ -f "$dest_file.flywheel-created" ] || [ "$same_as_merge" = yes ]; then
    if [ ! -f "$dest_file.flywheel-created" ]; then
      : > "$dest_file.flywheel-created"
      echo "  marked: ${dest_file#"$TARGET"/} (legacy flywheel-owned JSON)"
    fi
  elif [ ! -f "$dest_file.flywheel-bak" ]; then
    cp -f "$dest_file" "$dest_file.flywheel-bak"
    echo "  backed up: ${dest_file#"$TARGET"/} -> ${dest_file#"$TARGET"/}.flywheel-bak"
  fi
  result="$(run_json deep-merge "$merge_file" "$dest_file")"
  cp -f "$dest_file" "$dest_file.flywheel-merged"
  echo "  ${dest_file#"$TARGET"/}: $result"
}

restore_or_unmerge_json() {
  local dest_file="$1" result
  if [ -f "$dest_file.flywheel-bak" ]; then
    if [ -f "$dest_file.flywheel-merged" ] && [ -f "$dest_file" ] && ! cmp -s "$dest_file" "$dest_file.flywheel-merged"; then
      cp -f "$dest_file" "$dest_file.flywheel-uninstalled"
      echo "  warning: ${dest_file#"$TARGET"/} was edited after install — saved as ${dest_file#"$TARGET"/}.flywheel-uninstalled" >&2
    fi
    mv -f "$dest_file.flywheel-bak" "$dest_file"
    rm -f "$dest_file.flywheel-merged" "$dest_file.flywheel-created"
    echo "  restored: ${dest_file#"$TARGET"/} (from backup)"
  fi
  if [ ! -f "$dest_file" ]; then
    rm -f "$dest_file.flywheel-created" "$dest_file.flywheel-merged"
    return 0
  fi
  if [ -z "$RUNNER" ]; then
    echo "warning: python3 or node required to un-merge ${dest_file#"$TARGET"/} — left untouched" >&2
    return 0
  fi
  if ! is_valid_json "$dest_file"; then
    if [ -f "$dest_file.flywheel-created" ] || [ -f "$dest_file.flywheel-merged" ]; then
      cp -f "$dest_file" "$dest_file.flywheel-uninstalled"
      rm -f "$dest_file"
      echo "  warning: ${dest_file#"$TARGET"/} is not valid JSON — preserved verbatim as ${dest_file#"$TARGET"/}.flywheel-uninstalled and removed from the active path" >&2
    else
      echo "  warning: ${dest_file#"$TARGET"/} is unmanaged invalid JSON — left untouched" >&2
    fi
    rm -f "$dest_file.flywheel-created" "$dest_file.flywheel-merged"
    return 0
  fi
  result="$(run_json unmerge "$dest_file")"
  rm -f "$dest_file.flywheel-created" "$dest_file.flywheel-merged"
  echo "  ${dest_file#"$TARGET"/}: $result"
}

assert_uninstall_clean() {
  local stale="" managed_json suffix json_file
  for managed_json in "$TARGET/.codex/hooks.json" "$TARGET/.agents/hooks.json" \
                      "$TARGET/.claude/settings.json" "$TARGET/opencode.json"; do
    for suffix in .flywheel-created .flywheel-bak .flywheel-merged; do
      [ -e "$managed_json$suffix" ] && stale="${stale}${stale:+
}$managed_json$suffix"
    done
  done
  if [ -n "$stale" ]; then
    echo "error: stale flywheel installer sidecars remain:" >&2
    printf '%s\n' "$stale" >&2
    exit 1
  fi
  for json_file in "$TARGET/.codex/hooks.json" "$TARGET/.agents/hooks.json" "$TARGET/.claude/settings.json"; do
    [ -f "$json_file" ] || continue
    is_valid_json "$json_file" || continue
    if [ "$(run_json has-command "$json_file")" = yes ]; then
      echo "error: flywheel hook command remains in ${json_file#"$TARGET"/}" >&2
      exit 1
    fi
  done
}

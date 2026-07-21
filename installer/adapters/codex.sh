#!/usr/bin/env bash

adapter_install() {
  local file
  mkdir -p "$TARGET/.codex/agents"
  for file in "$ADAPTERS_DIR"/codex/agents/*.toml; do
    [ -e "$file" ] || continue
    copy_managed_if_ok "$file" "$TARGET/.codex/agents/$(basename "$file")"
  done
  merge_json "$ADAPTERS_DIR/codex/hooks.json.merge" "$TARGET/.codex/hooks.json"
}

adapter_uninstall() {
  remove_managed_files "$TARGET/.codex/agents" '*.toml'
  restore_or_unmerge_json "$TARGET/.codex/hooks.json"
  rmdir "$TARGET/.codex" 2>/dev/null || true
}

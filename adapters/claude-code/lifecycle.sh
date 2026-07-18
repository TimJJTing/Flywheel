#!/usr/bin/env bash

adapter_install() {
  local file
  wire_block "$ADAPTERS_DIR/claude-code/CLAUDE.md.block" "$TARGET/CLAUDE.md"
  echo "  wired: CLAUDE.md"
  mkdir -p "$TARGET/.claude/agents"
  for file in "$ADAPTERS_DIR"/claude-code/agents/*.md; do
    [ -e "$file" ] || continue
    copy_managed_if_ok "$file" "$TARGET/.claude/agents/$(basename "$file")"
  done
  install_claude_skills
  merge_json "$ADAPTERS_DIR/claude-code/settings.json.merge" "$TARGET/.claude/settings.json"
}

adapter_uninstall() {
  remove_managed_files "$TARGET/.claude/agents" '*.md'
  uninstall_claude_skills
  restore_or_unmerge_json "$TARGET/.claude/settings.json"
  rmdir "$TARGET/.claude" 2>/dev/null || true
}

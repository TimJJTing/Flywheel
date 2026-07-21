#!/usr/bin/env bash
# Coordinates shared marker and skill destinations across adapters.

adapter_selected() {
  local candidate
  for candidate in "${ADAPTER_LIST[@]}"; do [ "$candidate" = "$1" ] && return 0; done
  return 1
}

project_adapter_values() {
  if [ -f "$TARGET/flywheel/sync.py" ]; then
    if [ "$RUNNER" = python3 ]; then
      python3 "$TARGET/flywheel/sync.py"
    else
      # Node-only installs use the runner-neutral helper to apply the preserved
      # target config to Claude, Codex, and Flywheel-owned OpenCode projections.
      run_json project-adapters "$TARGET"
    fi
  fi
  # Snapshot after projection so reinstall and --check compare against the fully
  # target-configured OpenCode destination, not the release-default merge input.
  if adapter_selected opencode && [ -f "$TARGET/opencode.json" ] && is_valid_json "$TARGET/opencode.json"; then
    cp -f "$TARGET/opencode.json" "$TARGET/opencode.json.flywheel-merged"
  fi
}

install_shared_destinations() {
  local block skill
  if adapter_selected opencode || adapter_selected codex || adapter_selected antigravity; then
    if adapter_selected opencode; then
      block="$ADAPTERS_DIR/opencode/AGENTS.md.block"
      if adapter_selected codex || adapter_selected antigravity; then
        echo "  note: multiple adapters selected — AGENTS.md uses opencode's block"
      fi
    elif adapter_selected codex; then
      block="$ADAPTERS_DIR/codex/AGENTS.md.block"
      adapter_selected antigravity && echo "  note: both codex and antigravity selected — AGENTS.md uses codex's block"
    else
      block="$ADAPTERS_DIR/antigravity/AGENTS.md.block"
    fi
    wire_block "$block" "$TARGET/AGENTS.md"
    echo "  wired: AGENTS.md"
  fi
  if adapter_selected codex || adapter_selected antigravity; then
    for skill in "$SHARED_SKILLS_DIR"/*; do
      [ -d "$skill" ] || continue
      copy_managed_tree "$skill" "$TARGET/.agents/skills/$(basename "$skill")"
    done
  fi
}

install_claude_skills() {
  local root="$TARGET/.claude/skills" skill
  for skill in "$SHARED_SKILLS_DIR"/*; do
    [ -d "$skill" ] || continue
    copy_managed_tree "$skill" "$root/$(basename "$skill")"
  done
}

uninstall_claude_skills() {
  local root="$TARGET/.claude/skills" skill_name
  for skill_name in delegate improve wrapup; do
    remove_managed_tree_files "$root/$skill_name"
  done
  rmdir "$root" 2>/dev/null || true
}

uninstall_shared_destinations() {
  local skill_name
  strip_block "$TARGET/CLAUDE.md"
  strip_block "$TARGET/AGENTS.md"
  for skill_name in delegate improve wrapup; do
    remove_managed_tree_files "$TARGET/.agents/skills/$skill_name"
  done
  rmdir "$TARGET/.agents/skills" 2>/dev/null || true
  rmdir "$TARGET/.agents" 2>/dev/null || true
}

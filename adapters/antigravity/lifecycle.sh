#!/usr/bin/env bash

adapter_install() {
  local agent name
  mkdir -p "$TARGET/.agents/agents"
  for agent in "$ADAPTERS_DIR"/antigravity/agents/*; do
    [ -d "$agent" ] || continue
    name="$(basename "$agent")"
    copy_managed_if_ok "$agent/agent.json" "$TARGET/.agents/agents/$name/agent.json"
  done
  merge_json "$ADAPTERS_DIR/antigravity/hooks.json.merge" "$TARGET/.agents/hooks.json"
}

adapter_uninstall() {
  local agent
  if [ -d "$TARGET/.agents/agents" ]; then
    for agent in "$TARGET"/.agents/agents/*; do
      [ -d "$agent" ] || continue
      if [ -f "$agent/agent.json" ]; then
        rm -f "$agent/agent.json"
        echo "  removed: .agents/agents/$(basename "$agent")/agent.json"
      fi
      rmdir "$agent" 2>/dev/null || true
    done
    rmdir "$TARGET/.agents/agents" 2>/dev/null || true
  fi
  restore_or_unmerge_json "$TARGET/.agents/hooks.json"
  rmdir "$TARGET/.agents" 2>/dev/null || true
}

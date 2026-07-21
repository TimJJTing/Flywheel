#!/usr/bin/env bash

adapter_install() {
  local merge_file="$ADAPTERS_DIR/opencode/opencode.json.merge"
  local dest="$TARGET/opencode.json" result
  [ -f "$merge_file" ] || return 0
  if [ ! -f "$dest" ]; then
    cp -f "$merge_file" "$dest"
    : > "$dest.flywheel-created"
    echo "  created: opencode.json (flywheel-owned JSON)"
  elif ! is_valid_json "$dest"; then
    echo "  warning: ${dest#"$TARGET"/} is not valid JSON — skipping flywheel merge, file left untouched" >&2
  else
    if [ ! -f "$dest.flywheel-created" ] && [ ! -f "$dest.flywheel-bak" ]; then
      cp -f "$dest" "$dest.flywheel-bak"
      echo "  backed up: opencode.json -> opencode.json.flywheel-bak"
    fi
    if [ -z "$RUNNER" ]; then
      echo "error: python3 or node required to merge opencode.json" >&2
      exit 1
    fi
    result="$(run_json opencode-merge "$merge_file" "$dest")"
    echo "  opencode.json: $result"
  fi
}

adapter_uninstall() {
  local merge_file="$ADAPTERS_DIR/opencode/opencode.json.merge" same
  if [ -f "$TARGET/opencode.json.flywheel-bak" ]; then
    if [ -f "$TARGET/opencode.json.flywheel-merged" ] && [ -f "$TARGET/opencode.json" ] &&
       ! cmp -s "$TARGET/opencode.json" "$TARGET/opencode.json.flywheel-merged"; then
      cp -f "$TARGET/opencode.json" "$TARGET/opencode.json.flywheel-uninstalled"
      echo "  warning: opencode.json was edited after install — saved as opencode.json.flywheel-uninstalled" >&2
    fi
    mv -f "$TARGET/opencode.json.flywheel-bak" "$TARGET/opencode.json"
    rm -f "$TARGET/opencode.json.flywheel-merged" "$TARGET/opencode.json.flywheel-created"
    echo "  restored: opencode.json (from backup)"
  elif [ -f "$TARGET/opencode.json.flywheel-created" ]; then
    if [ -f "$TARGET/opencode.json" ] && [ -f "$TARGET/opencode.json.flywheel-merged" ] &&
       cmp -s "$TARGET/opencode.json" "$TARGET/opencode.json.flywheel-merged"; then
      rm -f "$TARGET/opencode.json"
      echo "  removed: opencode.json (unchanged Flywheel-created file)"
    elif [ -f "$TARGET/opencode.json" ]; then
      cp -f "$TARGET/opencode.json" "$TARGET/opencode.json.flywheel-uninstalled"
      rm -f "$TARGET/opencode.json"
      echo "  warning: edited Flywheel-created opencode.json preserved as opencode.json.flywheel-uninstalled" >&2
    fi
    rm -f "$TARGET/opencode.json.flywheel-created" "$TARGET/opencode.json.flywheel-merged"
  elif [ -f "$TARGET/opencode.json" ]; then
    if [ -f "$merge_file" ] && [ -n "$RUNNER" ]; then
      same="$(run_json opencode-only "$merge_file" "$TARGET/opencode.json")"
      if [ "$same" = yes ]; then
        rm -f "$TARGET/opencode.json"
        echo "  removed: opencode.json (flywheel-created, no backup needed)"
        return 0
      fi
    fi
    echo "  note: opencode.json present with no backup and does not look flywheel-only — left untouched"
  fi
}

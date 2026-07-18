#!/usr/bin/env bash
# Core payload/state/dashboard lifecycle. Requires common.sh globals.

install_core() {
  [ "$TARGET" != "$SCRIPT_DIR" ] || return 0
  local file src ledger
  mkdir -p "$TARGET/flywheel/state" "$TARGET/flywheel/dashboard"
  for file in INDEX.md ORCHESTRATION.md JUDGMENT.md AUTONOMY.md DIAGNOSIS.md \
              TEMPLATES.md MAINTENANCE.md GIT.md IMPROVE.md ADAPTERS.md check.sh \
              wrapup.sh compact.py resolve-spawn.py sync.py state/SCHEMAS.md; do
    if [ -f "$PAYLOAD/$file" ]; then
      cp -f "$PAYLOAD/$file" "$TARGET/flywheel/$file"
      echo "  managed: flywheel/$file"
    fi
  done
  if [ -d "$PAYLOAD/dashboard" ] && [ -n "$(ls -A "$PAYLOAD/dashboard" 2>/dev/null)" ]; then
    cp -Rf "$PAYLOAD/dashboard/." "$TARGET/flywheel/dashboard/"
    rm -f "$TARGET/flywheel/dashboard/dashboard.html"
    echo "  managed: flywheel/dashboard/*"
  fi

  DEFAULTS="$SCRIPT_DIR/defaults"
  for file in config.json FACTS.md STATUS.md LESSONS.md; do
    src="$DEFAULTS/$file"; [ -f "$src" ] || src="$PAYLOAD/$file"
    if [ -f "$src" ]; then
      if [ ! -f "$TARGET/flywheel/$file" ]; then
        cp -f "$src" "$TARGET/flywheel/$file"
        echo "  created: flywheel/$file"
      else
        echo "  kept: flywheel/$file (already present)"
      fi
    fi
  done
  for ledger in projects.json issues.json decisions.json activity.json spawns.json; do
    if [ ! -f "$TARGET/flywheel/state/$ledger" ]; then
      if [ -f "$DEFAULTS/state/$ledger" ]; then
        cp -f "$DEFAULTS/state/$ledger" "$TARGET/flywheel/state/$ledger"
      else
        printf '[]\n' > "$TARGET/flywheel/state/$ledger"
      fi
      echo "  created: flywheel/state/$ledger"
    else
      echo "  kept: flywheel/state/$ledger (already present)"
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
}

bootstrap_architecture() {
  mkdir -p "$TARGET/docs"
  if command -v python3 >/dev/null 2>&1; then
    python3 "$TARGET/flywheel/dashboard/gen_architecture.py" "$TARGET" >/dev/null 2>&1 || echo "  warning: initial docs/ARCHITECTURE.md generation failed"
  fi
}

archive_core_state() {
  local has_state=0 has_lessons=0 do_archive=1 answer state_file file
  if [ -d "$TARGET/flywheel/state" ]; then
    for state_file in "$TARGET"/flywheel/state/*.json; do
      [ -e "$state_file" ] || continue
      if [ "$(tr -d '[:space:]' < "$state_file")" != "[]" ]; then has_state=1; break; fi
    done
  fi
  if [ -f "$TARGET/flywheel/LESSONS.md" ] && [ "$(wc -l < "$TARGET/flywheel/LESSONS.md")" -gt 1 ]; then
    has_lessons=1
  fi
  if [ "$has_state" = 1 ] || [ "$has_lessons" = 1 ]; then
    if [ "$ASSUME_YES" != 1 ]; then
      read -r -p "Archive state to $TARGET/flywheel-archive/ before removing? [Y/n] " answer || answer=""
      case "$answer" in [nN]*) do_archive=0;; *) do_archive=1;; esac
    fi
    if [ "$do_archive" = 1 ]; then
      mkdir -p "$TARGET/flywheel-archive/state"
      [ -d "$TARGET/flywheel/state" ] && cp -Rf "$TARGET/flywheel/state/." "$TARGET/flywheel-archive/state/"
      for file in STATUS.md LESSONS.md FACTS.md config.json; do
        [ -f "$TARGET/flywheel/$file" ] && cp -f "$TARGET/flywheel/$file" "$TARGET/flywheel-archive/$file"
      done
      echo "  archived: $TARGET/flywheel-archive/"
    fi
  fi
}

remove_core() {
  if [ -f "$TARGET/docs/ARCHITECTURE.md" ]; then
    rm -f "$TARGET/docs/ARCHITECTURE.md"
    echo "  removed: docs/ARCHITECTURE.md"
    rmdir "$TARGET/docs" 2>/dev/null || true
  fi
  rm -rf "$TARGET/flywheel"
}

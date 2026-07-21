#!/usr/bin/env bash
# Core payload/state/dashboard lifecycle. Requires common.sh globals.

install_core() {
  local src rel
  mkdir -p "$TARGET/flywheel"
  while IFS= read -r -d '' src; do
    rel="${src#"$MANAGED/"}"
    mkdir -p "$(dirname "$TARGET/flywheel/$rel")"
    cp -f "$src" "$TARGET/flywheel/$rel"
    echo "  managed: flywheel/$rel"
  done < <(find "$MANAGED" -type f -print0)
  while IFS= read -r -d '' src; do
    rel="${src#"$DEFAULTS/"}"
    if [ ! -f "$TARGET/flywheel/$rel" ]; then
      mkdir -p "$(dirname "$TARGET/flywheel/$rel")"
      cp -f "$src" "$TARGET/flywheel/$rel"
      echo "  created: flywheel/$rel"
    else
      echo "  kept: flywheel/$rel (already present)"
    fi
  done < <(find "$DEFAULTS" -type f -print0)
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
  mkdir -p "$TARGET/docs/flywheel"
  if command -v python3 >/dev/null 2>&1; then
    python3 "$TARGET/flywheel/dashboard/gen_architecture.py" "$TARGET" >/dev/null 2>&1 || echo "  warning: initial docs/flywheel/ARCHITECTURE.md generation failed"
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
  if [ -f "$TARGET/docs/flywheel/ARCHITECTURE.md" ] &&
     grep -q '^<!-- flywheel-generated:architecture -->$' "$TARGET/docs/flywheel/ARCHITECTURE.md"; then
    rm -f "$TARGET/docs/flywheel/ARCHITECTURE.md"
    echo "  removed: docs/flywheel/ARCHITECTURE.md (Flywheel-generated)"
    rmdir "$TARGET/docs/flywheel" 2>/dev/null || true
    rmdir "$TARGET/docs" 2>/dev/null || true
  fi
  rm -rf "$TARGET/flywheel"
}

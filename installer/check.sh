#!/usr/bin/env bash
# Read-only drift check: install into a disposable clone and compare results.

check_installation() {
  local shadow diff_file log_file rc=0
  shadow="$(mktemp -d)"
  diff_file="$(mktemp)"
  log_file="$(mktemp)"
  trap 'rm -rf "$shadow" "$diff_file" "$diff_file.filtered" "$log_file"' RETURN
  cp -R "$TARGET/." "$shadow/"
  if ! FLYWHEEL_RUNNER="$RUNNER" bash "$INSTALLER_DIR/install.sh" "$shadow" \
      --adapters "$ADAPTERS_ARG" --yes >"$log_file" 2>&1; then
    echo "error: could not compute expected installation" >&2
    sed -n '1,80p' "$log_file" >&2
    return 1
  fi
  diff -qr "$TARGET" "$shadow" >"$diff_file" || rc=$?
  if [ "$rc" -gt 1 ]; then
    echo "error: target comparison failed" >&2
    return 1
  fi
  # dashboard.html is a mutable build artifact and is not an install input.
  sed '/flywheel\/dashboard\/dashboard.html/d' "$diff_file" >"$diff_file.filtered"
  if [ -s "$diff_file.filtered" ]; then
    echo "Flywheel installation drift detected:" >&2
    sed 's/^/  /' "$diff_file.filtered" >&2
    return 1
  fi
  echo "PASS --check: installation matches distribution; target unchanged"
  return 0
}

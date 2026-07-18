#!/usr/bin/env bash
# uninstall.sh — stable public entry point for removing Flywheel safely.
# Usage: ./uninstall.sh <target-dir> [--yes]
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ADAPTERS_DIR="$SCRIPT_DIR/adapters"

TARGET="${1:-}"
if [ -z "$TARGET" ]; then
  echo "Usage: $0 <target-dir> [--yes]" >&2
  exit 1
fi
shift

ASSUME_YES=0
while [ $# -gt 0 ]; do
  case "$1" in
    --yes) ASSUME_YES=1; shift ;;
    *) echo "Unknown argument: $1" >&2; exit 1 ;;
  esac
done

if [ ! -d "$TARGET" ]; then
  echo "error: target dir does not exist: $TARGET" >&2
  exit 1
fi
TARGET="$(cd "$TARGET" && pwd)"
if [ ! -d "$TARGET/flywheel" ]; then
  echo "error: $TARGET/flywheel not found — nothing to uninstall" >&2
  exit 1
fi

# shellcheck source=scripts/lifecycle/common.sh
source "$SCRIPT_DIR/scripts/lifecycle/common.sh"
# shellcheck source=scripts/lifecycle/core.sh
source "$SCRIPT_DIR/scripts/lifecycle/core.sh"
# shellcheck source=scripts/lifecycle/shared.sh
source "$SCRIPT_DIR/scripts/lifecycle/shared.sh"
select_runner

archive_core_state
uninstall_shared_destinations
# Uninstall has no historical adapter manifest, so every known module must clean up.
# Keep flywheel/ present until all hook unmerges have completed.
for adapter in claude-code codex antigravity opencode; do
  # shellcheck disable=SC1090
  source "$ADAPTERS_DIR/$adapter/lifecycle.sh"
  adapter_uninstall
done
remove_core
assert_uninstall_clean

echo ""
echo "flywheel uninstalled from $TARGET."

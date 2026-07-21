#!/usr/bin/env bash
set -euo pipefail

INSTALLER_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$INSTALLER_DIR")"
ADAPTERS_DIR="$REPO_ROOT/distribution/adapters"
SHARED_SKILLS_DIR="$REPO_ROOT/distribution/shared/skills"
TARGET="${1:-}"
[ -n "$TARGET" ] || { echo "Usage: $REPO_ROOT/uninstall.sh <target> [--yes]" >&2; exit 1; }
shift
ASSUME_YES=0
while [ $# -gt 0 ]; do
  case "$1" in --yes) ASSUME_YES=1; shift;; *) echo "Unknown argument: $1" >&2; exit 1;; esac
done
[ -d "$TARGET" ] || { echo "error: target dir does not exist: $TARGET" >&2; exit 1; }
TARGET="$(cd "$TARGET" && pwd)"
[ -d "$TARGET/flywheel" ] || { echo "error: $TARGET/flywheel not found — nothing to uninstall" >&2; exit 1; }

source "$INSTALLER_DIR/lifecycle/common.sh"
source "$INSTALLER_DIR/lifecycle/core.sh"
source "$INSTALLER_DIR/lifecycle/shared.sh"
select_runner
[ -n "$RUNNER" ] || { echo "error: uninstall requires python3 or node; target left unchanged" >&2; exit 1; }

archive_core_state
uninstall_shared_destinations
for adapter in claude-code codex antigravity opencode; do
  source "$INSTALLER_DIR/adapters/$adapter.sh"
  adapter_uninstall
done
remove_core
assert_uninstall_clean
echo "flywheel uninstalled from $TARGET."

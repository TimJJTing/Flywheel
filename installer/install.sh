#!/usr/bin/env bash
set -euo pipefail

INSTALLER_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$INSTALLER_DIR")"
MANAGED="$REPO_ROOT/distribution/managed/flywheel"
DEFAULTS="$REPO_ROOT/distribution/defaults/flywheel"
ADAPTERS_DIR="$REPO_ROOT/distribution/adapters"
SHARED_SKILLS_DIR="$REPO_ROOT/distribution/shared/skills"

usage() { echo "Usage: $REPO_ROOT/install.sh <target> --adapters <list> [--yes | --check]" >&2; exit 1; }
TARGET="${1:-}"
[ -n "$TARGET" ] && [ "$TARGET" != "--adapters" ] || usage
shift
ADAPTERS_ARG=""
ASSUME_YES=0
CHECK_ONLY=0
while [ $# -gt 0 ]; do
  case "$1" in
    --adapters) [ $# -ge 2 ] || usage; ADAPTERS_ARG="$2"; shift 2 ;;
    --adapters=*) ADAPTERS_ARG="${1#*=}"; shift ;;
    --yes) ASSUME_YES=1; shift ;;
    --check) CHECK_ONLY=1; shift ;;
    *) echo "Unknown argument: $1" >&2; usage ;;
  esac
done
[ -n "$ADAPTERS_ARG" ] || usage
if [ "$ASSUME_YES" = 1 ] && [ "$CHECK_ONLY" = 1 ]; then
  echo "error: --check and --yes are mutually exclusive" >&2
  exit 1
fi
[ -d "$TARGET" ] || { echo "error: target dir does not exist: $TARGET" >&2; exit 1; }
TARGET="$(cd "$TARGET" && pwd)"

# Runner selection is deliberately before confirmations or writes.
# shellcheck source=installer/lifecycle/common.sh
source "$INSTALLER_DIR/lifecycle/common.sh"
select_runner
if [ -z "$RUNNER" ]; then
  echo "error: installation requires python3 or node; target left unchanged" >&2
  exit 1
fi

IFS=',' read -ra ADAPTER_LIST <<< "$ADAPTERS_ARG"
for adapter in "${ADAPTER_LIST[@]}"; do
  case "$adapter" in claude-code|codex|opencode|antigravity) ;; *) echo "error: unknown adapter: $adapter" >&2; exit 1;; esac
done

# shellcheck source=installer/lifecycle/core.sh
source "$INSTALLER_DIR/lifecycle/core.sh"
# shellcheck source=installer/lifecycle/shared.sh
source "$INSTALLER_DIR/lifecycle/shared.sh"

if [ "$CHECK_ONLY" = 1 ]; then
  source "$INSTALLER_DIR/check.sh"
  check_installation
  exit $?
fi

if ! git -C "$TARGET" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "warning: $TARGET is not a git repo — no version-control safety net for this install" >&2
fi
if [ "$ASSUME_YES" != 1 ]; then
  echo "Flywheel is ready to install into: $TARGET"
  echo "Adapters: $ADAPTERS_ARG"
  echo "Planned write scope: flywheel/, docs/flywheel/ARCHITECTURE.md, and selected adapter projections."
  printf "Proceed with installation? [y/N] "
  IFS= read -r answer || answer=""
  case "$answer" in [yY]|[yY][eE][sS]) ;; *) echo "Installation cancelled; no files were changed."; exit 1;; esac
fi

echo "Installing flywheel into $TARGET"
install_core
install_shared_destinations
for adapter in codex antigravity claude-code opencode; do
  if adapter_selected "$adapter"; then
    # shellcheck disable=SC1090
    source "$INSTALLER_DIR/adapters/$adapter.sh"
    adapter_install
  fi
done
project_adapter_values
bootstrap_architecture
echo "flywheel install into $TARGET done (adapters: $ADAPTERS_ARG)."
echo "Next: open your adapter in $TARGET and paste docs/SEED-PROMPT.md (from the flywheel repo)."

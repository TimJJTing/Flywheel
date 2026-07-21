#!/usr/bin/env bash
# install.sh — stable public entry point for adopting Flywheel into a project.
# Usage: ./install.sh <target-dir> [--adapters claude-code,codex,opencode] [--yes]
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PAYLOAD="$SCRIPT_DIR/flywheel"
ADAPTERS_DIR="$SCRIPT_DIR/adapters"
SHARED_SKILLS_DIR="$ADAPTERS_DIR/shared/skills"

TARGET="${1:-}"
if [ -z "$TARGET" ] || [ "$TARGET" = "--adapters" ]; then
  echo "Usage: $0 <target-dir> [--adapters claude-code,codex,opencode] [--yes]" >&2
  exit 1
fi
shift

ADAPTERS_ARG="claude-code"
ASSUME_YES=0
while [ $# -gt 0 ]; do
  case "$1" in
    --adapters) ADAPTERS_ARG="${2:-}"; shift 2 ;;
    --adapters=*) ADAPTERS_ARG="${1#*=}"; shift ;;
    --yes) ASSUME_YES=1; shift ;;
    *) echo "Unknown argument: $1" >&2; exit 1 ;;
  esac
done

if [ ! -d "$TARGET" ]; then
  echo "error: target dir does not exist: $TARGET" >&2
  exit 1
fi
TARGET="$(cd "$TARGET" && pwd)"
if ! git -C "$TARGET" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "warning: $TARGET is not a git repo — no version-control safety net for this install" >&2
fi

# shellcheck source=scripts/lifecycle/common.sh
source "$SCRIPT_DIR/scripts/lifecycle/common.sh"
# shellcheck source=scripts/lifecycle/core.sh
source "$SCRIPT_DIR/scripts/lifecycle/core.sh"
# shellcheck source=scripts/lifecycle/shared.sh
source "$SCRIPT_DIR/scripts/lifecycle/shared.sh"
select_runner
if [ -z "$RUNNER" ]; then
  echo "warning: neither python3 nor node found — dashboard build and marker wiring will fail" >&2
fi
IFS=',' read -ra ADAPTER_LIST <<< "$ADAPTERS_ARG"

if [ "$ASSUME_YES" != 1 ]; then
  echo "Flywheel is ready to install into: $TARGET"
  echo "Adapters: $ADAPTERS_ARG"
  echo ""
  echo "Planned write scope:"
  echo "  - flywheel/ and docs/ARCHITECTURE.md"
  if adapter_selected codex || adapter_selected opencode || adapter_selected antigravity; then
    echo "  - AGENTS.md (Flywheel marker block)"
  fi
  if adapter_selected claude-code; then
    echo "  - CLAUDE.md (Flywheel marker block) and .claude/"
  fi
  adapter_selected codex && echo "  - .codex/ and shared .agents/skills/"
  adapter_selected antigravity && echo "  - .agents/"
  adapter_selected opencode && echo "  - opencode.json"
  echo ""
  echo "Those Markdown files are not backed up automatically; marker processing may"
  echo "normalize trailing blank lines, repeated blank lines, or line endings."
  echo "Commit or back up the target project first if exact restoration matters."
  echo ""
  printf "Proceed with installation? [y/N] "
  if ! IFS= read -r answer; then answer=""; fi
  case "$answer" in
    [yY]|[yY][eE][sS]) ;;
    *) echo "Installation cancelled; no files were changed."; exit 1 ;;
  esac
fi

echo "Installing flywheel into $TARGET"
install_core
install_shared_destinations

# Preserve historical adapter phase ordering. Unknown names remain ignored.
for adapter in codex antigravity claude-code opencode; do
  if adapter_selected "$adapter"; then
    # shellcheck disable=SC1090
    source "$ADAPTERS_DIR/$adapter/lifecycle.sh"
    adapter_install
  fi
done

bootstrap_architecture
echo ""
echo "flywheel install into $TARGET done (adapters: $ADAPTERS_ARG)."
echo "Next: open your adapter in $TARGET and paste docs/SEED-PROMPT.md (from the flywheel repo)."

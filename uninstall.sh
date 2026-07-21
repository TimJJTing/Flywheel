#!/usr/bin/env bash
# Stable public entry point. Implementation lives under installer/.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec bash "$SCRIPT_DIR/installer/uninstall.sh" "$@"

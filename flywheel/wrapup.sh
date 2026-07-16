#!/usr/bin/env bash
# Mechanical half of the wrapup procedure (the skill's judgment half stays prose):
# rule check, dashboard rebuild, ledger-freshness sanity, stage+commit the wrapup set.
# Run from anywhere: bash flywheel/wrapup.sh
set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"

# Never sweep an implementation path that the caller already staged into the
# bookkeeping commit. Reject before generation, staging, or committing.
cd "$REPO_ROOT"
OUTSIDE_STAGED=""
while IFS= read -r staged_path; do
  [ -n "$staged_path" ] || continue
  case "$staged_path" in
    flywheel/STATUS.md|flywheel/LESSONS.md|flywheel/state/*.json|flywheel/dashboard/dashboard.html|docs/ARCHITECTURE.md) ;;
    *) OUTSIDE_STAGED="${OUTSIDE_STAGED}${OUTSIDE_STAGED:+
}${staged_path}" ;;
  esac
done <<EOF
$(git diff --cached --name-only 2>/dev/null)
EOF
if [ -n "$OUTSIDE_STAGED" ]; then
  echo "✗ wrapup aborted: staged paths outside the bookkeeping allowlist:" >&2
  echo "$OUTSIDE_STAGED" >&2
  exit 1
fi

# 1. Auto-generate architecture docs if python3 is available.
if command -v python3 >/dev/null 2>&1; then
  python3 "$SCRIPT_DIR/dashboard/gen_architecture.py" "$REPO_ROOT" 2>/dev/null || echo "⚠ warning: architecture auto-generation failed"
fi

# 2. Mechanical rule check — a red check blocks the wrapup commit (MAINTENANCE.md §2).
bash "$SCRIPT_DIR/check.sh" || { echo "✗ wrapup aborted: fix check.sh failures (or log a justified override in LESSONS.md)"; exit 1; }

# 3. Rebuild the dashboard.
python3 "$SCRIPT_DIR/dashboard/build.py" 2>/dev/null \
  || node "$SCRIPT_DIR/dashboard/build.mjs" \
  || { echo "✗ wrapup aborted: dashboard build failed"; exit 1; }

# 4. Ledger freshness + improve cadence, read in one pass (python3 or node, like check.sh).
if command -v python3 >/dev/null 2>&1; then
  META=$(python3 -c '
import json, sys
d = sys.argv[1]
acts = json.load(open(f"{d}/state/activity.json", encoding="utf-8"))
cfg = json.load(open(f"{d}/config.json", encoding="utf-8"))
ts = max((a.get("ts", "") for a in acts), default="")
print(ts[:10] or "-", len(acts), cfg.get("improve_cadence_sessions", 5))
' "$SCRIPT_DIR")
else
  META=$(node -e '
const fs=require("fs"), d=process.argv[1];
const acts=JSON.parse(fs.readFileSync(d+"/state/activity.json","utf-8"));
const cfg=JSON.parse(fs.readFileSync(d+"/config.json","utf-8"));
const ts=acts.map(a=>a.ts||"").sort().pop()||"";
console.log(ts.slice(0,10)||"-", acts.length, cfg.improve_cadence_sessions||5);
' "$SCRIPT_DIR")
fi
set -- $META
NEWEST_TS="${1:--}"; COUNT="${2:-0}"; CADENCE="${3:-5}"
if [ "$NEWEST_TS" != "$(date +%F)" ]; then
  echo "⚠ newest activity.json entry is $NEWEST_TS — update the ledgers (wrapup skill step 2) before committing"
fi

# 5. Stage exactly the wrapup file set; commit only if something changed.
cd "$REPO_ROOT"
git add -- flywheel/STATUS.md flywheel/LESSONS.md flywheel/state/*.json \
  flywheel/dashboard/dashboard.html docs/ARCHITECTURE.md 2>/dev/null
if git diff --cached --quiet; then
  echo "✓ nothing to commit (wrapup file set unchanged)"
else
  git commit -m "chore(flywheel): update state ledgers + dashboard" || exit 1
  echo "✓ committed $(git rev-parse --short HEAD)"
fi

# 6. Improve-pass cadence notice (IMPROVE.md).
if [ "$COUNT" -gt 0 ] && [ $((COUNT % CADENCE)) -eq 0 ]; then
  echo "improve pass due — run the improve skill next session"
fi

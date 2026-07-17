# STATUS — session handover. Budget: ≤ 40 lines (check.sh enforces). Trim, don't grow.
Decisions history lives in `flywheel/state/decisions.json` (rendered by the dashboard).

Updated: 2026-07-17 (session 20, pre-merge simplification verified)

## Current state
- Branch `flywheel/improve-codex-adapter-robustness` adds verified simplification
  commit `7fcc696` after repair `7350d44` and bookkeeping `a884c06`.
- Official Codex docs confirm the git-root `SubagentStop` hook is native. Old Codex
  hook/skill migration, the no-op matcher, and the one-time scope script are removed.
- Fresh verifier retry is VERIFIED: 30 unit/spec tests, dual lifecycle runners,
  sync/drift, check.sh, nested-cwd Codex, and direct Agy probes passed.
- Remaining bounded limits: persisted human `/hooks` trust, all-pin entitlement,
  child runtime telemetry, and fresh live Claude/Agy sessions are unconfirmed.

## In flight
- None.

## Next actions (in order)
1. Human decides d13: merge the verified self-improvement branch or reject it.

## Blockers / decisions pending the human
- d13 — merge `flywheel/improve-codex-adapter-robustness` into `main` (L3 ask-first).

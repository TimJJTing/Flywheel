# STATUS — session handover. Budget: ≤ 40 lines (check.sh enforces). Trim, don't grow.
Decisions history lives in `flywheel/state/decisions.json` (rendered by the dashboard).

Updated: 2026-07-21 (session 30, installer confirmation merged)

## Current state
- `main` includes the fail-closed pre-write installer prompt and explicit `--yes`
  automation opt-in from `58a015a`.
- README and install docs now disclose that AGENTS.md/CLAUDE.md restoration is not
  byte-exact and that those files receive no automatic backup.
- A fresh verifier returned VERIFIED after 41 unit tests, both lifecycle runners,
  fail-closed/EOF probes, combined-adapter scope review, and framework checks.

## In flight
- None.

## Next actions (in order)
1. Await the human's next priority.

## Blockers / decisions pending the human
- None.

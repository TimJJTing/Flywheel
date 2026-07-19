# STATUS — session handover. Budget: ≤ 40 lines (check.sh enforces). Trim, don't grow.
Decisions history lives in `flywheel/state/decisions.json` (rendered by the dashboard).

Updated: 2026-07-19 (session 28, approved improvements merged and verified)

## Current state
- Human approved both verified self-improvement branches.
- Codex marker-block branch is merged into `main` as `cc9467b`.
- Bookkeeping-policy branch is merged into `main` as `1db5716` with independent
  ledger history preserved.
- Fresh post-merge verification passed 41 tests, both lifecycle runners, `check.sh`,
  ancestry, ledger integrity, canonical-block, and Antigravity-isolation probes.

## In flight
- None.

## Next actions (in order)
1. Continue new work from `main`.

## Blockers / decisions pending the human
- None.

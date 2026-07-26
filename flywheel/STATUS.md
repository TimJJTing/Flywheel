# STATUS — session handover. Budget: ≤ 40 lines (check.sh enforces). Trim, don't grow.
Decisions history lives in `flywheel/state/decisions.json` (rendered by the dashboard).

Updated: 2026-07-26 (session 32, file-boundary branch merged to main)

## Current state
- `main` is at `fe20156`. The file-boundary improvement (`b34653c`) merged by
  fast-forward after a pre-merge inspection; d19 resolved as `merge`.
- That inspection found one regression: `wire_block` replaces the whole managed
  marker block on refresh, so it silently overwrote the seeded `Project:` identity
  line (it had already wiped `CLAUDE.md:4`). Fixed in `fe20156` — both runner
  branches now carry a non-placeholder `Project:` line across the refresh.
- A fresh verifier returned VERIFIED on that fix: python3/node byte-parity across
  three input shapes, an out-of-block scoping probe, and a revert-probe on a repo
  copy proving the new test is not vacuous.
- Green on `main`: `dev/check.sh` → PASS repository distribution checks;
  `tests/test_adapter_lifecycle.sh` → PASS adapter lifecycle matrix.

## In flight
- Nothing. No branch is awaiting a merge gate.

## Next actions (in order)
1. Optional: decide i19 — a blanked `Project: ` line is preserved as empty across
   refreshes instead of falling back to the placeholder (P3, consistent with spec).
2. Resume the open backlog in `flywheel/state/issues.json` (i1-i11).

## Blockers / decisions pending the human
- None.

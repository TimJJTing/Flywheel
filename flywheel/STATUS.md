# STATUS — session handover. Budget: ≤ 40 lines (check.sh enforces). Trim, don't grow.
Decisions history lives in `flywheel/state/decisions.json` (rendered by the dashboard).

Updated: 2026-07-29 (session 38, i19 + i30 fixed, verified, merged and closed)

## Current state
- i19 CLOSED: `flywheel/improve-i19-blank-project-fallback` (a6b23d4), d35 human-approved,
  merged --no-ff as 45b8fd9. `installer/lifecycle/common.sh`
  wire_block() preserved any `Project: ` line not starting with `(one line`, so an
  emptied line survived every refresh instead of falling back to the placeholder. Both
  the python3 (:46-50) and node (:70-77) heredocs now require a non-blank stripped
  value; new dual-runner test at tests/test_adapter_lifecycle.sh:411-428.
- i30 CLOSED: `flywheel/improve-i30-spawn-outcome` (08ae05d, plan 81874da), d36
  human-approved, merged --no-ff as 58b58b0. Auto-logged spawn rows
  now write `pending` via a DEFAULT_OUTCOME constant instead of an unconditional `ok`;
  wrapup resolves each; check.sh fails (✗) on out-of-enum, warns (⚠) on pending.
  25 files = 11 authored + 14 mirrors/projections.
- Both verifiers fresh-context (5/5, 8/8), incl. a forced-node check.sh run.

## In flight
- Nothing. Both branches merged; all five agent worktrees removed.

## Next actions (in order)
1. i31 (opened this session): tests/test_adapter_lifecycle.sh aborts on the first
   runner under `set -euo pipefail`, so a node-only regression hides behind a python3
   failure. Own branch.
2. i25, the i30 §7 deferred FACTS row, and open backlog i1-i11 unchanged.

## Blockers / decisions pending the human
- None.
- Carry-forward: i30 is REAL but PARTIAL. check.sh only warns on `pending` and
  wrapup.sh never mentions outcome/pending/spawns, so pending→terminal rests on the
  wrapup skill body (`.claude/skills/wrapup/SKILL.md:19-23`) being obeyed — a pending
  row can persist forever with the gate passing. Same shape as i21's carry-forward.
- Carry-forward: i21's done-condition is a real but PARTIAL fix (verifier) — no
  externally-checkable artifact, so spawn review stays rubber-stampable in principle.
- A verifier run died on an API monthly-spend-limit error; the retry completed.

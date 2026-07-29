# STATUS — session handover. Budget: ≤ 40 lines (check.sh enforces). Trim, don't grow.
Decisions history lives in `flywheel/state/decisions.json` (rendered by the dashboard).

Updated: 2026-07-29 (session 36, i26/i27/i28 fixed and merged)

## Current state
- i26, i27, i28 FIXED, VERIFIED and MERGED. Each was one commit on its own branch off
  45e5a1c; d31/d32/d33 human-approved, merged --no-ff as e4e03a5, 008e041, ae18bf1.
  Plan: `docs/flywheel/plans/improve-i26-i27-i28.md`. Post-merge green: flywheel/check.sh,
  dev/check.sh, `python3 -m unittest tests.test_resolve_spawn` (OK).
  - i26 `flywheel/improve-orchestration-budget-95` (8dac62e): ORCHESTRATION.md:3 +
    MAINTENANCE.md:29 prose said budget 120; check.sh enforces 95. Prose moved to 95 —
    a tightening, check.sh untouched. 4 files.
  - i27 `flywheel/improve-auditor-tier-naming` (b0cf3b7): `dispatch \`auditor\`` →
    `dispatch tier \`auditor\`` in IMPROVE.md:17 AND MAINTENANCE.md:69. One word each,
    no reflow; keeps the tier vocabulary instead of renaming it in 7 files. 4 files.
  - i28 `flywheel/improve-spawn-ledger-indent` (8425d40): resolve-spawn.py:530 dumps
    indent=1 / ensure_ascii=False — spawns.json stops churning ~1000 lines per session.
    test_resolve_spawn.py:744 + the ledger normalized in the same commit. 4 files.
- plan-auditor: APPROVED WITH REQUIRED CHANGES (2 BLOCKER, 2 MAJOR, 3 MINOR), all 7
  applied by the coordinator before dispatch. Both blockers were real scope bugs: i27
  missed MAINTENANCE.md:69, and i26's "no stale 120" criterion was unpassable repo-wide
  (it also hits the historical issues.json record + generated dashboard). LESSONS.md +1.
- Verifier probed past the criteria: revert-then-dev/check.sh passes on all three, each
  parent == main tip, and i28's small 33-line diffstat was explained (the COMMITTED
  ledger was already indent=1; only the live hook append was indent=2).

## In flight
- Nothing. The three `flywheel/improve-*` branches are merged; safe to delete.

## Next actions (in order)
1. i29 (new, opened this session): `flywheel/compact.py:20` also writes indent=2 and
   would revert i28. **Do not run `python3 flywheel/compact.py` until i29 is fixed**,
   even though check.sh prints "compaction due" (>100 entries) every run.
2. i25 (docs/CONTEXT-ENGINEERING.md) and open backlog i1-i11 unchanged.

## Blockers / decisions pending the human
- None.
- Carry-forward: i21's done-condition is a real but PARTIAL fix (verifier) — no
  externally-checkable artifact, so spawn review stays rubber-stampable in principle.

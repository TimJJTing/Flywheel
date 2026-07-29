# STATUS — session handover. Budget: ≤ 40 lines (check.sh enforces). Trim, don't grow.
Decisions history lives in `flywheel/state/decisions.json` (rendered by the dashboard).

Updated: 2026-07-29 (session 36, i26/i27/i28 fixed — 3 branches await the merge decision)

## Current state
- i26, i27, i28 all FIXED and VERIFIED, each on its own single-commit branch off main
  (45e5a1c). None merged: AUTONOMY.md:16 is A at autonomy 3, so d31/d32/d33 are
  `pending` with recommendation "merge". Plan: `docs/flywheel/plans/improve-i26-i27-i28.md`.
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
- Nothing executing. Three unmerged branches pending d31/d32/d33.

## Next actions (in order)
1. Resolve d31/d32/d33 with the human, then merge --no-ff and close i26/i27/i28.
2. i29 (new, opened this session): `flywheel/compact.py:20` also writes indent=2 and
   would revert i28. **Do not run `python3 flywheel/compact.py` until i29 is fixed**,
   even though check.sh prints "compaction due" (109 > 100) every run.
3. i25 (docs/CONTEXT-ENGINEERING.md) and open backlog i1-i11 unchanged.

## Blockers / decisions pending the human
- d31/d32/d33: merge the three improvement branches. Recommendation: merge all three.
- Carry-forward: i21's done-condition is a real but PARTIAL fix (verifier) — no
  externally-checkable artifact, so spawn review stays rubber-stampable in principle.

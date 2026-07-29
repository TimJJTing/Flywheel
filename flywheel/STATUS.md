# STATUS — session handover. Budget: ≤ 40 lines (check.sh enforces). Trim, don't grow.
Decisions history lives in `flywheel/state/decisions.json` (rendered by the dashboard).

Updated: 2026-07-29 (session 37, i29 fixed — merge pending)

## Current state
- i29 FIXED and VERIFIED on `flywheel/improve-compact-ledger-indent` (0fe6afa, one
  commit off main 726bbc9), NOT merged — d34 is pending the human (AUTONOMY.md row
  "Merge flywheel self-improvement branch" = A at L3).
  `flywheel/compact.py:20` + its byte-identical distribution mirror now dump
  `indent=1, ensure_ascii=False`; it was the last state-ledger writer still on
  indent=2 and would have silently reverted i28 on the next compaction.
- Fresh verifier VERIFIED 7/7 empirically on a scratch copy seeded from
  `git show HEAD:flywheel/state/*.json` (real ledgers untouched): indent=1 output with
  zero `\u` escapes, rerun idempotent + byte-identical, summary keeps the SCHEMAS.md
  required fields, and 10 milestone hashes independently recomputed from the squashed
  entries matched the summary's `commits` exactly. A7 probe: no third indent=2 writer
  of `flywheel/state` exists, so i29 closes fully once merged.
- i26/i27/i28 remain merged and closed (e4e03a5, 008e041, ae18bf1); detail in the
  ledgers and `docs/flywheel/plans/improve-i26-i27-i28.md`.

## In flight
- `flywheel/improve-compact-ledger-indent` — awaiting the d34 merge decision.

## Next actions (in order)
1. On d34 approval: merge --no-ff, close i29, then run the compaction that
   MAINTENANCE.md:39-41 schedules (`python3 flywheel/compact.py`; check.sh has been
   printing "compaction due" — spawns.json 109 entries > 100). Dry run in scratch gave
   activity 36→31, spawns 109→31. **Until that merge lands, still do not run
   compaction on main** — main's compact.py is unchanged and would revert i28.
2. i30 (opened this session): `resolve-spawn.py:547,572` hardcode `"outcome": "ok"`,
   so IMPROVE.md:23's "gather spawn rows with outcome retried|escalated|failed" can
   never match; for background spawns the PostToolUse hook also writes the row at
   launch, asserting success before the agent finishes. Own branch, do not bundle.
3. i25 (docs/CONTEXT-ENGINEERING.md) and open backlog i1-i11 unchanged.

## Blockers / decisions pending the human
- d34: merge `flywheel/improve-compact-ledger-indent` (recommendation: merge).
- Carry-forward: i21's done-condition is a real but PARTIAL fix (verifier) — no
  externally-checkable artifact, so spawn review stays rubber-stampable in principle.

# STATUS — session handover. Budget: ≤ 40 lines (check.sh enforces). Trim, don't grow.
Decisions history lives in `flywheel/state/decisions.json` (rendered by the dashboard).

Updated: 2026-07-15 (session 14, architecture audit + install/uninstall fixes)

## Current state
- INSTALL/UNINSTALL FIXES LANDED ON MAIN (session 14): architecture audit
  (docs/plans/architecture-audit-2026-07.md, auditor-approved) produced 4 plans, all
  implemented + independently verified + merged: JSON deep-merge for codex/antigravity
  hooks.json (f9777e3), resolve-spawn.py+sync.py shipped on install + check.sh guard
  (0177d99), claude-code settings.json.merge wired (88fa129), codex uninstall parity
  + exact-match JSON un-merge (be5997f — first version verifier-FAILED on destructive
  substring match, fixed and re-VERIFIED).
- `flywheel/improve-architecture-docs` merged to main (d9 decided-by-human).
- ANTIGRAVITY ADAPTER BUILT & VERIFIED (session 9); codex Part A BUILT + VERIFIED
  (session 6): both awaiting live CLI verification.

## In flight
- None.

## Next actions (in order)
1. Deferred audit items logged as issues i9–i15 (state/issues.json) — pick up next
   session; i14/i15 are verifier-flagged defects (graceful merge_json error, stale
   .flywheel-bak restore warning).
2. Antigravity/Codex live verification: run SEED-PROMPT.md in `agy` or `codex` session.
3. Real-world adoption test: install into actual project, run SEED-PROMPT.md live.
4. opencode spawn-log plugin: verify opencode plugin API live, replace stub.

## Blockers / decisions pending the human
- None.

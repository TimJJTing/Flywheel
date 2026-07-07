# STATUS — session handover. Budget: ≤ 40 lines (check.sh enforces). Trim, don't grow.
Decisions history lives in `flywheel/state/decisions.json` (rendered by the dashboard).

Updated: 2026-07-08 (session 4, level vocabulary + ledger enrichment)

## Current state
- Unified reasoning-knob vocabulary: `effort`/`reasoning` → one `level` across
  config.json + ledger + dashboard. Native keys preserved at the sync.py boundary
  (claude-code `effort:` frontmatter, codex `reasoning`); mapping documented in
  MODELS.md/ADAPTERS.md. VERIFIED 8/8, auditor APPROVE (5 minors applied).
- Dashboard ledger now shows `adapter` + `level` columns and records the coordinator
  (main session) as its own row; `model:"per parent"` banned, all rows carry real IDs.
- Auto-log hook (SubagentStop resolver → auto-append rows) DESIGNED for all 3 adapters,
  DEFERRED — decisions.json d7 (extends d4). codex = session-level only (no subagents).
- Prior: default models per tier + config.json single-source via sync.py.

## In flight
- None.

## Next actions (in order)
1. Build the deferred auto-log hook (d7): claude-code + opencode wiring + shared
   resolve-spawn.py; codex session-level only.
2. Real-world adoption test: install into an actual project, run SEED-PROMPT.md end
   to end with a live adapter session (only simulated mechanically so far).
3. First improve pass once 5 sessions accumulate (or on demand).

## Blockers / decisions pending the human
- None.

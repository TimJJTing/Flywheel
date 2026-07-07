# STATUS — session handover. Budget: ≤ 40 lines (check.sh enforces). Trim, don't grow.
Decisions history lives in `flywheel/state/decisions.json` (rendered by the dashboard).

Updated: 2026-07-07 (session 3, default models + config-as-source)

## Current state
- Default models shipped for all tiers×adapters (config.json + projections): fable/opus/
  sonnet/haiku per tier, effort high except architect+utility=medium. Cost-safety:
  routine work hits haiku/sonnet, not opus/fable. FACTS.md model table filled + dated.
- `flywheel/sync.py` makes config.json the REAL single source: regenerates claude-code
  frontmatter (both dirs) + opencode.json.merge. VERIFIED (7/7, tree clean). check.sh
  still fails on drift; MAINTENANCE.md documents edit-config→sync→check flow.
- Prior: v0.1 + refinement pass on main. Dogfood: repo runs its own claude-code adapter.

## In flight
- None.

## Next actions (in order)
1. Real-world adoption test: install into an actual project, run SEED-PROMPT.md end
   to end with a live adapter session (only simulated mechanically so far).
2. Consider closing i1 (self-install target==source unsupported) or documenting it.
3. First improve pass once 5 sessions accumulate (or on demand).

## Blockers / decisions pending the human
- None.

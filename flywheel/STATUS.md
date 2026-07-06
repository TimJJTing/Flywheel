# STATUS — session handover. Budget: ≤ 60 lines (check.sh enforces). Trim, don't grow.

Updated: 2026-07-06 (bootstrap session, coordinated by fable)

## Current state
- v0.1 built: core doctrine, 3 adapters, dashboard + check.sh, install/uninstall,
  full docs set, README. All commits on main; check.sh green.
- Dogfood: repo runs its own Claude Code adapter (CLAUDE.md + .claude/).

## In flight
- None.

## Next actions (in order)
1. Real-world adoption test: install into an actual project, run SEED-PROMPT.md end
   to end with a live harness session (only simulated mechanically so far).
2. Consider closing i1 (self-install target==source unsupported) or documenting it.
3. First improve pass once 5 sessions accumulate (or on demand).

## Blockers / decisions pending the human
- None.

## Key decisions log (10 most recent)
- 2026-07-06: config tiers nest per-harness values under "harnesses" map (user
  request; extensible without schema change).
- 2026-07-06: JSON ledgers + build-step dashboard over live-fetch HTML (offline,
  diffable).
- 2026-07-06: no {{PLACEHOLDER}} templating; 3 bootstrap-owned files carry all
  project specifics.
- 2026-07-06: hooks skipped in v0.1; ADAPTERS.md documents them as hardening path.

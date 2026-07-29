# STATUS — session handover. Budget: ≤ 40 lines (check.sh enforces). Trim, don't grow.
Decisions history lives in `flywheel/state/decisions.json` (rendered by the dashboard).

Updated: 2026-07-29 (session 35, i22 merged)

## Current state
- i22 FIXED and MERGED (d30 human-approved). Branch `flywheel/improve-block-skill-dedup`,
  one commit `91f9cea` off 704fff9, merged --no-ff as `542b4db`. Plan
  `docs/flywheel/plans/improve-i22-block-skill-dedup.md`; verifier evidence in the d30
  entry. Post-merge green: flywheel/check.sh, dev/check.sh, tests/test_adapter_lifecycle.sh.
  - The claude-code block's 6-line `## Session protocol` section became a 3-line pointer
    to `flywheel/INDEX.md` §Session protocol (already `@`-loaded at CLAUDE.md:7); its only
    non-duplicate content was the `delegate`/`wrapup` skill names, which the skill
    descriptions carry. Same shape as Phase 4's Hard-rules pointer.
  - Skill whitelist kept byte-unchanged (exclusionary — no skill description supplies it).
  - claude-code only: the other three blocks don't `@`-load INDEX.md and their step 2
    carries adapter-specific spawn mechanics. Owned always-loaded 235 → 232/305.
  - 3 same-commit doc rewords (flywheel/ADAPTERS.md + managed mirror + docs/config/ADAPTERS.md)
    so no doc contradicts the diff.
- plan-auditor REJECTED the plan on 1 BLOCKER: the plan DOCUMENT itself broke
  `dev/check.sh` (its prose quoted path tokens that check greps for across the docs
  tree), making its own A3 criterion unpassable. Coordinator patched that + 6 minors
  and re-ran the plan's fence-uniqueness script before dispatching. LESSONS.md +1.

## In flight
- Nothing. `flywheel/improve-block-skill-dedup` is merged; safe to delete.

## Next actions (in order)
1. i28 (new, friction): `flywheel/resolve-spawn.py` re-serializes spawns.json at
   indent=2/ASCII-escaped, so every session shows ~1000 changed lines and wrapup
   re-normalizes by hand. One-line fix in the dumper.
2. i26 (MAINTENANCE.md:29 + ORCHESTRATION.md:3 say budget 120; check.sh:21 enforces 95),
   i27 (IMPROVE.md:17 dispatches `auditor`; the claude-code agent is `plan-auditor`).
3. i25 (docs/CONTEXT-ENGINEERING.md) and open backlog i1-i11 unchanged.

## Blockers / decisions pending the human
- None.
- Carry-forward: i21's done-condition is a real but PARTIAL fix (verifier) — no
  externally-checkable artifact, so spawn review stays rubber-stampable in principle.
  Revisit if it misses again.

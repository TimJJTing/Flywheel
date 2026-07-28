<!-- flywheel:begin -->
# Flywheel framework (managed block — edits outside the markers are yours, inside are flywheel's)

Project: flywheel — the portable agent-framework boilerplate itself (dogfooding its own system).

## Always loaded
@flywheel/INDEX.md
@flywheel/ORCHESTRATION.md
@flywheel/FACTS.md

## Session protocol
1. Read `flywheel/STATUS.md` first — resume from it, don't re-derive. Then
   `bash flywheel/check.sh`: ledger-untracked-commit warnings = work done outside the
   framework — triage, backfill ledgers/docs, note in STATUS.md.
2. Route work per ORCHESTRATION.md §1; use the `delegate` skill for any delegation.
3. Before ending / context low: run the `wrapup` skill. Uncommitted = lost.

## Hard rules
HR1-HR4 are stated once in `flywheel/INDEX.md` §Hard rules, always loaded above, and
bind every session. Never restate them here — a copy drifts from its source.

## Skill whitelist (ignore other skills unless the user names them)
Repo skills: `delegate`, `wrapup`, `improve`. (Add project-specific entries below this
line; DIAGNOSIS.md Leak 2 explains why this list stays short.)
<!-- flywheel:end -->

Motto: "Heroes come and go; policies compound." Strategy & roadmap assumptions:
`docs/flywheel/research/strategy-2026-07.md` — read before any feature/priority/roadmap decision.

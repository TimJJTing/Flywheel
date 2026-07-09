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

## Hard rules (point-of-use duplicates — keep identical to INDEX.md)
- HR1. Never Read a file listed in `flywheel/FACTS.md` §Big files (or any file > 200 KB)
  wholesale — slice via grep/jq/python, or delegate to `utility`.
- HR2. Model names / level values / API params come from `flywheel/config.json` +
  `flywheel/FACTS.md` only. Missing → write `Pending verification`, never invent.
- HR3. No agent declares its own work complete — dispatch `verifier` / `auditor`.
- HR4. Ask-vs-act is governed by `flywheel/AUTONOMY.md`; its level-invariant rows bind
  at every autonomy level.

## Skill whitelist (ignore other skills unless the user names them)
Repo skills: `delegate`, `wrapup`, `improve`. (Add project-specific entries below this
line; DIAGNOSIS.md Leak 2 explains why this list stays short.)
<!-- flywheel:end -->

Motto: "Heroes come and go; policies compound." Strategy & roadmap assumptions:
`docs/research/strategy-2026-07.md` — read before any feature/priority/roadmap decision.

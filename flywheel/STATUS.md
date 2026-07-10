# STATUS — session handover. Budget: ≤ 40 lines (check.sh enforces). Trim, don't grow.
Decisions history lives in `flywheel/state/decisions.json` (rendered by the dashboard).

Updated: 2026-07-10 (session 8, ideas consulting session)

## Current state
- IDEAS LEDGERED (session 8): five new ideas as issues i4–i8 (fabrication linter,
  compliance telemetry, with/without benchmark, rule provenance, LESSONS auto-
  harvest); spec: docs/research/ideas-2026-07-10.md. i4/i5 pair with improve pass.
- STRATEGY SET (session 7): motto "Heroes come and go; policies compound." (human-
  approved, d-ledger); niche = self-amending operating policy. Landscape + 5 revised
  assumptions + open research questions: docs/research/strategy-2026-07.md — read
  before feature/priority decisions. Embedded in README.md + CLAUDE.md pointer.
- codex Part A BUILT + VERIFIED (session 6, fresh-context verifier): "no subagents"
  refuted — codex has `.codex/agents/*.toml` + hooks.json + SKILL.md. adapters/codex/
  drafted; install.sh/resolve-spawn.py/check.sh wired (resolve-spawn codex branch
  reads config.json only; SubagentStop `model` = parent's, discarded). Audited (1
  major + 4 minor, all fixed), verified independently — SAFE TO MERGE, no regression
  to claude-code/opencode.
- AWAITING CODEX LIVE VERIFICATION: no codex CLI available this session. Part B
  (install `.codex/` into this repo) + Part C (11-step human checklist) in
  docs/plans/codex-adapter-dogfood.md are next, human-run.
- opencode wiring: comment-only stub (adapters/opencode/plugin/spawn-log.ts), pending.

## In flight
- None.

## Next actions (in order)
1. AWAITING CODEX LIVE VERIFICATION (human, needs codex CLI installed): run Part B
   (`./install.sh . --adapters claude-code,codex`) then Part C's checklist in
   docs/plans/codex-adapter-dogfood.md.
2. Real-world adoption test: install into an actual project, run SEED-PROMPT.md end
   to end with a live adapter session (only simulated mechanically so far).
3. Improve pass due (5 sessions reached) — run `improve` skill next session; fold in
   strategy items: i3 INDEX.md strategy-doc row, A1 prose-rule→check.sh migrations
   (candidates: i4 fabrication linter, i5 telemetry), A4 delete-to-add rule.
4. opencode spawn-log plugin: verify opencode plugin API live, replace stub.

## Blockers / decisions pending the human
- None.

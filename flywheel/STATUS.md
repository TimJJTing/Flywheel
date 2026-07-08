# STATUS — session handover. Budget: ≤ 40 lines (check.sh enforces). Trim, don't grow.
Decisions history lives in `flywheel/state/decisions.json` (rendered by the dashboard).

Updated: 2026-07-08 (session 5, d7 spawn hook built + codex hooks research)

## Current state
- d7 BUILT for claude-code: `.claude/settings.json` PostToolUse hook (matcher "Agent")
  → `flywheel/resolve-spawn.py` shows user "spawn <agent> → <model> / <level>" and
  auto-appends spawns.json rows (model from `tool_response.resolvedModel` = ground
  truth). VERIFIED incl. 3×20 concurrent stress after a flock race fix (buffered
  write flushed after LOCK_UN — see LESSONS.md). Coordinator row stays manual at
  wrapup (no session-level hook event carries the model).
- codex assumption REFUTED: codex hooks DO expose SubagentStart/SubagentStop
  (agent_type) + SessionStart (model slug) — per-spawn auto-log designable, see
  docs/research/codex-hooks.md. Not built: needs a live codex session to verify.
- TEMPLATES.md "Model/level: per config.json" dead text removed (frontmatter is the
  real binding, synced by sync.py; hook now reports the resolved model per spawn).
- opencode wiring: comment-only stub (adapters/opencode/plugin/spawn-log.ts), pending.
- Prior: level vocabulary unification; default models per tier via sync.py.

## In flight
- None.

## Next actions (in order)
1. Codex adapter: build .codex/hooks.json SubagentStop wiring per
   docs/research/codex-hooks.md — needs a live codex session (exact trigger wording
   still Pending verification).
2. Real-world adoption test: install into an actual project, run SEED-PROMPT.md end
   to end with a live adapter session (only simulated mechanically so far).
3. Improve pass due (5 sessions reached) — run `improve` skill next session.
4. opencode spawn-log plugin: verify opencode plugin API live, replace stub.

## Blockers / decisions pending the human
- None.

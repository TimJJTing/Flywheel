<!-- flywheel-managed -->
# Claude Code delegation

Spawn the named custom agent from `.claude/agents/*.md`. If the tier agents are not
in the available `subagent_type` list (agent files created this session may not
register until the next session), fall back to `subagent_type: general-purpose` with
the `model` parameter from `flywheel/config.json`
(`tiers.<tier>.adapters.claude-code.model`). Paste the tier's rules from
`.claude/agents/<agent>.md` into the prompt and state that level cannot be pinned this
way. If that config value is `Pending verification`, omit the model parameter — never
pass the placeholder string as a model.

Launch independent delegations in parallel in one message. Note each spawn (agent,
adapter, model, level, task ≤15 words, outcome) for wrapup. Never note
`model:"per parent"`; resolve the real model from `flywheel/config.json` for the tier.
If no native spawn mechanism is surfaced, use ORCHESTRATION.md degraded mode: paste
the filled template into a fresh session and record the limitation.

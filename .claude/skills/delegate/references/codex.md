<!-- flywheel-managed -->
# Codex delegation

When custom subagent tools are surfaced, spawn the named agent from
`.codex/agents/*.toml` (architect / researcher / engineer / utility / verifier /
plan-auditor) and pass the filled template as its task. Do not restate a model in the
prompt; the TOML is projected from `flywheel/config.json`.
If no native spawn mechanism is surfaced, use ORCHESTRATION.md degraded mode: paste
the filled template into a fresh session and record the limitation.

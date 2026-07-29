<!-- flywheel-managed -->
# Claude Code wrapup telemetry

The PostToolUse hook (`flywheel/resolve-spawn.py`) already auto-appended a row per
subagent spawned this session. It fires when the Agent tool CALL returns — for a
BACKGROUND spawn that is at launch, before any result exists — so every row it writes
carries the placeholder `outcome:"pending"`. Resolve each one yourself. Append one row
by hand for the coordinator itself
using the real model from `flywheel/config.json`. Never write `model:"per parent"`.

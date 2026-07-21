<!-- flywheel-managed -->
# Claude Code wrapup telemetry

The PostToolUse hook (`flywheel/resolve-spawn.py`) already auto-appended a row per
subagent spawned this session. Its default is `outcome:"ok"`; correct that value for
any retry, escalation, or failure. Append one row by hand for the coordinator itself
using the real model from `flywheel/config.json`. Never write `model:"per parent"`.

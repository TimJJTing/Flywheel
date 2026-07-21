<!-- flywheel-managed -->
# Antigravity wrapup telemetry

Adapter hooks may have auto-appended subagent rows; their default is
`outcome:"ok"`, so correct retries, escalations, and failures. Append one row by hand
for the coordinator when no session-level event captured it. Resolve manual
model/level from adapter facts; never write `model:"per parent"` or an unverified
model guess.

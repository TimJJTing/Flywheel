<!-- flywheel-managed -->
# Codex wrapup telemetry

Immediately before reviewing `spawns.json`, run
`python3 flywheel/resolve-spawn.py codex-coordinator`. It safely upserts this session
from current-turn telemetry, records a keyed pending row when only session identity
is available, or leaves the ledger unchanged when identity cannot be validated.

Adapter hooks may have auto-appended subagent rows; their placeholder is
`outcome:"pending"`, so resolve each into ok/retried/escalated/failed. Append one coordinator
row by hand when no session-level event captured it or the resolver reports telemetry
unavailable. Resolve manual model/level from adapter facts; never treat a config pin
as coordinator runtime telemetry or write an unverified model guess.

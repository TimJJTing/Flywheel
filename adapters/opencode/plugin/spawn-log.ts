// Pending verification (2026-07-08): no opencode session available to test this
// plugin's wiring or confirm opencode's plugin/hook API shape. Do NOT treat the
// hook name, event payload, or return type below as verified fact — they are a
// best-effort sketch mirroring the claude-code PostToolUse contract (see
// flywheel/resolve-spawn.py), not confirmed opencode API.
//
// Intent (per decision d7): on each subagent spawn, resolve the actual model/level
// and append a row to flywheel/state/spawns.json, the same way the claude-code
// PostToolUse hook does. Once opencode's real plugin API is confirmed, replace this
// stub with a thin wrapper that shells out to `python3 flywheel/resolve-spawn.py`
// with an equivalent JSON payload on stdin, or reimplements the same resolver logic.
//
// export default definePlugin(...) // shape unknown — verify against opencode docs
// before wiring this in.

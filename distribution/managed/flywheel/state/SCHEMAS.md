# Ledger schemas (managed file — agents writing state/*.json conform to these)

All flat JSON arrays. IDs: `p1`/`i1`/`d1`… (max existing + 1). Dates ISO-8601.
`check.sh` validates parseability and that commit hashes exist; field conformance is
on the writing agent.

```jsonc
// projects.json
{ "id":"p1","title":"","type":"feature|infra|flywheel","priority":"P1|P2|P3",
  "status":"active|paused|done","milestones":[{"title":"","done":false}],
  "detail":"","commits":["abc1234"],"updated":"2026-07-06" }

// issues.json
{ "id":"i1","title":"","type":"bug|friction|question|debt","priority":"P1|P2|P3",
  "status":"open|done|wontfix","detail":"","commits":[],
  "opened":"2026-07-06","closed":null }

// decisions.json — the CEO queue
{ "id":"d1","title":"","detail":"","options":["",""],"recommendation":"",
  "autonomy_row":"","status":"pending|approved|rejected|decided-by-llm",
  "outcome":"","created":"2026-07-06","resolved":null }

// activity.json — append-only session log
{ "ts":"2026-07-06T14:00","session":1,"summary":"","commits":[] }

// spawns.json — append-only agent-activity record (coordinator + subagents)
{ "ts":"2026-07-06T14:00","agent":"engineer","adapter":"claude-code",
  "model":"","level":"",
  "task":"<=15 words","outcome":"pending|ok|retried|escalated|failed","notes":"" }
// agent: add "coordinator" for the main session itself.
// outcome: automatic writers emit "pending" only — they fire before any verdict exists
//   (a background claude-code spawn logs at launch). Wrapup resolves every "pending" row
//   into ok|retried|escalated|failed; check.sh warns while any remain. Resolve them the
//   same session: once the ledger passes 100 entries check.sh calls for compaction, and
//   compact.py is then run to squash all but the newest 30 into the "(compacted)" rollup, and an unresolved "pending" row vanishes
//   into it silently — the warning stops without anyone having adjudicated the spawn.
// adapter: claude-code | codex | opencode | antigravity.
// model provenance is adapter-specific: resolved child runtime (claude-code),
//   configuration pin (codex child), current-turn telemetry (codex coordinator),
//   inherited parent/configured fallback (antigravity), or best verified manual
//   value; use "Pending verification" when unavailable.
// level: matching effort/reasoning provenance; "-" when unsupported or unknown.
```

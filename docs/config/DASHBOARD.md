# Configuring the dashboard

## Data flow

```
flywheel/state/*.json  (agents append; git-diffable source of truth)
        │
        ▼   python3 flywheel/dashboard/build.py   (or node build.mjs — identical output)
flywheel/dashboard/template.html  ──►  flywheel/dashboard/dashboard.html  (double-click)
```

Wrapup rebuilds it every session. Rebuild manually any time; it is deterministic
(set `FLYWHEEL_BUILD_TS` to pin the timestamp, e.g. in tests).

## Ledger schemas (source of truth for agents writing them)

All flat JSON arrays. IDs: `p1`/`i1`/`d1`… (max existing + 1). Dates ISO-8601.

```jsonc
// projects.json
{ "id":"p1","title":"","type":"feature|infra|flywheel","priority":"P1|P2|P3",
  "status":"active|paused|done","milestones":[{"title":"","done":false}],
  "detail":"","commits":["abc1234"],"updated":"2026-07-06" }
// issues.json
{ "id":"i1","title":"","type":"bug|friction|question|debt","priority":"P1|P2|P3",
  "status":"open|done|wontfix","detail":"","commits":[],"opened":"2026-07-06","closed":null }
// decisions.json  (the CEO queue)
{ "id":"d1","title":"","detail":"","options":["",""],"recommendation":"",
  "autonomy_row":"","status":"pending|approved|rejected|decided-by-llm",
  "outcome":"","created":"2026-07-06","resolved":null }
// activity.json  (append-only)
{ "ts":"2026-07-06T14:00","session":1,"summary":"","commits":[] }
// spawns.json  (append-only)
{ "ts":"2026-07-06T14:00","agent":"engineer","model":"","effort":"",
  "task":"","outcome":"ok|retried|escalated|failed","notes":"" }
```

`flywheel/check.sh` validates all five parse and that recorded commit hashes exist.

## Customizing

`template.html` is self-contained (inline CSS/JS, zero external requests — it must
open from `file://` offline). It is a managed structural file (MAINTENANCE.md): local
changes go through the improve protocol AND will be overwritten by a reinstall unless
you keep them as improve-branch commits you can re-apply.

Safe customizations: colors/typography (one CSS block at the top), section order
(the `render()` calls), row limits (constants near the top of the script). If you add
a ledger field, extend both the schema above and the section renderer — the build
scripts pass data through untouched, so no build change needed.

## Committing dashboard.html?

Your call (INSTALL.md §gitignore): ignore it if everyone can rebuild; commit it if
non-technical teammates open it from the repo/clone. The flywheel repo itself
ignores it.

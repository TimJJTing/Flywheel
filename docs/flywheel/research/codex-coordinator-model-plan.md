# Codex coordinator model resolution plan

Date: 2026-07-18

## Conclusion

The recurring Codex `Pending verification` row is resolvable without treating a
configured model pin as runtime truth. Codex exports `CODEX_THREAD_ID` to commands,
stores that ID in exactly one rollout filename, identifies the coordinator in the
first `session_meta`, and emits the active per-turn `model` and `effort` in
`turn_context`. A bounded, fail-closed resolver can upsert the coordinator row at
wrapup from those fields.

Claude Code is not currently auto-logging the coordinator. Its `PostToolUse(Agent)`
hook logs children only, using `tool_response.resolvedModel`; the wrapup skill then
instructs the coordinator to append its own row by hand. Claude appears reliable in
practice because its session environment makes the active model available to the
coordinator, not because `resolve-spawn.py` receives a coordinator event. Codex does
not expose an equivalent model fact in the agent-facing session header, so its
manual wrapup correctly falls back to `Pending verification` today.

## Exact current paths

### Claude Code

- `distribution/adapters/claude-code/settings.json.merge:3-5` installs only a
  `PostToolUse` hook matched on `Agent`.
- `flywheel/resolve-spawn.py:185-211` reads the child
  `tool_response.resolvedModel`, falling back to the verified tier config only when
  that response field is absent.
- `distribution/shared/skills/wrapup/references/claude-code.md:4-7` says those hook rows are
  subagents and explicitly requires a hand-written coordinator row because there is
  no session-level event.
- `flywheel/state/decisions.json:85` records the original design conclusion:
  coordinator remains manual because the session-end payload carries no model.

Therefore the exact Claude coordinator mechanism is: runtime model visible in the
session environment -> coordinator follows the wrapup instruction -> manual ledger
row. The exact Claude *child* mechanism is different: Agent response ->
`resolvedModel` -> `resolve-spawn.py` -> locked append.

### Codex

- `distribution/adapters/codex/hooks.json.merge:3-7` invokes
  `python3 "$(git rev-parse --show-toplevel)/flywheel/resolve-spawn.py" codex`
  only on `SubagentStop`.
- `flywheel/resolve-spawn.py:214-247` builds only a child row and deliberately
  ignores `payload.model`, which is the parent's model.
- `flywheel/resolve-spawn.py:300-337` reads hook JSON from stdin and appends the
  result under an exclusive lock.
- `distribution/shared/skills/wrapup/references/codex.md:4-13` handles the otherwise-unseen
  coordinator row manual and prohibits unverified guesses.
- `flywheel/state/spawns.json` currently contains three recent Codex coordinator
  rows whose notes say runtime model/level were unavailable (bounded JSON field
  extraction; no transcript content was read).

No current code attempts to use `CODEX_THREAD_ID` or parent `turn_context`, which is
why the safe manual outcome is `Pending verification`.

## Verified local telemetry

Two bounded checks were made independently in the coordinator and this researcher
subagent. Sensitive prompt/response fields were neither printed nor retained.

1. `env | cut -d= -f1 | rg 'CODEX|SESSION|THREAD|MODEL|REASON'` showed that
   `CODEX_THREAD_ID` is present. Only the variable name was printed.
2. A `Path.rglob('*<validated thread id>.jsonl')` filename lookup under
   `~/.codex/sessions` returned exactly one file for each current thread. The raw ID
   need not be logged.
3. The coordinator's exact match was scanned line-by-line. Its first record was
   `type=session_meta`; `payload.id` equalled `CODEX_THREAD_ID`, `payload.cwd` was
   this repository, `payload.source` was `cli`, and `payload.thread_source` was
   `user`.
4. The coordinator's latest `turn_context.payload` contained
   `model=gpt-5.6-sol` and `effort=medium`. The model is also a verified ID in
   `flywheel/FACTS.md:24`; the claim here is stronger and narrower: these exact
   values were emitted in the current coordinator's per-turn runtime metadata.
5. The researcher transcript demonstrated the rejection discriminator: its first
   metadata has `thread_source=subagent`, an `agent_path`, and a parent thread ID.
   A coordinator resolver must reject that transcript even though it also contains
   a valid `turn_context`.

The transcript fields are Codex-generated runtime telemetry, not a projection from
`flywheel/config.json`. They are evidence of the model/effort selected for the local
turn. They do not independently prove which server binary executed the request; the
ledger need not claim that stronger fact.

## Decision

Extend the existing resolver with a coordinator mode rather than adding a
`SessionStart` hook: `python3 flywheel/resolve-spawn.py codex-coordinator`.

Rationale: wrapup needs the latest model and effort, both are available in the
current transcript, and a per-turn model can change after session start. Reusing the
existing script also reuses the ledger lock, timestamp/row shape, installer payload,
and fail-open CLI convention.

Configured pins must not be used as fallback telemetry. On resolution failure the
row remains `model:"Pending verification", level:"-"` (or an existing manual
pending row remains untouched).

## Engineer-ready implementation

### Production changes

1. In `flywheel/resolve-spawn.py`, add constants such as
   `TRANSCRIPT_FILE_MAX_BYTES = 32 * 1024 * 1024` and retain the existing
   `TRANSCRIPT_META_MAX_BYTES` as the maximum JSONL record size. Do not read a
   transcript wholesale.
2. Add
   `build_row_codex_coordinator(cwd: str, environ: Mapping[str, str]) -> dict`.
   It returns the normal eight non-`ts` row fields plus an internal idempotency key,
   or a pending row when a current session is identified but telemetry is absent.
3. Add
   `codex_coordinator_telemetry(cwd: str, environ: Mapping[str, str]) -> tuple[str | None, str | None, str | None]`.
   The tuple is `(model, effort, session_key)`; values are `None` on any validation
   failure. The session key is `sha256(thread_id).hexdigest()[:12]`, never the raw ID.
4. Recognize `sys.argv[1] == "codex-coordinator"` before reading stdin. Resolve
   `cwd` from the installed script root, call the coordinator builder, and use the
   existing locked read-modify-write append path.
5. Refactor the locked writer into
   `append_or_update_rows(cwd, rows, coordinator_session_key=None)`. Normal spawn
   behavior must remain semantically compatible and serialize the ledger with the
   repository's standard two-space JSON indentation. For coordinator mode, store the
   non-secret key only in notes (for example
   `auto-resolved from Codex turn_context; session-key:abc123...`) and update the
   matching coordinator row instead of appending a duplicate. Preserve any curated
   timestamp, task, outcome, and notes while updating resolver-owned model/level. A
   later successful invocation may replace that same session's pending model/level.
6. In `.agents/skills/wrapup/SKILL.md` and its canonical shared source at
   `distribution/shared/skills/wrapup/`, instruct Codex coordinators via the Codex
   reference to run the command immediately before ledger review. Other adapter
   references keep their manual instruction. These managed structural skill changes
   need the repo's required auditor approval before application.
7. Update the approved structural provenance wording in `flywheel/FACTS.md`,
   `flywheel/ORCHESTRATION.md`, and `flywheel/state/SCHEMAS.md` so all three describe
   Codex child config-pin provenance separately from coordinator `turn_context`
   provenance. These files and the three wrapup skill copies are the complete
   structural edit scope for this improvement.

No new installed payload is needed because `resolve-spawn.py` is already copied by
`install.sh:313-318`. No hook change is needed; coordinator capture occurs at wrapup,
when the latest turn is known.

### Safe transcript mapping algorithm

1. Require `CODEX_THREAD_ID` to match the UUID-shaped identifier used by rollout
   filenames. Never interpolate an unchecked value into a glob or shell command.
2. Walk the Codex sessions directory without following symlink directories and
   accept only a regular, non-symlink file whose basename ends exactly
   `-<thread_id>.jsonl`. Require exactly one match.
3. Reject a file larger than the total cap. Open it with no-follow semantics where
   supported and verify the pre/post device+inode identity as the existing child
   transcript reader does at `flywheel/resolve-spawn.py:75-149`.
4. Parse one line at a time, rejecting an over-limit or malformed record. The first
   record must be `session_meta` with `payload.id == CODEX_THREAD_ID`, canonical
   `payload.cwd` equal to or below the installed repo root, `source == "cli"`,
   `thread_source == "user"`, and no `agent_path`. This prevents a subagent command
   from being logged as coordinator.
5. Keep only the last valid `turn_context` whose canonical `payload.cwd` is this
   repo. Accept `payload.model` and `payload.effort` only when both are non-empty,
   bounded strings. Do not read model or effort from global/project config.
6. Never persist or print the transcript path, raw thread ID, prompt text, response
   text, or unrelated metadata.

If `CODEX_HOME` is supported by the installed CLI, use an absolute validated
`$CODEX_HOME/sessions`; otherwise use the current user's `.codex/sessions`. Whether
`CODEX_HOME` is an officially stable environment contract is not verified here, so
tests must inject the sessions root and production should retain the standard local
path fallback.

### Failure behavior

- Missing/invalid ID, zero/multiple matches, symlink/special file, identity change,
  oversized file/line, malformed JSON, wrong metadata identity/source/cwd, subagent
  metadata, or missing/invalid `turn_context` must never use `config.json` as runtime
  proof.
- If a validated current coordinator session and session key exist but its turn
  telemetry is absent, upsert `Pending verification` / `-` for that key.
- A later successful run updates only model/level for that key and preserves curated
  timestamp, task, outcome, and notes. Reconcile an unkeyed manual pending row only
  when exactly one same-minute candidate exists; ambiguity appends rather than guesses.
- If even the current coordinator identity cannot be validated, do not mutate the
  ledger; print one generic system message telling wrapup to retain/append the manual
  `Pending verification` row. Exit 0, matching the current hook safety policy at
  `flywheel/resolve-spawn.py:347-352`.
- A second run for the same session updates one row; it never creates a duplicate.

### Tests

Add coordinator cases to `tests/test_resolve_spawn.py` using an injected temporary
sessions root (never the developer's real `~/.codex`):

- exact ID + coordinator meta + multiple turn contexts -> latest model/effort;
- model changes across turns -> last valid context wins;
- run twice -> exactly one coordinator row; pending then valid -> same row upgrades;
- current transcript is a subagent -> no mutation and generic pending message;
- wrong ID/source/thread_source/cwd, missing model/effort, malformed JSON -> fail
  closed without config fallback;
- zero and duplicate filename matches;
- symlink, FIFO, directory, inode swap, oversized first line, oversized file;
- no raw ID/path or fixture secret in stdout or ledger;
- all existing Claude, Codex child, and Antigravity golden tests unchanged.

### Verification commands

Run after each implementation step:

```sh
python3 -m unittest tests.test_resolve_spawn
bash tests/test_adapter_lifecycle.sh
bash flywheel/check.sh
git diff --check
rg -n 'CODEX_THREAD_ID|codex-coordinator|turn_context' flywheel/resolve-spawn.py tests/test_resolve_spawn.py .agents/skills/wrapup distribution/shared/skills/wrapup
```

Manual safe smoke test from a Codex coordinator (prints no transcript content):

```sh
python3 flywheel/resolve-spawn.py codex-coordinator
python3 -c 'import json; d=json.load(open("flywheel/state/spawns.json")); print({k:d[-1].get(k) for k in ("agent","adapter","model","level","notes")})'
```

Expected decisive fields are `agent=coordinator`, `adapter=codex`, the current
turn-context model/effort, and a hashed session key. Re-running the first command
must leave the coordinator-row count for that session key at one.

## Found / Assumed / Could not find

### Found

- Claude child model logging uses `tool_response.resolvedModel`; coordinator logging
  is manual (`flywheel/resolve-spawn.py:185-211`,
  `distribution/shared/skills/wrapup/references/claude-code.md:4-7`).
- Codex's installed hook covers `SubagentStop` only
  (`distribution/adapters/codex/hooks.json.merge:3-7`), and current coordinator wrapup is manual
  (`distribution/shared/skills/wrapup/references/codex.md:4-13`).
- `CODEX_THREAD_ID` exactly maps to one local rollout; validated coordinator
  `session_meta` distinguishes it from a subagent, and its `turn_context` contains
  the current model and effort (bounded local commands documented above).
- Current Codex child resolver rows use config pins and deliberately ignore the
  parent model (`flywheel/resolve-spawn.py:214-247`).

### Assumed

- `turn_context.payload.model` and `.effort` are the best available local statement
  of the model/effort selected for that turn. They are not claimed as independent
  server-side attestation.
- The standard per-user sessions root remains `.codex/sessions`; an injectable root
  keeps tests deterministic if that storage layout changes.

### Could not find

- A current repo script or Codex session-end hook that records the coordinator.
- A verified stable `CODEX_HOME` contract in the local repo documentation.
- A server-signed execution receipt proving the backend model; therefore no such
  stronger claim should be added to the ledger.

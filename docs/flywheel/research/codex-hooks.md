# Codex hooks — capability study for flywheel spawn auto-log (d7)

> **Revision 2 (2026-07-08)** — supersedes the WebFetch-summarizer caveats below with
> direct reads of the official docs. The `Pending verification` items in Revision 1
> (full hooks.json skeleton; subagent payload fields; the `model` field's referent) are
> now resolved, and a **much larger** finding landed: codex has **first-class custom
> subagents and skills**, not just a hook surface. See the "## Revision 2" section
> immediately below; Revision 1's body is retained unedited as the original record.

## Revision 2 — codex has full subagent + skill capability (VERIFIED)

**New sources (all developers.openai.com, read directly 2026-07-08):**
- https://developers.openai.com/codex/subagents (+ `.md` raw) — custom subagents
- https://developers.openai.com/codex/skills — Agent Skills (SKILL.md)
- https://developers.openai.com/codex/hooks — hooks.json skeleton (re-read)
- https://developers.openai.com/codex/config-reference — config + effort levels

**Headline upgrade:** the degraded-mode assumption for the codex adapter is not just
refuted at the hook layer — codex has a **first-class custom-subagent system** with
per-agent model + reasoning-effort pinning, plus a skills mechanism. The codex adapter
should be built as a **full (non-degraded) adapter**, mirroring claude-code/opencode.

| Claim | Status | Evidence (source, 2026-07-08) |
|---|---|---|
| Custom subagents defined as **TOML** in `.codex/agents/*.toml` (project) / `~/.codex/agents/` (personal) | **VERIFIED** | subagents.md, verbatim example `.codex/agents/reviewer.toml` reproduced |
| Required agent fields: `name`, `description`, `developer_instructions` | **VERIFIED** | subagents.md |
| Optional agent fields incl. `model`, `model_reasoning_effort`, `sandbox_mode`, `mcp_servers`, `skills.config`, `nickname_candidates` | **VERIFIED** | subagents.md |
| **Per-agent model + reasoning effort pinning works** | **VERIFIED (docs)** | example sets `model="gpt-5.4"`, `model_reasoning_effort="high"`. NB: live end-to-end pin still owed (FACTS.md row stays Pending until a running session confirms) |
| Valid effort levels: `minimal\|low\|medium\|high\|xhigh` | **VERIFIED** | config-reference (`model_reasoning_effort`; "xhigh is model-dependent") — validates config.json codex `high`/`xhigh` |
| Full literal `hooks.json` skeleton: top key `"hooks"` → EventName → `[{matcher, hooks:[{type:"command", command, statusMessage, timeout}]}]` | **VERIFIED (WebFetch summary; live-Pending)** (was Pending in Rev 1) | hooks doc, skeleton reproduced |
| `SubagentStop` payload: `turn_id`, `agent_id`, `agent_type`, `session_id`, `cwd`, `hook_event_name`, `model` | **VERIFIED (WebFetch summary; live-Pending)** | hooks doc |
| The `model` field in subagent events = **PARENT session model**, not the subagent's | **VERIFIED (WebFetch summary; live-Pending)** (was Pending/Assumed in Rev 1) | hooks doc: "reflects the parent session's model, not the subagent's individual model configuration" → **resolver MUST take model from config.json by `agent_type`→tier, never the payload** |
| Skills: folder w/ `SKILL.md` (frontmatter `name`,`description`) in `.codex/skills/` (project) / `~/.codex/skills/` | **VERIFIED** | skills doc — same shape as claude-code skills, so delegate/wrapup/improve port cleanly |
| Config: `.codex/config.toml` (project, when trusted) + `~/.codex/config.toml`; `[agents.<name>]`, `agents.max_threads` (default 6), `agents.max_depth` | **VERIFIED** | config-reference |
| Codex spawns a subagent **only when explicitly asked** (no autonomous fan-out) | **VERIFIED** | subagents doc — delegate skill must name the agent to spawn |
| flywheel's codex adapter spawns real subagent processes end-to-end; per-agent pin actually takes effect; `resolve-spawn.py` codex branch fires on `SubagentStop` | **Pending verification** | no live codex session run against this repo yet — this is the one validation still owed (see docs/flywheel/plans/codex-adapter-dogfood.md) |

**Consequence for the resolver:** unlike claude-code (`PostToolUse(Agent)` carries
`tool_response.resolvedModel` = the real subagent model), codex's `SubagentStop.model`
is the *parent's* model. So on codex the spawn row's `model`/`level` must be resolved
**entirely** from `flywheel/config.json` by `agent_type`→tier. `agent`←`agent_type`,
`task` is not cleanly in the payload (`last_assistant_message` is the result), so `task`
may stay manual-at-wrapup. See the dogfood plan for the exact `resolve-spawn.py` change.

---
 The event-name
  list and the load-bearing structural facts were **identical across both passes**
  (high confidence). The second pass's *prose trigger descriptions* were visibly
  garbled (it labeled `SubagentStart` as an approval hook and `SubagentStop` as a
  compaction hook — those are the `PermissionRequest`/`PostCompact` descriptions
  bleeding over), so per-event **trigger wording** below is marked
  `Pending verification` wherever the two passes disagreed or the summarizer clearly
  scrambled it. The WebFetch summarizer is a small model; treat exact prose as
  Pending, treat the cross-pass-consistent name/field lists as reliable.

## Headline

**The d7 assumption is REFUTED.** The Codex hooks doc documents `SubagentStart`,
`SubagentStop`, per-tool (`PreToolUse`/`PostToolUse`), and `SessionStart`-with-`model`
events. Codex therefore has a first-class subagent lifecycle *at the hook layer* and is
**not** limited to "session-level only via notify." The codex adapter can log spawns
essentially the same way claude-code does.

---

## Criterion 1 — Hook event catalog

Event names (consistent across both fetch passes):

| Event | Trigger (as documented) | Notes |
|---|---|---|
| `SessionStart` | Session initialization | Payload includes `model`; `source` ∈ {`startup`,`resume`,`clear`,`compact`} |
| `SubagentStart` | A subagent begins | `Pending verification` on exact wording (garbled in pass 2) |
| `SubagentStop` | A subagent terminates | Adds `agent_transcript_path`, `last_assistant_message`, `stop_hook_active` |
| `PreToolUse` | Before a tool executes | Per-tool |
| `PermissionRequest` | Before an approval prompt | Per-tool-ish (approval gate) |
| `PostToolUse` | After a tool completes | Per-tool; adds `tool_response` |
| `PreCompact` | Before conversation compaction | `trigger` ∈ {`manual`,`auto`} |
| `PostCompact` | After conversation compaction | `trigger` ∈ {`manual`,`auto`} |
| `UserPromptSubmit` | User submits a prompt | Adds `prompt` |
| `Stop` | A turn stops | Turn-end, NOT session-end |

### Payload fields (verbatim field names from the doc)

Common to all events: `session_id`, `transcript_path`, `cwd`, `hook_event_name`,
`model`, `permission_mode`.

- Turn-scoped events also carry: `turn_id`.
- `SessionStart`: `source`. The `model` field is documented as a "Codex-specific
  extension. Active model slug".
- `SubagentStart` / `SubagentStop`: `agent_id`, `agent_type` (also usable as a
  **matcher**). `SubagentStop` additionally: `agent_transcript_path`,
  `last_assistant_message`, `stop_hook_active`.
- `PreToolUse` / `PostToolUse` / `PermissionRequest`: `tool_name`, `tool_use_id`,
  `tool_input`; `tool_response` on `PostToolUse` only.
- `UserPromptSubmit`: `prompt`.
- `PreCompact` / `PostCompact`: `trigger`.

Whether the `model` field on `SubagentStart`/`SubagentStop` is the **subagent's** model
or the parent session's model: `Pending verification` (doc calls it "active model slug"
but does not say which is active inside a subagent event).

Whether any payload carries a **reasoning/effort level** (our schema's `level`):
`Could not find` — no level/effort field is documented. `level` must be resolved from
`flywheel/config.json` by `agent_type` → tier, exactly as the claude-code resolver does.

### Config syntax and location

Discovery paths (verbatim): `~/.codex/hooks.json`, `~/.codex/config.toml`,
`<repo>/.codex/hooks.json`, `<repo>/.codex/config.toml`. Hooks may be defined as JSON
or inline TOML.

JSON shape: keyed by event name → matcher group → handler array. Each handler:
`type` (`"command"`), `command`, optional `statusMessage`, optional `timeout`
(default 600s). Documented example:

```json
{
  "type": "command",
  "command": "python3 ~/.codex/hooks/session_start.py",
  "statusMessage": "Loading session notes"
}
```

Exact top-level wrapper keys around the matcher/handler arrays (e.g. the field name that
holds the per-event array): `Pending verification` — the summarizer described the
nesting but did not reproduce the full literal skeleton.

---

## Criterion 2 — Explicit yes/no answers

**(a) Per-turn or per-tool events?** **YES.** `PreToolUse`/`PostToolUse`/
`PermissionRequest` fire per tool invocation; `UserPromptSubmit`/`Stop`/`SubagentStop`
are turn-scoped (`turn_id` present). Source: the doc's per-tool and turn-scoped event
listings.

**(b) Session start/end with active model ID?** **PARTIAL.** `SessionStart` — YES, and
its payload carries `model` ("active model slug"). **Session END — NO**: there is no
`SessionEnd` event; only `Stop` (turn end). This mirrors claude-code, where the
coordinator's own row is likewise not derivable from a clean session-end payload.

**(c) Anything resembling subagent spawns?** **YES — directly.** `SubagentStart` and
`SubagentStop` are documented events with `agent_id` and `agent_type` in the payload and
`agent_type` matcher support. This is a genuine subagent lifecycle, not an approximation.

---

## Criterion 3 — Recommendation: codex wiring for spawns.json

Codex can log spawns with the **same shared resolver** used for claude-code; only the
wiring differs. Recommended today:

**Per-spawn row → `SubagentStop` hook** (config in `<repo>/.codex/hooks.json`, command
= the shared `resolve-spawn.py` in codex mode):

| spawns.json field | Codex source | Confidence |
|---|---|---|
| `ts` | generated in the hook script at fire time | reliable |
| `agent` | `agent_type` | reliable |
| `adapter` | constant `"codex"` | reliable |
| `model` | `model` payload field, OR resolve from config.json by `agent_type`→tier | model-field origin `Pending verification`; config.json resolution is reliable |
| `level` | resolve from config.json by `agent_type`→tier (no payload field) | reliable (via resolver) |
| `task` | `last_assistant_message` is available but is the *result*, not the *task*; a ≤15-word task is not cleanly in the payload | `Pending verification` / may stay manual |
| `outcome` | derive from `last_assistant_message` / `stop_hook_active` | `Pending verification` |

**Coordinator row → `SessionStart` hook**: emits `{adapter:"codex", model:<model slug>}`
for the coordinator/role. Same limitation as claude-code: no `SessionEnd`, so a
`SessionStart`-based row captures the model but `outcome` stays manual-at-wrapup (or use
`Stop` per-turn, noisier).

`SubagentStop` is preferred over `SubagentStart` for the log row because the terminal
event can carry outcome signal (`last_assistant_message`), matching how claude-code's
`PostToolUse(Agent)` uses `tool_response` as ground truth.

**Bottom line:** per-subagent auto-capture on codex is **possible today**, not N/A.

---

## Criterion 4 — Contradictions with current flywheel assumptions

1. **d7 detail** says: *"codex: degraded mode, no subagents to capture — only
   session-level (coordinator/role) events loggable via notify; per-subagent capture is
   N/A."* — **Contradicted.** The doc documents `SubagentStart`/`SubagentStop` with
   `agent_id`/`agent_type`. Per-subagent capture is available via a hook, and `notify`
   is not the only mechanism.

2. **d7 outcome** says: *"codex: N/A, no subagents."* — **Contradicted** on the same
   grounds.

3. **ADAPTERS.md** (being edited concurrently) reportedly encodes the same "codex =
   session-level only" asymmetry — **flag for revision**; the per-adapter asymmetry
   d7 wanted to "document rather than fake" does not actually exist at the hook layer.

4. **FACTS.md** "Adapter capabilities" rows (`Subagent spawn works for all tier
   agents` = `Pending verification`; `Per-agent level pinning` = `Pending
   verification`) are **not contradicted** — they remain Pending. This doc shows codex
   *documents* subagent hooks, but does **not** prove flywheel's codex adapter actually
   spawns subagent processes end-to-end. That live verification is still owed.

---

## Found (with evidence)

- Codex documents 10 hook events incl. `SubagentStart`, `SubagentStop`, `SessionStart`,
  `PreToolUse`, `PostToolUse` — consistent across two independent fetches of
  https://developers.openai.com/codex/hooks (2026-07-08).
- `SessionStart` payload carries `model` ("active model slug"); common payload fields
  `session_id`/`transcript_path`/`cwd`/`hook_event_name`/`model`/`permission_mode`;
  subagent events carry `agent_id`/`agent_type`.
- Config lives in `~/.codex/hooks.json` / `.codex/config.toml` (user + repo scope);
  handler shape `{type, command, statusMessage, timeout=600s}`; JSON example reproduced
  above.
- No `SessionEnd` event (only `Stop` = turn end).

## Assumed (with why)

- The `model` field inside subagent events reflects the subagent's model — **assumed by
  analogy** to `SessionStart`'s "active model slug", because a subagent's active model
  is the natural referent; not stated. Marked `Pending verification` above.
- `outcome`/`task` can be derived from `last_assistant_message` — assumed because that
  field exists on `SubagentStop`; the doc does not define a task or outcome field.

## Could not find

- Any reasoning/effort **level** field in any payload (our schema's `level`) — must come
  from config.json resolution.
- The full literal JSON skeleton (top-level per-event array wrapper key) and the exact
  verbatim trigger sentence for `SubagentStart`/`SubagentStop` (summarizer garbled the
  prose; names/fields are reliable, trigger wording is `Pending verification`).
- Proof that flywheel's codex adapter actually spawns real subagent processes (doc shows
  the hook surface exists; live end-to-end spawn behavior is still Pending verification
  per FACTS.md).

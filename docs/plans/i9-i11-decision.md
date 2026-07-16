# Decision: deferred audit issues i9 (AGENTS.md block collision) + i11 (spawns.json race)

Date: 2026-07-16 · Author: strategist · Mode: ponytail/full
Source issues: `flywheel/state/issues.json` i9, i11 (both debt/P3, deferred from
architecture-audit-2026-07).

## TL;DR

| Issue | Decision | One-line rationale |
|---|---|---|
| i9 | **(b) keep deferred** | Trigger unfired; install already picks one block deterministically and *prints a note* — announced degradation of prose only, not broken spawns. |
| i11 | **(b) keep deferred** | The only genuinely-concurrent writers (parallel-spawn hooks) are already correctly `flock`-locked; the one unlocked writer runs single-threaded at end-of-session; no Windows target exists. |

Neither trigger has fired. For both, the "fix" costs more than the wait (ponytail
rung 1: does this need to exist now? No).

---

## i9 — AGENTS.md single managed block across codex/opencode/antigravity

### What's actually true (investigated)
- One `AGENTS.md` per target, wired via a single marker pair
  `<!-- flywheel:begin --> … <!-- flywheel:end -->` (`install.sh:67`, py/node
  `wire_block`). markers-present → replace between markers; absent → append.
- The three source blocks **do differ** (not a non-issue):
  `diff adapters/codex/AGENTS.md.block adapters/opencode/AGENTS.md.block` and
  `… antigravity/AGENTS.md.block` both return hunks. Divergence is confined to:
  - step 2 spawn mechanics + exact paths (`.codex/agents/*.toml` vs opencode.json
    `agent` block vs `.agents/agents/{name}/agent.json`),
  - the skill-location note (`.codex/skills/` vs `.agents/skills/` vs opencode),
  - `auditor` vs `plan-auditor` naming.
  The session protocol shell and hard rules HR1–HR4 are identical (~80% of the block).
- `install.sh:293-306` already handles collision **deterministically and loudly**:
  precedence opencode > codex > antigravity, and it `echo`es
  `note: multiple adapters selected — AGENTS.md uses opencode's block` when more than
  one non-claude adapter is picked in a run.

### Why deferred beats fixing now
- **Trigger unfired**: "two non-claude adapters into the same target." No such install
  exists (this repo dogfoods claude-code, whose block is `CLAUDE.md.block`, a *separate*
  file — no collision with AGENTS.md at all).
- **Blast radius is prose, not function**: even on collision the losing adapter's real
  agent definitions (`.codex/agents/*.toml`, `.agents/agents/*`) are still installed
  correctly by their own install branches. Only the AGENTS.md *instructions* point at
  slightly-wrong paths. Hard rules + routing (the load-bearing 80%) are identical.
- **Both candidate fixes cost more than the wait:**
  - Per-adapter markers (`flywheel:begin:codex` …) → 2–3 near-duplicate blocks
    coexisting in one AGENTS.md = adding ~80%-duplicated bloat to solve a problem nobody
    has. Anti-ponytail.
  - Unify into one adapter-neutral block → loses the exact-path precision that helps a
    fresh subagent spawn correctly. This is the **runner-up** and the right move *if the
    trigger ever fires* (see below), but not worth doing speculatively.

### If the trigger fires (do this then, not now)
Prefer the runner-up: make step 2 adapter-neutral ("spawn subagents via your adapter's
mechanism — see the adapter row in `flywheel/ORCHESTRATION.md`/config") so one block
serves all three, and delete the per-adapter blocks. One block, no duplication, no
marker-suffix machinery. Re-scope as a real task at that point.

---

## i11 — spawns.json write race (hook flock vs coordinator write; fcntl Unix-only)

### What's actually true (investigated)
- `flywheel/resolve-spawn.py:182-191` does a correct read-modify-write **inside**
  `fcntl.flock(f, LOCK_EX)`: open `r+`, lock, read, `json.loads`, append, `seek(0)`,
  `truncate()`, `json.dump`. Any error → caught, `sys.exit(0)` (a hook must never block a
  spawn; `resolve-spawn.py:198-202`).
- The hook is the writer for **every subagent spawn**, including parallel ones.
  ORCHESTRATION.md §6 says independent delegations launch in one message (parallel) → the
  real concurrency is *multiple PostToolUse(Agent) hooks firing near-simultaneously*, and
  that is **exactly** what the `flock` protects. This path is already correct.
- The coordinator's wrapup write (`.claude/skills/wrapup/SKILL.md` step 2) is the only
  *unlocked* writer. But: (1) it is the coordinator editing the file via Edit/Write at
  **end of session**, single-threaded, when no spawns are in flight; (2) `wrapup.sh`
  itself never writes spawns.json content — it only `git add`s it (`wrapup.sh:50`).
- `fcntl` is Unix-only (module-level `import fcntl`, `resolve-spawn.py:23`). On Windows
  the hook would fail to import and simply not log — but there is **no Windows adapter**
  (claude-code/codex/opencode/antigravity all target Unix-like envs here).

### Why deferred beats fixing now
- **Both triggers unfired**: no lost ledger rows observed; no Windows support on the
  roadmap.
- **The design is already correct for the concurrency that actually happens.** The race
  the issue names (hook vs coordinator whole-file Write) requires a subagent spawn to
  complete during the exact read→write gap of an end-of-session manual edit — a window
  that is essentially never open, because spawning is done, not starting, at wrapup.
- A code fix (route the wrapup write through the same flock helper) means extracting a
  shared locked-append function and making the LLM call it instead of Edit — real code
  and a new call path, to close a window nobody has fallen through.

### If a trigger fires (do this then, not now)
- **Lost rows observed** → cheapest real fix is a **one-line doc note** in
  `.claude/skills/wrapup/SKILL.md` step 2: "re-read spawns.json immediately before
  editing — the spawn hook may have appended since your last read." Zero code. This is the
  **runner-up**; deferred only because there is no evidence the window is being hit.
- **Windows support added** → guard the import:
  `try: import fcntl / except ImportError: fcntl = None` and no-op the lock (or use
  `msvcrt.locking`). Trivial, but pointless without a Windows target.

---

## Found
- i9/i11 are debt/P3, open, triggers unfired — `flywheel/state/issues.json` (i9, i11
  objects; `detail` fields state the triggers).
- Single marker pair, replace-between-markers wiring — `install.sh:67,76-77` (py),
  `88,96-97` (node).
- Deterministic one-block collision handling with a printed note —
  `install.sh:293-306`.
- The three AGENTS.md blocks differ only in spawn mechanics/paths/skill-locations/
  auditor-naming — `diff adapters/codex/AGENTS.md.block adapters/{opencode,antigravity}/AGENTS.md.block`
  (both return hunks; shell + HR1–HR4 identical).
- claude-code uses a separate `CLAUDE.md.block`, so it never collides on AGENTS.md —
  `adapters/claude-code/CLAUDE.md.block`, `install.sh` claude branch.
- Hook does locked read-modify-write; parallel spawns are the real concurrency and are
  covered — `flywheel/resolve-spawn.py:182-191`, ORCHESTRATION.md §6.
- Hook fails safe (exit 0 on any error) — `flywheel/resolve-spawn.py:198-202`.
- wrapup writes spawns.json via LLM Edit at end of session; `wrapup.sh` only `git add`s
  it — `.claude/skills/wrapup/SKILL.md` step 2, `wrapup.sh:50`.
- `import fcntl` is module-level (Unix-only) — `flywheel/resolve-spawn.py:23`.

## Assumed
- No Windows adapter is planned near-term (i11's second trigger). Basis: all four current
  adapters target Unix-like envs; not verified against `docs/research/strategy-2026-07.md`
  line-by-line — if that doc commits to Windows, re-rank i11 to (a) with the import-guard.
- No subagent spawns fire during the coordinator's end-of-session wrapup edit. Basis: the
  session protocol runs wrapup as the terminal step after work is done; not enforced by
  code.

## Could not find
- No evidence of any actual lost spawns.json row (git history / issue notes) — consistent
  with i11's "lost rows observed" trigger being unfired.
- No existing install of two non-claude adapters into one target — consistent with i9's
  trigger being unfired.

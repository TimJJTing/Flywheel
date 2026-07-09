# Plan — full codex adapter + dogfooding flywheel under codex

**Status:** draft (strategist). Not yet auditor-approved. Depends on the research in
`docs/research/codex-hooks.md` (Revision 2, 2026-07-08), which is doc-verified but not
live-verified against a running codex CLI session. Every "Pending verification" here
is discharged by Part C (the human runs it once codex CLI is installed).

## 0. What already exists (drafted this session)

Adapter source (mirrors `adapters/claude-code/`), all `# flywheel-managed`:
- `adapters/codex/agents/{architect,researcher,engineer,utility,verifier,plan-auditor}.toml`
  — 6 custom-subagent TOMLs. `name` matches `resolve-spawn.py`'s `TIER_MAP` keys so the
  same resolver works. `model` / `model_reasoning_effort` pinned from config.json codex.
- `adapters/codex/hooks.json.merge` — `SubagentStop` hook → `python3 flywheel/resolve-spawn.py codex`.
- `adapters/codex/skills/{delegate,wrapup,improve}/SKILL.md` — ported skills.
- `adapters/codex/AGENTS.md.block` — rewritten to full-subagent mode.

What is NOT done and is Part A below: `install.sh` does not yet copy codex agents/skills
or merge the hooks file (it only wires `AGENTS.md.block`); `resolve-spawn.py` has no
codex branch; `check.sh` has no codex agent cross-check.

## 1. Facts this plan relies on (source: docs/research/codex-hooks.md Rev 2)

- Custom agents: TOML in `.codex/agents/*.toml`; required `name`/`description`/`developer_instructions`; optional `model`/`model_reasoning_effort` (per-agent).
- Skills: `SKILL.md` (frontmatter `name`,`description`) under `.codex/skills/<name>/`.
- Hooks: `.codex/hooks.json`, top key `"hooks"` → EventName → `[{matcher, hooks:[{type,command,timeout}]}]`.
- `SubagentStop` payload (top-level): `agent_id`, `agent_type`, `model` (= **parent**'s model, not the subagent's), `session_id`, `cwd`, `hook_event_name`, `turn_id`, `last_assistant_message`, `stop_hook_active`.
- Effort levels valid: `minimal|low|medium|high|xhigh`.
- Codex spawns a subagent only when explicitly asked.

Model/level values (from `flywheel/config.json` `tiers.<t>.adapters.codex`, do not restate from memory):
architect `gpt-5.5-pro`/`xhigh`; researcher(strategist) `gpt-5.5`/`high`; engineer `gpt-5.5`/`high`; utility `gpt-5.4-mini`/`high`; verifier `gpt-5.5`/`high`; plan-auditor(auditor) `gpt-5.5`/`high`.

---

## Part A — engineer work to make the codex adapter installable

### A1. Wire codex agents/skills/hooks in `install.sh`

**File:** `install.sh`, inside the `if [ "$DO_CODEX" = 1 ] || [ "$DO_OPENCODE" = 1 ]` /
codex branch region (after the shared `AGENTS.md` wiring at ~line 182). Add a
codex-only block that mirrors the claude-code agent/skill copy (lines 190-200) plus a
hooks merge:

```bash
if [ "$DO_CODEX" = 1 ]; then
  mkdir -p "$TARGET/.codex/agents"
  for af in "$ADAPTERS_DIR"/codex/agents/*.toml; do
    [ -e "$af" ] || continue
    copy_managed_if_ok "$af" "$TARGET/.codex/agents/$(basename "$af")"
  done
  for sd in "$ADAPTERS_DIR"/codex/skills/*/; do
    [ -d "$sd" ] || continue
    copy_managed_if_ok "$sd/SKILL.md" "$TARGET/.codex/skills/$(basename "$sd")/SKILL.md"
  done
  # hooks.json: create if absent; if present and not flywheel-managed, JSON-merge the
  # SubagentStop entry (reuse the opencode.json merge helper pattern, keyed by event).
  # Simplest correct v1: copy_managed_if_ok if the file is absent/managed; a full
  # deep-merge is only needed once real repos ship their own hooks.json.
  copy_managed_if_ok "$ADAPTERS_DIR/codex/hooks.json.merge" "$TARGET/.codex/hooks.json"
fi
```

Note: `copy_managed_if_ok` keys "managed" off the string `flywheel-managed`. TOML and
SKILL.md carry it in a comment/HTML-comment. **`hooks.json` is strict JSON and cannot
carry that marker** — so `copy_managed_if_ok` will always treat an existing hooks.json
as unmanaged and skip it. Acceptable v1 (first install writes it; re-install leaves the
user's file alone). If idempotent upgrade of hooks.json is wanted later, add a JSON
deep-merge like the `opencode.json` path (install.sh lines 219-263) keyed by event name;
that is a follow-up, not required for dogfooding — mark it `ponytail: add when a repo
ships its own hooks.json`.

**Acceptance:** installing with `--adapters codex` into a scratch repo creates
`.codex/agents/*.toml` (6), `.codex/skills/*/SKILL.md` (3), `.codex/hooks.json` (1), and
`AGENTS.md` with the flywheel block.
**Verify:**
```bash
tmp=$(mktemp -d); git -C "$tmp" init -q
./install.sh "$tmp" --adapters codex >/dev/null
ls "$tmp"/.codex/agents/*.toml | wc -l   # expect 6
ls "$tmp"/.codex/skills/*/SKILL.md | wc -l # expect 3
test -f "$tmp"/.codex/hooks.json && grep -q flywheel:begin "$tmp"/AGENTS.md && echo OK
```

### A2. Add a codex branch to `flywheel/resolve-spawn.py`

**File:** `flywheel/resolve-spawn.py`. The claude-code path reads
`tool_input.subagent_type` + `tool_response.resolvedModel`. The codex `SubagentStop`
payload is shaped differently and its `model` is the **parent's**, so it must be ignored.
Add an adapter selector as `sys.argv[1]` (default `"claude-code"` — the existing
`settings.json.merge` command passes no arg, so behavior is unchanged).

Exact change to `main()`:
- `adapter = sys.argv[1] if len(sys.argv) > 1 else "claude-code"`.
- **Branches per-adapter** (must NOT run unmodified against the other adapter's
  payload shape): everything that reads the payload and derives the row's
  `subagent_type`/`model`/`level`/`task`/`notes`/`adapter` fields. Split into
  `build_row_claude_code(payload, cwd)` / `build_row_codex(payload, cwd)`:
  - **claude-code branch** (existing logic, preserved as-is): reads
    `tool_input.subagent_type` + `tool_response.resolvedModel` (the real resolved
    subagent model — trustworthy, unlike codex's payload `model`). The
    `override_input = tool_input.get("model")` note logic is claude-code-specific
    (codex's payload has no `tool_input`) and stays in this branch only.
  - **codex branch** (new): `subagent_type = payload.get("agent_type") or "unknown"`
    (top-level, not `tool_input` — codex's `SubagentStop` payload has no
    `tool_input`/`tool_response` wrapper). Resolve `config_model`/`config_level` from
    `config["tiers"][tier]["adapters"]["codex"]` (generalize the existing lookup to use
    `adapter` instead of the hard-coded `"claude-code"`). `model = config_model or
    "Pending verification"` — **do NOT** read `payload["model"]` (it is the parent's
    model per the hooks doc, never the subagent's). `task = ""` (the payload has
    `last_assistant_message` = the *result*, not the task; leave `task` for manual
    wrapup fill). `notes = "auto-logged (codex; model from config, payload model is
    parent's)"`. `row["adapter"] = "codex"`.
- **Shared across both branches** (do not duplicate, do not fork): `TIER_MAP`, the
  `cwd`-resolution fallback, the `ts`/`outcome` row fields, the file-locking append to
  `spawns.json`, and exit-0-on-any-error via the top-level `try/except`.

**Acceptance:** feeding a synthetic codex `SubagentStop` payload appends one row with
`adapter:"codex"`, `agent` = the `agent_type`, and `model`/`level` = the config.json
codex values for that tier — never the payload's parent model.
**Verify:**
```bash
echo '{"agent_type":"engineer","model":"gpt-5.5-pro","cwd":"'"$PWD"'","hook_event_name":"SubagentStop"}' \
  | python3 flywheel/resolve-spawn.py codex
python3 -c "import json;r=json.load(open('flywheel/state/spawns.json'))[-1];print(r['adapter'],r['agent'],r['model'],r['level'])"
# expect: codex engineer gpt-5.5 high   (NOT gpt-5.5-pro — parent model ignored)
```
(Run in a scratch checkout or revert the appended test row afterward.)

### A3. Extend `flywheel/check.sh` to cross-check codex agent TOMLs

**File:** `flywheel/check.sh`, insert before the final FAIL-summary block
(check.sh:196) — i.e. between the closing `fi` of the `.claude/agents` frontmatter
check (check.sh:194, the python check itself ends at check.sh:193) and the blank line
that precedes `if [ "$FAIL" -eq 0 ]; then ...` (check.sh:196). Add a parallel block
guarded by `[ -d "$REPO_ROOT/.codex/agents" ]`
that, for each `.codex/agents/<name>.toml`, greps `^model = "..."` and
`^model_reasoning_effort = "..."` and compares to
`config.json tiers.<tier>.adapters.codex` (`model` / `level`), using the same
`{architect,researcher→strategist,engineer,utility,verifier,plan-auditor→auditor}`
mapping. Skip a tier whose config model is `Pending verification` (warn, don't fail).

**Acceptance:** with `.codex/agents/` installed and matching config.json, check.sh
prints `✓ <name>.toml frontmatter matches config.json` for all 6 and exits 0; a
deliberately mismatched model makes it print `✗ …` and exit 1.
**Verify:** `bash flywheel/check.sh` in a repo with `.codex/agents/` present exits 0 and
shows 6 `✓ *.toml` lines; flip one model and confirm exit 1.

---

## Part B — the `.codex/` layout for THIS repo (dogfooding flywheel under codex)

This repo already dogfoods claude-code (`CLAUDE.md` + `.claude/agents/` + `.claude/skills/`).
Dogfooding codex adds a sibling `.codex/` tree and an `AGENTS.md` block. After Part A,
running `./install.sh . --adapters codex` from the repo root produces:

```
AGENTS.md                              # flywheel block (codex full-subagent mode)
.codex/
  agents/
    architect.toml  researcher.toml  engineer.toml
    utility.toml    verifier.toml    plan-auditor.toml
  skills/
    delegate/SKILL.md   wrapup/SKILL.md   improve/SKILL.md
  hooks.json                           # SubagentStop → resolve-spawn.py codex
```

Optional (only if the human wants it; not required):
- `.codex/config.toml` — repo-scoped overrides. Useful keys if needed:
  `agents.max_threads` (default 6 is fine), trust settings so `.codex/config.toml` loads.
  **Skip by default** (ponytail: add when a real limit is hit).

Coexistence notes:
- `CLAUDE.md` and `AGENTS.md` both carry a flywheel block — expected; each adapter reads
  its own file. `check.sh`'s regression guard already loops all three adapters.
- `flywheel/state/*.json`, `flywheel/config.json`, `flywheel/*.md` are shared, adapter-
  neutral — nothing forks. `spawns.json` rows just carry `adapter:"codex"` vs `"claude-code"`.
- `install.sh`'s shared-`AGENTS.md` rule prefers opencode's block when both codex and
  opencode are selected; installing codex alone (as here) uses codex's block. Fine.

---

## Part C — human validation checklist (run once codex CLI is installed)

Per `flywheel/ADAPTERS.md` "test the port": scratch repo, one seed session, confirm
FACTS.md fills and the dashboard builds. Run top-to-bottom; each step has a pass check.

1. **Install codex CLI** and confirm version: `codex --version` prints a version.
   Record it (and the codex config schema date) — it becomes a FACTS.md toolchain row.
2. **Land Part A** (A1-A3 merged) on a branch; `bash flywheel/check.sh` exits 0 in this
   repo (claude-code checks still green; codex checks not yet present until step 4).
3. **Scratch install:** `tmp=$(mktemp -d); git -C "$tmp" init -q; ./install.sh "$tmp"
   --adapters codex`. Confirm the A1 verify block passes (6 agents, 3 skills, hooks.json,
   AGENTS.md block).
4. **Dogfood this repo:** `./install.sh . --adapters codex`; `bash flywheel/check.sh`
   exits 0 and shows 6 `✓ *.toml frontmatter matches config.json` lines (validates A3 +
   that config.json codex models are correct).
5. **Open codex in the scratch repo**, paste `docs/SEED-PROMPT.md`. Confirm the AGENTS.md
   flywheel block loads (codex acknowledges the session protocol / hard rules).
6. **Verify per-agent pinning (discharges the FACTS.md "Per-agent level pinning" +
   "Subagent spawn" Pending rows):** ask codex to spawn the `engineer` agent on a
   trivial task. Confirm via `/agent` (or the thread inspector) that the spawned thread
   runs `gpt-5.5` at `high` — the value from `engineer.toml`, not the parent's model.
   If codex ignores the TOML `model`/`model_reasoning_effort`, STOP: the adapter's
   pinning assumption is wrong — record it in FACTS.md and LESSONS.md and re-plan.
7. **Verify spawn auto-log (discharges A2 end-to-end):** after that spawn ends, check
   the scratch repo's `flywheel/state/spawns.json` has a new row with `adapter:"codex"`,
   `agent:"engineer"`, `model:"gpt-5.5"`, `level:"high"`. If the row is missing, the
   `SubagentStop` hook did not fire — check `.codex/hooks.json` discovery + the matcher.
   **Also explicitly confirm the matcher fires** — pipe-alternation matcher syntax
   (`"architect|researcher|..."`) is unverified against codex's matcher engine, which is
   why v1's `hooks.json.merge` ships a match-all matcher (`".*"`) instead. If this step
   passes, that confirms match-all is sufficient; only add a real per-agent matcher
   later if pipe-alternation is separately verified to work.
8. **FACTS.md fills:** run the seed session's normal flow; confirm `flywheel/FACTS.md`
   toolchain + adapter-capability rows get filled (codex version, "Subagent spawn works"
   → Verified for codex with today's date, "Per-agent level pinning" → Verified).
9. **Dashboard builds:** `python3 flywheel/dashboard/build.py`; open
   `flywheel/dashboard/dashboard.html` — the codex spawn row appears.
10. **Wrapup once:** run the `wrapup` skill in codex; confirm it commits, `check.sh`
    stays green, and the coordinator row was appended by hand (no session-end event).
11. **Record outcomes:** update `flywheel/FACTS.md` §Adapter capabilities (codex rows →
    Verified + date), `docs/research/codex-hooks.md` (flip the last "Pending" row), and
    log any surprise in `flywheel/LESSONS.md`.

**Definition of done:** steps 1-11 pass, FACTS.md codex rows read `Verified` with a live
date, and the dashboard shows a real codex spawn. Until then the codex adapter is
"doc-verified, live-Pending" and must say so in any report.

# Architecture audit — pre-adoption hardening (2026-07-13)

Author: strategist tier. Scope: audit the flywheel installer/adapter machinery for
structural defects and unverified assumptions worth fixing/verifying BEFORE the framework
is installed into a real project (STATUS.md next-action 3). Each issue below is a
standalone, engineer-executable fix plan. No production code was changed by this audit.

Convention: line/file references verified against the working tree on 2026-07-13.
Model names are NOT touched by any plan here (HR2). No file >200 KB was read (HR1).

---

## Ranked issue list (severity × likelihood-at-adoption)

| # | Sev | Likelihood | Issue | Decision | Plan |
|---|-----|-----------|-------|----------|------|
| A | CRITICAL | every install | `resolve-spawn.py` + `sync.py` never copied into target `flywheel/`; all four adapters' hooks call `python3 flywheel/resolve-spawn.py`, which does not exist there | fix-now | Plan 2 |
| B | CRITICAL | every claude-code install | claude-code `settings.json.merge` is authored but **never wired** by install.sh — the primary adapter's spawn-logging hook is inert on every install | fix-now | Plan 3 |
| 1 | HIGH | exact adoption scenario | `install.sh:207` codex `hooks.json` has no JSON deep-merge; an existing unmanaged `hooks.json` is skipped whole, so a repo shipping its own hooks never gets flywheel's (same defect on antigravity `hooks.json`, `install.sh:223`) | fix-now | **Plan 1 (mandated)** |
| D | MEDIUM | every codex uninstall | `uninstall.sh` never removes `.codex/` (agents, skills, hooks.json) — codex adapter is install-only, leaves orphans; JSON hooks merged by Plan 1/3 also need an un-merge path | fix-now | Plan 4 |
| C | MEDIUM | low (multi-non-claude) | Shared `AGENTS.md` allows only ONE block; codex/opencode/antigravity blocks differ materially, so a multi-adapter install feeds one adapter the other's instructions | defer (trigger: two of codex/opencode/antigravity installed together) | §Deferred |
| F | MEDIUM | ongoing maintenance | `build.py`/`build.mjs` (and check.sh, wrapup.sh, resolve-spawn dual paths) have no parity guard — python vs node implementations can silently drift | defer (trigger: any `build.*` edit) | §Deferred |
| G | LOW | rare | `spawns.json` write race: PostToolUse hook `flock`-appends while coordinator replaces the whole file via Write (no lock) — hook row can be clobbered | defer (trigger: observed lost spawn row) | §Deferred |
| H | LOW | opencode/antigravity | check.sh cross-checks model config only for claude-code + codex; opencode.json and antigravity have no config-drift guard | defer (trigger: opencode/antigravity live use) | §Deferred |
| I | LOW | install-from-worktree | install.sh copies `dashboard/.` wholesale, including a built `dashboard.html` carrying flywheel's own project data (regenerated on first wrapup) | defer (cosmetic) | §Deferred |
| J | INFO | needs live session | FACTS.md `Pending verification` rows: per-agent level pinning, opencode spawn-log plugin stub, codex hook events — none statically verifiable | defer (already STATUS next-actions 2 & 4) | §Deferred |

Fix-now: A, B, 1, D (Plans 1–4). Everything else is defer with a stated trigger — none
of the deferred items is statically verifiable now (they need live adapter sessions) or
is low enough impact that a pre-adoption fix is not warranted.

Execution order: Plan 1, then 2 (or 1+2 together), then 3, then 4.

Note on numbering: Issue **1** (codex hooks deep-merge) is the mandated Plan 1 and the
architectural keystone — its reusable JSON deep-merge helper is consumed by Plan 3; Plan 4
reverses Plan 1/3's merges via its own `restore_or_unmerge_json` and relies on the `.flywheel-bak` convention.
Findings A and B are higher raw severity but depend on nothing; do all four before adoption.

---

## Plan 1 (MANDATED) — JSON deep-merge for hook files (codex + antigravity)

**Goal & motivation.** `install.sh:207` (codex) and `install.sh:223` (antigravity) install
`hooks.json` via `copy_managed_if_ok`. Strict JSON cannot carry the `flywheel-managed`
comment marker that helper keys off, so an **existing** `hooks.json` is always skipped —
the exact adoption scenario is a real repo that already ships its own `.codex/hooks.json`,
which then silently never receives flywheel's spawn-logging hook. Fix: mirror the
`opencode.json` merge path (install.sh:243–308) with a reusable JSON deep-merge that
appends flywheel's hook entries without clobbering the user's.

**Files to touch:** `install.sh` only.

**Approach.**
1. Add one shell function `merge_json()` near `wire_block` (after install.sh:105). It
   takes `$1=merge_file $2=dest_file`, requires `$RUNNER`, backs the dest up **once** to
   `$2.flywheel-bak` when dest exists, then runs a python3 (primary) / node (fallback)
   deep-merge with these exact semantics — a single generic merge that fits all three
   hook shapes (codex `.hooks.<event>[]`, antigravity top-level `flywheel-spawn-log`,
   claude-code `.hooks.PostToolUse[]` in Plan 3):
   - dict + dict → recurse key-by-key;
   - list + list → start from dest's list, append each block item **only if** no
     structurally-equal item already present (compare by `json.dumps(sort_keys=True)` /
     `JSON.stringify`), so re-install is idempotent;
   - scalar/type-mismatch → keep dest's value, print `  skip (differs): <path>` to stderr
     (mirrors opencode merge behavior at install.sh:275).
   - Print `merged` / `already-merged` on stdout.
   
   **Caveat (engineer maintenance note):** append-if-absent means a future change to an already-installed hook command ADDS a duplicate rather than replacing it — acceptable for install idempotency; note for maintenance.
2. Replace `install.sh:207`
   `copy_managed_if_ok "$ADAPTERS_DIR/codex/hooks.json.merge" "$TARGET/.codex/hooks.json"`
   with:
   - `if [ ! -f "$TARGET/.codex/hooks.json" ]; then cp` the merge file and echo `created`;
   - `else merge_json "$ADAPTERS_DIR/codex/hooks.json.merge" "$TARGET/.codex/hooks.json"`.
3. Replace `install.sh:223` (antigravity) identically against
   `"$TARGET/.agents/hooks.json"`.
4. Delete the comment block install.sh:202-206 (the whole `# hooks.json is strict JSON …` note).

**Acceptance criteria & per-step verification** (run from repo root; use a scratch target):
```bash
T=$(mktemp -d); git -C "$T" init -q
# 1. fresh install writes flywheel's hook
bash install.sh "$T" --adapters codex >/dev/null
python3 -c "import json;d=json.load(open('$T/.codex/hooks.json'));assert d['hooks']['SubagentStop']" && echo AC1-PASS
# 2. user's pre-existing hook is PRESERVED and flywheel's is ADDED (the adoption scenario)
printf '{\n  \"hooks\": {\n    \"SubagentStop\": [ {\"matcher\": \"mine\", \"hooks\": []} ]\n  }\n}\n' > "$T/.codex/hooks.json"
bash install.sh "$T" --adapters codex >/dev/null
python3 -c "import json;d=json.load(open('$T/.codex/hooks.json'));ms=[x['matcher'] for x in d['hooks']['SubagentStop']];assert 'mine' in ms and '.*' in ms, ms" && echo AC2-PASS
test -f "$T/.codex/hooks.json.flywheel-bak" && echo AC3-backup-PASS
# 3. idempotent: second install adds no duplicate
bash install.sh "$T" --adapters codex >/dev/null
python3 -c "import json;d=json.load(open('$T/.codex/hooks.json'));assert len(d['hooks']['SubagentStop'])==2, len(d['hooks']['SubagentStop'])" && echo AC4-idempotent-PASS
# 4. antigravity path merges the top-level plugin key without clobber
printf '{\n  \"other-plugin\": {\"enabled\": true}\n}\n' > "$T/.agents/hooks.json" 2>/dev/null || (mkdir -p "$T/.agents" && printf '{\n  \"other-plugin\": {\"enabled\": true}\n}\n' > "$T/.agents/hooks.json")
bash install.sh "$T" --adapters antigravity >/dev/null
python3 -c "import json;d=json.load(open('$T/.agents/hooks.json'));assert 'other-plugin' in d and 'flywheel-spawn-log' in d, list(d)" && echo AC5-PASS
rm -rf "$T"
```
All five `*-PASS` lines must print.

---

## Plan 2 (CRITICAL, Finding A) — ship `resolve-spawn.py` and `sync.py` into the target

**Goal & motivation.** All four adapters' spawn-logging hooks call
`python3 flywheel/resolve-spawn.py` (verified: `distribution/adapters/{claude-code/settings.json.merge:4,
codex/hooks.json.merge:7, antigravity/hooks.json.merge:10}`), and check.sh's remediation
line tells the user to `run: python3 flywheel/sync.py`. Neither script is in install.sh's
MANAGED copy loop (`install.sh:125-127`), so **every** install ships hooks that reference a
missing file. The hook fails, but `resolve-spawn.py` exits 0 on any error by design
(resolve-spawn.py:198-202) — except it is never reached, so the failure is invisible:
`spawns.json` silently never gets auto-appended, defeating decision d7 on every adapter.
check.sh has **zero** references to `resolve-spawn.py` (verified), so nothing catches it.

**Files to touch:** `install.sh`, `flywheel/check.sh`.

**Approach.**
1. `install.sh:125-127` — add `resolve-spawn.py sync.py` to the MANAGED file list (these
   are framework-owned scripts → always overwrite, same class as `check.sh`/`wrapup.sh`).
   The loop already `cp -f`s each into `$TARGET/flywheel/` and echoes `managed:`.
2. `flywheel/check.sh` — add a presence guard so this class of omission can never regress
   silently. As a new block after the codex `.toml` frontmatter block (~check.sh:252), before the final `if [ "$FAIL" -eq 0 ]` summary, for each adapter hook file that exists in the target, assert the referenced `flywheel/resolve-spawn.py` exists; fail (`FAIL=1`) if a hook references it but the file is absent. Minimum viable guard: if any of `.codex/hooks.json`, `.agents/hooks.json`, `.claude/settings.json` exists AND references `resolve-spawn.py`, require `flywheel/resolve-spawn.py` present.
   
   **Note:** check.sh edit is a STRUCTURAL change per MAINTENANCE.md §1 — lands via strategist plan + auditor approval on a `flywheel/improve-*` branch (this audit is that approval).

**Acceptance criteria & verification:**
```bash
T=$(mktemp -d); git -C "$T" init -q
bash install.sh "$T" --adapters claude-code,codex,antigravity >/dev/null
test -f "$T/flywheel/resolve-spawn.py" && echo AC1-resolve-shipped-PASS
test -f "$T/flywheel/sync.py"          && echo AC2-sync-shipped-PASS
# the hook the installer wired can actually be executed:
echo '{}' | python3 "$T/flywheel/resolve-spawn.py" codex; echo "exit=$? (must be 0)"
# check.sh regression guard fires when the script is deleted:
rm -f "$T/flywheel/resolve-spawn.py"
( cd "$T" && bash flywheel/check.sh; echo "check exit=$? (must be 1)" )
rm -rf "$T"
```
AC1/AC2 print PASS; the deleted-script check.sh run exits non-zero.

**Note:** Plan 2 makes Plans 1 and 3 actually functional — merging a hook that points at a
missing script is worthless. Do Plan 2 first, or in the same change set.

---

## Plan 3 (CRITICAL, Finding B) — wire claude-code `settings.json` hook on install

**Goal & motivation.** `distribution/adapters/claude-code/settings.json.merge` defines the
`PostToolUse`/`Agent` hook that auto-logs spawns (decision d7). `grep settings.json
install.sh` returns nothing — the claude-code block (`install.sh:226-241`) wires CLAUDE.md
and copies agents/skills but **never installs the hook**. So the primary, default adapter
(`--adapters` default is `claude-code`, install.sh:23) never gets spawn auto-logging, while
codex and antigravity do. This is the highest-traffic adapter; the gap hits nearly every
real install.

**Files to touch:** `install.sh` only (depends on Plan 1's `merge_json`).

**Approach.**
1. Inside the `if [ "$DO_CLAUDE" = 1 ]` block (after the skills loop, ~install.sh:240), add:
   - `mkdir -p "$TARGET/.claude"`;
   - if `$TARGET/.claude/settings.json` absent → `cp -f
     "$ADAPTERS_DIR/claude-code/settings.json.merge" "$TARGET/.claude/settings.json"`,
     echo `created: .claude/settings.json`;
   - else → `merge_json "$ADAPTERS_DIR/claude-code/settings.json.merge"
     "$TARGET/.claude/settings.json"` (deep-merge appends the `PostToolUse[Agent]` hook
     into any user-existing settings.json without clobbering their other keys/hooks).
2. `.claude/settings.json` is user-config, not framework-managed — the deep-merge +
   `.flywheel-bak` model (Plan 1) is exactly right here; do NOT use `copy_managed_if_ok`.

**Acceptance criteria & verification:**
```bash
T=$(mktemp -d); git -C "$T" init -q
# fresh: hook installed
bash install.sh "$T" --adapters claude-code >/dev/null
python3 -c "import json;d=json.load(open('$T/.claude/settings.json'));h=d['hooks']['PostToolUse'];assert any('resolve-spawn.py' in x['hooks'][0]['command'] for x in h)" && echo AC1-PASS
# pre-existing user settings preserved + hook added
printf '{\n  \"permissions\": {\"allow\": [\"Bash\"]},\n  \"hooks\": {\"PreToolUse\": []}\n}\n' > "$T/.claude/settings.json"
bash install.sh "$T" --adapters claude-code >/dev/null
python3 -c "import json;d=json.load(open('$T/.claude/settings.json'));assert 'permissions' in d and d['hooks'].get('PostToolUse')" && echo AC2-PASS
test -f "$T/.claude/settings.json.flywheel-bak" && echo AC3-PASS
rm -rf "$T"
```

---

## Plan 4 (MEDIUM, Finding D) — uninstall parity for `.codex/` and merged JSON hooks

**Goal & motivation.** `grep -n codex uninstall.sh` returns nothing: uninstall removes
`.claude/agents`, `.claude/skills`, and `.agents/*` (uninstall.sh:126-177) but **never
touches `.codex/`** — codex agents, skills, and hooks.json are orphaned forever after
uninstall. Additionally, once Plans 1/3 deep-merge into existing `hooks.json` /
`settings.json`, uninstall must reverse the merge (restore `.flywheel-bak`, else remove
flywheel's injected entries) to be a true inverse; today `.claude/settings.json` and
`.codex/hooks.json` have no un-wire path at all.

**Files to touch:** `uninstall.sh` only.

**Approach.**
1. Add a `.codex/` removal block mirroring the existing `.agents/` block (uninstall.sh:150-177):
   - remove flywheel-managed `.codex/agents/*.toml` (guard by `grep -q 'flywheel-managed'`),
   - remove flywheel-managed `.codex/skills/*/SKILL.md`,
   - handle `.codex/hooks.json` per step 3, `rmdir` empty dirs.
2. Add a `restore_or_unmerge_json()` helper: if `$1.flywheel-bak` exists →
   `mv -f` it back over `$1` (mirrors opencode restore at uninstall.sh:180-182); else run
   a python3/node pass that removes exactly the entries flywheel added (match by the
   `resolve-spawn.py` command string / the `flywheel-spawn-log` key), and delete the file
   if it becomes empty (`{}`  or `{"hooks":{}}`).
3. Apply `restore_or_unmerge_json` to `.codex/hooks.json`, `.agents/hooks.json`
   (replacing the unconditional `rm` at uninstall.sh:173-176), and `.claude/settings.json`.

**Acceptance criteria & verification:**
```bash
T=$(mktemp -d); git -C "$T" init -q
bash install.sh "$T" --adapters claude-code,codex >/dev/null
# seed a user hook so we can prove uninstall preserves it
printf '{\n  \"hooks\": {\"SubagentStop\": [{\"matcher\":\"mine\",\"hooks\":[]}]}\n}\n' > "$T/.codex/hooks.json"
bash install.sh "$T" --adapters codex >/dev/null       # merges flywheel entry in
bash uninstall.sh "$T" --yes >/dev/null
test ! -d "$T/.codex/agents" && echo AC1-codex-agents-removed-PASS
python3 -c "import json,os;p='$T/.codex/hooks.json';d=json.load(open(p)) if os.path.exists(p) else {};ms=[x['matcher'] for x in d.get('hooks',{}).get('SubagentStop',[])];assert 'mine' in ms and '.*' not in ms, ms" && echo AC2-user-hook-kept-flywheel-removed-PASS
test ! -d "$T/flywheel" && echo AC3-PASS
# test .agents/hooks.json uninstall: user key kept, flywheel-spawn-log removed
T=$(mktemp -d); git -C "$T" init -q
bash install.sh "$T" --adapters antigravity >/dev/null
printf '{\n  \"other-plugin\": {\"enabled\": true}\n}\n' > "$T/.agents/hooks.json"
bash install.sh "$T" --adapters antigravity >/dev/null
bash uninstall.sh "$T" --yes >/dev/null
python3 -c "import json,os;p='$T/.agents/hooks.json';d=json.load(open(p)) if os.path.exists(p) else {};assert 'other-plugin' in d and 'flywheel-spawn-log' not in d, list(d)" && echo AC4-agents-user-kept-flywheel-removed-PASS
rm -rf "$T"
# test .claude/settings.json uninstall: user permissions/PreToolUse kept, flywheel PostToolUse removed
T=$(mktemp -d); git -C "$T" init -q
bash install.sh "$T" --adapters claude-code >/dev/null
printf '{\n  \"permissions\": {\"allow\": [\"Bash\"]},\n  \"hooks\": {\"PreToolUse\": []}\n}\n' > "$T/.claude/settings.json"
bash install.sh "$T" --adapters claude-code >/dev/null
bash uninstall.sh "$T" --yes >/dev/null
python3 -c "import json,os;p='$T/.claude/settings.json';d=json.load(open(p)) if os.path.exists(p) else {};assert 'permissions' in d and d['hooks'].get('PreToolUse') is not None and 'PostToolUse' not in d.get('hooks',{}), list(d.get('hooks',{}))" && echo AC5-claude-settings-user-kept-flywheel-removed-PASS
rm -rf "$T"
```

---

## Deferred issues (with triggers)

- **C — AGENTS.md single-block collision.** `AGENTS.md` is genuinely shared by codex,
  opencode, antigravity (install.sh:176-190 picks ONE block: opencode > codex >
  antigravity). Verified the three blocks differ materially (tier-spawn mechanics + skill
  whitelist + HR3 wording). A repo running two of these adapters gets one adapter fed the
  other's instructions. **Defer** — single-adapter is the norm; installer already prints a
  `note:`. **Trigger to fix:** first real install selecting two of {codex, opencode,
  antigravity} together → redesign the shared block to be adapter-neutral or emit
  per-adapter sub-sections.

- **F — build.py / build.mjs (and check.sh, wrapup.sh, resolve-spawn) dual-runtime drift.**
  Every python3 path has a hand-maintained node fallback with no parity test. **Defer** —
  no drift observed yet. **Trigger:** any edit to a `build.*` / dual-path block → manually
  run both and diff: `python3 flywheel/dashboard/build.py; cp flywheel/dashboard/dashboard.html /tmp/py.html; node flywheel/dashboard/build.mjs; diff /tmp/py.html flywheel/dashboard/dashboard.html`
  (note: exact byte-equality may fail on JSON formatting — compare rendered structure, not bytes).

- **G — spawns.json write race.** resolve-spawn.py appends under `fcntl.flock`
  (resolve-spawn.py:182-191), but the coordinator edits spawns.json at wrapup via a
  whole-file Write with no lock; a hook firing between the coordinator's read and write
  loses its row. **Defer** — low concurrency in practice. **Trigger:** an observed missing
  spawn row. Also note: `fcntl` is Unix-only → spawn logging is silently disabled on
  native Windows (hook excepts, exits 0). Flywheel targets Unix; document, don't fix.

- **H — config-drift guard only covers claude-code + codex.** check.sh validates
  `.claude/agents/*.md` and `.codex/agents/*.toml` against config.json but not
  `opencode.json` agent model strings (only sync.py writes them) or antigravity (no
  per-agent model file exists). **Defer.** **Trigger:** first opencode/antigravity live use
  → add an opencode.json vs config.json cross-check to check.sh.

- **I — dashboard.html data leak on install.** install.sh:133-136 copies `dashboard/.`
  wholesale; a locally-built `dashboard.html` (gitignored, so absent from a clean clone but
  present in a working tree) carries flywheel's own project data into the target until the
  first wrapup regenerates it. **Defer** — cosmetic, self-healing. **Trigger:** never, unless
  a screenshot of a fresh install shows flywheel's data.

- **J — FACTS.md `Pending verification` rows.** per-agent level pinning (native
  effort/reasoning key), the now-deleted OpenCode spawn-log prototype (an explicit,
  un-wired sketch), codex SubagentStop payload shape. None are statically
  verifiable — all require a live adapter session. **Defer** — already tracked as STATUS.md
  next-actions 2 & 4. **Trigger:** an `agy` / `codex` / `opencode` session becomes available.

---

## Found (evidence)

- **A** — `grep -n 'sync.py\|resolve-spawn' install.sh` → both `NOT COPIED`; MANAGED loop
  is `install.sh:125-127` (no resolve-spawn.py/sync.py). All four hooks call
  `python3 flywheel/resolve-spawn.py` (distribution/adapters/*/settings|hooks: verified lines). check.sh
  has 0 references to resolve-spawn.py.
- **B** — `grep -n settings.json install.sh` → `NONE`; claude-code block install.sh:226-241
  copies agents/skills only; `distribution/adapters/claude-code/settings.json.merge:4` is the unwired hook.
- **1** — `install.sh:202-207` codex hooks installed via `copy_managed_if_ok` (no JSON
  merge); antigravity same at `install.sh:223`. opencode has a real merge (install.sh:243-308)
  as the template to mirror.
- **D** — `grep -n codex uninstall.sh` → `NONE`; `grep -n settings.json uninstall.sh` → `NONE`.
  `.agents/` cleanup exists (uninstall.sh:150-177); `.codex/` has none.
- **C** — `diff distribution/adapters/{opencode,codex,antigravity}/AGENTS.md.block` → material differences
  in tier-spawn mechanics, skill whitelist, HR3 wording (output captured).
- **H** — check.sh:160-252 checks claude-code `.md` + codex `.toml` only; no opencode/antigravity.
- **G** — resolve-spawn.py:182-191 `fcntl.flock` append; wrapup.sh has no lock; `fcntl` import
  is Unix-only.
- **I** — install.sh:133-136 `cp -Rf dashboard/.`; `.gitignore` lists `flywheel/dashboard/dashboard.html`.
- Portability POSITIVE: `grep -nE 'sed -i|stat -|readlink -f|mapfile|declare -A|realpath'`
  over install/uninstall/check/wrapup → none. Only bashism is `read -ra … <<<`
  (install.sh:168), fine under bash 3.2 (macOS) with the `#!/usr/bin/env bash` shebang.
- distribution/defaults/flywheel/config.json ships all-`Pending verification` cells (correct for a fresh project;
  seed prompt fills them) — not a defect.

## Assumed

- opencode.json merge (install.sh:243-308) is a correct, tested reference to mirror for the
  JSON deep-merge — assumed from its structure + the existing `.flywheel-bak` round-trip in
  uninstall.sh:180-224; not re-executed in this audit.
- codex `SubagentStop` and antigravity `invoke_subagent` hook events fire as the merge files
  assume — assumed from `docs/flywheel/research/codex-hooks.md` and FACTS.md; not live-verified (that
  is finding J, deferred).
- A generic dict-recurse / list-append-if-absent deep-merge is sufficient for all three hook
  shapes — assumed from inspecting the three `.merge` files (codex `.hooks.<event>[]`,
  antigravity top-level plugin key, claude-code `.hooks.PostToolUse[]`); an engineer should
  confirm no shape needs key-level replace semantics.

## Could not find

- Any test/CI harness exercising install.sh/uninstall.sh end-to-end (no tests/ dir for the
  installer found) — the fix plans therefore ship their own inline verification blocks.
- A live adapter session (codex/opencode/antigravity) to verify the hook payload shapes —
  none available this session; those items are deferred, not resolved.
- Any existing guard that would catch A or B before adoption — check.sh does not, so Plan 2
  adds one.

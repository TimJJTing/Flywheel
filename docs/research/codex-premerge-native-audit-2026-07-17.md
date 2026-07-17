# Codex pre-merge native audit — 2026-07-17

## Recommendation

**Simplify, then merge.** Do not replace the `SubagentStop` design or the git-root
hook command. Current Codex documentation explicitly says hook commands run at the
session `cwd`, recommends resolving repo-local hooks from the git root, and shows the
same `$(git rev-parse --show-toplevel)` command shape used by this branch
([Hooks, lines 877–895](https://learn.chatgpt.com/docs/hooks)). The local CLI schema
also exposes no hook-handler working-directory field.

Before merge, remove dogfood-only Codex migration compatibility and the no-op
all-match matcher. Run the temporary adapter-scope checker once against the actual
merge base, record the result, then delete it instead of maintaining a permanent gate.
The claimed functional repair is otherwise realized.

## Scope evidence

`git diff --name-only main...HEAD` reported 30 changed paths, including the actual
behavioral surface:

```text
.codex/hooks.json
adapters/codex/hooks.json.merge
flywheel/resolve-spawn.py
flywheel/wrapup.sh
install.sh
uninstall.sh
tests/test_adapter_lifecycle.sh
tests/test_codex_adapter_repair_spec.py
tests/test_resolve_spawn.py
```

The complete command was `git diff --name-only main...HEAD`; the remaining paths are
docs, adapter skill mirrors, and state/bookkeeping files. `rg` found no caller of the
temporary scope checker; only the prior evidence document recorded a manual run.

## Codex-native decisions

| Mechanism | Decision | Evidence and rationale |
|---|---|---|
| Project `SubagentStop` command hook | **Keep** | This is Codex's native lifecycle surface. Official docs list `SubagentStop` as turn-scoped and project hooks at `<repo>/.codex/hooks.json` ([Hooks, lines 766–789](https://learn.chatgpt.com/docs/hooks)). |
| `python3 "$(git rev-parse --show-toplevel)/flywheel/resolve-spawn.py" codex` | **Keep** | Official docs: commands run at session `cwd`; repo-local hooks should resolve from git root because Codex may start in a subdirectory, and the examples use the same command substitution ([Hooks, lines 877–903](https://learn.chatgpt.com/docs/hooks)). Local `codex app-server generate-json-schema --experimental` shows command handlers have `command`, `commandWindows`, `statusMessage`, `timeoutSec`, and `async`, but no handler `cwd`/`working_directory`. |
| Resolver uses installed script realpath as Codex root | **Keep** | `flywheel/resolve-spawn.py:300-307` makes the installed adapter location authoritative for config/ledger while retaining payload `cwd` for Claude/Agy. This is required after the native command locates the script from a nested session. `test_nested_payload_cwd_uses_installed_resolver_root` passes. |
| Transcript recovery when `agent_type:"default"` | **Keep with explicit instability limit** | Current live CLI behavior requires it; `flywheel/FACTS.md` and the saved dogfood run show CLI 0.144.5 reports `default` while first `session_meta` exposes `/root/<role>`. However, official docs warn the transcript format is not stable ([Hooks, lines 983–1000](https://learn.chatgpt.com/docs/hooks)). No stable hook field for the configured custom agent was found. |
| `matcher: ".*"` on `SubagentStop` | **Simplify/remove** | It filters nothing. Official docs allow `"*"`, `""`, or omitted matcher to match all ([Hooks, lines 956–970](https://learn.chatgpt.com/docs/hooks)). Omission is the least code and avoids implying role filtering. |
| Convert Flywheel into a Codex plugin to use `PLUGIN_ROOT` | **Do not replace now** | Plugin hooks do receive `PLUGIN_ROOT`, but that points to the installed plugin, while this resolver/config/ledger are intentionally repo-installed. A plugin conversion changes installation and state ownership rather than merely improving root resolution ([Hooks, lines 939–955](https://learn.chatgpt.com/docs/hooks)). |

Local CLI/manual probes:

```text
$ codex --version
codex-cli 0.144.5

$ codex app-server generate-json-schema --experimental --out <tmp>
# ConfiguredHookHandler command properties:
async, command, commandWindows, statusMessage, timeoutSec, type
# no hook-handler working_directory property
```

## Confirmed removable, uncertain, and retained paths

### Confirmed removals applied

1. **Legacy relative Codex hook migration** — removed from `install.sh`; it existed
   only for pre-branch installations, and Codex has no users beyond dogfooding.
2. **Legacy Codex exact-command cleanup** — removed from the Python/Node uninstall
   command sets and lifecycle assertions.
3. **Legacy migration tests** — removed; the retained sibling-handler test now uses
   the current git-root command.
4. **No-op matcher** — removed from `.codex/hooks.json` and
   `adapters/codex/hooks.json.merge`.

### One-time scope audit

The temporary checker defaulted `BASE` to `HEAD`. On a clean committed branch,
`git diff HEAD -- <protected paths>` cannot detect protected files changed by the
branch. It was therefore run once with the actual merge base before deletion:

```text
base=$(git merge-base main HEAD)
# checker invoked with "$base"
PASS adapter isolation path scope
```

This result is historical evidence, not a future command gate. The checker had no
caller and was deleted after the meaningful run.

### Uncertain; do not remove without a fresh live probe

- `session_meta.payload.source.subagent.thread_spawn.agent_path` versus top-level
  `session_meta.payload.agent_path`: CLI 0.144.5 emitted both. Neither is documented
  as stable, so dual-shape handling is compatibility-like but not confirmed legacy.
- The transcript security checks (`O_NOFOLLOW`, same-directory identity, bounded
  first row) are not no-ops; they constrain an unstable external file path and have
  adversarial tests.
- `agent_type:"unknown"` recovery and safe `Pending verification` fallback are live
  failure behavior, not user-version compatibility.

## Claimed feature matrix

| Claim | Implementation path | Executable proof this session | Verdict |
|---|---|---|---|
| Nested-cwd Codex logging reaches repo config/ledger | Native command in `.codex/hooks.json` and adapter merge; `resolve-spawn.py:303-307` | Unit suite includes `test_nested_payload_cwd_uses_installed_resolver_root`; `python3 -m unittest ...` → `Ran 30 tests`, `OK`. Prior live nested dogfood produced two correct terminal rows. | **Realized** |
| Custom role recovered when stop payload says `default` | `codex_agent_from_transcript`, called at `resolve-spawn.py:220-224` | Six-role, captured-payload, malformed, FIFO, symlink, traversal, bounded-row tests all passed in the 30-test run; prior live run recovered utility/verifier. | **Realized, unstable-input limitation documented** |
| Codex rows are terminal, ID-free, config-pin based | `build_row_codex:225-246`; common terminal row at `313-323` | `test_codex_rows_ignore_agent_and_session_identifiers` and complete row assertions passed; live evidence has eight fields and no IDs. | **Realized** |
| Handler-level uninstall preserves sibling user hooks | Recursive exact-handler cleaner in `uninstall.sh:203-330` | `bash tests/test_adapter_lifecycle.sh` → Python PASS, Node PASS, sync/drift PASS, matrix PASS; targeted backup/sibling test passed. | **Realized** |
| Wrapup rejects staged implementation paths | `flywheel/wrapup.sh:10-30` | `WrapupAllowlistSpec` passed in 30-test run. | **Realized** |
| Claude/Agy adapter behavior unchanged | Codex-only root branch at `resolve-spawn.py:307`; shared cleaner; no protected asset diff | Complete Claude rows and Agy ordering/truncation/fallback goldens passed; lifecycle install/reinstall/uninstall pairs and all-adapter matrices passed in both runners. | **Deterministically realized; no fresh live adapter session** |
| Claude/Agy protected assets unchanged | One-time merge-base diff audit | Returned `PASS adapter isolation path scope` before its temporary checker was deleted. | **Realized as pre-merge evidence, not a permanent feature** |

## Claude Code and Antigravity impact

The resolver root change is adapter-isolated: Codex uses `installed_root`; Claude and
Agy still use payload `cwd` with the same fallback (`resolve-spawn.py:303-307`). The
branch does not change Claude/Agy agent or hook assets; the one-time merge-base scope
audit passed. Characterization tests freeze Claude
resolved-model overrides, mismatch notes, fallback, unknown agents, stdout, task
truncation, and terminal rows; Agy tests freeze multi-row ordering, truncation,
parent-model precedence, fallback, unknown agents, notes, stdout, and terminal rows.

The only shared behavioral change is uninstall cleanup. The new handler-granular
algorithm is an improvement: it removes exact Flywheel command objects and preserves
sibling handlers rather than deleting the entire matcher group. Both Python and Node
lifecycle runners passed single-adapter, pair, and all-adapter install/reinstall/
uninstall matrices. Remaining regression risk: it recursively recognizes an exact
Flywheel command anywhere in these adapter JSON files, not only below a hook group's
`hooks` list. Existing schemas make collision unlikely, but a path-structured cleaner
would be stricter. No fresh live Claude Code or Agy sessions were run; deterministic
non-regression is the approved proof level in the repair plan.

Commands required before merge after simplification:

```bash
python3 -m unittest tests.test_resolve_spawn tests.test_codex_adapter_repair_spec
bash tests/test_adapter_lifecycle.sh
bash flywheel/check.sh
git diff --check main...HEAD
bash -n install.sh uninstall.sh flywheel/wrapup.sh tests/test_adapter_lifecycle.sh
```

## Simplification applied

1. Removed `matcher: ".*"` from both Codex hook documents; omission is the native
   all-match form.
2. Removed the relative-command migration block and all old-command uninstall sets,
   assertions, fixtures, and tests.
3. Removed the old Codex skill-location migration and cleanup; current shared skills
   remain installed and safely uninstalled through `.agents/skills`.
4. Ran the temporary scope checker against `git merge-base main HEAD`, recorded its
   PASS, and deleted it rather than creating a permanent installation gate.
5. Updated the repair plan and evidence claims to match the simplified behavior.

## Found / Assumed / Could not find

### Found

- Current official Codex docs prescribe the branch's git-root command shape and say
  hooks run at session `cwd`.
- CLI 0.144.5's generated handler schema has no hook working-directory field.
- The 30 unit/spec tests and dual Python/Node lifecycle suites pass.
- Nested-cwd, role recovery, ID-free rows, granular cleanup, and wrapup allowlist have
  implementation plus executable proof.
- Legacy Codex migration/cleanup was isolated by exact command and removed for the
  dogfood-only user base.
- The temporary scope script passed against the merge base, had no gate caller, and
  was deleted after its one-time audit use.

### Assumed

- Removing support for already-installed relative Codex hooks is acceptable because
  the user explicitly states there are no Codex users beyond dogfooding.
- Deterministic characterization remains sufficient for Claude/Agy, as approved by
  the branch plan.

### Could not find

- A stable native `SubagentStop` field that identifies the configured custom agent
  when CLI 0.144.5 reports `agent_type:"default"`.
- A project-hook `working_directory` option or project-root environment variable.
- A native need for a permanent adapter-scope installation gate.
- Fresh live Claude Code or Antigravity execution evidence for this branch.

# Codex adapter repair and full-verification plan

Status: revised after plan-auditor findings; requires an `APPROVED` re-audit before
structural files are edited.

## Decision

Repair the Codex adapter as one user-visible compatibility change, add an automated
install lifecycle suite, then dogfood the same installed artifacts in this repository.
Keep live Codex proof separate from deterministic installer and hook tests: local tests
can prove file layout and payload handling, but only a trusted, authenticated Codex
session can prove discovery, per-agent model pinning, and hook firing.

## Confirmed gaps

1. Current Codex discovers project skills under `.agents/skills`, but `install.sh`
   writes `.codex/skills`; installed skills are invisible.
2. A clean install followed by reinstall creates `.codex/hooks.json.flywheel-bak`
   from Flywheel's own hook. Uninstall restores that backup and leaves a hook pointing
   to the deleted `flywheel/resolve-spawn.py`.
3. Managed `flywheel/ADAPTERS.md` names two repo-only dogfood files that are not in the
   payload, so every installed target gets dangling references.
4. `flywheel/sync.py` says Codex has no projection and cannot update installed
   `.codex/agents/*.toml` after the seed prompt changes config. Clean targets start
   with `Pending verification` config while copied TOMLs contain this repo's pins.
5. `README.md`, `docs/config/ADAPTERS.md`, `docs/config/MODELS.md`, and the old dogfood
   plan still describe Codex as degraded or Part A as unimplemented.
6. This repo has no `.codex/` dogfood projection. Its existing `.agents/skills` are
   Antigravity-specific, so overwriting them with Codex-specific bodies would break
   the other dogfood adapter.

## Implementation

### 1. Correct the installed-user layout and lifecycle

Files: `install.sh`, `uninstall.sh`, `adapters/codex/AGENTS.md.block`.

- Copy Codex skill sources to `.agents/skills/<name>/SKILL.md`; update the Codex
  managed block to name that supported location.
- Migrate an old Flywheel-managed `.codex/skills/<name>/SKILL.md` during reinstall:
  install the supported copy, remove only the legacy file carrying the
  `flywheel-managed` marker, and remove empty legacy directories. Never remove an
  unmanaged legacy file.
- Make JSON ownership explicit with a `.flywheel-created` sidecar. The complete state
  machine is: absent → copy, mark created, snapshot, no backup; marked-created → merge
  without backup and refresh snapshot; valid pre-existing unmarked → back up once,
  merge, snapshot; malformed pre-existing → byte-identical skip with no sidecars;
  legacy unmarked content structurally equal to Flywheel's merge source → mark created
  without backing up Flywheel's own content. If an ambiguous legacy file has user
  additions, preserve it as pre-existing and document that the old Flywheel entry may
  require exact-command unmerge rather than blind restore.
- On uninstall, marked-created files are exact-command unmerged so post-install user
  additions survive; remove empty JSON plus `.flywheel-created`/`.flywheel-merged`.
  Backed-up files restore the pre-install backup, preserve detected post-install edits
  as `.flywheel-uninstalled`, and remove all installer sidecars. Assert zero stale
  sidecars and zero exact Flywheel commands after every uninstall case.
- Make uninstall remove Flywheel-managed shared `.agents/skills` safely and preserve
  unmanaged same-name skills. Retain exact-command JSON unmerge and edit-preservation.
- Update output/comments so the lifecycle and ownership rules are explicit.

### 2. Make Codex projection truly config-driven

Files: `flywheel/sync.py`, `flywheel/check.sh`, `docs/SEED-PROMPT.md`.

- Add Codex TOML projection for local `.codex/agents` and, when present in this source
  repo, `adapters/codex/agents`. Translate config `level` to native
  `model_reasoning_effort`. Skip pending/missing cells without inventing values.
- Change the Codex drift failure hint to `python3 flywheel/sync.py`.
- After seed Step 3 updates config, require `python3 flywheel/sync.py` before Step 4
  live spawns. Explain that pending cells retain the installed template until verified
  and therefore must not be live-spawned as verified pins.
- Add unit coverage that edits a scratch config, runs the installed sync script, and
  asserts all six TOMLs change idempotently while pending cells remain untouched.

### 3. Correct shipped and repo-side documentation

Files: `flywheel/ADAPTERS.md`, `README.md`, `docs/config/ADAPTERS.md`,
`docs/config/MODELS.md`, `docs/plans/codex-adapter-dogfood.md`, `flywheel/FACTS.md`.

- In managed `ADAPTERS.md`, cite the public Codex docs and shipped adapter paths only;
  remove all repo-only dogfood path references.
- Describe Codex as a full custom-subagent adapter. Document `.codex/agents`,
  `.agents/skills`, `model_reasoning_effort`, sync behavior, and the hook trust gate.
- Mark old Part A complete and replace its stale instructions with a pointer to this
  plan and the final verification report.
- Add dated facts from the current official manual without changing existing model
  pins unless a live run verifies replacement values. Required limitations:
  project-local config/hooks load only for trusted projects; non-managed command hooks
  need review/trust; live model availability is account/version dependent; no stable
  hook payload supplies the child's actual model/effort, so spawn rows resolve pins
  from config and prove configuration, not runtime telemetry.

Structural paths in this change are `flywheel/ADAPTERS.md`, `flywheel/check.sh`, and
`adapters/codex/AGENTS.md.block` (adapter block). Apply every existing dirty hunk and
future edit to those paths only after this plan receives `APPROVED`, on a
`flywheel/improve-codex-adapter` branch. Adapter skill bodies require engineer+ under
the approved plan. At autonomy level 3, do not merge that branch without a pending
human decision.

### 4. Dogfood without breaking Antigravity

Files: `.codex/agents/*.toml`, `.codex/hooks.json`, `.agents/skills/*/SKILL.md`,
`adapters/{codex,antigravity}/skills/*/SKILL.md`.

- Install/copy the six Codex agent TOMLs and hook into this repo, then run sync.
- Convert all three Codex and Antigravity source skill pairs to byte-identical,
  adapter-neutral bodies. `delegate` reads the active adapter block and uses the spawn
  mechanism actually surfaced by that runtime (Codex custom subagent tools versus
  Antigravity `invoke_subagent`); `wrapup` describes hook logging without assuming one
  hook path; `improve` remains adapter-neutral. Never detect an adapter by guessing an
  unavailable tool: if neither mechanism is surfaced, use ORCHESTRATION degraded mode.
- Install the same neutral bytes for either adapter. Only remove legacy
  `.codex/skills` after the supported `.agents/skills` copy is confirmed present;
  preserve the legacy managed copy if an unmanaged destination collision prevented
  installation. Test Codex→Antigravity and Antigravity→Codex install orders, each
  reinstall, and uninstall; the shared skill hashes must remain identical.
- Run `check.sh` and the live probe from this repo. Dogfood is not verified merely
  because a scratch install succeeds.

## Automated verification matrix

Create `tests/test_adapter_lifecycle.sh` and `tests/test_resolve_spawn.py` (or one
equivalent hermetic runner) and wire them into `flywheel/check.sh` only if runtime is
acceptable. The suite must use temporary git repositories and assert:

1. Clean Codex install: managed block, six TOMLs, three `.agents/skills`, one valid
   hook; zero `.codex/skills`; no repo-only paths in installed managed docs.
2. Existing valid hook JSON: user hook preserved, Flywheel hook added once, backup and
   post-merge snapshot correct.
3. Existing malformed hook JSON: warning, byte-identical file, no backup/snapshot.
4. Reinstall: byte/idempotency checks, no backup of Flywheel's own first-install file.
5. Uninstall after one and two installs: no Flywheel command remains; pre-existing
   JSON and unmanaged skills restored/preserved.
6. Post-install user edit: `.flywheel-uninstalled` preserves edits and original JSON
   is restored per the documented contract.
7. Legacy `.codex/skills` migration: managed files move/remove; unmanaged files stay.
8. Sync/drift: all six tier mappings, pending skip, mismatch failure, second sync no
   diff.
9. Resolver: each known `agent_type`, unknown type, missing/invalid config, parent
   model ignored, malformed payload exits zero, concurrent writes keep valid JSON.
   Every Codex exit-zero path must emit exactly one valid JSON object on stdout; assert
   stdout, empty/non-sensitive stderr, exit status, and whether the ledger changed.
10. Adapter combinations: Codex alone and Codex with Claude/OpenCode/Antigravity,
    including both Codex/Antigravity installation orders. Their shared skills must be
    byte-identical; AGENTS.md precedence remains a separately documented limitation.
11. Run `bash flywheel/check.sh`, both dashboard builders with parity, shell syntax
    checks, and a clean `git diff --check`.
12. Force both installer runner implementations (Python first and Node with Python
    hidden from `PATH`) through clean, merge, reinstall, malformed JSON, edit
    preservation, and uninstall cases.

Save exact commands and decisive lines to
`docs/research/codex-adapter-verification-2026-07-16.md`.

## Live Codex verification

Using the locally available `codex-cli 0.144.5`, in a temporary installed repo and
then this dogfood repo:

1. Confirm project trust and inspect/trust the hook with `/hooks` (automation may use
   `--dangerously-bypass-hook-trust` only in the isolated vetted scratch repo).
2. Start an authenticated Codex session and explicitly spawn `utility`, `engineer`,
   and `verifier`; capture agent types and reported runtime models/efforts if the UI
   exposes them.
3. Confirm `SubagentStop` appends exactly one valid row per completed agent and does
   not use the parent model from the payload.
4. Invoke `delegate` and `wrapup` through skill discovery from `.agents/skills`.
5. Run the seed prompt through config update, sync, all-tier spawn, check, dashboard,
   and wrapup in a scratch repo if token budget permits. Otherwise mark the unrun
   portion `Unconfirmed, recommended to test live`.

Live authentication, entitlement, model availability, interactive trust state, and UI
model telemetry cannot be established by synthetic tests. Any unavailable proof stays
`Pending verification`; do not convert documented capability into a live-verified
claim.

## Acceptance commands

```bash
bash -n install.sh uninstall.sh flywheel/check.sh tests/test_adapter_lifecycle.sh
bash tests/test_adapter_lifecycle.sh
python3 -m unittest -v tests/test_resolve_spawn.py
bash flywheel/check.sh
python3 flywheel/dashboard/build.py
node flywheel/dashboard/build.mjs
git diff --check HEAD
```

## Found

- The six confirmed gaps above were reproduced by repository inspection and clean
  temporary installs on 2026-07-16.
- Official current Codex documentation supports `.codex/agents`, `.agents/skills`,
  project hooks, and custom per-agent model/reasoning settings.

## Assumed

- Shared skills can be made adapter-neutral without losing required adapter behavior;
  the engineer must stop if the active runtime cannot be detected safely.

## Could not find

- Stable child-runtime model/effort telemetry in `SubagentStop`.
- Proof yet that this account can run every configured model pin or that the local CLI
  has trusted and fired this repo's hook; those require the live phase.

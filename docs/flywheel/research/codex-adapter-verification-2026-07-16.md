# Codex adapter deterministic verification — 2026-07-16

Scope: engineer implementation run on `flywheel/improve-codex-adapter`. This is not
the independent verifier verdict and does not claim authenticated/live Codex proof.

## Deterministic acceptance commands

1. `bash -n install.sh uninstall.sh flywheel/check.sh tests/test_adapter_lifecycle.sh`
   — PASS (exit 0, no output).
2. `bash tests/test_adapter_lifecycle.sh` — PASS:
   `PASS lifecycle ownership/migration/combinations runner=python3`;
   `PASS lifecycle ownership/migration/combinations runner=node`;
   `PASS lifecycle sync/drift all six projections`;
   `PASS adapter lifecycle matrix`.
3. `python3 -m unittest -v tests/test_resolve_spawn.py` — PASS:
   `Ran 10 tests in 0.764s`, `OK`.
4. `bash flywheel/check.sh` — PASS: six
   `*.toml frontmatter matches config.json` lines and `✓ all checks passed`.
   It also emitted a non-failing architecture-review warning because structural
   files changed; the independent wrapup owner decides whether regenerated
   `docs/flywheel/ARCHITECTURE.md` is in scope.
5. `FLYWHEEL_BUILD_TS='1970-01-01T00:00' python3
   flywheel/dashboard/build.py`; save output; then the same timestamp with
   `node flywheel/dashboard/build.mjs`; `cmp -s` — PASS:
   `PASS dashboard builders parity`.
6. `git diff --check HEAD` — PASS (exit 0, no output).
7. `python3 flywheel/sync.py` — PASS: all existing Claude/OpenCode/Codex projections
   reported `unchanged`; all six local and template Codex TOMLs were present.
8. `for s in delegate improve wrapup; do cmp ...; done` across Codex source,
   Antigravity source, and `.agents/skills` — PASS:
   `PASS skill bytes delegate`, `PASS skill bytes improve`,
   `PASS skill bytes wrapup`.

## Automated matrix 1–12 → passing assertions

1. Clean Codex: lifecycle lines 94–106 compare the exact managed block, six TOMLs,
   three `.agents/skills`, one valid hook, zero legacy destination, and scan installed
   `flywheel/ADAPTERS.md` for forbidden repo-only references.
2. Valid existing JSON: lines 135–156 compare original→backup and merged→snapshot
   bytes, preserve `Stop`, add exactly one Flywheel hook, and prove reinstall does not
   refresh the backup.
3. Malformed JSON: lines 182–195 use `cmp` (including trailing bytes), assert the
   warning, and assert no backup/created/merged sidecar.
4. Reinstall: lines 103–107 compare whole managed-tree hashes and assert no backup of
   a Flywheel-created hook.
5. Uninstall: lifecycle covers one/two installs, created-file user additions,
   unrelated sidecar preservation, post-install malformed JSON, no managed sidecars,
   no exact active Flywheel command, and managed/unmanaged shared-skill removal. A
   malformed Flywheel-owned hook that cannot be structurally unmerged is preserved
   byte-for-byte as `.flywheel-uninstalled` and removed from the active adapter path.
6. Post-install edit: lines 146–156 assert original backup restoration and preserved
   `.flywheel-uninstalled` edit bytes.
7. Legacy skill migration/collision: lines 197–209 cover managed migration,
   unmanaged legacy preservation, unmanaged destination preservation, and preservation
   of managed legacy when destination collision prevents a supported copy.
8. Sync/drift: lines 240–278 change all six local/template TOMLs, check model+effort,
   hash the second sync for idempotence, retain a pending cell, and assert mismatch
   failure plus the `python3 flywheel/sync.py` repair hint.
9. Resolver: `tests/test_resolve_spawn.py` covers all six known types,
   unknown, missing/invalid config, missing/invalid ledger, ignored parent model,
   malformed payload, concurrency, live-shaped transcript derivation, bounded/unsafe
   transcript fallbacks, ledger mutation, exact one-object stdout, and empty stderr.
10. Combinations: lifecycle lines 211–235 cover Codex/Antigravity both
    orders and reinstalls, Claude/OpenCode combinations, exact OpenCode AGENTS block
    precedence, uninstall, and byte-identical shared skills.
11. Full checks: deterministic commands 1, 4–6 above prove syntax, check, dashboard
    parity, and whitespace checks.
12. Runner implementations: `exercise_runner python3` and `exercise_runner node`
    execute clean/merge/reinstall/malformed/edit/uninstall scenarios. The Node child
    `PATH` contains only explicit command shims and no Python; the harness uses an
    absolute host Python only for assertions/fixture mutation.

## Acceptance criteria

1. PASS (engineer run): plan sections 1–4 and checkpoint blocker/partial/missing
   items are represented above; matrix 1–12 has a passing assertion.
2. PASS: lifecycle command and four decisive PASS lines above.
3. PASS: resolver command, `Ran 10 tests`, `OK`.
4. PASS: source sync was idempotent; scratch all-six/template/pending/drift assertions
   passed; check printed six matching TOML lines.
5. PASS: shipped docs now describe `.codex/agents`, `.agents/skills`, sync,
   `model_reasoning_effort`, trust/account/telemetry limits; clean-install scan passed.
6. PASS: dogfood has six TOMLs plus `.codex/hooks.json`; all three skill triplets are
   byte-identical.
7. PASS: every deterministic acceptance command above exited zero.
8. PASS: exact commands/decisive lines are saved here; live boundaries are below.
9. PASS: no implementation-changing deviation from the approved plan.

## Per-file implementation summary

- `install.sh:141`: documents conservative JSON ownership; `install.sh:398` installs
  supported shared skills and preserves legacy managed copies on collisions.
- `uninstall.sh:40,151,168,181,496,511`: runner-neutral validation, malformed quarantine,
  backup exact-unmerge, scoped sidecar assertions, and parsed exact-command checks.
- `flywheel/sync.py:38,95,111`: local/template Codex projection and loud missing-key
  failures; pending cells remain untouched.
- `flywheel/resolve-spawn.py:42,45,132`: bounded transcript metadata derivation;
  config-derived child pins remain explicit and parent/runtime telemetry is ignored.
- `flywheel/ADAPTERS.md:39`, `README.md:28`, `docs/config/ADAPTERS.md:18`,
  `docs/config/MODELS.md:20`, `docs/SEED-PROMPT.md:38`: full Codex layout, sync,
  trust, account, and telemetry contracts.
- `flywheel/FACTS.md:50`: dated trust/account/telemetry facts without altering the
  audited GPT-5.6 mappings.
- `docs/flywheel/plans/codex-adapter-dogfood.md:1`: superseded draft now points to the approved
  plan and this report.
- `.codex/agents/*.toml`, `.codex/hooks.json`, `.agents/skills/*/SKILL.md`: dogfood
  projection from installed sources; no installer ownership sidecars retained.
- `tests/test_adapter_lifecycle.sh:85,240` and
  `tests/test_resolve_spawn.py:60`: deterministic ownership/projection and resolver
  regression coverage.

## Deviations and open/live issues

No implementation-changing deviation from the approved plan. Captured live CLI
0.144.5 evidence verifies custom-agent discovery/spawn, `.agents/skills` discovery,
and one `SubagentStop` hook firing. The engineer did not independently run the
authenticated session. Project trust UI inspection, all configured-model account
entitlements, exact live row count after the repair, and child runtime model/effort
telemetry are **Unconfirmed, recommended to test live**. Transcript runtime
model/effort is deliberately not ledger truth; resolver rows prove config pins only.
Independent verifier review and a second live scratch probe are still required.

## Verifier retry: malformed post-install hook

Fresh-verifier reproducer: install Codex, truncate only the final `}` while retaining
`python3 flywheel/resolve-spawn.py codex`, then uninstall. Recovery contract: a
malformed Flywheel-owned/merged JSON document cannot be safely structurally unmerged,
so uninstall copies every byte to `.flywheel-uninstalled`, removes the active JSON
path, and removes `.flywheel-created` / `.flywheel-merged`. Unmanaged malformed JSON
without ownership evidence is left untouched.

- Direct reproducer — PASS: `PASS malformed truncation quarantined; active command
  absent; recovery bytes preserved; sidecars cleared`.
- `bash tests/test_adapter_lifecycle.sh` — PASS: both runner ownership lines,
  `PASS lifecycle sync/drift all six projections`, `PASS adapter lifecycle matrix`.
- `bash -n install.sh uninstall.sh flywheel/check.sh
  tests/test_adapter_lifecycle.sh` and `git diff --check HEAD` — PASS, no output.
- `python3 -m unittest -v tests/test_resolve_spawn.py` — PASS:
  `Ran 6 tests in 0.380s`, `OK`.
- `bash flywheel/check.sh` — PASS: `✓ all checks passed` (same non-failing
  architecture-review warning recorded above).

## Engineer retry 2: safe live `agent_type:"default"` derivation

The resolver now requires absolute, distinct sibling parent/child `.jsonl` entries in
the same descriptor-pinned no-symlink directory. It validates both regular-file
identities, never parses the parent, opens the child nonblocking/no-follow, and reads
one newline-terminated row of at most 128 KiB. Missing platform capabilities and
`NotImplementedError` fail closed. Known payload agent types still skip transcript I/O;
all Codex model/effort values remain config pins and ignore payload/transcript values.

- `PYTHONPYCACHEPREFIX=/tmp/flywheel-pycache python3 -m py_compile
  flywheel/resolve-spawn.py tests/test_resolve_spawn.py` — PASS, exit 0/no output.
- `python3 -m unittest -v tests.test_resolve_spawn.ResolveSpawnTests.
  test_fifo_in_authorized_transcript_directory_never_blocks` — PASS:
  `Ran 1 test in 0.031s`, `OK`; the former pathname-open implementation blocks here.
- `python3 -m unittest -v tests/test_resolve_spawn.py` — PASS:
  `Ran 20 tests in 1.531s`, `OK`, including captured cross-tree utility/config replay,
  sibling authorization, parent-not-parsed, FIFO/device/directory/symlink, bounds,
  malicious paths, capability failures, one-object stdout, and ledger fallback.
- `bash tests/test_adapter_lifecycle.sh` — PASS: both runner ownership lines,
  `PASS lifecycle sync/drift all six projections`, `PASS adapter lifecycle matrix`.
- `bash flywheel/check.sh` — PASS: `✓ dashboard build.py/build.mjs parity: identical
  output` and `✓ all checks passed`; isolated fixed-timestamp Python/Node build plus
  `cmp -s` also exited 0. `git diff --check HEAD` was silent (exit 0).

The raw captured absolute path strings were not retained, so the replay preserves the
recorded relationship and exact metadata shape with isolated paths rather than claiming
those strings. This sandbox denied AF_UNIX socket creation, so that subcase is
permission-probed; all other available non-regular cases ran.

## Final isolated live Codex probe

After reinstalling the finished payload into `/tmp/fw-live2.gy3NLL`, seeding its
Codex tier cells with the audited GPT-5.6 mappings, running `flywheel/sync.py`, and
confirming `flywheel/check.sh` passed, the coordinator ran `codex exec` with
`--dangerously-bypass-hook-trust` only in that vetted isolated repository, as allowed
by the approved plan. The fresh session discovered and completed the three custom
agents, each returning `SAFE_PROBED`. The isolated ledger gained exactly three rows:

- `utility` — `gpt-5.6-luna` / `low`
- `engineer` — `gpt-5.6-terra` / `high`
- `verifier` — `gpt-5.6-sol` / `high`

Each row records that the agent name was derived from transcript `session_meta`, while
model/effort came from config and the parent payload model was ignored. This verifies
custom-agent discovery, `.agents/skills` discovery, hook firing, exact row count, and
config-pin ledger resolution on Codex CLI 0.144.5. Child runtime model/effort telemetry,
account-wide entitlement for all six pins, and interactive trust-UI review remain
**Unconfirmed, recommended to test live**; the isolated bypass is not proof of the
dogfood repository's persisted trust decision.

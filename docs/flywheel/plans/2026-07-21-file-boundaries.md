# Flywheel File-Boundary Reorganization Plan

> Implementation branch: `flywheel/improve-file-boundaries`
>
> Required execution path: engineer implementation, fresh verifier, then wrapup and
> the autonomy-level merge gate.

## Goal

Separate canonical install inputs from Flywheel's own dogfood state and development
tooling. Every Flywheel project, including this repository, must use the same installed
layout while framework-generated documents live under `docs/flywheel/` rather than
mixing with the host project's unqualified documentation.

## Locked ownership model

```text
distribution/
  managed/flywheel/       overwrite-on-upgrade installed core
  defaults/flywheel/      create-once config, facts, status, lessons, state
  adapters/<adapter>/     marker blocks, agent templates, JSON merge inputs
  shared/skills/          canonical shared skills
installer/                lifecycle implementation
dev/
  check.sh                repository/distribution checks
  sync-distribution.py    release-template generation
tests/                    repository-only tests

flywheel/                 installed dogfood core and mutable state
.agents/ .claude/ .codex/ installed dogfood adapter projections
docs/flywheel/            plans, research, generated architecture
```

Keep `install.sh` and `uninstall.sh` as thin root entry points. Retire the old
`adapters/`, `defaults/`, and `scripts/` trees after their contents move. Delete the
unused OpenCode `spawn-log.ts` prototype and its FACTS reference. Product docs,
README, tests, and repository metadata remain in their current top-level locations.

The repository root is a real installation, not a source directory. Canonical changes
are made in `distribution/` and refreshed into the root through the public installer.

## Distribution and projection behavior

1. Recursively copy `distribution/managed/flywheel/` to `flywheel/` on install and
   reinstall. These managed files must be byte-identical in dogfood.
2. Create files from `distribution/defaults/flywheel/` only when absent. Existing
   target config, facts, status, lessons, and state are preserved and checked for
   existence/schema rather than byte parity.
3. Make `distribution/defaults/flywheel/config.json` the release model/config source.
   It contains verified release tier values; its FACTS file carries the dated
   verification. Distribution adapter templates are generated from that pair.
4. Root dogfood config may differ from the release default only at `project_name`,
   `autonomy`, `improve_cadence_sessions`, and `audit_cadence_sessions`. All other
   fields must be semantically equal.
5. Adapter files are projected managed artifacts. Install/reinstall refreshes their
   canonical structure from distribution templates, then projects model, level, and
   provider values from the target's preserved `flywheel/config.json` into Claude,
   Codex, and Flywheel-owned OpenCode fields. Antigravity remains structure-only
   because its agents inherit the parent model.
6. Installed `flywheel/sync.py` updates installed projections only. Repository-only
   `dev/sync-distribution.py` updates distribution templates only; dogfood is then
   refreshed with the installer.
7. Installed `flywheel/check.sh` must not reference repository-only paths.
   `dev/check.sh` runs the installed checks and adds distribution ownership,
   generation, config-divergence, and dogfood-parity checks.
8. Standardize duplicated HR3 wording on the actual spawn name `plan-auditor` in
   INDEX and every managed adapter block. Add a repository check that duplicated hard
   rules remain identical.

## Documentation migration

Move all existing Flywheel artifacts and update every tracked reference:

- `docs/plans/` -> `docs/flywheel/plans/`
- `docs/research/` -> `docs/flywheel/research/`
- `docs/ARCHITECTURE.md` -> `docs/flywheel/ARCHITECTURE.md`

This includes doctrine, delegation templates, adapter prompts, README/product docs,
installer messages, wrapup logic, architecture generation, dashboard links, tests,
and path strings stored in state ledgers.

Generated architecture carries a Flywheel ownership marker. Uninstall removes it only
when marked and never removes plans, research, unrelated documents, or an unmarked
file at the same path. No compatibility shim for old paths is required because the
human confirmed there are no external users.

Preserve the existing core archive contract: before removing `flywheel/`, uninstall
offers to copy non-empty state plus `STATUS.md`, `LESSONS.md`, `FACTS.md`, and
`config.json` into `flywheel-archive/`; `--yes` retains the current automatic archive
behavior. The source-tree move must not weaken this recovery path.

## CLI and dogfood workflow

The single supported forms are:

```text
./install.sh <target> --adapters <list> [--yes]
./install.sh <target> --adapters <list> --check
./uninstall.sh <target> [--yes]
```

`--check` is read-only, performs no confirmation, and is mutually exclusive with
`--yes`. It creates no files, directories, sidecars, generated architecture, or
formatting changes; it prints drift and exits nonzero when the target differs.
Installation fails before its first write if neither Python 3 nor Node is available.

Refresh this repository with:

```sh
./install.sh . --adapters claude-code,codex,antigravity --yes
```

Validate it with the same command using `--check` instead of `--yes`. OpenCode is
validated through clean temporary-target lifecycle tests rather than installed into
the root dogfood combination.

## Test and acceptance plan

1. Preserve the Python/Node clean-install, reinstall, uninstall, backup, malformed-file
   recovery, and multi-adapter lifecycle matrix.
2. Prove reinstall preserves create-once target state while refreshing managed core
   and adapter structure and honoring target config values.
3. Hash the target tree before and after clean and drifting `--check` runs; both must
   prove zero writes, with the drifting run exiting nonzero.
4. Refresh root dogfood and require its `--check`, installed `flywheel/check.sh`, and
   repository `dev/check.sh` to pass.
5. Cover managed byte parity, default schema validation, config divergence allowlist,
   template structure, projected model values, and Flywheel-owned JSON/marker portions.
6. Require every model ID in the distribution default config to have a dated
   verification row in the distribution FACTS file; include a deliberately mismatched
   fixture that makes `dev/check.sh` fail.
7. Verify marked architecture removal and preservation of plans, research, unrelated
   docs, and unmarked architecture files. Populate state and mutable core documents,
   uninstall, and verify the complete `flywheel-archive/` recovery set.
8. Add CLI contract probes for runnerless fail-before-write, `--check` without a
   confirmation prompt, and rejection of `--check --yes`; compare complete target-tree
   hashes before and after every probe.
9. Scan the repository to prove no install-consumed canonical input exists outside
   `distribution/`, no Flywheel artifact remains at the old unqualified docs paths,
   and installed files contain no references to `distribution/`, `installer/`,
   `dev/`, or `tests/`.
10. Run installed checks from a temporary target without repository sources, proving
   the installed runtime is self-contained.

Primary verification commands after implementation:

```sh
bash tests/test_adapter_lifecycle.sh
python3 -m unittest discover -s tests -p 'test_*.py'
bash flywheel/check.sh
bash dev/check.sh
./install.sh . --adapters claude-code,codex,antigravity --check
```

Any ambiguity that changes ownership, preservation, projection precedence, or CLI
behavior stops implementation for clarification; it must not be guessed.

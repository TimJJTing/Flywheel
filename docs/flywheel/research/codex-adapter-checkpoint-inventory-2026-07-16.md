# Codex adapter checkpoint inventory — 2026-07-16

## Scope and reconciliation

This inventory compares the paused branch to `main`, including checkpoint commit
`37c84f4`, wrapup commit `27dfe28`, and the current worktree. The report itself is the
only edit made by this review.

- Before this report was created, `git diff --name-only main | wc -l` returned **28**
  branch-changed files, while `git status --short | wc -l` returned **8** current
  worktree files. The tests are committed checkpoint additions, so they occur in the
  first count, not the second.
- After adding this report, `(git diff --name-only main; git ls-files --others
  --exclude-standard) | sort -u | wc -l` returns **29** branch-changed/untracked files,
  and `git status --short | wc -l` returns **9** status entries. (`git diff` alone
  still returns 28 because it excludes the untracked report.) The 29-file inventory
  below includes this report; the 9 worktree entries are marked **WT**.
- `git diff --check main` produced no output (clean). `find . -path ./.git -prune -o
  -type f -size +200k -print` produced no paths, so no big-file exception was needed.

Labels: **implemented** = hunk matches its plan requirement; **partial** = useful but
acceptance is incomplete; **missing** = required plan hunk absent; **questionable** =
stale, unsafe, contradictory, or outside the approved implementation scope.

## File and logical-hunk inventory (29 files)

1. The then adapter-local Antigravity delegate skill, now consolidated at
   `distribution/shared/skills/delegate/`, — **implemented**: surfaced-runtime
   dispatch and degraded-mode fallback; **implemented**: adapter-neutral spawn logging.
   Byte-identical to the Codex source, but not to repo `.agents/skills` dogfood.
2. The then adapter-local Antigravity wrapup skill, now consolidated at
   `distribution/shared/skills/wrapup/`, — **implemented**: adapter-neutral hook
   and coordinator-row language. Byte-identical to the Codex source, but not dogfood.
3. `distribution/adapters/codex/AGENTS.md.block` — **implemented**: whitelist now names
   `.agents/skills`.
4. `distribution/adapters/codex/agents/architect.toml` **WT** — **questionable**: model changed to
   `gpt-5.6-sol`; config-consistent, but the plan forbids changing pins without live
   verification and none is recorded. The nearby top-model rationale was not revised.
5. `distribution/adapters/codex/agents/engineer.toml` **WT** — **questionable**: model changed to
   `gpt-5.6-terra` without recorded live verification.
6. `distribution/adapters/codex/agents/plan-auditor.toml` **WT** — **questionable**: model changed to
   `gpt-5.6-sol` without recorded live verification.
7. `distribution/adapters/codex/agents/researcher.toml` **WT** — **questionable**: model changed to
   `gpt-5.6-sol` without recorded live verification.
8. `distribution/adapters/codex/agents/utility.toml` **WT** — **questionable**: model and effort
   changed to `gpt-5.6-luna`/`low` without recorded live verification.
9. `distribution/adapters/codex/agents/verifier.toml` **WT** — **questionable**: model changed to
   `gpt-5.6-sol` without recorded live verification.
10. The then adapter-local Codex delegate skill, now consolidated at
    `distribution/shared/skills/delegate/`, — **implemented**: replaces Codex-only
    dispatch/logging with the same neutral body as Antigravity.
11. The then adapter-local Codex wrapup skill, now consolidated at
    `distribution/shared/skills/wrapup/`, — **implemented**: same neutral body as
    Antigravity.
12. `docs/flywheel/plans/codex-adapter-full-verification.md` — **implemented** plan artifact,
    not implementation. **Questionable metadata**: its header still says an APPROVED
    re-audit is required, while STATUS says that audit already passed.
13. `flywheel/ADAPTERS.md` — **partial**: adds the public hook URL, but still ships the
    two forbidden repo-only references at lines 43 and 46 and retains old Part C
    language. Installed-user gap 3 therefore remains.
14. `flywheel/FACTS.md` **WT** — **questionable**: replaces all Codex model facts and
    adds a GPT-5.6 allocation policy based on the manual, while the approved plan says
    not to change pins absent a live run. Trust/telemetry/account limitations required
    by the plan are still missing.
15. `flywheel/LESSONS.md` — **questionable/outside implementation scope**: adds a
    process-friction lesson. It is reasonable session bookkeeping but not a repair-plan
    file.
16. `flywheel/STATUS.md` — **implemented bookkeeping**: records pause, partial state,
    and required follow-up; its “config still contains GPT-5.5/GPT-5.4” statement is
    now stale after the current WT edits (line 16).
17. `flywheel/check.sh` — **implemented**: Codex and OpenCode drift hints now point to
    `sync.py`. **Partial**: no lifecycle/unit tests are wired, and no new matrix-11
    execution coverage is added.
18. `flywheel/config.json` **WT** — **questionable**: six Codex model cells and utility
    effort changed; consistent with TOMLs/FACTS but contrary to the plan's live-proof
    gate. Newline normalization is harmless.
19. `flywheel/resolve-spawn.py` — **implemented**: all success paths emit one JSON
    object and exceptions emit one JSON skip object. **Partial**: tests do not exercise
    all agent/config/ledger-change paths, and source comments still cite the repo-only
    research doc (lines 12, 89).
20. `flywheel/state/activity.json` — **implemented bookkeeping**: records session 16
    and checkpoint commit.
21. `flywheel/state/decisions.json` — **implemented bookkeeping**: adds pending d12
    merge decision.
22. `flywheel/state/issues.json` — **implemented bookkeeping**: associates i1 with the
    checkpoint and opens i16. **Questionable**: i16 still says GPT-5.6 migration is a
    future action despite current WT migration.
23. `flywheel/state/spawns.json` — **implemented bookkeeping** for the audit, failed
    engineer, and coordinator. Historical `gpt-5.5` at line 614 is intentional history,
    not a pin to rewrite.
24. `flywheel/sync.py` — **implemented**: adds both local/template Codex TOML targets,
    level-to-`model_reasoning_effort`, pending/missing skips, and main invocation.
    **Partial**: it silently succeeds if a TOML lacks either replaceable key and tests
    do not prove all six files or adapter-template projection.
25. `install.sh` — **implemented**: runner override; explicit created/backup/snapshot
    JSON states; shared `.agents/skills` destination; guarded legacy managed migration;
    unified merge path for all hook/settings JSON. **Questionable ownership**: any
    unmarked JSON structurally equal to the merge source is claimed as created
    (lines 161-190), which follows the plan's legacy rule but cannot prove provenance.
    **Partial**: the ambiguous-legacy-with-user-additions contract is undocumented.
26. `tests/test_adapter_lifecycle.sh` — **partial**; detailed matrix mapping below.
    The runner override does not hide Python from `PATH`, helper/assertion logic still
    calls Python under the Node case, the sync idempotency assertion at line 143 is a
    no-op (`... || true`), and only Codex→Antigravity order is covered.
27. `tests/test_resolve_spawn.py` — **partial**; detailed matrix mapping below. Current
    line 50 expects stale `gpt-5.5`, causing one failure after the WT model update.
28. `uninstall.sh` — **implemented**: runner override, created/snapshot cleanup,
    shared managed-skill removal, and post-uninstall assertions. **Questionable/unsafe**:
    the final `find` rejects every `*.flywheel-bak` anywhere under the target, including
    unrelated user files (lines 467-472); exact-command assertion uses regex text
    matching rather than parsing JSON (lines 474-479). **Partial**: malformed installed
    JSON can make exact unmerge fail under `set -e`, and ownership cases lack tests.
29. `docs/flywheel/research/codex-adapter-checkpoint-inventory-2026-07-16.md` **WT** —
    **implemented**: this review-only inventory.

## Explicit test-hunk review and matrix mapping

`tests/test_adapter_lifecycle.sh` is one new-file hunk (lines 1-149) with logical
sections: helpers/runner selection (1-49), clean/reinstall/uninstall (51-68), merge +
edit preservation (70-96), malformed JSON (98-104), legacy skills (106-113), adapter
combination (115-123), and sync (125-143). `tests/test_resolve_spawn.py` is one
new-file hunk (lines 1-77): fixture/one-JSON contract (1-43), known agent/parent ignore
(45-51), unknown+missing config (53-59), malformed payload/no change (61-63), and
concurrency (65-73).

| Matrix | Status | Evidence and gaps |
|---:|---|---|
| 1 | partial | Lifecycle 51-62 checks block, 6 TOMLs, 3 skills, valid hook, no legacy dir, and installed-doc strings. It does not assert the exact managed block or exact one-hook event structure. |
| 2 | partial | 70-85 checks user `Stop`, added `SubagentStop`, backup/snapshot, one Flywheel hook, reinstall. It does not compare backup/snapshot bytes at merge time. |
| 3 | partial | 98-104 checks success, content by command substitution, and no backup/created marker; it omits no-snapshot and warning assertions, and command substitution cannot prove the trailing newline byte-identical. |
| 4 | partial | 63-65 and 84-85 check no backup and hook count; no whole-tree/file byte-idempotency comparison. |
| 5 | partial | 66-68 and 93-96 cover uninstall after two installs and backup restore. No explicit one-install case, unmanaged same-name shared skill, exact-command absence, or all adapter JSON cases. |
| 6 | covered | 86-96 adds a post-install hook edit, checks original restore, `.flywheel-uninstalled`, and no ownership sidecars. Only Python JSON editing is used even in Node runner. |
| 7 | partial | 106-113 proves one managed legacy removal and one unmanaged preservation. It does not test destination collision/preserve-managed-legacy or all three skills/directories. |
| 8 | partial | 125-143 proves one changed tier and one pending skip. It does not prove all six, template TOMLs, mismatch failure, or a real second-sync no-diff (line 143 is ineffective). |
| 9 | partial | Resolver 25-73 checks one-JSON stdout, empty stderr, zero exit, known engineer, unknown+missing config, parent ignored, malformed payload/no ledger change, and concurrent validity. Missing five known types, invalid config, absent/invalid ledger, per-path ledger-change assertions, and output object contents. |
| 10 | partial | 115-123 covers Codex then Antigravity and source/installed byte equality. Missing reverse order, reinstalls for both orders, Claude/OpenCode combinations, and documented AGENTS precedence assertion. |
| 11 | missing | No test invokes `check.sh`, dashboard builders/parity, shell syntax, or `git diff --check`; checkpoint review ran syntax and diff-check separately only. |
| 12 | partial | Both `FLYWHEEL_RUNNER=python3` and `node` run the listed Codex scenarios, but Node is not run with Python hidden and the test itself requires/calls Python. |

Observed command results: `bash -n install.sh uninstall.sh flywheel/check.sh
tests/test_adapter_lifecycle.sh` passed; `bash tests/test_adapter_lifecycle.sh` passed
both named runners; `python3 -m unittest -v tests/test_resolve_spawn.py` ran 4 tests
with 1 failure at line 50 (`gpt-5.6-terra != gpt-5.5`); `git diff --check main` was
clean. These are checkpoint-review observations, not the plan's missing full verifier.

## Required targeted scans

Commands run:

```bash
rg -n "gpt-5\\.(5|4)|\\.codex/skills|docs/(plans/codex-adapter-dogfood|research/codex-hooks)\\.md|flywheel-created|flywheel-(bak|merged|uninstalled)" adapters flywheel install.sh uninstall.sh tests README.md docs/config docs/flywheel/plans/codex-adapter-dogfood.md
rg -n "Codex|codex|\\.codex/skills|degraded|Pending|hook|trust|model_reasoning_effort" README.md docs/config/ADAPTERS.md docs/config/MODELS.md docs/flywheel/plans/codex-adapter-dogfood.md docs/SEED-PROMPT.md
git diff --check main
```

Decisive findings: stale model expectation in `tests/test_resolve_spawn.py:50`;
obsolete skill/model/Part-A instructions throughout `docs/flywheel/plans/codex-adapter-dogfood.md`
(notably lines 18-32); degraded Codex claims at `README.md:28`,
`docs/config/ADAPTERS.md:11-20`, and `docs/config/MODELS.md:26-34`; missing seed sync
step between `docs/SEED-PROMPT.md:29-38`; forbidden installed references at
`flywheel/ADAPTERS.md:43,46`; no `.codex` dogfood files; repo `.agents/skills/delegate`
and `wrapup` differ from the neutral source bodies. `git diff --check main` was clean.

## Missing plan work / resume blockers

1. Fix and substantially expand both tests; current resolver suite fails and matrix
   items 1-5, 7-10, 12 are partial while 11 is missing.
2. Finish all user docs and seed flow; the shipped `ADAPTERS.md` still contains the
   exact repo-only references the repair was meant to remove.
3. Add `.codex/agents`, `.codex/hooks.json`, and updated shared `.agents/skills`
   dogfood; then sync and verify hashes without breaking Antigravity.
4. Resolve the model-pin gate: either record the required live verification for the
   GPT-5.6 worktree changes or revert/mark them Pending; update stale test/state text.
5. Constrain uninstall's global sidecar assertion and add ownership/unmanaged-collision
   coverage before treating the lifecycle as safe.
6. Produce the limitations/final verification report, run the complete acceptance and
   live trust/hook/spawn flow, and obtain fresh independent GPT-5.6 verification before
   requesting the human merge decision.

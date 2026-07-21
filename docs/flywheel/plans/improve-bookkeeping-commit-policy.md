# Improve bookkeeping commit policy alignment

## Conclusion

Treat `flywheel/IMPROVE.md` as the authoritative self-improvement commit policy and
repair the stale summary in `flywheel/GIT.md`. The durable atomic change is one prose
replacement in `flywheel/GIT.md`, packaged with this approved process plan in the same
implementation commit; do not change `IMPROVE.md`, the improve skill projections,
`wrapup.sh`, `check.sh`, or tests. The specific improve policy was
deliberately changed later than the generic Git summary, is repeated in both current
skill copies, and is already backed by a wrapup path allowlist and a regression test.

## Motivating contradiction

- `flywheel/IMPROVE.md:4-5` defines one implementation commit followed by at most one
  bookkeeping-only commit, and `flywheel/IMPROVE.md:30-34` repeats the ordering and
  prohibits implementation paths from the optional commit.
- `flywheel/GIT.md:25-26` still says one total commit per improve branch while pointing
  readers to `IMPROVE.md`, so an agent cannot satisfy both literal rules.
- Required inventory command:
  `rg -n "ONE commit|implementation commit|bookkeeping" flywheel .agents adapters defaults`.
  Its relevant hits are `flywheel/GIT.md:26`, `flywheel/IMPROVE.md:4-5,30-34`,
  `.agents/skills/improve/SKILL.md:27,29`,
  `distribution/shared/skills/improve/SKILL.md:27,29`, and
  `flywheel/wrapup.sh:11,25`. The `spawns.json` bookkeeping hit is task data, not policy.

## Why `IMPROVE.md` is authoritative

1. `flywheel/GIT.md:25-26` explicitly delegates improve-branch detail to
   `IMPROVE.md`; the specific procedure therefore governs the generic branch summary.
2. `git blame -L 3,6 -- flywheel/IMPROVE.md` attributes the two-commit exception to
   later commit `7350d44`, while `git blame -L 24,27 -- flywheel/GIT.md` shows the
   one-total-commit wording predates it at the initial commit.
3. The approved repair plan deliberately says to permit the implementation commit and
   bookkeeping-only wrapup commit (`docs/flywheel/plans/codex-adapter-robustness-repair.md:33-36`),
   and the same implementation commit updated the public summary
   (`README.md:22-24`) plus the canonical improve procedure. `git show --name-only
   --format= 7350d44` confirms that prior improve implementation commit also included
   its approved plan artifact.
4. The behavior is not merely aspirational: `flywheel/wrapup.sh:10-28` rejects staged
   non-bookkeeping paths, `flywheel/wrapup.sh:68-76` stages only the bookkeeping set,
   and `tests/test_codex_adapter_repair_spec.py:107-134` regression-tests rejection.

## Exact atomic edit set

Changed artifacts in the single implementation commit:

- `flywheel/GIT.md` — the sole implementation path and sole doctrine change.
- `docs/flywheel/plans/improve-bookkeeping-commit-policy.md` — the approved structural-process
  artifact; it records the motivation, exact change, approval boundary, and checks.

Replace `flywheel/GIT.md:25-26`:

```markdown
- `flywheel/improve-<slug>` — flywheel self-improvements, ONE improvement per branch,
  ONE commit per branch (IMPROVE.md). Individually revertible by design.
```

with:

```markdown
- `flywheel/improve-<slug>` — flywheel self-improvements, ONE improvement and ONE
  implementation commit per branch, followed by at most one bookkeeping-only wrapup
  commit (IMPROVE.md). Individually revertible by design.
```

Exact semantics after replacement:

- Each `flywheel/improve-<slug>` branch still carries exactly one improvement.
- It has exactly one implementation commit named per `flywheel/IMPROVE.md:30-31`.
- After that commit, wrapup may add zero or one bookkeeping-only commit; therefore the
  branch has one or two commits total, never two implementation commits.
- The optional commit remains limited by `flywheel/IMPROVE.md:32-34` and the mechanical
  allowlist at `flywheel/wrapup.sh:17`: `flywheel/STATUS.md`,
  `flywheel/LESSONS.md`, `flywheel/state/*.json`,
  `flywheel/dashboard/dashboard.html`, and `docs/flywheel/ARCHITECTURE.md`.
- Independent revertibility is preserved because implementation remains one atomic
  commit on a branch containing no second implementation concern; bookkeeping is
  isolated in the optional second commit.

Explicitly excluded from the implementation commit: every path except
`flywheel/GIT.md` and `docs/flywheel/plans/improve-bookkeeping-commit-policy.md`, including
`flywheel/IMPROVE.md`, `flywheel/check.sh`, `flywheel/wrapup.sh`, `README.md`,
`.agents/**`, `distribution/adapters/**`, `distribution/defaults/flywheel/**`, tests, state ledgers, generated
dashboard/architecture output, and unrelated doctrine. Wrapup may create its
separately allowed bookkeeping commit, but none of those allowlisted bookkeeping
paths belongs in the implementation commit.

Rationale: this changes the one stale generic summary rather than duplicating or
rewriting the newer specific policy and its already-tested enforcement.

## Implementation and verification

1. From `main`, create `flywheel/improve-bookkeeping-commit-policy` after confirming
   no unrelated work would be carried onto it.
2. Apply only the exact `flywheel/GIT.md` replacement above.
3. Run the required consistency inventory:

   ```bash
   rg -n "ONE commit|implementation commit|bookkeeping" flywheel .agents adapters defaults
   ```

   Expected: no `ONE commit per branch` policy remains; `GIT.md` now agrees with the
   implementation-plus-optional-bookkeeping wording in `IMPROVE.md` and both skill
   copies. Data-ledger hits do not affect this expectation.
4. Run the focused negative probe:

   ```bash
   ! rg -n "ONE commit per branch" flywheel .agents adapters defaults
   ```

5. Re-run the existing mechanical path-boundary regression:

   ```bash
   python3 -m unittest tests.test_codex_adapter_repair_spec.WrapupAllowlistSpec
   ```

6. Run repository checks and diff hygiene:

   ```bash
   bash flywheel/check.sh
   git diff --check
   git diff -- flywheel/GIT.md docs/flywheel/plans/improve-bookkeeping-commit-policy.md
   git diff --name-only
   ```

   Expected path list: exactly `flywheel/GIT.md` and
   `docs/flywheel/plans/improve-bookkeeping-commit-policy.md`; stop if any other path appears.
7. Have the auditor approve that exact two-file diff. Stage both paths explicitly:

   ```bash
   git add -- flywheel/GIT.md docs/flywheel/plans/improve-bookkeeping-commit-policy.md
   git diff --cached --name-only
   ```

   Expected staged path list: exactly the same two paths. Create the single
   implementation commit `improve(flywheel): align bookkeeping commit policy`; its
   body must cite the audit finding at `flywheel/IMPROVE.md:4-5,30-34` versus
   `flywheel/GIT.md:25-26`. This saves both the approved process artifact and its sole
   implementation edit, consistent with the repository's uncommitted-work rule.
8. If wrapup changes allowlisted bookkeeping paths, commit those once afterward using
   the standard bookkeeping commit. Neither `flywheel/GIT.md` nor the plan may enter
   that optional commit.

## Found

- The literal contradiction is at `flywheel/IMPROVE.md:4-5,30-34` and
  `flywheel/GIT.md:25-26`; inventory source: required `rg -n "ONE commit|implementation commit|bookkeeping" flywheel .agents adapters defaults` command.
- `IMPROVE.md` is the later, specific policy and `GIT.md` points to it; sources:
  `git blame -L 3,6 -- flywheel/IMPROVE.md`,
  `git blame -L 24,27 -- flywheel/GIT.md`, and commit `7350d44`.
- The intended exception and its path boundary are corroborated by
  `docs/flywheel/plans/codex-adapter-robustness-repair.md:33-36`, `README.md:22-24`,
  `flywheel/wrapup.sh:10-28,68-76`, and
  `tests/test_codex_adapter_repair_spec.py:107-134`.
- Prior improve commit `7350d44` packages its approved plan with its implementation;
  source: `git show --name-only --format= 7350d44`.
- `python3 -m unittest tests.test_codex_adapter_repair_spec.WrapupAllowlistSpec`
  passed before planning; `bash flywheel/check.sh` also passed at session start.

## Assumed

- The supplied MAJOR audit finding is the motivating observation for this one
  improvement; no broader commit-history doctrine change is intended.
- The engineer will start the independent branch from clean `main` and preserve any
  unrelated existing worktree changes before editing.

## Could not find

- No existing check asserts the total commit count of an improve branch or semantic
  parity between these two prose summaries; source: `rg -n 'GIT\\.md|IMPROVE\\.md|ONE commit|implementation commit|bookkeeping|improve-' flywheel/check.sh tests adapters defaults .agents`. Adding such a new gate is outside the smallest fix because the path safety property is already enforced and regression-tested.

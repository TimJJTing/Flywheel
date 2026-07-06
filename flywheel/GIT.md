# Git — clean history is a product feature

The commit log is the CEO's audit trail: the dashboard links ledger items to commits,
so a messy history breaks transparency, not just aesthetics.

## Commit messages (Conventional Commits)

`<type>(<scope>): <subject ≤ 50 chars>`

- Types: `feat`, `fix`, `docs`, `refactor`, `test`, `chore`, `improve` (reserved for
  flywheel self-improvements, see IMPROVE.md).
- Body: WHY, not what (the diff shows what). Wrap at 72.
- One logical change per commit. Stage specific files — never `git add -A` / `git add .`.
- Never `--no-verify`.

✓ `feat(importer): reject rows with missing required columns`
  body: "Malformed uploads previously wrote partial data; plan csv-import.md §2."
✗ `misc fixes` staged with `-A` — unreviewable, unlinkable, breaks the dashboard trail.

## Branches

- `main` — always releasable; only verified work merges in.
- `feature/<slug>` — product work.
- `fix/<slug>` — bug fixes.
- `flywheel/improve-<slug>` — flywheel self-improvements, ONE improvement per branch,
  ONE commit per branch (IMPROVE.md). Individually revertible by design.
- Merging anything → consult the autonomy matrix (AUTONOMY.md) for whether to ask,
  report, or just do.

## Ledger ↔ commit linking

- Every commit that advances a project/issue/decision: append its short hash (7 chars,
  `git rev-parse --short HEAD`) to that item's `commits` array in `flywheel/state/`.
- Every session's wrapup appends one `activity.json` entry listing the session's
  commit hashes.
- `flywheel/check.sh` verifies recorded hashes exist (`git cat-file -e`).

## Wrapup commit protocol (executed by the wrapup procedure)

1. `git status --porcelain` — review; stage only intended files.
2. Group commits by concern (doctrine change ≠ code change ≠ state-ledger update);
   `chore(flywheel): update state ledgers + dashboard` is the standard final commit.
3. Quote the resulting hash(es) in the session report.

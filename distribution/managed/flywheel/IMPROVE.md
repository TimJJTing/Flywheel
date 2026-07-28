# Improve — the flywheel's flywheel (the COO office optimizing itself)

Iteration by iteration, the framework adapts to THIS project. Every self-improvement is
one branch + one implementation commit = individually revertible. After that commit,
wrapup may add at most one bookkeeping-only commit. The CEO never wakes up to an
unrecognizable system.

## Trigger

- Session count (length of `state/activity.json`) is a multiple of
  `improve_cadence_sessions` (config.json, default 5) — wrapup prints "improve pass
  due" and the next session runs it first.
- Or on demand: the human asks, or the coordinator sees ≥ 3 open `friction` issues.

## Procedure

1. **Audit first** (MAINTENANCE.md §4): dispatch `auditor` over `flywheel/*.md` +
   adapter block. Fix BLOCKER/MAJOR findings as improvements below.
2. **Gather inputs:** `flywheel/LESSONS.md`; `state/issues.json` where
   `type == "friction"`; latest `flywheel/check.sh` output; `state/spawns.json` rows
   with outcome `retried|escalated|failed`.
3. **Propose ≤ 3 atomic improvements.** Each: one sentence + expected effect + the
   input line that motivated it. No improvement without a motivating observation —
   speculative rules are how doc rot starts.
4. **Apply each on its own branch:**
   - `git checkout -b flywheel/improve-<slug>` from main.
   - Structural files still require the MAINTENANCE.md §1 process (strategist plan +
     auditor approval) — the branch is where the approved edit lands.
   - Run `flywheel/check.sh` + rebuild the dashboard.
   - ONE implementation commit: `improve(flywheel): <slug>`, body cites the motivating
     LESSONS/issue line.
   - Wrapup may then add at most one bookkeeping-only commit, limited to `STATUS.md`,
     `LESSONS.md`, state ledgers, and generated dashboard/architecture output. No
     implementation path may enter it.
5. **Merge gate = AUTONOMY.md row "Merge flywheel self-improvement branch":**
   - A (levels 1–3): create a `pending` decisions.json entry (options: merge/reject,
     recommendation + branch name in detail). Leave the branch. Continue other work.
   - R (level 4): merge, write a `decided-by-llm` decisions entry.
   - D (level 5): merge, activity log only.
6. **Record:** activity.json entry with branch name + commit hash; close the
   motivating issue if fixed.

## Rules

- Never bundle improvements: one branch fixing three things cannot be reverted
  selectively, which defeats the whole design.
- An improvement that loosens a rule (raises a budget, relaxes a gate) needs an
  explicit LESSONS.md justification line — loosening under friction is the main
  degradation path of tiered systems.
- If two consecutive improve passes propose nothing, that is fine. Zero is a valid
  count; manufactured improvements are negative value.
- When two candidate improvements are otherwise equal, prefer the one that converts a
  prose rule into a mechanical check (check.sh, a hook, a schema). Docs teach, checks
  enforce; a rule that can be checked and is not is debt. This ranks candidates — it
  never manufactures one (the zero-improvement rule above still stands).

✓ "LESSONS 2026-08-02: utility misread 'update all configs' as including config.json
→ improvement: add explicit exclusion to Template 3 CONTEXT line. Branch
flywheel/improve-template3-config-exclusion, 1 commit, decisions entry d7 pending."
✗ "Rewrote ORCHESTRATION.md for clarity" as one mega-branch — no motivating
observation per change, not selectively revertible, structural process skipped.

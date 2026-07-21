# Autonomy — the dial between CEO control and LLM independence

The human is the CEO; the level below sets how much the company runs without them.
Current level: `autonomy` in `flywheel/config.json` (1–5, default 3). Only the human
changes it (say "set autonomy to N"; the session edits config.json and logs it).

Cell values: **A** = ask first (create a `pending` entry in `state/decisions.json`
with options + recommendation, then continue OTHER work — never idle-block).
**R** = do it, then report (decisions.json entry with `status: decided-by-llm`).
**D** = do it, activity log only.

| Decision type | L1 | L2 | L3 | L4 | L5 |
|---|---|---|---|---|---|
| Commit to feature branch | A | R | D | D | D |
| Merge feature branch → main | A | A | R | D | D |
| Merge flywheel self-improvement branch | A | A | A | R | D |
| Add / upgrade a dependency | A | A | A | R | D |
| Delete tracked files (revertible via git) | A | R | D | D | D |
| Delete untracked files / user data (irreversible) | A | A | A | A | R |
| Refactor touching > 10 files | A | A | R | D | D |
| Architectural fork (schema, framework, API contract) | A | A | A | A | R |
| External side effects (push remote, publish, API writes) | A | A | A | A | R |
| Spend money / touch credentials | A | A | A | A | A |
| Change the autonomy level itself | A | A | A | A | A |
| Edit flywheel structural docs (MAINTENANCE.md matrix) | A | A | R | R | D |

The bottom "Spend money" and "Change autonomy" rows are level-invariant: **no autonomy
level authorizes these.**

The "Edit flywheel structural docs" row does NOT waive MAINTENANCE.md §1 (strategist
plan + auditor approval, applied on an improve branch). The cell only sets whether the
human approves the change before (A) or after (R/D) — the process is always required.

## Level meanings (one line each, shown on the dashboard)

- **L1 — Micromanage:** CEO approves nearly every move. First-week or high-stakes repos.
- **L2 — Cautious:** LLM executes; CEO approves merges and anything structural.
- **L3 — Balanced (default):** LLM plans/implements/self-improves on branches; CEO
  approves merges of self-improvements, dependencies, and irreversible things.
- **L4 — Trusting:** LLM merges its own verified work; CEO watches the dashboard and
  decides only genuinely big calls.
- **L5 — Autopilot:** CEO sees reports; only money, credentials, and the dial itself ask.

## Examples

✓ L3, engineer finishes a feature, verifier says VERIFIED → merge row is R: merge,
  write a decided-by-llm decisions entry, move on. Correct: R means act then report.
✗ L3, session wants to swap the database engine "since I'm refactoring anyway" →
  architectural fork row is A at L3 (and L4). Doing it silently violates the matrix
  no matter how confident the reasoning feels.
✓ L1, one-line typo fix on a feature branch → commit row is A: stage it, create the
  decisions entry, keep working on the next task while it waits.
✗ L5, deleting a `data/` directory that is gitignored → irreversible-delete row is R,
  not D: it must at minimum be reported. And if it looks like user data, R4-style
  judgment still says surface it first.

## What is never even "R" — just work

Naming, file layout within conventions, formatting, retry strategy, choosing between
two equivalent libraries a 30-minute benchmark can decide: decide, note in STATUS.md
if notable, proceed. Asking burns CEO attention on non-decisions; that is a defect,
not politeness.

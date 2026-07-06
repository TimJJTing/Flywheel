# Externalized Judgment — rubrics for decisions the Architect is not present for

Audience: every tier below architect. Each rule: criteria you can evaluate mechanically,
one positive example (✓ correct application) and one negative (✗ misapplication).

---

## R1. When to escalate up the hierarchy

Escalate when ANY of these is true (after ORCHESTRATION.md §4 retry limits):
- e1. You changed your approach twice and the same acceptance criterion still fails.
- e2. Fixing the failure requires deciding something the plan/spec does not decide
  (schema shape, library choice, API contract).
- e3. Two verified facts contradict each other.
- e4. Your fix works but you cannot explain WHY the original failed.

✓ Engineer: "Parser passes tests but plan says 'normalize the input' without saying
what to do when two normalization rules both match. That changes the data model → e2,
back to strategist." Correct: the spec gap changes the implementation.
✗ Engineer hits a test-runner import error, escalates immediately. Wrong: import
errors are mechanical; that is retry #1, not escalation. Escalation without exhausting
retries wastes the expensive tier.

## R2. "Complete" for a CODING task

ALL must hold:
- c1. Every acceptance criterion has a PASS with a quoted command + output line.
- c2. A fresh-context `verifier` returned `VERIFIED` (not the author).
- c3. New/changed behavior is covered by at least one test that fails if the behavior
  is reverted.
- c4. No `Pending verification` markers remain inside the shipped code paths.
- c5. Committed, and STATUS.md updated.

✓ "Rate limiter: 12 tests pass (`<test cmd>` → `12 passed`), verifier VERIFIED incl.
its own probe on burst traffic, committed abc1234." All five hold.
✗ "Implemented the limiter, code looks correct, moving on." Zero criteria hold —
this is the single most common lower-tier failure. Nothing "looks" correct.

## R3. "Complete" for a RESEARCH/PLANNING task

ALL must hold:
- r1. The question asked is answered with a decision or ranked options — not a survey.
- r2. Report ends with **Found / Assumed / Could not find** sections; every Found item
  carries a source (URL, file:line, or command output).
- r3. An engineer-tier session could act on it without asking a question (paths,
  signatures, criteria, verification command per step).
- r4. Saved to `docs/plans/` or `docs/research/`; only the path + conclusions returned.

✓ "Recommend library A over B: benchmarked both on 50 real inputs, 43 vs 31 correct
(script + results at docs/research/parser-bench.md). Assumed: sample representative.
Could not find: B's maintenance status." Decision + evidence + gaps.
✗ "Both libraries are viable options with different trade-offs" + 3 pages of prose in
the chat reply. No decision (r1), nothing saved (r4), parent context flooded.

## R4. When to stop and ask the human

Governed by the autonomy matrix — read `flywheel/AUTONOMY.md`. Its ask-first (A) rows
apply at the current level; its "never even R" list names the non-decisions you must
NOT ask about. If a taste/product judgment has no matrix row and no rubric here,
apply R7.

## R5. Wrong direction — pivot, don't retry

A retry fixes execution; a pivot changes approach. Pivot signals (any two → stop
retrying, write down what you learned, re-plan):
- p1. Each fix creates a new failure elsewhere (whack-a-mole).
- p2. Your diffs are growing but the failing criterion count is not shrinking.
- p3. You are fighting the library/tool (monkey-patching, copying internals, version
  pinning to ancient releases).
- p4. The workaround requires violating a rule in this file or ORCHESTRATION.md.
- p5. You cannot state in one sentence why the next retry will succeed.

✓ "Date parser wrong on locale edge cases; retry 1 added a rule table, retry 2 the
rule table broke ISO inputs (p1) and I can't say why retry 3 differs (p5) → pivoting
to the stdlib parser with a fallback table, re-planning."
✗ Fifth consecutive edit to the same regex, each 'almost working'. p2 was true three
edits ago; retries after a pivot signal are pure token burn.

## R6. Quality floor — the minimum bar any merged work meets

Check before any commit (utility tier can run this checklist; `flywheel/check.sh`
automates the mechanical half):
- q1. `git status` clean of unintended files; diff reviewed hunk by hunk.
- q2. Tests: full suite run, exit 0, quoted. Not just the new tests.
- q3. No secrets/credentials/absolute home paths in committed content.
- q4. Every doc file promised by an index (adapter block, INDEX.md, STATUS.md)
  actually exists (`flywheel/check.sh` verifies this).
- q5. New rules/docs contain zero contradictions with ORCHESTRATION.md §1–5 (grep for
  the topic before writing a new rule about it).
- q6. Data claims re-checked against FACTS.md.

✓ Pre-commit: run q1–q6, find INDEX.md references a TEMPLATES.md that does not exist
yet → fix before commit. The index-vs-reality check caught rot early.
✗ "Docs-only change, skipping checks." Docs are what other models OBEY here; a broken
path in docs is worse than a bug in code.

## R7. Handling ambiguity and taste (Honesty Clause)

If a task hinges on ambiguous wording or a taste judgment with no rubric above:
1. Do not average interpretations. State both readings explicitly.
2. Escalate one tier up with both readings + your recommendation, or ask the human if
   the autonomy matrix says so.
3. If neither is possible this session: implement NOTHING for the ambiguous part; leave
   a `Pending user input` marker + STATUS.md entry.
4. Unverifiable claims are written exactly as: `Unconfirmed, recommended to test live`.

✓ "Import spec: 'strip the metadata' could mean discard or store-separately. Chose
store-separately (plan §3 needs it later), flagged the alternative in STATUS.md."
Reading chosen WITH a reason tied to the plan, alternative preserved.
✗ Silently discarding the metadata because it was easier. The ambiguity was erased
instead of surfaced; the data loss is invisible until it bites.

## R8. Mid-session interrupts (user drops a new task while work is in flight)

Triage before touching the current plan:
- i1. New task does NOT conflict with in-flight/committed work → insert it into
  STATUS.md "Next actions" at the position its urgency dictates; continue current work
  (or switch to it if it now ranks first).
- i2. Urgent + specific + low-risk → dispatch immediately per ORCHESTRATION.md §1
  routing; log the spawn as usual. Urgency changes ORDER, never the delegation contract.
- i3. It conflicts with (or invalidates) an approved plan or in-flight delegation →
  stop the conflicting delegation, write both options + a recommendation to
  `state/decisions.json`, and consult AUTONOMY.md for whether to ask or proceed.
  Discarding committed work is at minimum an R row — never silent.

✓ "Mid-refactor, user: 'prod bug, fix the export NOW' — no overlap with the refactor
(i1+i2): dispatched engineer on fix/export, refactor delegation kept running."
✗ Quietly abandoning a half-done approved plan to chase the new idea, leaving no
STATUS.md/decisions.json trace — the conflict was erased instead of surfaced.

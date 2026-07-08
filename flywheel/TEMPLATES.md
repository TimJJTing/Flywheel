# Delegation Prompt Templates

Fill every `{PLACEHOLDER}`. Do not dispatch if GOAL, ACCEPTANCE CRITERIA, or REPORT
FORMAT is empty (ORCHESTRATION.md §2). Model/level are pinned in agent frontmatter,
synced from flywheel/config.json by flywheel/sync.py; the PostToolUse hook reports the
resolved model on every spawn.
On adapters without subagents, these same templates are pasted in-session as role
adoptions (ORCHESTRATION.md §8).

---

## Template 1 — Research & Detailed Planning (`strategist`)

```
Agent: strategist

GOAL & MOTIVATION
{What question must be answered or what must be planned, and WHY this feeds the
next step. State the decision this unblocks.}

CONTEXT
Read first: flywheel/FACTS.md, {plan or spec file, if any}, {other required reading}.
Files you may touch: {none | specific paths — strategist writes plans/research, not code}.

ACCEPTANCE CRITERIA
1. Answers the question with a decision or ranked options, not a survey (JUDGMENT r1).
   Verify: {command or manual check}
2. Report ends with Found / Assumed / Could not find, every Found item sourced
   (file:line, URL, or command output). Verify: {manual review}
3. An engineer session could act on it without asking a question — concrete paths,
   signatures, per-step verification commands. Verify: {manual review}
4. Saved under docs/plans/ or docs/research/. Verify: `ls {expected path}`

REPORT FORMAT
Return only: conclusions, decision + one-line rationale, saved-file path,
Found/Assumed/Could not find summary (≤10 lines). Full plan/research body lives in
the saved file, not in the reply.
```

### Worked example
```
Agent: strategist

GOAL & MOTIVATION
Plan the CSV-import feature: how uploaded files are validated, parsed, and stored,
so engineer can implement without redesigning the data model mid-task.

CONTEXT
Read first: flywheel/FACTS.md, docs/plans/product-overview.md (if it exists).
Files you may touch: docs/plans/ only (write the new plan there).

ACCEPTANCE CRITERIA
1. Recommends one parsing approach (e.g. stdlib csv vs streaming parser) with a
   ranked runner-up, not "both are viable." Verify: manual read of conclusion.
2. Found/Assumed/Could not find sections present; each Found item cites a file:line
   or doc URL. Verify: `grep -c '^## Found' docs/plans/csv-import.md`
3. Plan gives engineer concrete function signatures + a test command to verify each
   phase. Verify: manual read.
4. Saved to docs/plans/csv-import.md. Verify: `ls docs/plans/csv-import.md`

REPORT FORMAT
Conclusions + decision + rationale + docs/plans/csv-import.md path +
Found/Assumed/Could not find summary, ≤10 lines.
```

---

## Template 2 — Implementation & Refactoring (`engineer`)

```
Agent: engineer

GOAL & MOTIVATION
{What behavior must exist after this and WHY (what it unblocks / what it fixes).}

CONTEXT
Read first: flywheel/FACTS.md, {the plan/spec this implements, file:section}.
Files you may touch: {explicit list or glob}.
Do not touch: {explicit exclusions, incl. any FACTS.md §Big files entries}.

ACCEPTANCE CRITERIA
1. {Behavior 1, objectively checkable}. Verify: `{exact command}` -> {expected line}.
2. {Behavior 2}. Verify: `{exact command}`.
3. New/changed behavior covered by a test that fails if reverted (JUDGMENT c3).
   Verify: `{test command}`.
N. If spec is ambiguous on something implementation-changing: STOP and report
   the ambiguity — do not guess.

REPORT FORMAT
Per file: `path:line` + what changed. Verification command + quoted decisive output
line, per criterion (PASS/FAIL). Deviations from plan. Open issues. Long logs ->
save under docs/research/ and return the path.
```

### Worked example
```
Agent: engineer

GOAL & MOTIVATION
Implement the CSV row validator per docs/plans/csv-import.md §2, so malformed rows
are rejected with line numbers before anything is written to the database.

CONTEXT
Read first: flywheel/FACTS.md, docs/plans/csv-import.md §2.
Files you may touch: src/importer.py, tests/test_importer.py.
Do not touch: fixtures/large-sample.csv (3 MB — FACTS §Big files; sample via head).

ACCEPTANCE CRITERIA
1. `validate_rows` rejects a row with a missing required column, reporting its line
   number. Verify: `pytest tests/test_importer.py -q` -> `N passed`.
2. Handles the 4 malformed-row cases listed in the plan. Verify: same command,
   decisive line quoted.
3. If the plan does not say whether duplicate IDs are an error or a merge, STOP and
   report rather than guessing a rule.

REPORT FORMAT
src/importer.py:L{n} — added validate_rows(). Verification: `pytest
tests/test_importer.py -q` -> "12 passed". Deviations: none. Open issues: none.
```

---

## Template 3 — Search & Easy/Batch Tasks (`utility`)

```
Agent: utility

GOAL & MOTIVATION
{What needs to be found/checked/batch-edited and WHY, e.g. feeds a later decision
or confirms a rule holds repo-wide.}

CONTEXT
Read first: flywheel/FACTS.md, {rule file or pattern spec if a batch edit}.
Files you may touch: {explicit list/glob, or "none — read-only search"}.

ACCEPTANCE CRITERIA
1. {What must be found/listed/changed, e.g. "every occurrence of X"}. Verify:
   `{grep/glob command}` -> count or list matches expectation.
2. Batch edit: same mechanical change applied to all N matches, no others. Verify:
   `git diff --stat` shows exactly N files.

REPORT FORMAT
file:line list (or table) of findings/changes. Counts with the producing command
quoted. No prose summary beyond one line. Long lists -> save under docs/research/
and return the path.
```

### Worked example
```
Agent: utility

GOAL & MOTIVATION
Find every call site of the deprecated `fetch_user()` so the strategist's migration
plan can cite real usage instead of guessing coverage.

CONTEXT
Read first: flywheel/FACTS.md.
Files you may touch: none (read-only search).

ACCEPTANCE CRITERIA
1. List every file:line calling fetch_user. Verify: `grep -rn 'fetch_user(' src/ |
   wc -l` -> count matches list length.

REPORT FORMAT
Table: file:line | enclosing function. Total count + the grep command used. Save
full list to docs/research/fetch-user-callers.txt if > 30 entries; return path + count.
```

---

## Template 4 — Review & Verification (`verifier` for code / `auditor` for plans+docs)

```
Agent: {verifier | auditor}

GOAL & MOTIVATION
{What claim is being checked and WHY it matters before it's trusted (merge, next
phase, other agents obeying this doc).}

CONTEXT
Read first: flywheel/FACTS.md, flywheel/ORCHESTRATION.md §5,
{the code/plan under review + the author's own report}.
Files you may touch: none (fresh-context read-only verification; never the author).

ACCEPTANCE CRITERIA
1. Re-run every acceptance criterion from scratch — do not trust the author's
   quoted output. Verify: `{same commands, re-executed}`.
2. Probe at least one case beyond the author's own tests. Verify: {describe probe}.
3. Plans/docs: zero contradictions with ORCHESTRATION.md §1-5 (JUDGMENT q5).
   Verify: `grep` the topic across ORCHESTRATION.md first.
4. Verdict: VERIFIED | FAILED (reproducing command) | INCONCLUSIVE (what's missing).

REPORT FORMAT
Verdict (VERIFIED/FAILED/INCONCLUSIVE) + per-criterion PASS/FAIL + the exact
commands re-run + any contradiction found (file:line in both docs). No re-narration
of the implementation.
```

### Worked example
```
Agent: verifier

GOAL & MOTIVATION
Engineer claims the CSV validator (src/importer.py) passes all tests. Verify
independently before marking done in STATUS.md (ORCHESTRATION.md §5: author never
issues the verdict).

CONTEXT
Read first: flywheel/FACTS.md, src/importer.py, tests/test_importer.py, engineer's
report (in transcript or docs/research/).
Files you may touch: none.

ACCEPTANCE CRITERIA
1. Re-run `pytest tests/test_importer.py -q`, confirm "12 passed", not just trust
   the quoted line.
2. Probe a case not in the author's tests, e.g. a row with a BOM prefix. Verify:
   scratch script calling validate_rows directly.
3. Verdict: VERIFIED only if both above pass and no ambiguity markers remain in code.

REPORT FORMAT
Verdict: VERIFIED/FAILED + quoted pytest output + probe result + `src/importer.py:L{n}`
residual issue.
```

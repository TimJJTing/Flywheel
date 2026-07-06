# Philosophy — why flywheel exists

## The company analogy

A software project run with LLM agents is a company:

- **You are the CEO.** You own the vision, make the big irreversible calls, and read
  the dashboard. You should not be asked whether to use pytest or unittest.
- **The main LLM session is the COO.** It runs daily operations: routes work, integrates
  results, keeps the books. It does not do the detail work itself.
- **The tier agents are departments.** Strategy (strategist), engineering (engineer),
  back office (utility), QA (verifier), internal audit (auditor), and a board-level
  advisor consulted rarely and expensively (architect).
- **The flywheel improve pass is the COO's office of operational excellence.** Every
  few iterations it reviews what caused friction and changes the company's own
  processes — in small, individually revertible steps.

## The founding insight

Flywheel descends from a one-shot experiment: a scarce, expensive top-tier model was
given one session to set up a project so that all future sessions — run by cheaper
models — would be MORE capable because of what it left behind. The lesson that
survived: **the durable product of high-level intelligence is not answers, it is
systems that cheaper intelligence can follow.** Concretely:

1. **Abstract requirements are as good as unwritten.** Every rule ships with
   mechanical criteria and a ✓/✗ example pair (see JUDGMENT.md). A rule a smaller
   model can interpret two ways will be interpreted the wrong way, eventually.
2. **Context is the scarcest resource.** Always-loaded files are line-budgeted;
   everything else loads on demand via an index. One careless file read can end a
   session's usefulness (DIAGNOSIS.md Leak 1).
3. **Facts are verified or marked, never recalled.** Model IDs, API parameters,
   data shapes: from FACTS.md/config.json or `Pending verification`. One fabricated
   value propagates into every later session.
4. **Nobody grades their own homework.** Completion verdicts come from fresh-context
   verifier/auditor agents, never the author (ORCHESTRATION.md §5).
5. **The Commander does not step onto the battlefield.** Expensive tiers decide;
   cheap tiers execute; escalation is explicit and budgeted (max 2 retries per tier).
6. **Rules survive only at point of use.** A rule buried in a reference file rots;
   the four hard rules are duplicated into the always-loaded adapter block, and
   check.sh mechanically enforces the budgets nobody would otherwise re-check.
7. **What is not committed does not exist.** Save as you go; wrapup is a protocol,
   not a habit.

## The flywheel effect

Each session leaves the system slightly better: lessons logged, friction filed as
issues, and every `improve_cadence_sessions` a self-improvement pass turns those
observations into process changes — one branch, one commit each, merge-gated by the
autonomy level you set. Over iterations the harness molds itself to your project.
That compounding is the flywheel.

## Transparency over trust

The CEO dashboard exists so you never have to interrogate the LLM about state:
projects, progress, open issues, decisions waiting for you, and a full record of which
agent (model, effort) did what. Autonomy is a dial, not a philosophy debate: the
matrix in AUTONOMY.md says exactly who decides what at each level, and two rows
(money/credentials, the dial itself) never leave your hands.

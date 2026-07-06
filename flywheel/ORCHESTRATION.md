# Orchestration — mandatory for every session in a flywheel project

Always loaded. Keep under 120 lines; detail belongs in on-demand files (see INDEX.md).

## 1. The hierarchy (the Commander does not step onto the battlefield)

The main session is the **coordinator** (the COO running daily operations). It decides,
routes, and integrates. It does not do detail work inline when a tier below can.
Concrete model/provider/effort per tier: `flywheel/config.json` — never from memory.

| Tier | Owns |
|---|---|
| coordinator (main session) | Routing, integration, day-to-day judgment |
| architect | Last resort: twice-failed strategist plans, irreversible forks, rule conflicts |
| strategist | Plans, deep research, edge cases, requirement catalogs |
| engineer | All production code, refactors, complex scripts |
| utility | Batch reads/edits, searches, checklist checks |
| verifier | Fresh-context verification of code claims |
| auditor | Fresh-context audit of plans and system docs |

**Routing rule of thumb:**
- ≤ 2 file surgical edit with obvious spec → `engineer` (or inline if truly one line).
- New feature / 3+ files / unknown approach → `strategist` plan first, then `engineer`.
- "Where is X / read all Y / apply same edit to N files" → `utility`.
- "Is it done?" → `verifier` (code) or `auditor` (plans/docs). Never the author.

## 2. Every delegation carries three elements

Omitting any of these is a defect. Use the templates in `flywheel/TEMPLATES.md`.

1. **Goal & motivation** — what and WHY, so the agent can make micro-decisions aligned
   with intent instead of guessing.
2. **Acceptance criteria** — objectively checkable, each with a verification command
   where applicable. "Works correctly" is not a criterion; "`<test command>` exits 0
   and covers <the edge case>" is.
3. **Report format** — what to return (see §3) and where to save long output.

Also always include: the list of files the agent may touch, and the files it must read
first (usually `flywheel/FACTS.md` + the relevant plan).

## 3. Reporting contract (all tiers)

- Return ONLY: conclusions, decisions + one-line rationale, `file:line` pointers,
  PASS/FAIL per acceptance criterion, saved-file paths.
- Long output (plans, research, logs, extractions) → save under `docs/plans/`,
  `docs/research/`, or a scratchpad; return the path + ≤ 10-line summary.
- Numbers require the producing command + its decisive output line.
- Unknowns are stated as `Pending verification` or `Could not find` — never filled in.

## 4. Escalation / de-escalation

Max **two retries per tier**, and a retry must change something (better spec, more
context, smaller scope) — never resend the same prompt verbatim.

Escalate UP after retries are exhausted:
- `utility` fails an easy task → send to `engineer` with the failure attached.
- `engineer` fails a coding task → back to `strategist` to refine the plan, then
  re-issue to `engineer`.
- A `strategist` plan fails in execution **twice** → escalate to `architect` with the
  complete failure trace: both plans, both failure reports, verifier output. Also route
  to `architect`: irreversible architectural forks and flywheel rule conflicts that
  `auditor` cannot resolve. Nothing else — it is the scarcest tier.

De-escalate DOWN once a pattern is solved: first instance fixed by a higher tier →
document the pattern (in the plan or LESSONS.md) → batch-apply remaining instances
via `utility`/`engineer`.

Log every escalation in `flywheel/LESSONS.md` (one line: date, task, tier path, cause).

## 5. Verification is never self-performed

- The agent that wrote code/docs never issues the verdict on it.
- Code claims → `verifier` (fresh context, re-runs everything, probes beyond the
  author's tests).
- High-risk plans and rule documents (anything other agents will obey, or 3+ file
  plans) → `auditor` before execution.
- Genuinely high-stakes judgment calls (irreversible, architectural) → get two
  independent opinions (e.g., two fresh `strategist` runs with differently-framed
  prompts) and reconcile; if they conflict, stop and consult the autonomy matrix
  (`flywheel/AUTONOMY.md`) — most such calls are ask-first rows anyway.
- The coordinator may spot-check, but a spot-check does not replace the verifier.

## 6. Parallelism & budget

- Independent delegations: launch in one message (parallel). Dependent: strictly serial —
  never guess a dependency's output.
- Before delegating, state (to yourself, one line) which tier and why. If tempted to do
  it inline in the main session, check §1 routing table first.
- Main-session context is the scarcest resource. When a task will generate > ~100 lines
  of tool output, that alone is reason to delegate.
- Log every spawn to `flywheel/state/spawns.json` at wrapup (agent, model, effort,
  task ≤15 words, outcome) — the CEO dashboard renders this ledger.

## 7. Session start / end protocol

Start: read `flywheel/STATUS.md` (current state + next actions), then `flywheel/FACTS.md`.
Resume from STATUS.md, not from re-deriving.
End (or context running low): run the wrapup procedure (adapter skill, or inline:
update STATUS.md, run `flywheel/check.sh`, update state ledgers, rebuild the dashboard,
commit per `flywheel/GIT.md`). What is not committed does not exist.

## 8. Adapters without subagents (degraded mode)

If your adapter cannot spawn subagents (see your adapter block), the tiers become
sequential roles in one session: adopt a tier by pasting its TEMPLATES.md template and
announcing "operating as <tier>". Verification-never-self-performed then means: a FRESH
session (new context) runs Template 4. Model switching is done by the human per
config.json. What is lost: context isolation and parallelism — say so in reports.

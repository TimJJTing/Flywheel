# What still needs the human (CEO duties that never delegate)

## Always yours, at every autonomy level

- **Money and credentials.** No level authorizes spend, API keys, or secrets handling.
- **The autonomy dial itself.** Only you change it ("set autonomy to N").
- **The decisions queue.** Anything your level marks A waits for you in the dashboard.
  At the default L3 that means: merging self-improvements, adding dependencies,
  architectural forks, irreversible deletions, anything outward-facing (push,
  publish, external API writes).

## Yours in practice (the system can't know these)

- **Taste and product judgment.** JUDGMENT.md R7 makes ambiguity surface instead of
  being averaged away — but surfaced ambiguity still needs your answer.
- **Priorities.** Sessions execute the STATUS.md order; reordering it is a sentence
  from you.
- **The seed interview** (greenfield): goals, constraints, what v1 means.
- **Periodic sanity read.** Skim the spawn ledger and LESSONS.md monthly-ish. The
  system self-audits every N sessions, but the auditor is still an LLM; clusters of
  failed spawns or repeated lessons are your cue to intervene.

## Known low-confidence areas (honest disclosure)

- **Effort/reasoning pinning per agent** varies by harness and version; FACTS.md
  records what your bootstrap actually verified. Where marked
  `Unconfirmed, recommended to test live`, believe the marking.
- **Degraded mode (no subagents)** loses real context isolation; its "fresh session
  verification" is only as independent as you make it.
- **The autonomy matrix rows are a design, not a guarantee.** They constrain an LLM
  via instructions, not via sandboxing. For hard guarantees (e.g., no pushes), use
  your harness's permission system as the enforcement layer and the matrix as policy.

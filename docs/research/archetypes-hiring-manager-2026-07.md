# Consulting note — five archetypes & the "Hiring Manager" idea (2026-07-09)

Input: an observation (source: Anthropic/Claude Code team anecdote shared by the user)
that engineering/design/DS roles are melting into five archetypes — Prototyper,
Builder, Sweeper, Grower, Maintainer — with a stage-mix formula (pre-PMF: 1+2+3;
growth: 2+3+4+some 5; mature: 3+4+5+some 2). User proposal: add a "Hiring Manager"
that hires agents (writes agent docs) per stage mix, and possibly fires them
(archives docs so the adapter stops spawning them).

Read together with `docs/research/strategy-2026-07.md` (A2, A4, positioning rule).

## Findings

### F1. Archetypes describe careers; agents don't have careers
The archetype framing carries weight for humans because taste and tacit skill
accumulate in a person over years. An agent spawn is fresh context every time — its
entire "skill" IS the agent doc. So the transferable part of the idea is not the five
roles; it is the **lifecycle**: agent docs treated as staffing decisions, written and
retired deliberately as the project's stage changes, instead of accreting forever.

### F2. Axis mismatch: flywheel tiers ≠ archetypes
Flywheel's tiers (strategist/engineer/utility/verifier/auditor) sit on a
**capability-and-cost axis** — how smart, how expensive, how verified. The archetypes
sit on a **product-lifecycle-stance axis** — what kind of work the moment demands.
They are orthogonal:

| Archetype | Flywheel expression today |
|---|---|
| Prototyper | strategist + engineer with "throwaway OK, skip polish" acceptance criteria |
| Builder | engineer with production-grade criteria + verifier |
| Sweeper | engineer/utility on a simplify/delete pass (improve pass is the flywheel-internal sweeper) |
| Grower | engineer iterating an existing surface; different criteria, same tier |
| Maintainer | engineer + verifier with regression-first criteria |

Conclusion: archetypes map to **delegation stances (TEMPLATES.md variants /
acceptance-criteria presets)**, not to five new agents. Five more agent docs would
duplicate the tier roster on a different axis — crowding, the user's own stated worry.

### F3. Hiring is a policy, not an agent
The staffing insight is right; making it a "Hiring Manager" agent is the wrong
container ("Heroes come and go; policies compound"). Writing/retiring agent docs is a
structural change — in flywheel that already routes through MAINTENANCE.md (strategist
plan + auditor + improve branch). A dedicated hiring agent adds a tier of hierarchy to
manage the tiers of hierarchy. Cheaper form: a **staffing review step in the improve
pass** — coordinator compares project stage against the active agent roster, proposes
hires/retires through the existing improve process.

### F4. Firing is the more valuable half (user doubted it; disagree)
Every active agent doc costs context and attention each session (the roster is
injected into every conversation). A4 (delete-to-add) applies to agents exactly as to
rules. Mechanism needs zero tooling: `git mv` the doc to an archive dir outside the
adapter's agent path; rehire = `git mv` back. A policy line suffices — no feature.

### F5. The stage-mix formula is A2's collapse levels with better vocabulary
Strategy A2 already calls for a collapsible hierarchy (full / lean / solo). The
archetype formula supplies the missing trigger: record project **stage**
(pre-PMF / growth / mature) in `state/projects.json`, and let the staffing review
read it. Pre-PMF small repo ≈ coordinator+engineer+verifier; mature ≈ full roster.

### F6. Positioning caution
Strategy rule: never pitch the org chart — BMAD owns the 12-persona story. If any of
this ships, frame it as **roster hygiene / self-amending staffing policy**
(differentiators 3+4), not "flywheel has archetypes too".

## Recommendation

Do NOT add a Hiring Manager agent or five archetype agents. Instead, when the due
improve pass runs (STATUS.md next-action 3):
1. Add a **staffing review** step to IMPROVE.md: compare roster vs. project stage;
   retire (archive) agent docs the stage no longer needs; propose new ones only
   through the normal MAINTENANCE.md process. (Extends A4 delete-to-add to agents.)
2. Add a `stage` field (pre-pmf | growth | mature) to the projects.json schema when
   A2 collapse-levels work happens — the two land together or not at all.
3. Optionally: archetype-stance presets as TEMPLATES.md acceptance-criteria variants,
   only if delegation friction shows up in LESSONS.md first (YAGNI until then).

Open questions for a future strategist run: does roster size measurably degrade
routing quality (spawns.json evidence)? What stage is flywheel-the-repo itself in
(likely pre-PMF → per its own formula: prototype/build/sweep, defer maintainer
machinery)?

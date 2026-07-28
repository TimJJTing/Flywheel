# Context-engineering guide implications for flywheel (2026-07-28)

Coordinator analysis (session 33) of:
- Anthropic guide: https://claude.com/blog/the-new-rules-of-context-engineering-for-claude-5-generation-models
  (core: Anthropic cut >80% of Claude Code's system prompt with no measured loss;
  shifts: rules→judgment, examples→interface design, upfront→progressive disclosure,
  repetition→single description, manual memory→auto-memory, simple specs→rich references)
- GPT-model feedback (user-supplied, 2026-07-28): guide transfers to frontier GPT
  (5.4–5.6) EXCEPT — keep examples where formatting/taste/tool-routing is subtle or
  the reader model is weak/low-reasoning; keep explicit rules for hard boundaries
  (authz, irreversible writes, compliance, output schemas); manage memory manually
  cross-platform (auto-memory is vendor-specific); never delete 80% blind — baseline,
  one variable at a time, re-run evals.
- docs/flywheel/research/positioning-and-cognitive-dashboard-2026-07.md

## Core razor

Guide threatens flywheel's FAT, not its MOAT. Strategy doc A1/A2/A4/A5 already
predicted the direction. Split every flywheel rule into:
- **Hard boundary (keep explicit, never soften to judgment):** HR2 anti-fabrication,
  HR3 never-self-verify, AUTONOMY.md ask-vs-act. Differentiation ranking #1 #2 #4.
- **Old-model compensation (cut/soften candidates):** duplicated rule blocks, verbose
  routing/escalation choreography, always-loaded detail used only mid-delegation.

## Proposed revisions (ranked)

1. **Kill duplication (guide shift: repetition→single description).** HR1-4 exist in
   CLAUDE.md adapter block AND INDEX.md plus a "keep identical" sync rule. State once
   in INDEX.md; adapter block points. Removes drift-maintenance burden.
2. **Slim always-loaded set (progressive disclosure).** Now 265/500 lines
   (CLAUDE.md+INDEX+ORCHESTRATION+FACTS). ORCHESTRATION keeps hierarchy table,
   three-element delegation, verification-never-self-performed; move §4 escalation
   detail, §6 parallelism/budget/spawn-provenance, §8 degraded mode to on-demand
   (fold into TEMPLATES.md or a DELEGATION.md). FACTS always-loaded shrinks to
   tier→model table + big-files + never-invent rule; verification provenance
   (source URLs, dates, adapter payload archaeology) moves to an on-demand log.
3. **New principle for MAINTENANCE.md: scaffold density scales with the weakest
   reader.** Coordinator docs (read by Fable/Opus/Sol) = lean principles. Delegation
   templates aimed at haiku/luna-class = keep full scaffolding, worked examples,
   checkable criteria. Protects TEMPLATES.md from blind future cuts.
4. **Accelerate A1 prose→interfaces.** Each improve pass converts ≥1 prose rule into
   check.sh/hook enforcement; state SCHEMAS.md → machine-validated JSON schema in
   check.sh; enum-constrained fields replace prose usage guidance.
5. **A2 hierarchy collapse knob more urgent.** config.json `full/lean/solo` collapse
   levels; verification separation survives collapse, 5-tier routing may not.
6. **Measure before cutting (GPT feedback).** Cuts happen on revertible improve
   branches, one variable at a time; spawns.json/LESSONS.md/activity.json are the
   eval substrate; log rule-violation incidents so each rule earns its tokens.
7. **Absorption events (A5):** auto-memory and `/doctor` (rightsizing) are vendor
   absorption of memory management + part of the improve loop. claude-code adapter
   may lean on /doctor for redundancy pruning; flywheel improve loop differentiates
   on friction-driven cross-vendor policy amendment. STATUS.md/state ledgers stay —
   manual state is required for portability (GPT feedback concurs).
8. **Rich references for verifier (guide shift 6 + positioning Q2).** Verifier/auditor
   delegations carry rubric files; dashboard debt/depth scores generated only by
   fresh-context auditor against a written rubric.

## Non-goals

- Do not drop TEMPLATES.md or the acceptance-criteria requirement.
- Do not relax HR2/HR3/AUTONOMY into "model judgment."
- Do not replace STATUS.md/ledgers with vendor auto-memory.

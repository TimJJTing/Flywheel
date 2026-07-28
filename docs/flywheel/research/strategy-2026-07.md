# Strategy — competitive positioning & assumptions to revise (2026-07-09)

Consulting session output (coordinator + web search, 2026-07-09). Guides roadmap and
priority decisions. Future strategist runs: start from the OPEN RESEARCH questions
below; update this file (or supersede it dated) rather than re-deriving.

Motto (human-chosen): **"Heroes come and go; policies compound."**
Niche statement: flywheel is not "another agent framework" — it is a **self-amending
operating policy** for LLM-run projects: facts verified or marked, completion never
self-graded, rules that amend themselves session by session. Portable to any adapter,
bound to none.

HR2 note: all external values below (stars, prices, feature claims) are web-sourced
2026-07-09, NOT verified in-repo. Re-verify before citing in user-facing docs.

## Competitive landscape

| Project | What it is | Overlap with flywheel | What flywheel has that it lacks |
|---|---|---|---|
| BMAD-METHOD (~48k stars) | Agent orchestration across full SDLC; 12+ role personas (PM, Architect, Dev, QA); file-based context passing; tool-portable markdown | HIGHEST — company metaphor, role tiers, portability. Closest competitor; it "won" the org-chart story | FACTS anti-fabrication ledger; fresh-context never-self-verified; self-amending improve loop; autonomy matrix; degraded mode |
| GStack (Garry Tan) | Opinionated roles, slash commands, and browser-based QA for Claude Code | High — role/workflow-centric, custom skills | Self-amending policy, anti-fabrication ledger, autonomy matrix, adapter neutrality, independent verification |
| Agent OS (Builder Methods) | "Install into any project, works with any tool"; spec-driven standards files | High on pitch (portable, repo-resident) | Orchestration policy, verification tiers, self-improvement, state ledgers |
| GitHub Spec Kit | Constitution-document, spec-driven development, tool-agnostic | Medium — repo-as-source-of-truth | Everything runtime: routing, verification, autonomy, improve loop |
| OpenSpec | Every change = approved proposal before code | Medium — approval gates ≈ autonomy matrix subset | Same as Spec Kit row |
| GSD (Open GSD) | CLI harness to slice milestones and run isolated tasks | High — context sharding, fresh runs, git branch hygiene | Self-amending policy, anti-fabrication ledger, autonomy matrix, adapter neutrality |
| MetaGPT / ChatDev / CrewAI | Harness-level multi-agent "software company" frameworks (Python) | Same founding metaphor, wrong layer — they ARE a harness | Adapter-neutrality; repo-is-the-harness; self-amendment |
| Vendor-native absorption (AGENTS.md standard, Claude Code skills/memory/plans, Cursor rules) | Harnesses shipping the convention layer natively | Eats flywheel from below | Cross-vendor portability; policy/verification/improvement layer vendors won't ship |

Sources: [HackerNoon spec-first showdown](https://hackernoon.com/the-spec-first-development-showdown-spec-kit-openspec-bmad-and-gangsta-agents-compared),
[Reenbit BMAD vs Spec Kit vs OpenSpec](https://reenbit.com/bmad-vs-spec-kit-vs-openspec-choosing-your-spec-driven-ai-framework/),
[Augment Code SDD tools 2026](https://www.augmentcode.com/tools/best-spec-driven-development-tools),
[ArceApps SDD deep dive](https://arceapps.com/blog/sdd-frameworks-analysis-spec-kit-openspec-bmad/).

## Differentiation ranking (invest top-down)

1. **Anti-fabrication discipline as first-class artifact** (FACTS.md, `Pending
   verification`, source+date per value). No competitor treats fabrication as the
   central failure mode. Sharpest original insight.
2. **Verification never self-performed as policy** (HR3, fresh-context verifier/auditor).
   BMAD has a QA persona but not the adversarial fresh-context framing.
3. **Self-amending improve loop** (IMPROVE.md, LESSONS.md, friction ledger). Competitors
   ship static methodology; flywheel amends its own.
4. **Autonomy matrix** — explicit ask-vs-act contract (AUTONOMY.md). Rare.
5. **Degraded mode** (ORCHESTRATION.md §8) — graceful no-subagent fallback. Nobody
   designs for this.

Positioning rule: pitch 1+3 ("policies that verify and amend themselves"), never the
org chart — BMAD owns that story.

## Strategic assumptions to revise

### A1. Prose policy ≠ enforcement
Assumption: markdown rules are followed. Reality: LLM compliance is probabilistic and
decays with context length; humans follow policy because of incentives/audits, LLMs
don't. Every rule that stays prose will eventually be violated.
Revise: treat every prose rule as debt; migrate rules into executable checks/hooks
(check.sh, PreToolUse/PostToolUse) per adapter. Docs teach, hooks enforce.
OPEN RESEARCH: measure prose-rule violation rate across sessions (spawns.json +
LESSONS.md as data); rank ORCHESTRATION/JUDGMENT rules by mechanizability; prototype
2-3 new check.sh checks or hooks per improve pass.

### A2. Fixed tier hierarchy is a cost optimization that dates fast
Assumption: smart labor scarce/expensive, so route by tier. Reality: token prices
falling, frontier models one-shot more; delegation overhead (prompts, report parsing,
retries) can exceed the work. BMAD's "$2k+/month" criticism applies here too.
Revise: make hierarchy collapsible — config knob where small projects run
coordinator+verifier only. Verification separation ages well; 5-tier routing may not.
OPEN RESEARCH: define collapse levels in config.json (full / lean / solo); measure
per-tier overhead vs. value from spawns.json; decide default for small repos.

### A3. Adapter-neutrality has a real cost
Assumption: lowest-common-denominator portability is worth it. Reality: harnesses
diverge fast; neutrality forfeits each harness's best features; N adapters against
moving targets (codex-hooks research already showed assumption rot).
Revise: claude-code = first-class adapter; others "supported, degraded". Never let
neutrality block best native features.
OPEN RESEARCH: write explicit adapter-tier policy (first-class / supported / degraded)
into ADAPTERS.md via structural process; audit which claude-code features are being
underused for neutrality's sake.

### A4. Self-improvement may not converge
Assumption: session-by-session amendment improves the system. Risk: rules accumulate
faster than deleted; long always-loaded files degrade compliance (the exact thing
being fought). Line budgets are the right instinct — generalize.
Revise: hard budget on TOTAL always-loaded bytes (check.sh already sums lines ≤500);
improve pass must delete to add (net-zero or net-negative rule growth).
OPEN RESEARCH: add delete-to-add rule to IMPROVE.md (structural process); track
always-loaded size over sessions in activity.json; alarm on growth trend.

### A5. Platform absorption is the existential risk
Assumption: the orchestration layer stays third-party. Reality: vendors shipping
memory, skills, plans, subagent policy natively; in ~18 months half of flywheel may be
a settings file.
Revise: invest only in what vendors won't ship — cross-vendor portability,
anti-fabrication ledger, self-amendment, independent-verification culture. Don't
over-invest in orchestration plumbing vendors will obsolete.
OPEN RESEARCH: quarterly vendor-parity check (what did claude-code/codex/opencode ship
natively that duplicates a flywheel file?); prune duplicated plumbing each improve pass.

## Update 2026-07-28: Anthropic context-engineering guide confirms A1/A2/A4/A5

Anthropic's Claude-5 context-engineering guide (claude.com/blog/the-new-rules-of-
context-engineering-for-claude-5-generation-models) + cross-vendor GPT feedback
independently confirm: A1 (interfaces over prose), A2 (frontier models one-shot more;
tier overhead can exceed work), A4 (always-loaded size is the enemy), A5 (new
absorption events: auto-memory, `/doctor` rightsizing). Hard boundaries (HR2, HR3,
autonomy matrix) are explicitly the KEEP category per both sources — moat unchanged.
Analysis + ranked revisions: docs/flywheel/research/context-engineering-guide-implications-2026-07.md.

## Standing instruction to future agents

Before any feature/priority/roadmap decision: read this file. Align with the
differentiation ranking (invest 1-3 first) and the five revise-actions. If evidence
contradicts an assumption here, update this file (dated) — don't silently diverge.

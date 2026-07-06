# Recommended companions — skills/plugins that pair well

Flywheel is deliberately self-contained. These pair well WITH it; none are required.
Whatever you adopt, add it to the adapter block's whitelist — unlisted skills are
ignored by design (DIAGNOSIS.md Leak 2).

## Worth whitelisting (Claude Code ecosystem examples)

- **A verification-before-completion skill** — reinforces JUDGMENT.md R2/R6 at the
  moment of claiming done.
- **A systematic-debugging skill** — structures bug work before the engineer tier
  starts patching symptoms.
- **Plan writing/executing skills** — complement the strategist tier's templates for
  long multi-session workstreams.
- **A chart/dataviz skill** — if you extend the dashboard, keep its design-system
  discipline.

## Adapter features worth enabling

- **Permission allowlists** — encode the autonomy matrix's hard rows (no push, no
  credential reads) as actual adapter permissions; policy + enforcement beats policy
  alone.
- **Session-end hooks** — IF sessions repeatedly skip wrapup (check LESSONS.md), a
  hook running `bash flywheel/check.sh` is the documented hardening path
  (flywheel/ADAPTERS.md Q5). Don't start with it; add it when evidence says so.

## Anti-recommendations

- Personality/verbosity modifiers and "always do X before ANY response" hooks —
  they compete with the orchestration rules for the model's obedience and burn the
  always-loaded budget. If you must keep one, whitelist it consciously.
- Additional agent frameworks on top of the tier system — two routing doctrines in
  one repo guarantees contradictions. Port the useful agent into a tier instead.

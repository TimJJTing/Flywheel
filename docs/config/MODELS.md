# Configuring models & providers per tier

All tier→model mapping lives in `flywheel/config.json` under
`tiers.<tier>.adapters.<adapter>`. Adapters mirror it; nothing else does.

## The iron rule

**Never write a model ID from memory** — not you, not the LLM. Model IDs recalled
from memory are the #1 fabrication vector in multi-session systems (flywheel's
ancestor project verified this the hard way). Every ID in config.json must have a
matching row in `flywheel/FACTS.md` §Model IDs with a source URL + date. Can't
verify → the cell stays `Pending verification` and the adapter falls back to its
default model (Claude Code: `model: inherit` in the agent files).

## Changing a tier's model

1. Verify the new ID against the provider/adapter live docs; record source + date in
   FACTS.md (MAINTENANCE.md: changing an existing fact needs an auditor check).
2. Edit `tiers.<tier>.adapters.<adapter>` in config.json.
3. Update the adapter mirror:
   - **Claude Code:** the `model:` frontmatter in `.claude/agents/<agent>.md`
     (agent↔tier mapping: researcher=strategist, plan-auditor=auditor, others
     same-named). `flywheel/check.sh` cross-checks frontmatter vs config and fails
     on drift.
   - **OpenCode:** the `model` ("provider/model-id") in opencode.json's agent entries.
   - **Codex:** nothing to edit — the block quotes config.json at runtime.
4. `bash flywheel/check.sh` must pass.

## Per-adapter value shapes

| Adapter | Keys | Notes |
|---|---|---|
| claude-code | `model` (alias or full ID), `effort` | effort levels are adapter-version-dependent — verify live, record in FACTS |
| codex | `model`, `reasoning` | applied by the human switching models; the block instructs |
| opencode | `provider`, `model` | opencode.json wants `"provider/model-id"` as one string — join them |

## Adding an adapter

Add a `<your-adapter>: { ... }` key under each tier's `adapters` (any shape your
adapter needs), then follow `flywheel/ADAPTERS.md`. The map is open — no schema
change required.

## Sizing guidance (design intent, not facts)

architect = your scarcest/strongest model, effort medium (judgment, not labor);
strategist/auditor = strong reasoning model, effort high; engineer/verifier = the
best coding model you can afford, effort high; utility = cheapest competent model,
effort high (high effort on a cheap model prevents careless batch errors — that
asymmetry is deliberate).

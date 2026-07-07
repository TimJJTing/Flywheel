# FACTS — Verified values only. Never fill these from memory.

Every value here was verified against a live source on the stated date, or is marked
`Pending verification`. If a value you need is absent, write `Pending verification`
and flag it in your report — do not invent. Model IDs recalled from memory are the
single most common fabrication vector in multi-session systems.

The bootstrap seed prompt (docs/SEED-PROMPT.md in the flywheel repo) fills this file.
Update it whenever a value is verified or found wrong; date-stamp every change.

## Model IDs / aliases per tier

Source of truth for tier→model mapping: `flywheel/config.json`. This table records the
VERIFICATION of those values (source URL + date).

Note: architect uses `xhigh` reasoning on codex (vs. `medium` effort on claude-code) —
an intentional cross-adapter asymmetry, not a mismatch to "fix" (codex has no
`medium`-tier convention documented here — codex has no `medium`, so architect
falls back to the top-tier codex model at its highest reasoning, `xhigh`).

| Tier | Adapter | Model ID | Verified against | Date |
|---|---|---|---|---|
| architect | claude-code | claude-fable-5 | session environment model table | 2026-07-07 |
| architect | codex | gpt-5.5-pro | GPT-5.5/GPT-5.4-mini web search | 2026-07-07 |
| architect | opencode | claude-fable-5 | mirrors claude-code via anthropic provider | 2026-07-07 |
| strategist | claude-code | claude-opus-4-8 | session environment model table | 2026-07-07 |
| strategist | codex | gpt-5.5 | GPT-5.5/GPT-5.4-mini web search | 2026-07-07 |
| strategist | opencode | claude-opus-4-8 | mirrors claude-code via anthropic provider | 2026-07-07 |
| engineer | claude-code | claude-sonnet-5 | session environment model table | 2026-07-07 |
| engineer | codex | gpt-5.5 | GPT-5.5/GPT-5.4-mini web search | 2026-07-07 |
| engineer | opencode | claude-sonnet-5 | mirrors claude-code via anthropic provider | 2026-07-07 |
| utility | claude-code | claude-haiku-4-5-20251001 | session environment model table | 2026-07-07 |
| utility | codex | gpt-5.4-mini | GPT-5.5/GPT-5.4-mini web search | 2026-07-07 |
| utility | opencode | claude-haiku-4-5-20251001 | mirrors claude-code via anthropic provider | 2026-07-07 |
| verifier | claude-code | claude-sonnet-5 | session environment model table | 2026-07-07 |
| verifier | codex | gpt-5.5 | GPT-5.5/GPT-5.4-mini web search | 2026-07-07 |
| verifier | opencode | claude-sonnet-5 | mirrors claude-code via anthropic provider | 2026-07-07 |
| auditor | claude-code | claude-opus-4-8 | session environment model table | 2026-07-07 |
| auditor | codex | gpt-5.5 | GPT-5.5/GPT-5.4-mini web search | 2026-07-07 |
| auditor | opencode | claude-opus-4-8 | mirrors claude-code via anthropic provider | 2026-07-07 |

## Adapter capabilities (verified live, not assumed)

| Fact | Value | Date |
|---|---|---|
| Subagent spawn works for all tier agents | Pending verification | — |
| Per-agent effort/reasoning pinning works | Pending verification | — |

## Toolchain (versions from commands run in THIS repo)

| Tool | Version | Command run | Date |
|---|---|---|---|
| (fill at bootstrap: language runtimes, package manager, test runner, git) | Pending verification | — | — |

## Big files — NEVER Read wholesale

Files > 200 KB in this repo (found via `find . -size +200k -not -path './.git/*'`).
Inspect via `jq`/`python3 -c`/`grep` slices or delegate to `utility`.

| File | Size | Notes |
|---|---|---|
| (fill at bootstrap; keep current) | — | — |

## Project data facts

Verified facts about this project's data/domain that agents would otherwise guess
(counts, schemas, formats). Each with the producing command.

- (fill at bootstrap)

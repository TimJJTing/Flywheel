# FACTS — Verified values only. Never fill these from memory.

Every value here was verified against a live source on the stated date, or is marked
`Pending verification`. If a value you need is absent, write `Pending verification`
and flag it in your report — do not invent. Model IDs recalled from memory are the
single most common fabrication vector in multi-session systems.

The bootstrap seed prompt (docs/SEED-PROMPT.md in the flywheel repo) fills this file.
Update it whenever a value is verified or found wrong; date-stamp every change.

## Model IDs / aliases per tier

Source of truth for tier→model mapping: `flywheel/config.json`. This table records the
VERIFICATION of those values (source URL + date). Verified: `Pending verification`.

| Tier | Model ID | Verified against | Date |
|---|---|---|---|
| architect | Pending verification | — | — |
| strategist | Pending verification | — | — |
| engineer | Pending verification | — | — |
| utility | Pending verification | — | — |
| verifier | Pending verification | — | — |
| auditor | Pending verification | — | — |

## Harness capabilities (verified live, not assumed)

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

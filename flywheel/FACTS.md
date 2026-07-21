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

Codex GPT-5.6 mapping policy: Sol for complex judgment, planning, verification, and
polish; Terra for everyday implementation; Luna for clear repeatable utility work.
Effort follows task complexity because the official manual states there is no exact
GPT-5.5→GPT-5.6 effort mapping.

| Tier | Adapter | Model ID | Verified against | Date |
|---|---|---|---|---|
| architect | claude-code | claude-fable-5 | session environment model table | 2026-07-07 |
| architect | codex | gpt-5.6-sol | https://learn.chatgpt.com/docs/models.md, Recommended models / Where each model shines | 2026-07-16 |
| architect | opencode | claude-fable-5 | mirrors claude-code via anthropic provider | 2026-07-07 |
| strategist | claude-code | claude-opus-4-8 | session environment model table | 2026-07-07 |
| strategist | codex | gpt-5.6-sol | https://learn.chatgpt.com/docs/models.md, Recommended models / Where each model shines | 2026-07-16 |
| strategist | opencode | claude-opus-4-8 | mirrors claude-code via anthropic provider | 2026-07-07 |
| engineer | claude-code | claude-sonnet-5 | session environment model table | 2026-07-07 |
| engineer | codex | gpt-5.6-terra | https://learn.chatgpt.com/docs/models.md, Recommended models / Where each model shines | 2026-07-16 |
| engineer | opencode | claude-sonnet-5 | mirrors claude-code via anthropic provider | 2026-07-07 |
| utility | claude-code | claude-haiku-4-5-20251001 | session environment model table | 2026-07-07 |
| utility | codex | gpt-5.6-luna | https://learn.chatgpt.com/docs/models.md, Recommended models / Where each model shines | 2026-07-16 |
| utility | opencode | claude-haiku-4-5-20251001 | mirrors claude-code via anthropic provider | 2026-07-07 |
| verifier | claude-code | claude-sonnet-5 | session environment model table | 2026-07-07 |
| verifier | codex | gpt-5.6-sol | https://learn.chatgpt.com/docs/models.md, Recommended models / Where each model shines | 2026-07-16 |
| verifier | opencode | claude-sonnet-5 | mirrors claude-code via anthropic provider | 2026-07-07 |
| auditor | claude-code | claude-opus-4-8 | session environment model table | 2026-07-07 |
| auditor | codex | gpt-5.6-sol | https://learn.chatgpt.com/docs/models.md, Recommended models / Where each model shines | 2026-07-16 |
| auditor | opencode | claude-opus-4-8 | mirrors claude-code via anthropic provider | 2026-07-07 |

## Adapter capabilities (verified live, not assumed)

| Fact | Value | Date |
|---|---|---|
| Subagent spawn/custom-agent discovery works | Verified for claude-code (2026-07-08); Codex CLI 0.144.5 live-spawned the custom utility agent (2026-07-16) | 2026-07-16 |
| Per-agent level pinning works (native effort/reasoning key) | Pending verification | — |
| claude-code Agent-spawn hook payload | matcher/tool_name is `"Agent"` (not `"Task"`); PreToolUse has no resolved model; PostToolUse adds `tool_response.resolvedModel` (actual model ID) — see `flywheel/resolve-spawn.py` | 2026-07-08 |
| codex SubagentStop payload | Live CLI 0.144.5 reports custom agent `agent_type:"default"` and parent `model`; child transcript first `session_meta` exposes `payload.source.subagent.thread_spawn.agent_path:"/root/utility"` and top-level `payload.agent_path` | 2026-07-16 |
| Codex project skill discovery | `.agents/skills` discovery verified live with CLI 0.144.5 | 2026-07-16 |
| Codex project trust/config/hooks | Project-local configuration and hooks load only for trusted projects; non-managed command hooks require explicit review/trust | 2026-07-16 |
| Codex live model availability | Account and CLI-version dependent; configured pins are not proof of entitlement | 2026-07-16 |
| Codex child runtime telemetry | Stable stop-hook payload does not expose the child's actual model/effort; resolver rows record config pins, not runtime proof | 2026-07-16 |
| Codex coordinator runtime telemetry | Exact `CODEX_THREAD_ID` rollout `turn_context` exposes the current turn's model/effort; the bounded wrapup resolver records it only after coordinator identity and repo cwd validation | 2026-07-18 |
| Antigravity CLI (agy) subagent model inheritance | Spawned subagents inherit the active model of the parent session; routing subagents to different models is not supported (known limitation) | 2026-07-12 |

## Toolchain (versions from commands run in THIS repo)

| Tool | Version | Command run | Date |
|---|---|---|---|
| Codex CLI | 0.144.5 | `codex --version` | 2026-07-16 |

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

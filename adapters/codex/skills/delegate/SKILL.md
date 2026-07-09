---
name: delegate
description: Use when composing any subagent delegation in this repo — selects the right tier agent and fills the matching template from flywheel/TEMPLATES.md
---
<!-- flywheel-managed -->

# Delegate

## 1. Route (flywheel/ORCHESTRATION.md §1 table)
- ≤2-file surgical edit, spec is obvious -> `engineer`. Truly one line -> inline instead.
- New feature / 3+ files / unknown approach -> `researcher` for a plan first, then
  `engineer`.
- "Where is X / read all Y / same edit across N files" -> `utility`.
- "Is it done?" for code -> `verifier`. For plans/docs -> `plan-auditor`. Never the
  author of the work being checked.
(Agent names map to tiers: researcher=strategist, plan-auditor=auditor.)

## 2. Fill the template
Open `flywheel/TEMPLATES.md`, pick the template matching the tier (1=strategist,
2=engineer, 3=utility, 4=verifier/auditor), fill every `{PLACEHOLDER}`. Do not
paraphrase the section headers (GOAL & MOTIVATION, CONTEXT, ACCEPTANCE CRITERIA,
REPORT FORMAT) — copy them verbatim so the receiving agent recognizes the contract.

## 3. Refuse to dispatch if any of these three are empty
1. GOAL & MOTIVATION (what + why)
2. ACCEPTANCE CRITERIA (objectively checkable, verification command per item where
   applicable)
3. REPORT FORMAT (what to return, where long output is saved)
If any is empty, stop and fill it — do not send the delegation anyway.

## 4. Spawn the codex agent
Codex only spawns a subagent when you explicitly ask it to. Name the agent to spawn
(one of `.codex/agents/*.toml`: architect / researcher / engineer / utility / verifier
/ plan-auditor) and pass the filled template as its task. Its `model` /
`model_reasoning_effort` are pinned in its `.toml` — do NOT restate a model in the
prompt; if a tier's config.json codex cell is still `Pending verification`, say so and
let the agent inherit the parent model rather than naming one from memory.

## 5. Respect the limits, log the spawn
Max two retries per tier (ORCHESTRATION.md §4); a retry must change something, never
resend the same prompt. Independent delegations can run in parallel (codex
`agents.max_threads`, default 6). The `SubagentStop` hook (`flywheel/resolve-spawn.py`,
wired in `.codex/hooks.json`) auto-appends the spawn row to
`flywheel/state/spawns.json`; verify/correct `outcome`/`notes` at wrapup. Never note
`model: per parent` — the real model is the tier's config.json codex value.

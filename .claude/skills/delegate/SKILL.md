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

## 4. Fallback if tier agents aren't registered
If the tier agents are not in the available `subagent_type` list (agent files created
this session may not register until next session), fall back to
`subagent_type: general-purpose` with the `model` parameter from
`flywheel/config.json` (tiers.<tier>.adapters.claude-code.model), paste the tier's rules from
`.claude/agents/<agent>.md` into the prompt, and state in the prompt that level
cannot be pinned this way. If that config value is still `Pending verification`, omit
the model parameter (adapter default) — never pass the placeholder string as a model.

## 5. Respect the limits, log the spawn
Max two retries per tier (ORCHESTRATION.md §4); a retry must change something, never
resend the same prompt. Independent delegations: launch in parallel, one message.
Note each spawn (agent, adapter, model, level, task ≤15 words, outcome) for wrapup to
append to `flywheel/state/spawns.json`. Never note `model: per parent` — resolve the
real model from `flywheel/config.json` for the tier.

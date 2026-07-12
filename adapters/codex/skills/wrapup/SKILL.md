---
name: wrapup
description: Use before ending a session or when context runs low — updates STATUS.md and state ledgers, runs check.sh, rebuilds the dashboard, commits
---
<!-- flywheel-managed -->

# Wrapup

## 1. Update flywheel/STATUS.md
Edit each section with what's true now: Current state, In flight, Next actions (in
order), Blockers/decisions pending the human. Amend existing entries; stay ≤ 40 lines
(check.sh enforces). Decisions history lives in state/decisions.json, not here.

## 2. Update state ledgers (flywheel/state/)
- `activity.json`: append one entry {ts, session (= previous max +1), summary ≤1 line,
  commits: [hashes made this session — fill after step 5, or amend]}.
- `spawns.json`: the `SubagentStop` hook (`flywheel/resolve-spawn.py`, wired in
  `.codex/hooks.json`) already auto-appended a row per subagent spawned this session —
  verify those rows and correct any wrong `outcome`/`notes` (the hook logs
  `outcome:"ok"`; fix it if a spawn actually retried/escalated/failed). Append one row
  by hand for the coordinator itself (this session's main model — no session-level event
  captures it). Resolve the real model from `flywheel/config.json` codex entries; never
  write `model:"per parent"`.
- `projects.json` / `issues.json`: update statuses, milestones, and commits arrays for
  anything this session advanced. Friction you noticed → new issue with
  `type: "friction"` (feeds the improve pass).
- `decisions.json`: entries for anything the autonomy matrix classed A (pending) or
  R (decided-by-llm) this session.

## 3. Quality floor (judgment — not automated)
JUDGMENT.md R6 remainder: q1 diff review hunk by hunk; q2 full test suite, quote the
summary line; q3 `git diff | grep -inE 'secret|password|api[_-]?key'` → no hits;
q6 data claims re-checked against FACTS.md.

## 4. Log escalations
Any delegation that hit ORCHESTRATION.md §4 (retry exhausted, escalated) → append one
line to `flywheel/LESSONS.md`: date | task | tier path | cause | rule to update.

## 5. Run the mechanical script
- First commit any NON-wrapup changes (code, docs) per `flywheel/GIT.md` — specific
  files, conventional message, never `-A`/`.`, never `--no-verify` — and append those
  hashes to this session's activity.json entry (else next session's drift check flags
  them).
- Then `bash flywheel/wrapup.sh` — automatically runs `gen_architecture.py` to update
  `docs/ARCHITECTURE.md` if python3 is present, executes `check.sh` (aborts on ✗; fix
  or log a justified override in LESSONS.md), rebuilds the dashboard, warns if
  activity.json is stale, commits the wrapup file set (including state ledgers, dashboard,
  and architecture doc) as `chore(flywheel): update state ledgers + dashboard`, and
  announces "improve pass due" on the `improve_cadence_sessions` boundary.

## 6. Report
Return the commit hash(es) (`git rev-parse --short HEAD`) and a one-line summary per
file group.

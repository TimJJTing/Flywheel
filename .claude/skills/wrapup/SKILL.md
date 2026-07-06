---
name: wrapup
description: Use before ending a session or when context runs low — updates STATUS.md and state ledgers, runs check.sh, rebuilds the dashboard, commits
---
<!-- flywheel-managed -->

# Wrapup

## 1. Update flywheel/STATUS.md
Edit each section with what's true now: Current state, In flight, Next actions (in
order), Blockers/decisions pending the human, Key decisions log (keep 10). Amend
existing entries; stay ≤ 60 lines (check.sh enforces).

## 2. Update state ledgers (flywheel/state/)
- `activity.json`: append one entry {ts, session (= previous max +1), summary ≤1 line,
  commits: [hashes made this session — fill after step 5, or amend]}.
- `spawns.json`: append one row per subagent spawned this session (agent, model,
  effort, task ≤15 words, outcome ok|retried|escalated|failed).
- `projects.json` / `issues.json`: update statuses, milestones, and commits arrays for
  anything this session advanced. Friction you noticed → new issue with
  `type: "friction"` (feeds the improve pass).
- `decisions.json`: entries for anything the autonomy matrix classed A (pending) or
  R (decided-by-llm) this session.

## 3. Run the mechanical check + quality floor
- `bash flywheel/check.sh` — a ✗ blocks committing doc changes; fix or log a justified
  override in LESSONS.md.
- JUDGMENT.md R6 remainder (not automated): q1 diff review hunk by hunk; q2 full test
  suite, quote the summary line; q3 `git diff | grep -inE 'secret|password|api[_-]?key'`
  → no hits; q6 data claims re-checked against FACTS.md.
- Delegate the mechanical parts to `utility` if main-session context is low.

## 4. Log escalations
Any delegation that hit ORCHESTRATION.md §4 (retry exhausted, escalated) → append one
line to `flywheel/LESSONS.md`: date | task | tier path | cause | rule to update.

## 5. Rebuild dashboard + commit
- `python3 flywheel/dashboard/build.py || node flywheel/dashboard/build.mjs`
- Commit per `flywheel/GIT.md`: specific files (never `-A`/`.`), conventional message,
  body says why, never `--no-verify`. Standard final commit:
  `chore(flywheel): update state ledgers + dashboard`.
- If activity.json length is now a multiple of `improve_cadence_sessions`
  (flywheel/config.json), say "improve pass due — run the improve skill next session."

## 6. Report
Return the commit hash(es) (`git rev-parse --short HEAD`) and a one-line summary per
file group.

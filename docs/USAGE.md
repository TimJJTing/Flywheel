# Usage — day to day with flywheel

## Giving work

Just describe the outcome you want. The coordinator routes it (plans via strategist,
code via engineer, checks via verifier). You don't pick tiers — but you can
("have the strategist plan this first").

Useful phrasings:
- "What's the state of X?" → answered from STATUS.md + ledgers, not vibes.
- "Set autonomy to 2" → the one config change only you may order.
- "Run the improve pass" → on-demand self-improvement (see BEHAVIORS.md).
- "Wrap up" → forces the end-of-session protocol early.

## Reading the dashboard

Open `flywheel/dashboard/dashboard.html` (double-click; works offline). It is rebuilt
at every wrapup.

- **Decisions awaiting you** — your inbox. Each has options + the LLM's
  recommendation + which autonomy rule sent it to you. Reply in your next session
  ("approve d3", "reject d4 because …").
- **Projects & milestones** — progress bars; expand for detail + linked commits.
- **Open issues** — bugs, questions, debt, and `friction` (fuel for improve passes).
- **Recent activity** — per-session summaries with commit hashes.
- **Agent spawns** — which agent (model, effort) did what, with outcomes. Failed or
  escalated rows are your early-warning signal that a tier is mis-sized.

Filters: per-section priority/type/status dropdowns + global text search.

## Approving / rejecting decisions

Tell any session "approve d3" / "reject d5: <reason>". It updates decisions.json,
executes or discards (e.g., merges the waiting improve branch), and the next
dashboard build reflects it.

## Reverting a self-improvement

Every improvement is one commit on one `flywheel/improve-<slug>` branch. Merged and
regretted? `git revert <hash>` — nothing else is entangled with it.

## Checking on health

- `bash flywheel/check.sh` — instant rules/budget/state audit, human-runnable.
- `flywheel/LESSONS.md` — the failure log; recurring lines mean the improve pass has
  material.
- Spawn ledger outcome column — retried/escalated/failed clusters show where the
  hierarchy leaks.

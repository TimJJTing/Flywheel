# Behaviors — what flywheel actually does, session to session

## Every session

1. **Start:** the LLM reads `flywheel/STATUS.md` and resumes from it — no re-deriving,
   no "let me look around first."
2. **Work:** the coordinator routes tasks to tier agents per ORCHESTRATION.md §1.
   Delegations carry goal+motivation, acceptance criteria, and a report format —
   always. Long outputs go to files, not into the conversation.
3. **Decisions:** anything the autonomy matrix marks A becomes a pending entry in
   `state/decisions.json` (your dashboard inbox); the session continues other work.
   R items are done and reported; D items just happen and are logged.
4. **Verification:** claimed-done code goes to a fresh `verifier`; rule docs and big
   plans go to the `auditor`. Authors never self-certify.
5. **End (wrapup):** STATUS.md updated, ledgers updated (activity, spawns, projects,
   issues, decisions), `check.sh` run (budget/consistency enforcement), dashboard
   rebuilt, everything committed with conventional messages on the right branches.

## Every N sessions (default 5)

The **improve pass**: audit the flywheel docs, read LESSONS.md + friction issues +
failed/escalated spawns, propose ≤ 3 atomic improvements, apply each on its own
`flywheel/improve-<slug>` branch with one commit. Whether they merge automatically
depends on your autonomy level; at the default (3) they wait in your decision queue.

## What accumulates

| Artifact | Grows how | Trimmed how |
|---|---|---|
| `state/*.json` ledgers | Append per session | Done items stay (history); dashboard filters |
| `flywheel/LESSONS.md` | One line per escalation/pivot/misread rule | > 80 lines → consolidated into JUDGMENT.md rules, raw log archived |
| `flywheel/STATUS.md` | Rewritten each wrapup | Hard ≤ 60 lines, enforced by check.sh |
| Commit history | Small conventional commits, branch per concern | Never rewritten |

## What never happens without you

Spending money, touching credentials, changing the autonomy level — at ANY level.
Plus everything your current level marks A (see `flywheel/AUTONOMY.md`).

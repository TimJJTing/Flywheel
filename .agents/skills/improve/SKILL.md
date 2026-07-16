---
name: improve
description: Use when wrapup announced "improve pass due", the user asks for it, or friction issues accumulate — runs the flywheel self-improvement protocol on revertible branches
---
<!-- flywheel-managed -->

# Improve

Execute `flywheel/IMPROVE.md` exactly. Condensed checklist:

1. **Audit:** dispatch `plan-auditor` over `flywheel/*.md` + the AGENTS.md flywheel
   block (contradictions, ground truth, ambiguity, executability). BLOCKER/MAJOR
   findings become improvement candidates.
2. **Gather:** `flywheel/LESSONS.md`; `flywheel/state/issues.json` where
   `type=="friction"`; latest `bash flywheel/check.sh` output; `spawns.json` rows with
   outcome retried/escalated/failed.
3. **Propose ≤ 3 atomic improvements**, each citing its motivating line. Zero is a
   valid outcome — do not manufacture improvements.
4. **Per improvement:**
   - `git checkout -b flywheel/improve-<slug>` (from main).
   - Structural files → MAINTENANCE.md §1 process first (researcher plan +
     plan-auditor approval).
   - Apply; `bash flywheel/check.sh`; rebuild dashboard.
   - ONE implementation commit: `improve(flywheel): <slug>`, body cites the
     motivating line.
   - Wrapup may add at most one bookkeeping-only commit, limited to STATUS, LESSONS,
     state ledgers, and generated dashboard/architecture output.
   - `git checkout main` before the next improvement (branches are independent).
5. **Merge gate:** AUTONOMY.md row "Merge flywheel self-improvement branch" at the
   current level (config.json). A → pending decisions.json entry with branch name,
   leave the branch unmerged. R → merge + decided-by-llm entry. D → merge + activity
   log.
6. **Record:** activity.json entry per improvement (branch + hash); close fixed
   friction issues; update STATUS.md.

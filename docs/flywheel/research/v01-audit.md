# Flywheel v0.1 — fresh-context plan/doc audit

Date: 2026-07-06 · Auditor: plan-auditor (opus, fresh context) · Scope: flywheel/*.md,
config.json, check.sh, distribution/adapters/**, docs/**, README.md, CLAUDE.md, install.sh, uninstall.sh.
Method: read every file; ran `bash flywheel/check.sh` (exit 0); diffed the four hard-rule
blocks; grepped repo-wide for concrete model IDs and for "check.sh compares" claims.

## Verdict: REVISE (1 blocker)

---

## Findings

### F1 — BLOCKER — flywheel/state/*.json (payload) + install.sh:137-158 + docs/SEED-PROMPT.md:52
The install payload ships flywheel's OWN populated ledgers as OWNED-BY-TARGET files.
`projects.json` and `activity.json` carry five commit hashes (`5fcca4c 089bfdb a26c727
eff2cd9 18649d1`) that exist only in the flywheel repo's git history, plus flywheel's own
project ("Flywheel v0.1 boilerplate") and issues (i1/i2). install.sh copies these verbatim
into a fresh target (create-if-absent). SEED-PROMPT Step 6 then says `bash flywheel/check.sh`
"must pass" — but check.sh (lines 93-99) runs `git cat-file -e <hash>` in the TARGET repo,
where none of the five hashes resolve → check.sh exits 1. Nothing in the seed prompt clears
the ledgers before Step 6. A fresh install therefore fails its own bootstrap gate, and every
new project inherits flywheel's project/issue rows as its own.
**Fix:** ship EMPTY ledgers in the install payload — the OWNED-BY-TARGET state files must be
`[]` (issues/decisions/spawns) and `[]`/skeleton (projects/activity) with no commit hashes.
Keep the populated dogfood ledgers only in the flywheel repo's working tree, not in what
install.sh copies. (Simplest: install.sh writes `[]` for each state file it creates instead
of `cp` from payload; or split payload/state-template/ from the dogfood state/.)

### F2 — MAJOR — flywheel/ADAPTERS.md:47
"the four hard rules in the block ... keep them verbatim-identical to INDEX.md's list
(check.sh compares)." check.sh does NOT compare the hard rules — grep confirms no HR /
hard-rule / verbatim logic anywhere in check.sh. The 4-file HR duplication (INDEX + 3 blocks)
has no mechanical guard, so a future edit to one copy silently drifts. The claim advertises a
safety net that does not exist. (HR bodies are currently identical — verified by diff — so no
present contradiction; the risk is the false guarantee.)
**Fix:** either add an HR-block comparison to check.sh, or reword to
"(keep in sync by hand; MAINTENANCE.md §1 governs edits — no automated check yet)".

### F3 — MAJOR — flywheel/MAINTENANCE.md:26-29
§2 claims budgets are "Enforced mechanically by flywheel/check.sh" and lists two the script
does NOT enforce: "Adapter always-loaded block ≤ 50 lines" (check.sh never line-counts any
*.block file) and "Always-loaded set (block + INDEX + ORCHESTRATION + FACTS) ≤ 500 lines
total" (no summation exists). Conversely check.sh enforces per-file budgets (ORCHESTRATION
120, AUTONOMY 75, JUDGMENT 130, GIT 55, IMPROVE 75, ADAPTERS 85, DIAGNOSIS 85, TEMPLATES 230,
FACTS 80) that §2 never documents. Doc and enforcer disagree on both sides.
**Fix:** add the block-≤50 and set-≤500 checks to check.sh, OR reword §2 to mark those two as
manual and list the per-file budgets check.sh actually owns.

### F4 — MAJOR — flywheel/AUTONOMY.md:25 vs flywheel/MAINTENANCE.md:15
AUTONOMY matrix row "Edit flywheel structural docs (MAINTENANCE.md matrix) | A A R R D" gives
"R" (do it, then report — no human ask) at L3. MAINTENANCE §1 says edits to
ORCHESTRATION/JUDGMENT/AUTONOMY/etc. UNCONDITIONALLY require "written strategist plan +
auditor approval, applied on a flywheel/improve-* branch." A lower-tier session reading only
AUTONOMY's "R" can reasonably conclude it may edit a structural doc in place and just report,
bypassing the strategist+auditor+branch process. The two rules govern the same action with
different framings and no cross-reference.
Reading A: "R" = permission to make the edit without pre-asking, but still via the MAINTENANCE
§1 process (branch + auditor), with the separate "Merge self-improvement branch" row (A at L3)
gating the human ask. Reading B: "R" = edit directly and report.
**Fix:** append to the AUTONOMY row/legend: "structural-doc edits always follow MAINTENANCE.md
§1 (strategist plan + auditor + improve branch); the A/R/D value only sets whether the human
is asked before the branch is opened."

### F5 — MINOR — flywheel/check.sh:125-127 vs docs/config/MODELS.md:23-24
The frontmatter-vs-config check does `if exp_model == "Pending verification": continue`, so at
bootstrap (all models Pending) it validates NEITHER model NOR effort — yet MODELS.md and
docs/config/ADAPTERS.md state "check.sh cross-checks frontmatter vs config and fails on drift."
True only after model cells are filled; effort drift is undetectable in the meantime.
**Fix:** compare `effort` independently of the model gate, or note "model+effort cross-check
activates once config.json model cells leave Pending verification."

### F6 — MINOR — flywheel/INDEX.md:36 + docs/config/DASHBOARD.md
The ledger field schemas (source of truth for agents writing state/*.json) live only in
docs/config/DASHBOARD.md, which install.sh does NOT copy into target projects; INDEX.md:36
even points to "the flywheel repo's docs/config/DASHBOARD.md." An installed project's session
has no shipped field schema — check.sh only validates array-shape + hash existence, not fields.
Compounded by F1's fix (emptying ledgers removes the implicit by-example schema).
**Fix:** ship a condensed ledger schema inside the flywheel/ payload (e.g. a
flywheel/state/SCHEMA.md or a section appended to a shipped doc) so installed sessions have it.

### F7 — MINOR — .claude/skills/delegate/SKILL.md:34-37 (and adapter copy)
Fallback §4 says fall back to `general-purpose` "with the `model` parameter from
flywheel/config.json (tiers.<tier>.harnesses.claude-code.model)." At bootstrap that cell is
literally "Pending verification"; a lower-tier session could pass `model:"Pending
verification"`. The dead value is never guarded.
**Fix:** add "if that cell is still `Pending verification`, omit the model param (use the
session default / `inherit`) and say so in the spawn note."

---

## Checked and OK (no finding)
- Four hard rules HR1-HR4 verbatim-identical across INDEX.md, claude-code block, opencode
  block, repo CLAUDE.md (diffed — IDENTICAL). Codex block's HR1 (drops "delegate to utility")
  and HR3 ("fresh-session Template 4 verdict") are deliberate degraded-mode variants, not
  contradictions.
- No concrete model ID anywhere in the repo — every tier model is `Pending verification`;
  agent frontmatter uses `model: inherit`. AC5 satisfied. Harness-capability claims that ARE
  concrete carry source+date (docs/config/ADAPTERS.md:16-17 opencode fields, 2026-07-06) or
  the `Unconfirmed, recommended to test live` marker (ADAPTERS.md:22-23, HUMAN-ATTENTION.md:26).
- Agent↔tier mapping (researcher=strategist, plan-auditor=auditor) stated where both
  vocabularies meet: agent file bodies, delegate SKILL:16, MODELS.md:23, check.sh mapping.
- config.json shape matches every prose reference to tiers.<tier>.harnesses.<harness>.{model,
  effort|reasoning|provider}.
- All flywheel/*.md line budgets pass check.sh; check.sh exits 0 in the dogfood repo; all
  ledger hashes resolve HERE (they won't in a fresh target — see F1).
- install.sh managed/owned split covers all 13 doctrine .md + check.sh; AGENTS.md
  single-block rule (opencode wins when both selected) matches docs. uninstall untested paths
  are honestly filed as issues i1/i2.

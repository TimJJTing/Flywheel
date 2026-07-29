# Verification — i20/i21/i23/i24 improvement branches (2026-07-29)

Verifier: fresh-context re-derivation, no author-supplied output trusted.

## Branch identity (git itself)

| Issue | Branch | HEAD | Commits ahead of main | Files touched |
|---|---|---|---|---|
| i20 | flywheel/improve-audit-failure-mode-rubric | 73610a5 (matches claim) | 1 | flywheel/IMPROVE.md, distribution/managed/flywheel/IMPROVE.md |
| i21 | flywheel/improve-wrapup-spawns-done-condition | ad49607 (matches claim) | 1 | .agents/skills/wrapup/SKILL.md, .claude/skills/wrapup/SKILL.md, distribution/shared/skills/wrapup/SKILL.md |
| i23 | flywheel/improve-positive-framing-judgment-r7 | 44e78b9 (matches claim) | 1 | flywheel/JUDGMENT.md, distribution/managed/flywheel/JUDGMENT.md |
| i24 | flywheel/improve-check-label-double-plus | 987800a (matches claim) | 1 | flywheel/check.sh, distribution/managed/flywheel/check.sh |

Pairwise `comm -12` on the four file lists: all empty — zero file overlap, confirming
independent revertibility. `git branch --merged main | grep improve-` does not list any
of the four (checked before and after the session's branch inspections). Commit subjects
44/47/47/42 chars, format `improve(flywheel): <slug>`, each body cites its issue.

## Per-branch gate re-run (commands executed by the verifier, not quoted from the author)

i20: `bash flywheel/check.sh | tail -1` → `✓ all checks passed`; `bash flywheel/check.sh
| grep IMPROVE.md` → `✓ IMPROVE.md: 64/75 lines`; `bash dev/check.sh | tail -1` → `PASS
repository distribution checks`; `grep -c 'premature completion' flywheel/IMPROVE.md` →
`1`; all five taxonomy names present (sediment, sprawl, no-op lines, duplicated sources
of truth, premature completion); `cmp` of the two copies silent/exit 0.

i21: `bash flywheel/check.sh | tail -1` → `✓ all checks passed`; `bash dev/check.sh |
tail -1` → `PASS repository distribution checks`; `bash tests/test_adapter_lifecycle.sh |
tail -1` → `PASS adapter lifecycle matrix`; `bash install.sh . --check --adapters
claude-code,codex,antigravity` → `PASS --check: installation matches distribution;
target unchanged`; all three SKILL.md copies 56 lines, `diff -r` silent both ways;
`grep -rniE 'Codex|Claude|Antigravity|\.codex|\.claude' distribution/shared/skills/wrapup/SKILL.md`
→ no output (exit 1).

i23: `bash flywheel/check.sh | tail -1` → `✓ all checks passed`; `... | grep JUDGMENT.md`
→ `✓ JUDGMENT.md: 129/130 lines`; `bash dev/check.sh | tail -1` → `PASS repository
distribution checks`; `wc -l` both copies → 129/129; `cmp` silent; line 100 reads exactly
`1. State both readings explicitly and pick neither.`; `grep -c 'Do not average
interpretations'` → `0`; `git diff --stat main..HEAD` → `2 files changed, 2
insertions(+), 2 deletions(-)`.

i24: `bash flywheel/check.sh | tail -1` → `✓ all checks passed`; `bash flywheel/check.sh
| grep flywheel-owned` → `✓ ... (CLAUDE.md block+INDEX+ORCHESTRATION+FACTS): 235/305
lines` and `✓ ... (AGENTS.md block+INDEX+ORCHESTRATION+FACTS): 246/305 lines` (single
`+`, caps unchanged); `grep -c 'block++'` → `0`; `bash dev/check.sh | tail -1` → `PASS
repository distribution checks`; `bash tests/test_adapter_lifecycle.sh | tail -1` → `PASS
adapter lifecycle matrix`; `cmp` of the two copies silent; `git diff --stat main..HEAD`
→ `2 files changed, 4 insertions(+), 4 deletions(-)` (matches AC4.5, not the earlier
wrong `2/2` the plan flagged as its own prior error).

## Probe (a): four-way merge simulation

First attempt used a bare `git clone` into scratch and FAILED `install.sh --check`
(exit 1) on the merged tree — but the identical command also failed identically on a
bare clone of **main alone** (no branches merged). Root cause: `.claude/`, `.codex/`,
`.agents/` local install marker files (`*.flywheel-created`, `*.flywheel-merged`) and
`flywheel/dashboard/dashboard.html` are gitignored (`.gitignore:1,3`; confirmed via
`git check-ignore -v`) and therefore absent from any fresh clone — an artifact of the
test method, not a defect in the branches. Corrected method: `cp -R` the full working
copy (git history + gitignored local install state) into scratchpad, merge there. Result:
octopus merge of all four branches onto main — clean, **zero conflicts** (`git merge
--no-edit <4 branches>` → "Merge made by the 'octopus' strategy", 9 files changed,
20 insertions(+), 8 deletions(-), matching the plan's zero-overlap claim). On that
merged tree: `flywheel/check.sh` → `✓ all checks passed`; `dev/check.sh` → `PASS
repository distribution checks`; `tests/test_adapter_lifecycle.sh` → `PASS adapter
lifecycle matrix`; `install.sh . --check --adapters claude-code,codex,antigravity` →
`PASS --check: installation matches distribution; target unchanged` (exit 0). All
scratch clones removed after use; real repo untouched throughout.

## Probe (b): i21 done-condition — reachable but still self-attested

Full `## 2` step read (`.claude/skills/wrapup/SKILL.md:14-30`). The new sentence —
"Done only when every spawn row from this session has been cross-checked, one at a
time, against this session's own record of what that spawn did" — upgrades the bullet
from an implicit "verify rows" to an explicit exhaustiveness requirement (every row,
one at a time, not a blanket glance). It closes the literal rubber-stamp gap the issue
named. It does NOT create an externally-checkable artifact: nothing forces the agent to
emit per-row evidence, and audit-fix #2 deliberately dropped a per-row report
requirement from `## 6` to avoid an unbounded enumeration. So a coordinator still cannot
mechanically confirm compliance from the report alone — only from re-doing the
cross-check itself. This is a real but partial fix: language-level rubber-stamp
prevention, not a structurally enforced one. Not a criterion failure (no AC claims full
external verifiability), but worth flagging as residual risk.

## Probe (c): i23 "pick neither" vs. removed "Do not average interpretations"

Read `flywheel/JUDGMENT.md:96-104` in full (all of R7). "Pick neither" alone is
theoretically satisfiable by implementing an averaged/blended reading (technically
"neither" of the two pure readings). However R7 is a 4-step unit, not a single line:
step 2 mandates escalation with both readings + a recommendation (not silent
implementation), and step 3 is explicit — "If neither is possible this session:
implement NOTHING for the ambiguous part." A model that implemented a blend without
escalating would violate step 2/3 regardless of step 1's wording, so the removed
sentence's binding force is preserved by the surrounding steps, not lost. No test
greps the old string (confirmed: `grep -c 'Do not average interpretations'` → 0
repo-wide on this branch), and `.claude/agents/plan-auditor.md` / `.codex/agents/
plan-auditor.toml` already say "state both readings" (consistent, unaffected).

## Probe (d): i20 rubric vs. MAINTENANCE.md §4 / improve skill / agent naming

`flywheel/IMPROVE.md:17` says "dispatch `auditor`" — consistent with `MAINTENANCE.md:69`
("dispatch `auditor`"), `ORCHESTRATION.md:19,25,65` (tier name "auditor" throughout),
`TEMPLATES.md:172`, `IMPROVE.md:31` ("auditor approval"). No contradiction introduced.
Pre-existing, unrelated naming split: `.claude/skills/improve/SKILL.md:11` says
"dispatch `plan-auditor`" (the concrete claude-code agent name) and `INDEX.md:19` (HR3)
also says `plan-auditor` — this split between tier-name "auditor" and agent-name
"plan-auditor" predates this branch and this branch does not touch either file, so it
is out of scope for i20's verdict (flagged for awareness, not a defect of this change).

## Repo state confirmation

Ended on `main` (`git branch --show-current` → `main`), zero merges, working tree
restored to the exact pre-session state (`flywheel/state/spawns.json` modified,
`docs/flywheel/plans/improve-i20-i21-i23-i24.md` untracked — both present, nothing
else). A `git stash -u` used mid-session to allow branch checkouts was popped back
cleanly (`git stash list` → empty) before the session ended.

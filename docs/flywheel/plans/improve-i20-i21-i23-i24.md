# Plan — improvements i20, i21, i23, i24 (four independent branches)

Author: strategist (claude-opus-5). Date: 2026-07-29. Status: awaiting `plan-auditor`.

Structural files per MAINTENANCE.md §1 → this plan + auditor approval, applied on
`flywheel/improve-*` branches, ONE implementation commit each (IMPROVE.md §Rules:
never bundle improvements).

## 0. Shared preconditions (read before any section)

Baseline verified this session (commands + decisive output):

| Command | Decisive output |
|---|---|
| `bash flywheel/check.sh \| head -25` | `✓ IMPROVE.md: 61/75 lines`, `✓ JUDGMENT.md: 129/130 lines`, `✓ all checks passed` |
| `bash dev/check.sh \| tail -3` | `PASS repository distribution checks` |
| `bash tests/test_adapter_lifecycle.sh \| tail -1` | `PASS adapter lifecycle matrix` (exit 0) |
| `bash install.sh . --check --adapters claude-code,codex,antigravity` | `PASS --check: installation matches distribution; target unchanged` |
| `wc -l flywheel/IMPROVE.md flywheel/JUDGMENT.md flywheel/check.sh .claude/skills/wrapup/SKILL.md` | `61`, `129`, `357`, `54` |

**Dogfood duplication rule (applies to i20, i23, i24).** `dev/check.sh:13-17` byte-compares
every file under `distribution/managed/flywheel/` against `flywheel/`:

```
  cmp -s "$src" "$ROOT/flywheel/$rel" || { echo "managed dogfood drift: flywheel/$rel" >&2; bad=1; }
```

So any edit to `flywheel/IMPROVE.md`, `flywheel/JUDGMENT.md`, or `flywheel/check.sh`
MUST be applied identically to `distribution/managed/flywheel/<same name>`.
Verified today: `diff -r flywheel distribution/managed/flywheel` reports only
FACTS.md / LESSONS.md / STATUS.md / config.json / state ledgers / dashboard.html as
"Only in flywheel" — every other file is byte-identical.

**Per-branch mechanics (IMPROVE.md step 4), identical for all four sections:**

```bash
git checkout main && git checkout -b flywheel/improve-<slug>
# apply the edits in this section
bash flywheel/check.sh                       # must end "✓ all checks passed"
python3 flywheel/dashboard/build.py          # dashboard.html is gitignored (.gitignore:1)
git add <exact files listed in the section>  # never -A / . (GIT.md:13)
git commit -m "improve(flywheel): <slug>" -m "<body: motivating issue line>"
git checkout main
```

AUDIT FIX (finding 9): the gates above are NOT sufficient on their own — for i21 a
missed copy passes `flywheel/check.sh`, `dev/check.sh`, AND
`tests/test_adapter_lifecycle.sh` (all exit 0; only the `install.sh --check` in §2
catches it). Before committing, run this section's own **Verification** block in full.
Those section-local blocks are the real gates.

**Expected benign warning.** `flywheel/check.sh:159` flags edits to
`flywheel/IMPROVE.md`, `flywheel/JUDGMENT.md`, `flywheel/check.sh`, `.claude/`, `.agents/`
with `⚠ Structural changes detected … ARCHITECTURE.md was not updated`. This is warn-only
(no `FAIL=1`). Verified: `python3 flywheel/dashboard/gen_architecture.py` followed by
`git status --porcelain docs/flywheel/ARCHITECTURE.md` prints nothing — the generated
architecture doc is structure-only and none of these edits change it. No action needed;
do NOT commit an ARCHITECTURE.md change.

**Independence.** The four sections touch six distinct files with zero overlap:

| Section | Files |
|---|---|
| i20 | `flywheel/IMPROVE.md`, `distribution/managed/flywheel/IMPROVE.md` |
| i21 | `distribution/shared/skills/wrapup/SKILL.md`, `.claude/skills/wrapup/SKILL.md`, `.agents/skills/wrapup/SKILL.md` |
| i23 | `flywheel/JUDGMENT.md`, `distribution/managed/flywheel/JUDGMENT.md` |
| i24 | `flywheel/check.sh`, `distribution/managed/flywheel/check.sh` |

No file, and no line, is touched by two sections. Any one branch applied alone leaves
`bash flywheel/check.sh` green (stated again per section). No coupling found — see
§5 Coupling notes for the two near-misses that were deliberately designed out.

---

## 1. i20 — IMPROVE.md audit step gains a named failure-mode rubric

Branch: `flywheel/improve-audit-failure-mode-rubric`
Commit subject: `improve(flywheel): audit-failure-mode-rubric` (44 chars ≤ 50)
Commit body must cite: `state/issues.json i20 — "Adopt named failure modes from mattpocock
writing-great-skills … as an explicit rubric for the improve-pass plan-auditor dispatch in
IMPROVE.md step 1"`.

### Files to edit (both, identically)
1. `/Users/jjting/Documents/projects/flywheel/flywheel/IMPROVE.md`
2. `/Users/jjting/Documents/projects/flywheel/distribution/managed/flywheel/IMPROVE.md`

### Budget check
`bash flywheel/check.sh` line for this file is `check_budget IMPROVE.md 75`
(`flywheel/check.sh:26`). The task brief's premise that "IMPROVE.md has no check.sh line
budget of its own" is **wrong** — it does: 75.

| File | Current lines | Budget | Post-edit lines |
|---|---|---|---|
| `flywheel/IMPROVE.md` | 61 (`wc -l`) | 75 (`check.sh:26`) | 64 |
| `distribution/managed/flywheel/IMPROVE.md` | 61 (`wc -l`) | none (no check_budget entry) | 64 |

Net +3 lines. IMPROVE.md is NOT in `ALWAYS_LOADED` (`check.sh:50` = `INDEX.md
ORCHESTRATION.md FACTS.md`), so the 305/500 always-loaded ratchets are unaffected.

### Edit — exact before/after

BEFORE (`flywheel/IMPROVE.md:17-18`, verbatim):

```
1. **Audit first** (MAINTENANCE.md §4): dispatch `auditor` over `flywheel/*.md` +
   adapter block. Fix BLOCKER/MAJOR findings as improvements below.
```

AFTER (replace those two lines with these five, verbatim):

```
1. **Audit first** (MAINTENANCE.md §4): dispatch `auditor` over `flywheel/*.md` +
   adapter block; the dispatch prompt lists these failure modes: sediment (stale
   lines nobody removed), sprawl (rules leaking past their home file), no-op lines
   stating default model behavior, duplicated sources of truth, premature completion
   (a step with no checkable done-condition). Fix BLOCKER/MAJOR findings below.
```

AUDIT FIX (finding 7): "naming this rubric" was readable as "mention that a rubric
exists". Replaced with "the dispatch prompt lists these failure modes" so the five
names must appear in the prompt. Still 5 lines, so IMPROVE.md still lands at 64/75.

EXECUTION FIX (engineer retry 1): an earlier revision of this fence wrapped as
"premature\n   completion", which made AC1.4's `grep -c 'premature completion'` return
0 and broke the section's own gate. The fence above keeps "premature completion" and
"no-op lines" each intact on a single line. Verify before committing:
`grep -c 'premature completion' flywheel/IMPROVE.md` -> 1.

Widths: 81/80/82/84/79 chars — within IMPROVE.md's existing 87-char maximum
(`awk '{print length}' flywheel/IMPROVE.md | sort -rn | head -1` → `87`).

### Deliberate non-edit (decision + rationale)
`.claude/skills/improve/SKILL.md:14-16` (and its `.agents/` + `distribution/shared/`
twins) condense the same step. They are NOT edited: line 9 of that skill reads
`Execute \`flywheel/IMPROVE.md\` exactly. Condensed checklist:` — the skill already
delegates to IMPROVE.md, and copying the rubric into three more files would create
exactly the "duplicated sources of truth" failure mode the rubric names.

### Verification (each must pass)
```bash
wc -l flywheel/IMPROVE.md distribution/managed/flywheel/IMPROVE.md   # both 64
cmp flywheel/IMPROVE.md distribution/managed/flywheel/IMPROVE.md     # silent, exit 0
bash flywheel/check.sh | grep 'IMPROVE.md'                           # ✓ IMPROVE.md: 64/75 lines
grep -c 'premature completion' flywheel/IMPROVE.md                   # 1
bash flywheel/check.sh | tail -1                                     # ✓ all checks passed
bash dev/check.sh | tail -1                                          # PASS repository distribution checks
```

### Acceptance criteria
- AC1.1 `cmp` of the two IMPROVE.md copies exits 0.
- AC1.2 `bash flywheel/check.sh` prints `✓ IMPROVE.md: 64/75 lines` and ends
  `✓ all checks passed`.
- AC1.3 `bash dev/check.sh` ends `PASS repository distribution checks`.
- AC1.4 All five taxonomy names appear on the branch:
  `grep -oE 'sediment|sprawl|no-op lines|duplicated sources of truth|premature completion' flywheel/IMPROVE.md | sort -u | wc -l` → `5`.
- AC1.5 Exactly one commit on the branch: `git rev-list --count main..HEAD` → `1`.

### Independence
Touches only IMPROVE.md. Applied alone, check.sh stays green (AC1.2).

---

## 2. i21 — wrapup skill: checkable done-condition for the spawns.json review

Branch: `flywheel/improve-wrapup-spawns-done-condition`
Commit subject: `improve(flywheel): wrapup-spawns-done-condition` (47 chars ≤ 50)
Commit body must cite: `state/issues.json i21 — "wrapup SKILL.md step 2 lacks a
done-condition; auto-appended spawn rows risk rubber-stamped default outcomes"`.

### Every copy of the wrapup skill text (evidence)

`find . -name SKILL.md -not -path './.git/*'` returns nine files; the wrapup ones are:

```
./.claude/skills/wrapup/SKILL.md
./.agents/skills/wrapup/SKILL.md
./distribution/shared/skills/wrapup/SKILL.md
```

They are three **independent regular files** (`ls -i` → inodes 21172529 / 22835638 /
23283329 — no symlinks, no hardlinks) and currently byte-identical
(`diff -r distribution/shared/skills/wrapup .claude/skills/wrapup` and
`… .agents/skills/wrapup` both silent).

Distribution source = `distribution/shared/skills/wrapup/SKILL.md`. Proof from the
installer: `installer/install.sh:9` sets
`SHARED_SKILLS_DIR="$REPO_ROOT/distribution/shared/skills"`; `installer/lifecycle/shared.sh:44-49`
copies that tree to `$TARGET/.agents/skills/…` when codex or antigravity is selected;
`installer/lifecycle/shared.sh:52-58` (`install_claude_skills`, called from
`installer/adapters/claude-code.sh:12`) copies the same tree to `$TARGET/.claude/skills/…`.
**All three must be edited.**

Per-adapter variants: none for this text. The only adapter-specific wrapup material is
`references/{claude-code,codex,antigravity}.md`, which cover telemetry provenance, not the
review's done-condition. They are NOT edited. Opencode installs no skill tree
(`installer/lifecycle/shared.sh:44` gates on codex/antigravity only; there is no
`.opencode/` directory in this repo).

### Consistency checks that exist (and the one gap)
- `tests/test_adapter_lifecycle.sh:28` — `diff -ru distribution/shared/skills/$skill
  .agents/skills/$skill` → covers source ↔ `.agents`.
- `tests/test_adapter_lifecycle.sh:22-23` — SKILL.md must still contain the literal
  `read exactly one file in \`references/\``.
- `tests/test_adapter_lifecycle.sh:24-27` — SKILL.md must NOT match
  `Codex|Claude|Antigravity|\.codex|\.claude`. **The new text below deliberately avoids
  all of those words.**
- `tests/test_adapter_lifecycle.sh:31-33` — every file under those trees must contain
  `flywheel-managed`.
(AUDIT FIX, finding 6: three of these four citations were off by one; corrected.)
- **Gap (finding):** no test compares `distribution/shared` ↔ `.claude/skills`. The
  command that does cover it is
  `bash install.sh . --check --adapters claude-code,codex,antigravity`
  (`installer/check.sh:4-30` installs into a shadow copy and `diff -qr`s the target).
  Verified green today. Use it as the cross-copy proof.

### Budget check

| File | Current lines | Budget | Post-edit lines |
|---|---|---|---|
| `distribution/shared/skills/wrapup/SKILL.md` | 54 (`wc -l`) | none — `check_budget` (check.sh:19-31) covers only `flywheel/*.md` | 56 |
| `.claude/skills/wrapup/SKILL.md` | 54 | none | 56 |
| `.agents/skills/wrapup/SKILL.md` | 54 | none | 56 |

### Edit — exact before/after (apply to all three files)

BEFORE (`distribution/shared/skills/wrapup/SKILL.md:19-23`, verbatim):

```
- `spawns.json`: verify any automatically appended subagent rows and correct wrong
  `outcome`/`notes` values; a default successful outcome must be changed when a spawn
  actually retried, escalated, or failed. Add the coordinator row as directed by the
  active-adapter reference. Resolve manual model/level only from verified adapter
  facts; never write inheritance placeholders or unverified model guesses.
```

AFTER (same five lines, plus three new lines appended to the same bullet):

```
- `spawns.json`: verify any automatically appended subagent rows and correct wrong
  `outcome`/`notes` values; a default successful outcome must be changed when a spawn
  actually retried, escalated, or failed. Add the coordinator row as directed by the
  active-adapter reference. Resolve manual model/level only from verified adapter
  facts; never write inheritance placeholders or unverified model guesses.
  Done only when every spawn row from this session has been cross-checked, one at a
  time, against this session's own record of what that spawn did.
```

Notes for the engineer:
- `spawns.json` rows have no `id` field — the schema
  (`flywheel/state/SCHEMAS.md`, spawns block) is
  `{ "ts", "agent", "adapter", "model", "level", "task", "outcome", "notes" }`, so the
  criterion identifies rows by `ts` + `task`. Use the wording above verbatim.
- AUDIT FIX (finding 2): the earlier draft added a third line requiring the `## 6.
  Report` section to enumerate every row. Dropped — §6 does not carry that requirement,
  an unbounded per-row enumeration cuts against ORCHESTRATION.md §3 ("Return ONLY:
  conclusions…"), and editing §6 would widen this branch beyond its one improvement.
- AUDIT FIX (finding 3): "against the transcript" was ambiguous for a smaller model
  (conversation history vs. the adapter's rollout file). Replaced with "this session's
  own record of what that spawn did" — adapter-neutral, and it adds no forbidden
  adapter name.
- Two lines added, not three: all three copies go 54 → **56** lines (not 57).
- Widths 83/65 — under the file's existing 153-char maximum.

### Verification
```bash
wc -l distribution/shared/skills/wrapup/SKILL.md .claude/skills/wrapup/SKILL.md .agents/skills/wrapup/SKILL.md   # 56 56 56
diff -r distribution/shared/skills/wrapup .claude/skills/wrapup    # silent
diff -r distribution/shared/skills/wrapup .agents/skills/wrapup    # silent
grep -c 'Done only when every spawn row' distribution/shared/skills/wrapup/SKILL.md   # 1
grep -rniE 'Codex|Claude|Antigravity|\.codex|\.claude' distribution/shared/skills/wrapup/SKILL.md   # no output
bash tests/test_adapter_lifecycle.sh | tail -1                    # PASS adapter lifecycle matrix
bash install.sh . --check --adapters claude-code,codex,antigravity  # PASS --check: installation matches distribution; target unchanged
bash flywheel/check.sh | tail -1                                  # ✓ all checks passed
```

### Acceptance criteria
- AC2.1 All three SKILL.md copies are 56 lines and byte-identical (`diff -r` silent ×2).
- AC2.2 `bash tests/test_adapter_lifecycle.sh` exits 0 (`echo $?` → `0`).
- AC2.3 `bash install.sh . --check --adapters claude-code,codex,antigravity` prints
  `PASS --check: installation matches distribution; target unchanged`.
- AC2.4 The adapter-name grep above returns no match (lifecycle boundary preserved).
- AC2.5 `git rev-list --count main..HEAD` → `1`; `git diff --name-only main..HEAD`
  lists exactly the three SKILL.md paths.

### Independence
Touches only the three wrapup SKILL.md copies; no `flywheel/*.md` and no budgeted file.
Applied alone, `bash flywheel/check.sh` is unaffected and stays green.

---

## 3. i23 — narrow negation audit (audited 25 candidates; 1 rewrite, 24 rejected)

Branch: `flywheel/improve-positive-framing-judgment-r7`
Commit subject: `improve(flywheel): positive-framing-judgment-r7` (47 chars ≤ 50)
Commit body must cite: `state/issues.json i23 — "Sweep flywheel/*.md for reframable style
negations … hard boundaries stay explicit prohibitions"`.

### Method (reproducible)
```bash
grep -nE "\b([Nn]ever|[Dd]on't|[Dd]o not|[Nn]ot |[Nn]o )" flywheel/*.md \
  | grep -vE "^flywheel/(STATUS|LESSONS|FACTS).md"
grep -nE "[Aa]void|must not|MUST NOT|should not|[Nn]ever\b" flywheel/*.md
```
Second pass added nothing new. Selection filter, applied in order:
1. Reject if it restates HR1–HR4, an AUTONOMY.md matrix/level-invariant rule, the
   `git add -A` ban, or `--no-verify` (issue text puts these out of scope).
2. Reject if the file is executed by utility/engineer-class models (TEMPLATES.md,
   DIAGNOSIS.md, adapter skill bodies) — MAINTENANCE.md:75-80 keeps their scaffolding
   and never softens hard boundaries "for anyone".
3. Reject if the line already pairs the prohibition with the positive alternative in
   the same sentence ("do X, not Y"). Pocock's negation failure mode is prohibition
   *without* a positive; a contrast clause is specification, not a leak.
4. Reject if the rewrite would add a line (always-loaded ratchet is at 235/305 and
   246/305; `ORCHESTRATION.md` and `INDEX.md` are always-loaded per `check.sh:50`).
5. Borderline → reject, with the reason recorded.

### ACCEPTED rewrite (exactly one)

`file:line | current | proposed`

`flywheel/JUDGMENT.md:100` |
`1. Do not average interpretations. State both readings explicitly.` |
`1. State both readings explicitly and pick neither.`

AUDIT FIX (finding 8): the first draft proposed "…and keep them separate", which drops
binding force — a model could state both and still implement a blend. "pick neither"
preserves the original prohibition's force in positive form. The auditor confirmed no
test, script, or agent definition greps the old string, and that
`.claude/agents/plan-auditor.md:22` + `.codex/agents/plan-auditor.toml:16` already say
"state both readings", so the rewrite stays consistent with them.

Rationale: the only pure style-steering prohibition found in a doc MAINTENANCE.md:77-78
explicitly classes as a strong-reader file ("Docs read only by
coordinator/architect/strategist tiers (INDEX, ORCHESTRATION, JUDGMENT) stay lean
principles"). "pick neither" carries the identical constraint as
"do not average" with no information loss. Line-count neutral (one line → one line).

Files to edit (both, identically):
1. `/Users/jjting/Documents/projects/flywheel/flywheel/JUDGMENT.md`
2. `/Users/jjting/Documents/projects/flywheel/distribution/managed/flywheel/JUDGMENT.md`

Exact context so the engineer edits the right line — BEFORE (`JUDGMENT.md:99-102`):

```
If a task hinges on ambiguous wording or a taste judgment with no rubric above:
1. Do not average interpretations. State both readings explicitly.
2. Escalate one tier up with both readings + your recommendation, or ask the human if
   the autonomy matrix says so.
```

AFTER:

```
If a task hinges on ambiguous wording or a taste judgment with no rubric above:
1. State both readings explicitly and pick neither.
2. Escalate one tier up with both readings + your recommendation, or ask the human if
   the autonomy matrix says so.
```

| File | Current lines | Budget | Post-edit lines |
|---|---|---|---|
| `flywheel/JUDGMENT.md` | 129 (`wc -l`) | 130 (`check.sh:23`) | 129 (neutral) |
| `distribution/managed/flywheel/JUDGMENT.md` | 129 | none | 129 |

JUDGMENT.md is at 129/130 — one line of headroom. The edit MUST stay line-neutral.

### REJECTED candidates (all of them, with the one-line reason)

Hard boundaries — HR1–HR4 restatements (filter 1):
- `flywheel/INDEX.md:15` `HR1. Never Read a file …` — HR1 itself.
- `flywheel/INDEX.md:18` `… never invent.` — HR2 itself.
- `flywheel/INDEX.md:19` `HR3. No agent declares its own work complete …` — HR3 itself.
- `flywheel/ORCHESTRATION.md:9` `— never from memory.` — HR2 at point of use.
- `flywheel/ORCHESTRATION.md:25` `Never the author.` — HR3 at point of use.
- `flywheel/ORCHESTRATION.md:48` `— never filled in.` — HR2 at point of use.
- `flywheel/ORCHESTRATION.md:59` `## 5. Verification is never self-performed` — HR3 heading.
- `flywheel/ORCHESTRATION.md:61` `… never issues the verdict on it.` — HR3.
- `flywheel/ORCHESTRATION.md:70` `a spot-check does not replace the verifier.` — HR3 limit.
- `flywheel/ORCHESTRATION.md:80` `… never invented (HR2)` — cites HR2 explicitly.
- `flywheel/ADAPTERS.md:27` `never name a model from memory.` — HR2.
- `flywheel/ADAPTERS.md:59` `Verification-never-self-performed` — HR3 term of art.
- `flywheel/DIAGNOSIS.md:64` `— never invent.` — HR2.
- `flywheel/DIAGNOSIS.md:67` `never self-verify.` — HR3.
- `flywheel/DIAGNOSIS.md:70` `— do not fill the gap.` — HR2 (the `Unconfirmed` literal).
- `flywheel/MAINTENANCE.md:80` `Hard boundaries … never soften for anyone.` — the
  meta-rule that makes this whole exclusion list binding.

Autonomy / explicitly fenced by the issue (filter 1):
- `flywheel/AUTONOMY.md:8, 27, 50, 54, 57, 62` — the matrix and its level-invariant rows.
- `flywheel/MAINTENANCE.md:14` `| \`autonomy\` value | Never by an agent |` — level-invariant row.
- `flywheel/JUDGMENT.md:58-59` `… names the non-decisions you must NOT ask about.` —
  **borderline, rejected**: a clean −1-line positive rewrite exists ("the non-decisions
  you just execute"), but the line governs ask-vs-act (HR4 territory) and the issue
  fences that off. Recorded here so a future pass can reconsider deliberately.
- `flywheel/JUDGMENT.md:124` `… at minimum an R row — never silent.` — autonomy row reference.
- `flywheel/GIT.md:13` `never \`git add -A\` / \`git add .\`` — named out of scope.
- `flywheel/GIT.md:14` `Never \`--no-verify\`.` — named out of scope.

Weakest-reader docs (filter 2 — MAINTENANCE.md:75-80):
- `flywheel/TEMPLATES.md:3, 80, 88, 107, 114, 140, 145, 184, 187, 196, 206, 217, 219` —
  templates are executed by engineer/utility tiers; scaffolding and explicit
  prohibitions stay.
- `flywheel/DIAGNOSIS.md:14` `do NOT Read directly` — HR1 procedure for every tier.
- `flywheel/DIAGNOSIS.md:43` `Do not invoke skills to satisfy a hook's blanket demand.` —
  **borderline, rejected**: it is the Leak 2 precedence rule read by every tier including
  the weakest; softening it is exactly the risk MAINTENANCE.md:80 forbids.

Positive alternative already present in the same sentence (filter 3):
- `flywheel/ADAPTERS.md:68` `The adapter never duplicates doctrine — it points at
  flywheel/ files.` — the positive ("points at flywheel/ files") is already there.
- `flywheel/ORCHESTRATION.md:5, 8` `the Commander does not step onto the battlefield` /
  `does not do detail work inline when a tier below can` — paired with "decides, routes,
  integrates".
- `flywheel/ORCHESTRATION.md:34` `"Works correctly" is not a criterion; "<test command>
  exits 0" is.` — contrast pair, the positive is the point.
- `flywheel/ORCHESTRATION.md:53` `never resend the same prompt verbatim` — paired with
  "a retry must change something".
- `flywheel/ORCHESTRATION.md:75` `never guess a dependency's output` — paired with
  "Dependent: strictly serial"; also a correctness rule.
- `flywheel/ORCHESTRATION.md:86, 89` `Resume from STATUS.md, not from re-deriving.` /
  `What is not committed does not exist.` — contrast pairs; also always-loaded (filter 4).
- `flywheel/JUDGMENT.md:62` `## R5. Wrong direction — pivot, don't retry` — the heading's
  contrast IS the rule.
- `flywheel/MAINTENANCE.md:30` `never by letting a file grow past one` — paired with
  "edit budgets there, via the structural process".
- `flywheel/MAINTENANCE.md:13` `never hand-edited` — paired with "config.json is the
  source of truth; run sync.py".

Own-file coupling (filter 5):
- `flywheel/IMPROVE.md:5, 23, 45, 55` (`The CEO never wakes up…`, `No improvement without
  a motivating observation`, `Never bundle improvements`, `never manufactures one`) —
  **rejected to preserve branch independence**: §1 (i20) edits IMPROVE.md on a different
  branch, and two branches editing one file defeats selective revertibility.
  `Never bundle improvements` is additionally a hard process boundary.

EXECUTION FIX (engineer retry 1): this section previously carried BOTH wordings — the
finding-8 text in the accepted-rewrite table and the pre-fix text in the AFTER fence and
the Verification grep. The single authoritative replacement line is
`1. State both readings explicitly and pick neither.` Both have been reconciled.

### Verification
```bash
wc -l flywheel/JUDGMENT.md distribution/managed/flywheel/JUDGMENT.md   # both 129
cmp flywheel/JUDGMENT.md distribution/managed/flywheel/JUDGMENT.md     # silent, exit 0
bash flywheel/check.sh | grep 'JUDGMENT.md'                            # ✓ JUDGMENT.md: 129/130 lines
grep -n 'State both readings explicitly and pick neither' flywheel/JUDGMENT.md   # 100:1. State …
grep -c 'Do not average interpretations' flywheel/JUDGMENT.md          # 0
bash flywheel/check.sh | tail -1                                       # ✓ all checks passed
bash dev/check.sh | tail -1                                            # PASS repository distribution checks
```

### Acceptance criteria
- AC3.1 `wc -l flywheel/JUDGMENT.md` → `129` (line-count neutral, ratchet unmoved).
- AC3.2 `cmp` of the two JUDGMENT.md copies exits 0.
- AC3.3 `bash flywheel/check.sh` prints `✓ JUDGMENT.md: 129/130 lines` and ends
  `✓ all checks passed`.
- AC3.4 `git diff --stat main..HEAD` shows exactly 2 files, `2 insertions(+), 2 deletions(-)`.
- AC3.5 `bash dev/check.sh` ends `PASS repository distribution checks`.

### Independence
Touches only JUDGMENT.md. The IMPROVE.md candidates were deliberately rejected so this
branch never collides with §1. Applied alone, check.sh stays green (AC3.3).

---

## 4. i24 — check.sh owned-cap label prints `block++`

Branch: `flywheel/improve-check-label-double-plus`
Commit subject: `improve(flywheel): check-label-double-plus` (42 chars ≤ 50)
Commit body must cite: `state/issues.json i24 — "check.sh flywheel-owned label renders
'AGENTS.md block++INDEX+ORCHESTRATION+FACTS' — double plus"`.

### Root cause (confirmed)
`flywheel/check.sh:55` seeds `label="$adapter_file"`; `check.sh:59` appends
`label="$label+${f%.md}"` per always-loaded file, giving
`CLAUDE.md+INDEX+ORCHESTRATION+FACTS`. Lines 66-67 then print
`"$adapter_file block+${label#*.md}"`; `${label#*.md}` strips the shortest `*.md`
prefix (`CLAUDE.md`) and leaves `+INDEX+ORCHESTRATION+FACTS`, which already starts with
`+`. Fix: delete the redundant literal `+` (one character per line, two lines).
Caps are computed from `$owned`, untouched — the change is display-only.

### Files to edit (both, identically)
1. `/Users/jjting/Documents/projects/flywheel/flywheel/check.sh`
2. `/Users/jjting/Documents/projects/flywheel/distribution/managed/flywheel/check.sh`

### Edit — exact before/after

BEFORE (`flywheel/check.sh:66-67`, verbatim, 4-space indent):

```
    if [ "$owned" -le 305 ]; then echo "✓ flywheel-owned always-loaded ($adapter_file block+${label#*.md}): $owned/305 lines";
    else echo "✗ flywheel-owned always-loaded ($adapter_file block+${label#*.md}): $owned lines exceeds 305"; FAIL=1; fi
```

AFTER:

```
    if [ "$owned" -le 305 ]; then echo "✓ flywheel-owned always-loaded ($adapter_file block${label#*.md}): $owned/305 lines";
    else echo "✗ flywheel-owned always-loaded ($adapter_file block${label#*.md}): $owned lines exceeds 305"; FAIL=1; fi
```

Both occurrences (the ✓ branch and the ✗ branch) change. The edit is mid-file, so do
not touch the file's trailing bytes. (AUDIT FIX, finding 4: an earlier claim that the
file lacks a final newline was false — it ends with `\n` and is exactly 357 lines.)

| File | Current lines | Budget | Post-edit lines |
|---|---|---|---|
| `flywheel/check.sh` | 357 (`wc -l`) | none — `check_budget` covers `.md` files only | 357 |
| `distribution/managed/flywheel/check.sh` | 357 | none | 357 |

### Exact expected output after the fix

`bash flywheel/check.sh | grep 'flywheel-owned'` must print exactly these two lines:

```
✓ flywheel-owned always-loaded (CLAUDE.md block+INDEX+ORCHESTRATION+FACTS): 235/305 lines
✓ flywheel-owned always-loaded (AGENTS.md block+INDEX+ORCHESTRATION+FACTS): 246/305 lines
```

(235 and 246 are today's measured values —
`bash flywheel/check.sh | grep 'flywheel-owned'` currently prints the same numbers with
`block++`. Neither i20, i21 nor i23 changes an always-loaded file, so these two numbers
hold on any combination of the four branches.)

The two `always-loaded set (…)` lines above them use `$label` directly and are already
correct; they must remain byte-identical:

```
✓ always-loaded set (CLAUDE.md+INDEX+ORCHESTRATION+FACTS): 238/500 lines
✓ always-loaded set (AGENTS.md+INDEX+ORCHESTRATION+FACTS): 246/500 lines
```

### Verification
```bash
grep -Fc 'block${label#*.md}'  flywheel/check.sh    # 2
grep -Fc 'block+${label#*.md}' flywheel/check.sh    # 0
cmp flywheel/check.sh distribution/managed/flywheel/check.sh   # silent, exit 0
bash flywheel/check.sh | grep 'flywheel-owned'                 # the two lines quoted above
bash flywheel/check.sh | grep -c 'block++'                     # 0
bash flywheel/check.sh | tail -1                               # ✓ all checks passed
bash dev/check.sh | tail -1                                    # PASS repository distribution checks
bash tests/test_adapter_lifecycle.sh | tail -1                 # PASS adapter lifecycle matrix
```

### Acceptance criteria
- AC4.1 `bash flywheel/check.sh | grep -c 'block++'` → `0`.
- AC4.2 The two `flywheel-owned` lines match the expected strings above character for
  character, including `235/305` and `246/305`.
- AC4.3 `cmp` of the two check.sh copies exits 0; both are 357 lines.
- AC4.4 `bash flywheel/check.sh` still ends `✓ all checks passed` and
  `bash dev/check.sh` ends `PASS repository distribution checks`.
- AC4.5 `git diff --stat main..HEAD` shows exactly
  `2 files changed, 4 insertions(+), 4 deletions(-)` — two changed lines per file
  (the ✓ branch and the ✗ branch) across both copies. AUDIT FIX (finding 1): the
  earlier `2 insertions(+), 2 deletions(-)` was wrong and would have read as a
  failure on a correct edit.

### Independence
Touches only check.sh (display strings). Applied alone, all caps compute identically and
check.sh stays green (AC4.4). `tests/test_adapter_lifecycle.sh` is included in the
verification set because its install probes execute the installed `check.sh`.

---

## 5. Coupling notes

- **Designed-out coupling A:** i23's raw candidate list contained four IMPROVE.md lines
  (`IMPROVE.md:5, 23, 45, 55`). They were rejected so §3 never touches the file §1 edits.
  Documented in §3's rejected list.
- **Designed-out coupling B:** i20's rubric could have been mirrored into
  `.claude/.agents/distribution` `improve/SKILL.md`, which would have made §1 touch skill
  files alongside §2. Rejected (§1 "Deliberate non-edit") — the skill already says
  "Execute `flywheel/IMPROVE.md` exactly".
- **No ordering constraint.** The four branches may be created and merged in any order.
  Merges are independent: no two branches touch the same file, so no rebase or conflict
  resolution is expected. If a merge conflict does appear, that is a signal the plan was
  deviated from — stop and report.
- **Merge gate.** All four fall under AUTONOMY.md's "Merge flywheel self-improvement
  branch" row; the coordinator applies it at the configured autonomy level
  (IMPROVE.md step 5). Out of scope for the engineer.
- **Ledger updates** (`state/issues.json` i20/i21/i23/i24 → closed, `activity.json`,
  `decisions.json`) are wrapup/coordinator work, not part of any implementation commit
  (IMPROVE.md step 4: bookkeeping stays out of the implementation commit).

---

## Found

- `flywheel/check.sh:26` — `check_budget IMPROVE.md 75`. IMPROVE.md **does** have a
  check.sh budget (the task brief said it had none); current 61 lines, so +3 fits.
  Command: `bash flywheel/check.sh | head -12` → `✓ IMPROVE.md: 61/75 lines`.
- `flywheel/check.sh:55,59,66-67` — the `block++` defect is a redundant literal `+`
  before `${label#*.md}`, which already begins with `+`. Live output:
  `✓ flywheel-owned always-loaded (CLAUDE.md block++INDEX+ORCHESTRATION+FACTS): 235/305 lines`.
- Three independent copies of the wrapup skill exist:
  `distribution/shared/skills/wrapup/SKILL.md` (source, per `installer/install.sh:9`),
  `.claude/skills/wrapup/SKILL.md` (`installer/lifecycle/shared.sh:52-58` ←
  `installer/adapters/claude-code.sh:12`), `.agents/skills/wrapup/SKILL.md`
  (`installer/lifecycle/shared.sh:44-49`). Distinct inodes (`ls -i`), currently identical
  (`diff -r` silent).
- `tests/test_adapter_lifecycle.sh:24-27` forbids the strings
  `Codex|Claude|Antigravity|\.codex|\.claude` inside the shared SKILL.md bodies — a real
  constraint on i21's wording.
- **Gap:** no test compares `distribution/shared/skills` against `.claude/skills`;
  `tests/test_adapter_lifecycle.sh:28` covers only `.agents`. The covering command is
  `bash install.sh . --check --adapters claude-code,codex,antigravity`
  (`installer/check.sh:4-30`), verified green today.
- `dev/check.sh:13-17` byte-compares `distribution/managed/flywheel/*` to `flywheel/*`,
  so IMPROVE.md, JUDGMENT.md and check.sh each have a mandatory second edit site.
  Verified: `bash dev/check.sh` → `PASS managed dogfood files are byte-identical`.
- `flywheel/state/SCHEMAS.md` spawns block — spawn rows carry
  `ts/agent/adapter/model/level/task/outcome/notes` and **no `id`**; the i21 criterion
  therefore identifies rows by `ts` + `task`.
- Negation sweep: 25 distinct negation lines in `flywheel/*.md` (excluding
  STATUS/LESSONS/FACTS). 24 are hard boundaries, autonomy rows, weakest-reader
  scaffolding, or already-paired contrast statements. Exactly one — `JUDGMENT.md:100` —
  is a pure style-steering prohibition in a strong-reader doc.
- `python3 flywheel/dashboard/gen_architecture.py` then
  `git status --porcelain docs/flywheel/ARCHITECTURE.md` → empty. The `⚠ Structural
  changes detected` warning from `check.sh:158-167` is expected and benign for all four
  branches.
- Baseline green before any edit: `bash flywheel/check.sh` → `✓ all checks passed`;
  `bash dev/check.sh` → `PASS repository distribution checks`;
  `bash tests/test_adapter_lifecycle.sh` → exit 0.

## Assumed

- The i20 taxonomy wording (the parenthetical glosses: "stale lines nobody removed",
  "rules leaking past their home file", "a step with no checkable done-condition") is
  authored here, not quoted. The mattpocock source was not fetched this session; only
  the derived summary in `docs/flywheel/research/positioning-and-cognitive-dashboard-2026-07.md:70-79`
  was available, and it names only "premature completion" and the information hierarchy
  verbatim. The five failure-mode NAMES come from the i20 issue `detail` field, which the
  task brief designates as the requirement statement.
- The i23 filter treats "prohibition already paired with its positive alternative in the
  same sentence" as out of scope. This reading of the Pocock negation failure mode is my
  interpretation; it is what keeps the rewrite list honest rather than manufactured
  (IMPROVE.md:50-51: "Zero is a valid count; manufactured improvements are negative
  value").
- Merge order and merge-gate handling are assumed to stay with the coordinator; the plan
  only guarantees the branches do not conflict.

## Could not find

- Any existing automated check that `distribution/shared/skills` matches
  `.claude/skills` other than the full `install.sh --check` shadow install. If the
  auditor wants that gap closed mechanically, it is a separate improvement (candidate
  for a future pass — IMPROVE.md's "prefer the candidate that converts a prose rule into
  a mechanical check" ranking rule).
- Any `.opencode/` skills tree in this repo (`ls -d .*/` → `.agents .claude .codex .git`),
  so "per-adapter wrapup variants for opencode" do not exist to keep in sync.
- The original mattpocock `writing-great-skills` text (no web fetch performed); the five
  failure-mode names are taken from the i20 issue entry, not from the upstream source.

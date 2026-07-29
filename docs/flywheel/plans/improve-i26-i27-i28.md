# Plan — improve pass for i26, i27, i28

Status: APPROVED. `plan-auditor` (fresh context, 2026-07-29) returned APPROVED WITH
REQUIRED CHANGES — 2 BLOCKER, 2 MAJOR, 3 MINOR. All seven were applied to this document
by the coordinator before dispatch: A3's scope narrowed to the rule files (§1.5),
`flywheel/MAINTENANCE.md:69` added to i27 (§2.3, §2.4b, §2.5-2.7), C6's expected output
corrected to two lines (§3.8), the `compact.py` stop-instruction promoted to §0.5, and
the §3.3 / §5 wording corrected. Re-audit is not required; execute as written.
Author tier: strategist. Date: 2026-07-29. Autonomy level at authoring: 3
(`flywheel/config.json:4`).

## 0. Scope, invariants, and rules that bind every section

Three independent, already-triaged issues from `flywheel/state/issues.json`. Each is
applied on its **own** branch cut from `main`, as **one** implementation commit.
`flywheel/IMPROVE.md:48-49` ("Never bundle improvements") forbids combining them; a
single branch fixing all three could not be reverted selectively.

**Structural authority.** `flywheel/MAINTENANCE.md:15-16` puts `ORCHESTRATION.md`,
`MAINTENANCE.md`, and `IMPROVE.md` behind "written `strategist` plan + `auditor`
approval, applied on a `flywheel/improve-*` branch". This document is that plan.
`flywheel/resolve-spawn.py` and `tests/test_resolve_spawn.py` fall under
`flywheel/MAINTENANCE.md:11` ("project code, tests | engineer+ per approved plan").

### 0.1 Mirror rule (VERIFIED — do not use the sync script for this)

`dev/check.sh:12-17` walks every file under `distribution/managed/flywheel` and runs
`cmp -s` against `flywheel/<rel>`; any byte difference fails the check with
`managed dogfood drift: flywheel/<rel>`.

`dev/sync-distribution.py` does **not** regenerate those mirrors. Its `outputs()`
function (`dev/sync-distribution.py:44-69`) only rewrites per-agent model/effort
projections and the OpenCode merge input; it never reads or writes anything under
`distribution/managed/`. `python3 dev/sync-distribution.py --check`
(`dev/check.sh:10`) therefore cannot repair a managed mirror.

**Consequence — the mirror is updated by hand-copy, one command per edited file:**

```
cp flywheel/<FILE> distribution/managed/flywheel/<FILE>
```

Run it AFTER the source edit, BEFORE staging. Never edit the mirror independently.

Files edited in this plan that HAVE a managed mirror (confirmed present by
`ls distribution/managed/flywheel/`): `ORCHESTRATION.md`, `MAINTENANCE.md`,
`IMPROVE.md`, `resolve-spawn.py`.
Files edited that have **no** mirror: `flywheel/state/spawns.json` (only `SCHEMAS.md`
lives under `distribution/managed/flywheel/state/`), `tests/test_resolve_spawn.py`
(repository-only).

### 0.2 Repository-gate impact, stated per edit (constraint (e))

| Gate | Location | i26 | i27 | i28 |
|---|---|---|---|---|
| Hard-rule verbatim duplicates | `dev/check.sh:32-48` | Not affected — reads only `distribution/managed/flywheel/INDEX.md` and the three non-Claude adapter block files; none is edited. | Same — not affected. | Same — not affected. |
| Repository-only paths inside the managed tree | `dev/check.sh:54-59` | Not affected — the replacement text adds no `distribution/`, `installer/`, `dev/`, or `tests/` token. | Not affected — same reason. | Not affected — the one-token change `indent=2` → `indent=1, ensure_ascii=False` introduces none of those tokens. The `tests/` edit is outside the managed tree. |
| Retired / unqualified path tokens across `flywheel`, `distribution`, `docs`, and the root docs | `dev/check.sh:61-68` | Not affected. | Not affected. | Not affected. |
| Managed dogfood byte-identity | `dev/check.sh:12-17` | **Affected** — §1 mirror step is mandatory. | **Affected** — §2 mirror step is mandatory. | **Affected** — §3 mirror step is mandatory. |
| Line budgets | `flywheel/check.sh:19-31` | Affected in the safe direction (see §1). | Line count unchanged (see §2). | Not affected (no `.md` line-count change). |

This plan document itself is inside `dev/check.sh:61`'s ripgrep scope (`$ROOT/docs`).
It has been written to contain none of that pattern's tokens, and the check was run
against it before dispatch — see §4.

### 0.3 Merge gate (identical for all three branches)

`flywheel/AUTONOMY.md:16` row "Merge flywheel self-improvement branch" is **A** at
levels 1-3, and `flywheel/config.json:4` is `"autonomy": 3`. Therefore, for each of
the three branches: **do not merge.** Per `flywheel/IMPROVE.md:39-40`, append a
`pending` entry to `flywheel/state/decisions.json` with options merge/reject, the
recommendation, and the branch name in `detail`. Leave the branch in place.

### 0.4 Commit hygiene (identical for all three branches)

- Stage only the files listed in that section's file list. Never `git add -A` / `git
  add .` (`flywheel/GIT.md:13`). Never `--no-verify` (`flywheel/GIT.md:14`).
- Exactly ONE implementation commit per branch (`flywheel/IMPROVE.md:33`).
- Commit body cites the motivating issue id and the source line, wrapped at 72
  (`flywheel/GIT.md:12`).
- Closing the issue in `flywheel/state/issues.json`, the `flywheel/state/activity.json`
  entry, and any `flywheel/STATUS.md` edit belong to the wrapup bookkeeping commit, NOT
  the implementation commit (`flywheel/IMPROVE.md:35-37`). The one exception is i28's
  one-time ledger normalization, which is part of the fix itself — see §3.
- Rebuild the dashboard after the edit (`flywheel/IMPROVE.md:32`):
  `python3 flywheel/dashboard/build.py`. Its output `flywheel/dashboard/dashboard.html`
  is gitignored (`.gitignore:1`) and is never staged.

### 0.5 Execution order

The three branches are independent and all cut from `main`. Run them in the order
i26 → i27 → i28. i26 and i27 both edit `flywheel/MAINTENANCE.md` (line 29 and line 69
respectively) — distant, non-overlapping hunks, so branches cut from the same `main`
merge cleanly, but land i26 first (or rebase i27 onto it) so any conflict surfaces once.

**Do NOT run `python3 flywheel/compact.py` anywhere in this pass**, even though
`flywheel/check.sh` prints `compaction due` on every run and
`flywheel/MAINTENANCE.md:39-41` schedules compaction for an improve pass.
`flywheel/compact.py:20` writes `indent=2` and would silently revert i28 (and churn
`activity.json`, indent=1 today). Open i29 for `compact.py` instead — §5 item 1.

Each section begins on `main`:

```
git -C /Users/jjting/Documents/projects/flywheel checkout main
git -C /Users/jjting/Documents/projects/flywheel status --porcelain
```

Expected working-tree state: `flywheel/state/spawns.json` is frequently dirty because
the spawn hook appends rows live (observed during authoring: ` M
flywheel/state/spawns.json`). That is normal and is not a blocker. Any OTHER modified
path is a blocker — stop and report it. Sections 1 and 2 must not stage
`flywheel/state/spawns.json`; section 3 stages it deliberately.

---

## 1. i26 — budget citations say 120, the check enforces 95

**Issue** (`flywheel/state/issues.json`, id `i26`, type `friction`, priority `P3`):
"MAINTENANCE.md and ORCHESTRATION.md cite ORCHESTRATION budget 120; check.sh enforces
95".

**Decision: reconcile the two prose citations DOWN to the enforced value 95; do not
touch `flywheel/check.sh`.** Rationale: the enforced value is the one that actually
gates commits, and `flywheel/MAINTENANCE.md:28` already declares the `check_budget`
list "the authoritative table" — prose must follow it, not the reverse. This is a
tightening, not a loosening, so `flywheel/IMPROVE.md:50-52` (loosening needs a
LESSONS.md justification) does not apply. Verified non-binding: `ORCHESTRATION.md` is
currently 90 lines (`wc -l flywheel/ORCHESTRATION.md` → `90`), so 95 leaves 5 lines of
headroom and no content must be cut.

**Branch slug:** `orchestration-budget-95`
**Branch:** `flywheel/improve-orchestration-budget-95`
**Commit subject:** `improve(flywheel): orchestration-budget-95`

### 1.1 Files touched (exhaustive)

1. `flywheel/ORCHESTRATION.md` — line 3
2. `distribution/managed/flywheel/ORCHESTRATION.md` — mirror, via `cp`
3. `flywheel/MAINTENANCE.md` — line 29
4. `distribution/managed/flywheel/MAINTENANCE.md` — mirror, via `cp`

No other file. `flywheel/check.sh:21` is deliberately left at 95.

### 1.2 Exact edits

**Edit A — `flywheel/ORCHESTRATION.md` line 3.** Replace the whole line.

BEFORE (exact, one line):

```
Always loaded. Keep under 120 lines; detail belongs in on-demand files (see INDEX.md).
```

AFTER (exact, one line):

```
Always loaded. Keep under 95 lines; detail belongs in on-demand files (see INDEX.md).
```

Only `120` → `95`. The line shortens by one character; no re-wrap, no neighbouring line
is touched.

**Edit B — `flywheel/MAINTENANCE.md` line 29.** Replace the whole line. Note the two
leading spaces (continuation of the bullet started on line 28) and the em dash.

BEFORE (exact, one line):

```
  `flywheel/check.sh` (INDEX 50, STATUS 40, ORCHESTRATION 120, and so on) — edit
```

AFTER (exact, one line):

```
  `flywheel/check.sh` (INDEX 50, STATUS 40, ORCHESTRATION 95, and so on) — edit
```

Only `ORCHESTRATION 120` → `ORCHESTRATION 95`. Line 28 and line 30 stay byte-identical;
do not re-wrap the bullet.

### 1.3 Mirror step

```
cd /Users/jjting/Documents/projects/flywheel
cp flywheel/ORCHESTRATION.md distribution/managed/flywheel/ORCHESTRATION.md
cp flywheel/MAINTENANCE.md   distribution/managed/flywheel/MAINTENANCE.md
```

### 1.4 Commit

```
git add flywheel/ORCHESTRATION.md flywheel/MAINTENANCE.md \
        distribution/managed/flywheel/ORCHESTRATION.md \
        distribution/managed/flywheel/MAINTENANCE.md
git commit
```

Subject: `improve(flywheel): orchestration-budget-95`
Body:

```
i26: MAINTENANCE.md:29 and ORCHESTRATION.md:3 cited an ORCHESTRATION
budget of 120 while flywheel/check.sh:21 enforces 95. Prose now follows
the check_budget list, which MAINTENANCE.md:28 already names as the
authoritative table. Tightening only: the file is 90 lines today.

Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>
```

### 1.5 Acceptance criteria (i26)

| # | Criterion | Command | Expected decisive output |
|---|---|---|---|
| A1 | The check still passes ORCHESTRATION.md, now against 95 | `bash flywheel/check.sh 2>&1 \| grep 'ORCHESTRATION.md'` | `✓ ORCHESTRATION.md: 90/95 lines` |
| A2 | Both prose citations now read 95 | `grep -n 'under 95 lines' flywheel/ORCHESTRATION.md distribution/managed/flywheel/ORCHESTRATION.md; grep -n 'ORCHESTRATION 95' flywheel/MAINTENANCE.md distribution/managed/flywheel/MAINTENANCE.md` | four hits: `...ORCHESTRATION.md:3:` twice and `...MAINTENANCE.md:29:` twice |
| A3 | No stale 120 citation survives in the rule files | `grep -rn 'ORCHESTRATION 120\|under 120 lines' flywheel/*.md distribution/managed/flywheel/*.md` | no output; exit status 1 |
| A4 | `check.sh` was NOT loosened | `grep -n 'check_budget ORCHESTRATION.md' flywheel/check.sh distribution/managed/flywheel/check.sh` | both lines read `check_budget ORCHESTRATION.md 95` |
| A5 | Mirrors are byte-identical and every repository gate passes | `bash dev/check.sh` | final line `PASS repository distribution checks`, exit 0; no `managed dogfood drift` line |
| A6 | Exactly one implementation commit on the branch | `git log --oneline main..HEAD` | exactly one line, subject `improve(flywheel): orchestration-budget-95` |
| A7 | Only the four planned files changed | `git diff --stat main..HEAD` | exactly 4 files, `4 files changed, 4 insertions(+), 4 deletions(-)` |

A3's scope is deliberately the rule files, not the whole tree. A repo-wide grep also
matches the historical `flywheel/state/issues.json` i26 record (which quotes both
strings verbatim as evidence), the generated `flywheel/dashboard/dashboard.html` that
embeds it, and this plan. Those are history and must NOT be rewritten — audit finding,
2026-07-29.

---

## 2. i27 — `IMPROVE.md` dispatches `auditor`; the Claude Code agent is `plan-auditor`

**Issue** (`flywheel/state/issues.json`, id `i27`, type `debt`, priority `P4`):
"IMPROVE.md dispatches `auditor` while the claude-code agent is named plan-auditor".

### 2.1 The constraint that shapes the wording (constraint (c))

`auditor` is the correct **tier** name and is used as such throughout the
adapter-neutral core: `flywheel/ORCHESTRATION.md:19` (tier table row `| auditor |`),
`flywheel/ORCHESTRATION.md:25`, `flywheel/ORCHESTRATION.md:56`,
`flywheel/ORCHESTRATION.md:65`, `flywheel/MAINTENANCE.md:15`,
`flywheel/MAINTENANCE.md:69`, `flywheel/TEMPLATES.md:172`, `flywheel/TEMPLATES.md:175`,
`flywheel/DELEGATION.md:15`. The fix must therefore NOT rename the tier — it must make
clear that `auditor` is a tier label the adapter layer resolves to a local agent name.
The Claude Code adapter already resolves it correctly
(`.claude/skills/improve/SKILL.md:14` dispatches `plan-auditor`;
`.claude/skills/delegate/SKILL.md:16` states "plan-auditor=auditor").

A pointer such as "see ADAPTERS.md" was rejected: `flywheel/ADAPTERS.md` contains no
tier-to-agent-name mapping table (verified by reading all 78 lines), so that pointer
would dangle.

### 2.2 Recommended wording (ONE recommendation)

**Recommendation: insert the single word `tier` before the backticked label on line 17,
changing nothing else.** It marks `auditor` as a tier label at the exact point of
confusion, keeps the tier vocabulary used by the six files listed in §2.1, adds no
adapter-specific name to an adapter-neutral file, and — decisively — fits on the
existing line, so no surrounding line re-wraps. Line 17 goes from 82 to 87 characters,
which equals the file's current longest line (line 3, 87 characters, measured with
`awk '{print length}' flywheel/IMPROVE.md | sort -rn | head -1` → `87`). The
re-wrap-free property matters: `flywheel/LESSONS.md` records three separate defects in
2026-07-29 entries caused by reflowing plan/doc text, and the minimal edit avoids that
class entirely.

**Runner-up (not chosen):** re-wrap lines 17-18 to read "dispatch the `auditor` tier
over `flywheel/*.md` / + adapter block; …" — better English, but it rewrites two lines
and moves a token across a line boundary, which is precisely the reflow pattern that
produced the 2026-07-29 fence defects.

### 2.3 Files touched (exhaustive)

1. `flywheel/IMPROVE.md` — line 17
2. `distribution/managed/flywheel/IMPROVE.md` — mirror, via `cp`
3. `flywheel/MAINTENANCE.md` — line 69
4. `distribution/managed/flywheel/MAINTENANCE.md` — mirror, via `cp`

`flywheel/MAINTENANCE.md:69` carries a byte-identical construction to the IMPROVE.md:17
defect, and IMPROVE.md:17 points straight at it ("MAINTENANCE.md §4"). Fixing only one
would leave the two canonical sources disagreeing — audit finding, 2026-07-29. This is
ONE improvement applied in two places, which `flywheel/IMPROVE.md:48-49` permits; that
rule forbids bundling separate improvements onto one branch, not applying one fix
everywhere it lands.

No other file. In particular the skill bodies are NOT touched: they already say
`plan-auditor`.

**Branch slug:** `auditor-tier-naming`
**Branch:** `flywheel/improve-auditor-tier-naming`
**Commit subject:** `improve(flywheel): auditor-tier-naming`

### 2.4 Exact edit — `flywheel/IMPROVE.md` line 17

Replace the whole line. Note the `§` in `§4` is a multi-byte character; copy the line
verbatim.

BEFORE (exact, one line):

```
1. **Audit first** (MAINTENANCE.md §4): dispatch `auditor` over `flywheel/*.md` +
```

AFTER (exact, one line):

```
1. **Audit first** (MAINTENANCE.md §4): dispatch tier `auditor` over `flywheel/*.md` +
```

The ONLY difference is the inserted word `tier ` between `dispatch ` and `` `auditor` ``.
Lines 16 and 18 stay byte-identical; the trailing `+` stays on line 17; the file line
count stays 64.

### 2.4b Exact edit — `flywheel/MAINTENANCE.md` line 69

Same one-word insertion, same rationale. Replace the whole line.

BEFORE (exact, one line):

```
release, dispatch `auditor` over `flywheel/*.md` + the adapter block, checking:
```

AFTER (exact, one line):

```
release, dispatch tier `auditor` over `flywheel/*.md` + the adapter block, checking:
```

Lines 68 and 70 stay byte-identical; the file line count stays 83 (budget 90).

### 2.5 Mirror step

```
cd /Users/jjting/Documents/projects/flywheel
cp flywheel/IMPROVE.md distribution/managed/flywheel/IMPROVE.md
cp flywheel/MAINTENANCE.md distribution/managed/flywheel/MAINTENANCE.md
```

### 2.6 Commit

```
git add flywheel/IMPROVE.md distribution/managed/flywheel/IMPROVE.md \
        flywheel/MAINTENANCE.md distribution/managed/flywheel/MAINTENANCE.md
git commit
```

Subject: `improve(flywheel): auditor-tier-naming`
Body:

```
i27: IMPROVE.md:17 read as an agent name, but no adapter ships an agent
called "auditor" — Claude Code names it plan-auditor. Marking the label
as a tier keeps the adapter-neutral vocabulary used by
ORCHESTRATION.md:19 and TEMPLATES.md:172 while removing the misread.
MAINTENANCE.md:69 carries the same construction and is the line
IMPROVE.md:17 points at, so it takes the same one-word fix.

Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>
```

### 2.7 Acceptance criteria (i27)

| # | Criterion | Command | Expected decisive output |
|---|---|---|---|
| B1 | Line 17 is exactly the AFTER text | `awk 'NR==17' flywheel/IMPROVE.md` | ``1. **Audit first** (MAINTENANCE.md §4): dispatch tier `auditor` over `flywheel/*.md` +`` |
| B1b | MAINTENANCE.md line 69 is exactly the AFTER text | `awk 'NR==69' flywheel/MAINTENANCE.md` | ``release, dispatch tier `auditor` over `flywheel/*.md` + the adapter block, checking:`` |
| B2 | The diff is a one-word insertion per file, nothing else | `git diff --word-diff=plain main..HEAD -- flywheel/IMPROVE.md flywheel/MAINTENANCE.md` | two hunks, each whose only change marker is `{+tier +}` (or `{+tier+}`) |
| B3 | Line counts unchanged and inside budget | `bash flywheel/check.sh 2>&1 \| grep -E 'IMPROVE.md\|MAINTENANCE.md'` | `✓ IMPROVE.md: 64/75 lines` and `✓ MAINTENANCE.md: 83/90 lines` |
| B4 | Mirrors are byte-identical | `cmp flywheel/IMPROVE.md distribution/managed/flywheel/IMPROVE.md; cmp flywheel/MAINTENANCE.md distribution/managed/flywheel/MAINTENANCE.md; echo rc=$?` | `rc=0`, no other output |
| B5 | Tier vocabulary elsewhere is untouched | `git diff --stat main..HEAD -- flywheel/ORCHESTRATION.md flywheel/TEMPLATES.md flywheel/DELEGATION.md flywheel/INDEX.md` | no output |
| B6 | Every repository gate passes | `bash dev/check.sh` | final line `PASS repository distribution checks`, exit 0 |
| B7 | Exactly one implementation commit, four files | `git log --oneline main..HEAD; git diff --stat main..HEAD` | one commit line; `4 files changed, 4 insertions(+), 4 deletions(-)` |

---

## 3. i28 — `resolve-spawn.py` rewrites the spawn ledger with the wrong shape

**Issue** (`flywheel/state/issues.json`, id `i28`, type `friction`, priority `P3`):
"resolve-spawn.py rewrites spawns.json with indent=2/ensure_ascii=True, churning the
whole file".

**Confirmed on disk.** Top-level indent of each ledger, and whether it contains
`\u` escapes, measured per file:

| Ledger | Top-level indent | Non-ASCII escaped? |
|---|---|---|
| `flywheel/state/projects.json` | 1 | no |
| `flywheel/state/issues.json` | 1 | no |
| `flywheel/state/decisions.json` | 1 | no |
| `flywheel/state/activity.json` | 1 | no |
| `flywheel/state/spawns.json` | **2** | **yes** (`"summary": "compacted 73 entries — …"`) |

`flywheel/state/spawns.json` is the only ledger written by a script on this path
(`flywheel/resolve-spawn.py:530`), and it is the only one that diverges. Every hook
firing therefore re-indents and re-escapes the entire file, producing a whole-file diff
for a one-row append.

**Decision: change the writer to `indent=1, ensure_ascii=False`, normalize the existing
ledger once in the same commit, and update the one test that asserts the old byte
shape.** Normalizing in the same commit is what makes the fix observable — without it
the first post-fix hook run produces exactly the whole-file churn the issue is about,
and the commit would not be cleanly revertible as a unit.

**Branch slug:** `spawn-ledger-indent`
**Branch:** `flywheel/improve-spawn-ledger-indent`
**Commit subject:** `improve(flywheel): spawn-ledger-indent`

### 3.1 Files touched (exhaustive)

1. `flywheel/resolve-spawn.py` — line 530
2. `distribution/managed/flywheel/resolve-spawn.py` — mirror, via `cp` (line 530 is
   currently byte-identical)
3. `tests/test_resolve_spawn.py` — line 744 (the golden byte-shape assertion)
4. `flywheel/state/spawns.json` — one-time normalization, generated by the command in
   §3.4, never hand-edited

No mirror exists for items 3 and 4: `tests/` is repository-only, and
`distribution/managed/flywheel/state/` contains only `SCHEMAS.md` (verified by `ls`).
`distribution/defaults/flywheel/state/spawns.json` is the two-byte seed `[]` and is
NOT touched.

### 3.2 Exact edit A — `flywheel/resolve-spawn.py` line 530

Replace the whole line. Note the eight leading spaces.

BEFORE (exact, one line):

```
        json.dump(data, f, indent=2)
```

AFTER (exact, one line):

```
        json.dump(data, f, indent=1, ensure_ascii=False)
```

Lines 528-529 (`f.seek(0)` / `f.truncate()`) and line 531 (`f.write("\n")`) stay
byte-identical. The trailing newline written by line 531 already matches the other
ledgers (all five end in `0x0a`, verified with `tail -c 1 | xxd`).

### 3.3 Exact edit B — `tests/test_resolve_spawn.py` line 744

This is the only assertion in the suite that pins the serialized byte shape (found with
`grep -n "startswith" tests/test_resolve_spawn.py`, which returns exactly three hits in
total: 459 and 555 are message/notes prefixes and stay untouched, and 743 is this same
assertion's own multi-line opener). It currently encodes
`indent=2` and WILL fail after edit A.

Context lines 743-745, BEFORE (exact):

```
        self.assertTrue(self.ledger.read_text(encoding="utf-8").startswith(
            '[\n  {\n    "ts"'
        ))
```

AFTER (exact):

```
        self.assertTrue(self.ledger.read_text(encoding="utf-8").startswith(
            '[\n {\n  "ts"'
        ))
```

Only line 744 changes: the two-space/four-space indents inside the literal become
one-space/two-space. Lines 743 and 745 stay byte-identical.

Do NOT change the fixture writers at `tests/test_resolve_spawn.py:497`, `:548`, and
`:565` — they build ledger *inputs* with `json.dumps(..., indent=2)`, are consumed by
`json.load`, and leaving them at indent 2 keeps them a useful proof that the writer
normalizes whatever shape it reads.

### 3.4 Exact edit C — one-time normalization of `flywheel/state/spawns.json`

Do not hand-edit. Run exactly this, from the repository root, AFTER edit A. The first
line snapshots the pre-normalization bytes; criterion C4 reads that snapshot. The
snapshot must be taken from the WORKING TREE, not from `main` — the spawn hook appends
rows live, so `git show main:flywheel/state/spawns.json` is not a valid baseline
(verified during authoring: it already differed from the working tree).

```
cd /Users/jjting/Documents/projects/flywheel
cp flywheel/state/spawns.json /tmp/i28-before.json
python3 - <<'PY'
import json, pathlib
p = pathlib.Path("flywheel/state/spawns.json")
data = json.loads(p.read_text(encoding="utf-8"))
p.write_text(json.dumps(data, indent=1, ensure_ascii=False) + "\n", encoding="utf-8")
print("rows:", len(data))
PY
```

This reproduces byte-for-byte what `flywheel/resolve-spawn.py:530` + `:531` will emit
after edit A, so the next hook firing appends one row and diffs one row.

If a hook fires between the normalization and the commit and re-churns the file, re-run
this snippet before staging.

### 3.5 Mirror step

```
cd /Users/jjting/Documents/projects/flywheel
cp flywheel/resolve-spawn.py distribution/managed/flywheel/resolve-spawn.py
```

### 3.6 Commit

```
git add flywheel/resolve-spawn.py distribution/managed/flywheel/resolve-spawn.py \
        tests/test_resolve_spawn.py flywheel/state/spawns.json
git commit
```

Subject: `improve(flywheel): spawn-ledger-indent`
Body:

```
i28: resolve-spawn.py:530 wrote the spawn ledger with indent=2 and ASCII
escaping while every other flywheel/state ledger is indent=1 with
literal UTF-8, so each hook firing rewrote the whole file for a one-row
append. Existing ledger normalized once so the change is observable;
the golden byte-shape assertion follows the new writer.

Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>
```

### 3.7 Known, accepted side effect

Any repository that already has this framework installed will see its
`flywheel/state/spawns.json` reformatted once, on the first hook firing after the
upgrade. That is a single one-time diff replacing an every-firing diff, which is the
point of the fix. No schema, key order, or value changes — `json.load` output is
identical before and after (proved by criterion C4).

### 3.8 Acceptance criteria (i28)

| # | Criterion | Command | Expected decisive output |
|---|---|---|---|
| C1 | Writer uses the ledger convention, in source and mirror | `grep -n 'json.dump(data, f' flywheel/resolve-spawn.py distribution/managed/flywheel/resolve-spawn.py` | two hits, both line 530, both `        json.dump(data, f, indent=1, ensure_ascii=False)` |
| C2 | No `indent=2` writer remains in `resolve-spawn.py` | `grep -n 'indent=2' flywheel/resolve-spawn.py` | no output; exit status 1 |
| C3 | The ledger now matches the other four ledgers | `python3 -c "import json;t=open('flywheel/state/spawns.json',encoding='utf-8').read();l=t.split(chr(10))[1];print('indent',len(l)-len(l.lstrip()),'escapes',chr(92)+'u' in t)"` | `indent 1 escapes False` |
| C4 | Normalization changed formatting only, never data | `python3 -c "import json;a=json.load(open('/tmp/i28-before.json'));b=json.load(open('flywheel/state/spawns.json'));print('equal',a==b,'rows',len(b))"` | `equal True rows N` (N is the row count reused by C6; it was 107 at authoring time and grows with every spawn) |
| C5 | Full spawn-resolver suite green | `python3 -m unittest tests.test_resolve_spawn -q 2>&1 \| tail -3` | `Ran 37 tests in ...` followed by `OK` (baseline before the change was also `Ran 37 tests` / `OK`) |
| C6 | The ledger integrity check still parses the file | `bash flywheel/check.sh 2>&1 \| grep 'state/spawns.json'` | TWO lines: `✓ state/spawns.json: valid JSON array (N entries)` where N equals C4's row count, plus the pre-existing `⚠ state/spawns.json: N entries (>100) — compaction due (python3 flywheel/compact.py)`. The `⚠` line is expected, predates this change, and is NOT part of this criterion. Re-run C4 immediately before C6 if a spawn hook fired in between — N grows live. |
| C7 | Mirrors byte-identical and every repository gate passes | `bash dev/check.sh` | final line `PASS repository distribution checks`, exit 0; no `managed dogfood drift` line |
| C8 | Exactly one implementation commit, four files | `git log --oneline main..HEAD; git diff --stat main..HEAD` | one commit line; exactly 4 files listed |

---

## 4. Self-check of this document against `dev/check.sh:61`

`flywheel/LESSONS.md` (2026-07-29, "i22 plan audit") records a plan REJECTED because the
plan document itself tripped this gate. Command run against this file before dispatch:

```
rg -n 'docs/(plans|research)/|docs/ARCHITECTURE\.md|(^|[^A-Za-z0-9_/-])(adapters|defaults|scripts)/|distribution/adapters/(antigravity|claude-code|codex|opencode)/(lifecycle\.sh|skills/|plugin/)' docs/flywheel/plans/improve-i26-i27-i28.md
```

Result: no output, exit status 1 (no matches). Re-run it after any edit to this file.

Note for the executing tier: when the gate itself must be discussed, name the tokens
descriptively (as §0.2 does) rather than writing them in their trigger form.

## 5. Out of scope — observations recorded, not fixed here

These were found while writing this plan. Each deserves its own issue and its own
branch; `flywheel/IMPROVE.md:48-49` forbids folding them in.

1. `flywheel/compact.py:20` also writes ledgers with `indent=2` (with
   `ensure_ascii=False`). It is the second writer of the same files and will re-churn
   indentation on the next compaction run — **undoing i28's normalization**. This is
   live, not theoretical: `bash flywheel/check.sh` currently prints
   `⚠ state/spawns.json: 107 entries (>100) — compaction due (python3
   flywheel/compact.py)`, and `flywheel/MAINTENANCE.md:39-41` schedules that compaction
   for an improve pass. Fix `compact.py` to `indent=1` BEFORE running compaction, on its
   own branch. Same fix shape as i28, different file. **Action for this pass: open i29
   and do not run compaction** (§0.5 carries the stop-instruction). Keeping it out of
   i28's commit is deliberate — separate file, separate revert unit.
2. `distribution/shared/skills/improve/SKILL.md:14` and `:25` use the Claude Code agent
   name `plan-auditor` inside a *shared* (multi-adapter) skill body. Related to i27 but a
   different file and a different direction of leak. Full blast radius of that leak, for
   whoever scopes the follow-up issue: the installed copy at
   `.claude/skills/improve/SKILL.md:14,25`, and — the significant one —
   `flywheel/INDEX.md:19` (HR3), which embeds the Claude-Code-specific name
   `plan-auditor` in the adapter-NEUTRAL core and is verbatim-duplicated into all four
   adapter blocks by the gate at `dev/check.sh:32-48`. Any fix there is a four-block
   coordinated edit, not a one-liner.
3. `flywheel/MAINTENANCE.md:29` will drift again: it restates numbers from a list it
   itself calls authoritative. i26 fixes the instance; the drift class survives. A
   follow-up could drop the numeric examples entirely.

# Plan — i22: dedup session-protocol / skill instructions out of the claude-code block

Branch: `flywheel/improve-block-skill-dedup` (cut from `main`)
Commit: `improve(flywheel): claude-code block points at canonical session protocol`
Tier: `engineer`, one implementation commit, 5 files.
Motivating input: `flywheel/state/issues.json` i22 (P2 debt, opened 2026-07-29).
Precedent followed byte-for-byte in shape: `docs/flywheel/plans/context-engineering-revision-2026-07.md` §6.4 (Phase 4).
Structural files — MAINTENANCE.md:15 process applies (this plan + `plan-auditor` approval before the edit lands).

---

## 1. Baseline (verified 2026-07-29 on `main`, commit `704fff9`)

`bash flywheel/check.sh 2>&1 | grep -i "always-loaded\|INDEX.md:\|ORCHESTRATION.md:\|FACTS.md:"`

```
✓ INDEX.md: 43/50 lines
✓ ORCHESTRATION.md: 90/95 lines
✓ FACTS.md: 77/80 lines
✓ always-loaded set (CLAUDE.md+INDEX+ORCHESTRATION+FACTS): 238/500 lines
✓ flywheel-owned always-loaded (CLAUDE.md block+INDEX+ORCHESTRATION+FACTS): 235/305 lines
✓ always-loaded set (AGENTS.md+INDEX+ORCHESTRATION+FACTS): 246/500 lines
✓ flywheel-owned always-loaded (AGENTS.md block+INDEX+ORCHESTRATION+FACTS): 246/305 lines
```

`wc -l`: `distribution/adapters/claude-code/CLAUDE.md.block` 25, `CLAUDE.md` 28,
`flywheel/ADAPTERS.md` 76, `docs/config/ADAPTERS.md` 58.

Predicted after this commit: block 25 → **22**, `CLAUDE.md` 28 → **25**,
owned always-loaded (CLAUDE) 235 → **232**, always-loaded set (CLAUDE) 238 → **235**,
`flywheel/ADAPTERS.md` 76 → **77/85**, all AGENTS.md numbers **unchanged** (246/246).

---

## 2. Judgment calls (decided, with evidence)

**JC1 — the whole `## Session protocol` section goes, replaced by a 3-line pointer.**
Diff of block step 1 against the canonical text shows **no unique words**:
`distribution/adapters/claude-code/CLAUDE.md.block:12-14` and `flywheel/INDEX.md:6-8`
name the same file (`flywheel/STATUS.md`), the same command (`bash flywheel/check.sh`),
the same warning class (ledger-untracked commits) and the same triage action
("triage, backfill ledgers/docs, note it in STATUS.md"). The block says "first —
resume from it, don't re-derive"; INDEX.md says "current state, in-flight work, next
actions. Resume from it" — INDEX.md is the *superset*. Step 2's only non-duplicate
clause is "use the `delegate` skill for any delegation", covered by the delegate skill
description (`.claude/skills/delegate/SKILL.md:3`: "Use when composing any subagent
delegation in this repo"). Step 3's only non-duplicate clause is the `wrapup` skill
name, covered by `.claude/skills/wrapup/SKILL.md:3` ("Use before ending a session or
when context runs low"). Rationale: nothing in the section survives the diff, so a
partial cut would leave a section whose remaining lines are still 100% duplicated.
A 3-line pointer (not a bare deletion) is kept for the same reason Phase 4 kept one at
`CLAUDE.md.block:18-20` — it is the anti-restatement guard that stops a future session
re-pasting the steps, and it costs 3 of the 6 lines while buying the ratchet.

**JC2 — `## Skill whitelist` (block lines 22-24) STAYS, byte-unchanged.** Its function
is *exclusionary* ("ignore other skills unless the user names them") and no skill
description can state it: a description advertises its own skill, it cannot suppress
the ~40 non-flywheel skills a real installation surfaces (this session alone lists 25+
plugin skills). It is also the only place naming `improve`, which has no
session-protocol trigger at all (`.claude/skills/improve/SKILL.md:3` fires on "wrapup
announced improve pass due"). Keep.

**JC3 — the end-of-session wrapup duty survives; this is not a regression.** After the
cut it is stated in three always-loaded/always-visible places, two of them
adapter-neutral: `flywheel/INDEX.md:10-12` ("Before ending / when context runs low: run
the wrapup procedure … Uncommitted = lost") and `flywheel/ORCHESTRATION.md:83-89`
(§7 Session start / end protocol, "What is not committed does not exist") — both are
`@`-imported by `CLAUDE.md:7-8` — plus the model-invoked description at
`.claude/skills/wrapup/SKILL.md:3`. Same for delegation:
`flywheel/ORCHESTRATION.md:11-25` (§1 tier table + routing rules) +
`.claude/skills/delegate/SKILL.md:3`.
The duty is strengthened rather than weakened, because after the cut there is exactly
one statement of it instead of two that can drift apart.

**JC4 — claude-code only; the other three blocks are NOT edited.** Two independent
reasons. (a) They do not mechanically load INDEX.md — they say "Read
`flywheel/INDEX.md` now" (`distribution/adapters/codex/AGENTS.md.block:6`,
`opencode/AGENTS.md.block:6`, `antigravity/AGENTS.md.block:6`), an instruction that can
be skipped; only `claude-code/CLAUDE.md.block:7` has the real `@flywheel/INDEX.md`
import. (b) Their step 2 is **not** duplication: it carries adapter-specific spawn
mechanics absent from INDEX.md — `.codex/agents/*.toml` and "codex only spawns one when
explicitly asked" (`codex/AGENTS.md.block:12-16`), `opencode.json` under `"agent"`
(`opencode/AGENTS.md.block:12-14`), `.agents/agents/{agent_name}/agent.json` + TypeName
invocation (`antigravity/AGENTS.md.block:12-16`). Whether those adapters surface skill
`description:` frontmatter unprompted is `Pending verification` (FACTS.md records only
that Codex *discovers* `.agents/skills`), so their skill mentions stay. Same reasoning
Phase 4 used (`context-engineering-revision-2026-07.md:504-508`), and i9 (contested
shared AGENTS.md block) is another reason not to perturb them.

**JC5 — two docs assert the block carries the session protocol and are reworded in
this same commit** (a doc contradicting its own commit's diff is worse than the
duplication): `flywheel/ADAPTERS.md:14` and `:72-74`, its mandatory mirror
`distribution/managed/flywheel/ADAPTERS.md`, and `docs/config/ADAPTERS.md:48`.
Proving command (run from repo root):

```bash
rg -n "[Ss]ession protocol" --glob '!.git' --glob '!flywheel/dashboard/dashboard.html' .
```

Everything else it returns is out of scope and must stay untouched: `CLAUDE.md:11` and
`distribution/adapters/claude-code/CLAUDE.md.block:11` are the headings this plan
edits; `AGENTS.md:6,8` and the three `distribution/adapters/*/AGENTS.md.block:6,8` are
JC4 (other adapters); `flywheel/INDEX.md:5` and
`distribution/managed/flywheel/INDEX.md:5` are the canonical text (must stay
byte-identical); `docs/USAGE.md:13` is about the *user* saying "wrap up";
`docs/flywheel/plans/i9-i11-decision.md:32,127` is a historical plan (never edit
landed plans). `README.md`, `docs/flywheel/ARCHITECTURE.md` and `docs/SEED-PROMPT.md`
contain **no** such assertion (the rg above returns no hits for them).

**No script depends on the deleted prose.** `dev/check.sh:46-47` greps the block only
for the whole line `@flywheel/INDEX.md`; `installer/adapters/claude-code.sh:5` wires the
block file wholesale; `installer/lifecycle/shared.sh:62,72` hardcode the skill *names*
`delegate improve wrapup`, never block wording; `tests/test_adapter_lifecycle.sh:406`
asserts on `AGENTS.md` ("Read `flywheel/INDEX.md` now"), not on `CLAUDE.md`;
`dev/sync-distribution.py` matches nothing on `CLAUDE.md`/`block`
(`grep -n "CLAUDE.md\|block\|Project:" dev/sync-distribution.py` → no output).

---

## 3. Steps

Each `old_string` below was confirmed to occur **exactly once** in its file on
`704fff9` (script in §4, step V0). Whitespace is exact — copy verbatim, do not reflow.

### Step 1 — `distribution/adapters/claude-code/CLAUDE.md.block` (lines 11-16 → 3 lines)

`old_string`:

```
## Session protocol
1. Read `flywheel/STATUS.md` first — resume from it, don't re-derive. Then
   `bash flywheel/check.sh`: ledger-untracked-commit warnings = work done outside the
   framework — triage, backfill ledgers/docs, note in STATUS.md.
2. Route work per ORCHESTRATION.md §1; use the `delegate` skill for any delegation.
3. Before ending / context low: run the `wrapup` skill. Uncommitted = lost.
```

`new_string`:

```
## Session protocol
Stated once in `flywheel/INDEX.md` §Session protocol, always loaded above; the
`delegate` and `wrapup` skills carry their own triggers. Never restate them here.
```

Acceptance: `wc -l < distribution/adapters/claude-code/CLAUDE.md.block` → `22`.
Verify: `sed -n '11,13p' distribution/adapters/claude-code/CLAUDE.md.block` prints the
three new lines and `grep -c '^1\. Read' distribution/adapters/claude-code/CLAUDE.md.block` → `0`.

### Step 2 — `CLAUDE.md` (dogfood instance, identical edit inside the markers)

Apply the **same** `old_string` → `new_string` as Step 1. Do **not** run `install.sh`
on this repo (issue i1 / K11 — the installer cannot target the flywheel repo itself).
`CLAUDE.md:4` (the seeded `Project:` line) and `CLAUDE.md:27-28` (the user-owned Motto
lines, outside `<!-- flywheel:end -->`) must survive byte-identical.

Acceptance: `wc -l < CLAUDE.md` → `25`; the marker region matches the shipped block
except the Project line (command D2 in §4).

### Step 3 — `flywheel/ADAPTERS.md:14` (0-line delta)

Re-locate the line first (line numbers drift):
`grep -n 'the four hard rules, and the session protocol' flywheel/ADAPTERS.md`

`old_string` (leading 3 spaces are part of the string):

```
   to `flywheel/INDEX.md`, the four hard rules, and the session protocol. install.sh
```

`new_string`:

```
   to `flywheel/INDEX.md`; §Rules for adapter authors says what else it carries. install.sh
```

Why: the old sentence tells a new adapter author the block contains the hard rules and
the session protocol; after this commit (and after Phase 4) the claude-code block
contains neither. The author rules section is now the single place that says what a
block carries, and Step 4 makes it cover both.

### Step 4 — `flywheel/ADAPTERS.md:72-74`, the Exception clause (+1 line)

`old_string`:

```
  point-of-use duplicates, verbatim-identical to INDEX.md. Blocks that do load it
  (claude-code, via `@flywheel/INDEX.md`) point at INDEX.md instead. The repository
  distribution check diffs the remaining copies line-by-line.
```

`new_string`:

```
  point-of-use duplicates, verbatim-identical to INDEX.md, and restate the session
  protocol with their own spawn mechanics. Blocks that do load it (claude-code, via
  `@flywheel/INDEX.md`) point at INDEX.md for both. The repository distribution check
  diffs the remaining hard-rule copies line-by-line.
```

Do **not** touch the two lines above it (`- The adapter never duplicates doctrine …` /
`into an adapter block will drift …`) — replacing them orphans the indented paragraph
(same warning as Phase 4 step 4). Re-locate before editing with
`grep -n 'point-of-use duplicates' flywheel/ADAPTERS.md`.

**Constraint (load-bearing):** the replacement text must not contain the literal
strings `dev/`, `distribution/`, `installer/` or `tests/` — `flywheel/ADAPTERS.md` is
mirrored into `distribution/managed/flywheel/`, which `dev/check.sh:54-59` rg-scans for
repository-only paths. Hence the wording "The repository distribution check". The text
above satisfies this; if you reword it, re-check.

Acceptance: `wc -l < flywheel/ADAPTERS.md` → `77`; `bash flywheel/check.sh 2>&1 | grep
ADAPTERS` → `✓ ADAPTERS.md: 77/85 lines`.

### Step 5 — mirror the managed file (K4, `dev/check.sh:12-17`)

```bash
cp flywheel/ADAPTERS.md distribution/managed/flywheel/ADAPTERS.md
```

Acceptance: `cmp flywheel/ADAPTERS.md distribution/managed/flywheel/ADAPTERS.md` exits 0.
No other `flywheel/*` file is touched by this plan, so no other mirror is needed —
confirm with `git status --porcelain flywheel/ | grep -v ADAPTERS.md` → empty.

### Step 6 — `docs/config/ADAPTERS.md:48` (0-line delta, repo-only doc, not mirrored)

`old_string`:

```
   lines: pointer to INDEX.md + session protocol + the four hard rules verbatim) and
```

`new_string`:

```
   lines: pointer to INDEX.md, plus any doctrine the block cannot mechanically load) and
```

Why: the clause is stale twice over — the "hard rules verbatim" half has been false for
claude-code since Phase 4 landed, and this commit makes the "session protocol" half
false too. The replacement introduces no bare `adapters`, `defaults` or `scripts` path
prefix, so `dev/check.sh:61-68` still passes. (This sentence deliberately omits the
trailing slashes: `dev/check.sh:61-68` scans `docs/`, so writing them here would make
this plan file itself fail A3.)

### Step 7 — generated architecture doc (K10)

```bash
python3 flywheel/dashboard/gen_architecture.py .
git status --porcelain docs/flywheel/ARCHITECTURE.md   # must be EMPTY
```

`gen_architecture.py` discovers only `*.sh`/`*.py` under `flywheel/`, so a docs-only
change produces no diff. Never hand-edit that file. `flywheel/check.sh` may emit a
warn-only "structural change without ARCHITECTURE.md update" notice — **accept it, do
not "fix" it**; record that expectation in the commit body.

### Step 8 — commit (one implementation commit, GIT.md:12-14)

```bash
git checkout -b flywheel/improve-block-skill-dedup   # from main
git add distribution/adapters/claude-code/CLAUDE.md.block CLAUDE.md \
        flywheel/ADAPTERS.md distribution/managed/flywheel/ADAPTERS.md \
        docs/config/ADAPTERS.md
git commit    # message below; never `git add -A`, never `--no-verify`
```

Subject: `improve(flywheel): claude-code block points at canonical session protocol`
Body (WHY, wrapped at 72): cite issues.json i22; state that `@flywheel/INDEX.md`
(`CLAUDE.md.block:7`) already puts INDEX.md §Session protocol in context and the
`delegate`/`wrapup` skill descriptions already carry their own triggers; note the
expected warn-only ARCHITECTURE.md notice from Step 7.

This plan file itself is NOT the engineer's to commit: the coordinator/wrapup commits
`docs/flywheel/plans/improve-i22-block-skill-dedup.md`, so it stays out of the
implementation commit's 5-file set (D8 still holds — an untracked file is invisible to
`git diff --name-only`).

Do **not** rebuild/stage `flywheel/dashboard/dashboard.html` in this commit — if it
changes from unrelated ledger state, leave it for wrapup's bookkeeping commit
(IMPROVE.md:35-37).

---

## 4. Verification harness (run all; every one must match)

```bash
# V0 — before editing: every old_string occurs exactly once
python3 - <<'PY'
import pathlib
BLOCK = """## Session protocol
1. Read `flywheel/STATUS.md` first \u2014 resume from it, don't re-derive. Then
   `bash flywheel/check.sh`: ledger-untracked-commit warnings = work done outside the
   framework \u2014 triage, backfill ledgers/docs, note in STATUS.md.
2. Route work per ORCHESTRATION.md \u00a71; use the `delegate` skill for any delegation.
3. Before ending / context low: run the `wrapup` skill. Uncommitted = lost.
"""
checks = [
 ("distribution/adapters/claude-code/CLAUDE.md.block", BLOCK),
 ("CLAUDE.md", BLOCK),
 ("flywheel/ADAPTERS.md", "   to `flywheel/INDEX.md`, the four hard rules, and the session protocol. install.sh\n"),
 ("flywheel/ADAPTERS.md", "  point-of-use duplicates, verbatim-identical to INDEX.md. Blocks that do load it\n"),
 ("docs/config/ADAPTERS.md", "   lines: pointer to INDEX.md + session protocol + the four hard rules verbatim) and\n"),
]
for f, s in checks:
    print(f, pathlib.Path(f).read_text().count(s))   # every line must end in 1
PY
```

| ID | Command | Expected |
|---|---|---|
| A1 | `bash flywheel/check.sh 2>&1 \| grep always-loaded` | four lines, full labels (no elision — do not grep the `…`): `✓ always-loaded set (CLAUDE.md+INDEX+ORCHESTRATION+FACTS): 235/500 lines`, `✓ flywheel-owned always-loaded (CLAUDE.md block+INDEX+ORCHESTRATION+FACTS): 232/305 lines`, `✓ always-loaded set (AGENTS.md+INDEX+ORCHESTRATION+FACTS): 246/500 lines`, `✓ flywheel-owned always-loaded (AGENTS.md block+INDEX+ORCHESTRATION+FACTS): 246/305 lines` |
| A2 | `bash flywheel/check.sh 2>&1 \| tail -1` | `✓ all checks passed` |
| A3 | `bash dev/check.sh 2>&1 \| tail -1` | `PASS repository distribution checks` |
| A4 | `bash dev/check.sh 2>&1 \| grep hard-rule` | `PASS hard-rule duplicates are identical and the claude-code block imports INDEX.md` |
| A5 | `bash tests/test_adapter_lifecycle.sh 2>&1 \| tail -3` | PASS (no FAIL lines) |
| D2 | `diff <(sed -n '/flywheel:begin/,/flywheel:end/p' CLAUDE.md) distribution/adapters/claude-code/CLAUDE.md.block` | exactly one hunk, `4c4`, the `Project:` line. Anything else means the next `install.sh` refresh (`installer/lifecycle/common.sh` replaces the whole region) would overwrite the cut |
| D3 | `for f in distribution/adapters/claude-code/CLAUDE.md.block CLAUDE.md flywheel/ADAPTERS.md docs/config/ADAPTERS.md; do wc -l < "$f"; done` | four lines: `22`, `25`, `77`, `58` (per-file form avoids `wc`'s extra `total` row) |
| D4 | `grep -cE '^[123]\. ' CLAUDE.md distribution/adapters/claude-code/CLAUDE.md.block` | `0` for both — the numbered protocol steps (and their skill imperatives) are gone |
| D5 | `grep -cE '^Repo skills: ' CLAUDE.md distribution/adapters/claude-code/CLAUDE.md.block` | `1` for both — JC2, the Skill whitelist survives byte-unchanged |
| D6 | `git diff main --stat -- CLAUDE.md \| tail -1` and `sed -n '22,25p' CLAUDE.md` | user-owned tail intact: line 22 `<!-- flywheel:end -->`, 23 blank, 24-25 the Motto / strategy-doc lines, byte-identical to `git show main:CLAUDE.md \| tail -2` |
| D7 | `git diff main -- flywheel/INDEX.md flywheel/ORCHESTRATION.md flywheel/FACTS.md` | empty — canonical text untouched |
| D8 | `git diff --name-only main` | exactly the 5 files in Step 8; `docs/flywheel/ARCHITECTURE.md` and `flywheel/dashboard/dashboard.html` must NOT appear |
| D9 | `cmp flywheel/ADAPTERS.md distribution/managed/flywheel/ADAPTERS.md` | exit 0 |
| D10 (negative fixture — the guard is not vacuous) | `sed -i.bak '/^@flywheel\/INDEX\.md$/d' distribution/adapters/claude-code/CLAUDE.md.block && bash dev/check.sh 2>&1 \| grep "always-loaded import"; mv distribution/adapters/claude-code/CLAUDE.md.block.bak distribution/adapters/claude-code/CLAUDE.md.block` | prints `FAIL claude-code block lost its @flywheel/INDEX.md always-loaded import`, then `git status --porcelain distribution/adapters/claude-code/` → empty. **If it passes silently, STOP and report — the whole safety argument (JC1/JC3) rests on that import being real.** |

`dev/check.sh` needs no change in this commit: its only claude-code-block assertion is
the `@flywheel/INDEX.md` whole-line grep (`dev/check.sh:46-47`), which this edit
preserves.

---

## 5. Bookkeeping (coordinator, after `verifier` passes — not part of the implementation commit)

- Autonomy is `3` (`flywheel/config.json`), so IMPROVE.md:39-41 row A applies: create a
  `pending` entry in `flywheel/state/decisions.json` (options merge/reject,
  recommendation + branch name `flywheel/improve-block-skill-dedup` in `detail`) and
  **leave the branch unmerged**.
- `flywheel/state/activity.json`: entry with branch name + commit hash.
- Close i22 in `flywheel/state/issues.json` only when the branch merges (set `closed`
  and the commit hash), not when the branch is cut.
- Dispatch a fresh `verifier` on the branch (HR3) with the §4 table as its checklist.
  The author of the edit never issues the verdict.

---

## 6. Risks and what would falsify this plan

- **R1 — the `@flywheel/INDEX.md` import is not actually always-loaded.** Falsified by
  D10; if D10 passes silently the cut is unsafe and must be reverted, not narrowed.
- **R2 — skill descriptions are not surfaced unprompted in some claude-code
  configuration** (e.g. a session with skills disabled). Residual risk accepted because
  JC3's fallback is adapter-neutral: `INDEX.md:10-12` and `ORCHESTRATION.md:83-89` are
  `@`-imported and state the wrapup duty without naming any skill. The block's Skill
  whitelist (JC2) still names all three skills by name.
- **R3 — an `install.sh` refresh overwrites the dogfood cut.** Prevented by keeping the
  block and the dogfood marker region identical (D2); this is why Step 2 is a hand-edit
  mirroring Step 1 exactly rather than a reflow.
- **R4 — bundling.** Steps 3/4/6 are doc-consistency fixes forced by this commit's own
  diff (JC5), not separate improvements; they are the same-commit rule Phase 4 applied
  to K1/K2. No budget is raised anywhere in this plan (ADAPTERS.md 77 ≤ its existing 85),
  so IMPROVE.md:50-51's LESSONS.md justification requirement is not triggered.

---

## 7. Found / Assumed / Could not find

### Found
- The claude-code block's session protocol is fully redundant: block:12-14 vs
  `flywheel/INDEX.md:6-8` (same file, command, warning, triage action; INDEX.md is the
  superset), block:15 vs INDEX.md:9 + `.claude/skills/delegate/SKILL.md:3`, block:16 vs
  `flywheel/INDEX.md:10-12` + `flywheel/ORCHESTRATION.md:87-89` +
  `.claude/skills/wrapup/SKILL.md:3`.
- `CLAUDE.md:7` / `distribution/adapters/claude-code/CLAUDE.md.block:7` is a real
  `@flywheel/INDEX.md` import; the other three blocks only *instruct* a read
  (`codex/AGENTS.md.block:6`, `opencode/AGENTS.md.block:6`, `antigravity/AGENTS.md.block:6`).
- The other blocks' step 2 carries adapter-specific spawn mechanics not in INDEX.md
  (`codex/AGENTS.md.block:12-16`, `opencode/AGENTS.md.block:12-14`,
  `antigravity/AGENTS.md.block:12-16`) — deleting it there would lose information.
- Baseline numbers from `bash flywheel/check.sh` on `704fff9` (§1 output block):
  238/500 and 235/305 for the CLAUDE.md set; `flywheel/ADAPTERS.md` 76/85.
- Only two docs assert the block carries a session protocol
  (`flywheel/ADAPTERS.md:14`, `docs/config/ADAPTERS.md:48`, plus the ADAPTERS.md
  Exception clause at :72-74 and the managed mirror), per the `rg "[Ss]ession
  protocol"` sweep in JC5.
- No script or test greps the block prose being deleted: `dev/check.sh:46-47`
  (`@flywheel/INDEX.md` whole-line only), `installer/adapters/claude-code.sh:5`,
  `installer/lifecycle/shared.sh:62,72` (skill names, not wording),
  `tests/test_adapter_lifecycle.sh:406` (AGENTS.md), `dev/sync-distribution.py` (no
  match for `CLAUDE.md`/`block`/`Project:`).
- All five `old_string`s occur exactly once in their files (V0 script output: all `1`).

### Assumed
- Skill `description:` frontmatter is surfaced to the claude-code model unprompted —
  assumed from this session's own available-skills listing, which shows the exact
  description strings of `delegate`, `wrapup` and `improve`. Not recorded in FACTS.md;
  R2 covers the failure mode.
- Predicted post-edit sums (235/500, 232/305) are computed arithmetically from the
  line deltas (block −3, no `flywheel/*.md` always-loaded file changes), not from a
  post-edit run — A1 is the check that closes this.

### Could not find
- No mechanical guard anywhere that a managed block still *contains* a session
  protocol — the ≤ 50-line block cap in `flywheel/MAINTENANCE.md:35` is an audit-pass
  convention, not a `check.sh` assertion. Nothing therefore breaks on removal, and
  nothing prevents a future session from re-pasting the steps except the 3-line
  pointer this plan leaves behind.
- No FACTS.md row on whether codex / opencode / antigravity surface skill descriptions
  unprompted — `Pending verification`; this is why JC4 leaves those blocks alone.

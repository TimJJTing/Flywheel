# Plan — i30: spawn rows must not assert an outcome the system cannot back

Status: DRAFT (strategist). Not validated — the coordinator must dispatch `plan-auditor`
before an engineer executes this (MAINTENANCE.md:15, ORCHESTRATION.md §5).

Issue: `flywheel/state/issues.json` `i30`, opened 2026-07-29, `type: friction`, `P3`.
Branch: `flywheel/improve-spawn-outcome-pending` (cut from `main`).
One implementation commit (IMPROVE.md:33): `improve(flywheel): spawn rows log outcome pending until wrapup adjudicates`

---

## 1. Recommendation

**Adopt candidate 2 — write `"pending"` at launch and require the wrapup procedure to
resolve it into a terminal value, with `check.sh` mechanically enforcing the enum and
warning on any unresolved `pending` row.**

One-line rationale: it is the only candidate that fixes *both* defects for *all four*
adapters using only facts verified in this repo, and it converts an existing prose rule
(wrapup SKILL.md:19-21 "correct wrong outcome values") into a mechanical check, which
IMPROVE.md:56-58 names as the tie-breaker between otherwise-equal candidates.

**Runner-up: candidate 1 — drop `outcome` from auto-logged rows.**
One-line rationale: equally honest at write time and one line simpler, but it deletes
the enforcement surface — an absent field cannot distinguish "not yet adjudicated" from
"adjudicated, fine", so nothing can ever detect skipped curation, and it breaks the
uniform 8-key row shape that `tests/test_resolve_spawn.py:103-104` and the dashboard
(`flywheel/dashboard/template.html:322`) both rely on.

**Rejected: candidate 3 — move background-spawn logging to a completion-time signal.**
Two independent reasons:
1. No completion-time signal for claude-code background subagents is verified anywhere
   in this repo. `flywheel/FACTS.md:42-56` §Adapter capabilities records exactly one
   claude-code spawn hook fact (the `PostToolUse` / matcher `Agent` payload, line 48);
   `.claude/settings.json:4` wires only that event. `flywheel/state/decisions.json:85`
   records that a claude-code `SubagentStop` was *considered* in the d7 design and that
   the shipped solution was "single PostToolUse hook (matcher \"Agent\")". Whether
   claude-code exposes a subagent-completion hook event is **`Pending verification`** —
   HR2 forbids filling it from memory.
2. Even a verified completion signal would not fix defect (a). Codex *already* logs from
   a completion-time event (`.codex/hooks.json` wires `SubagentStop`;
   `flywheel/FACTS.md:49` documents the payload) and its row *still* hardcodes
   `"outcome": "ok"` at `flywheel/resolve-spawn.py:572`. `ok|retried|escalated|failed`
   are coordinator-level judgments about a delegation (ORCHESTRATION.md §4), not process
   exit statuses; no hook payload can produce them. Completion timing is therefore
   necessary-at-best and sufficient-never.

### Why this is one atomic improvement, not a bundle (IMPROVE.md:48-49)

Every edit below exists to make a single claim true: *no automatic writer asserts a spawn
outcome it cannot back.* The resolver stops asserting it; the schema legalises the
non-assertion; `check.sh` detects an unresolved non-assertion; the dashboard renders it
without colouring it as a failure; the wrapup skill and IMPROVE.md describe the new
contract. Reverting the single commit restores the old behaviour completely. There is no
second, separable improvement hiding in the set.

---

## 2. Value chosen: `pending`

- Spelled `pending` (lowercase), not `unknown`. It reads as "awaiting adjudication",
  rhymes with the codebase's existing `Pending verification` idiom
  (`flywheel/resolve-spawn.py:362`, `:400`), and is unambiguously non-terminal.
- `pending` becomes a **legal** schema value but a **non-terminal** one: it is the only
  value an automatic writer may emit, and it must not survive a wrapup.
- Terminal values are unchanged: `ok|retried|escalated|failed`.

---

## 3. Files changed (implementation commit)

| # | Path | Kind |
|---|---|---|
| 1 | `flywheel/resolve-spawn.py` | code |
| 2 | `distribution/managed/flywheel/resolve-spawn.py` | byte-identical mirror |
| 3 | `flywheel/state/SCHEMAS.md` | structural |
| 4 | `distribution/managed/flywheel/state/SCHEMAS.md` | byte-identical mirror |
| 5 | `flywheel/check.sh` | structural |
| 6 | `distribution/managed/flywheel/check.sh` | byte-identical mirror |
| 7 | `flywheel/dashboard/template.html` | structural |
| 8 | `distribution/managed/flywheel/dashboard/template.html` | byte-identical mirror |
| 9 | `flywheel/IMPROVE.md` | structural |
| 10 | `distribution/managed/flywheel/IMPROVE.md` | byte-identical mirror |
| 11 | `flywheel/DELEGATION.md` | structural |
| 12 | `distribution/managed/flywheel/DELEGATION.md` | byte-identical mirror |
| 13 | `distribution/shared/skills/wrapup/SKILL.md` | skill body (canonical) |
| 14 | `distribution/shared/skills/wrapup/references/claude-code.md` | skill body (canonical) |
| 15 | `distribution/shared/skills/wrapup/references/codex.md` | skill body (canonical) |
| 16 | `distribution/shared/skills/wrapup/references/antigravity.md` | skill body (canonical) |
| 17-20 | same four files under `.agents/skills/wrapup/` | dogfood projection |
| 21-24 | same four files under `.claude/skills/wrapup/` | dogfood projection |
| 25 | `tests/test_resolve_spawn.py` | tests |

25 files: 11 authored files across 7 edit sites (rows 1, 3, 5, 7, 9, 11, 13-16, 25 —
the skill bodies counted as one edit set) plus 14 mechanical mirrors/projections.

**Not changed, deliberately:**
- `flywheel/compact.py:57` — writes `"outcome": "ok"` on the synthetic `agent:"(compacted)"`
  rollup row (see `flywheel/state/spawns.json` index 0). That row is a compaction receipt,
  not a spawn record, and "ok" there means "the compaction ran". Changing it would make
  the step 4 / §4 `pending` warning fire permanently on a row no wrapup can ever adjudicate.
  (Its *other* effect — silently swallowing an unresolved `pending` row once the ledger
  passes 100 entries — is documented in the Step 3 schema comment, not fixed here.)
- `flywheel/FACTS.md` / `distribution/defaults/flywheel/FACTS.md` — deferred, see §7.
- `flywheel/state/spawns.json` — see §5.
- `.claude/settings.json`, `.codex/hooks.json`, `.agents/hooks.json` — hook wiring is
  unchanged; only what the resolver writes changes.

---

## 4. Steps

Eleven steps, numbered 0-10. Each lists the exact anchor, the edit, its acceptance
criterion, and a verification command. Run every command from the repo root
(`/Users/jjting/Documents/projects/flywheel`).

### Step 0 — branch

```bash
git checkout main && git pull --ff-only 2>/dev/null; git checkout -b flywheel/improve-spawn-outcome-pending
```
Acceptance: `git rev-parse --abbrev-ref HEAD` prints `flywheel/improve-spawn-outcome-pending`.
Verify: `git rev-parse --abbrev-ref HEAD`

Note: another agent may be working in this repo concurrently. Confirm
`git status --porcelain` is clean before starting; if not, stop and report.

---

### Step 1 — resolver stops asserting an outcome

File: `flywheel/resolve-spawn.py`

1a. Add a module constant immediately after the `COORDINATOR_KEY_MARKER` assignment
(currently line 53), so both write sites share one source:

```python
# Automatic writers never adjudicate a spawn: hooks fire at tool-call return (which for
# a background claude-code spawn is at LAUNCH) and no adapter payload carries a
# retried/escalated/failed verdict. Rows are written non-terminal and the wrapup
# procedure resolves them (flywheel/state/SCHEMAS.md, wrapup skill step 2).
DEFAULT_OUTCOME = "pending"
```

1b. Line 547, inside the `codex-coordinator` branch of `main()`. Replace:

```python
            "task": fields["task"], "outcome": "ok", "notes": fields["notes"],
```
with:
```python
            "task": fields["task"], "outcome": DEFAULT_OUTCOME, "notes": fields["notes"],
```

1c. Line 572, inside the generic row-assembly loop of `main()`. Replace:

```python
            "outcome": "ok",
```
with:
```python
            "outcome": DEFAULT_OUTCOME,
```

1d. Docstring line 19-20 currently reads
`"... the cwd-resolution fallback, the ts/outcome row fields, the file-locking append to"`.
Replace `the ts/outcome row fields` with `the ts field and the non-terminal
DEFAULT_OUTCOME` (keep the surrounding sentence and the 88-column wrap).

Acceptance:
- `grep -n '"outcome": "ok"' flywheel/resolve-spawn.py` returns nothing.
- `grep -c DEFAULT_OUTCOME flywheel/resolve-spawn.py` returns `4` (the constant's own
  definition in 1a, the two write sites in 1b/1c, and the docstring mention in 1d).
- The upsert path at `flywheel/resolve-spawn.py:496-503` is **untouched** — it already
  preserves a curated `outcome` on a coordinator rerun (comment at :498-499), which is
  exactly the behaviour `tests/test_resolve_spawn.py:508-512` pins.

Verify:
```bash
grep -n '"outcome": "ok"' flywheel/resolve-spawn.py; grep -c DEFAULT_OUTCOME flywheel/resolve-spawn.py
```
(expect: no grep output line, then `4`)

---

### Step 2 — mirror the resolver

```bash
cp flywheel/resolve-spawn.py distribution/managed/flywheel/resolve-spawn.py
```
Acceptance: files are byte-identical (`dev/check.sh:12-17` fails otherwise).
Verify: `cmp flywheel/resolve-spawn.py distribution/managed/flywheel/resolve-spawn.py && echo IDENTICAL`

---

### Step 3 — schema: legalise `pending`, define it as non-terminal

File: `flywheel/state/SCHEMAS.md`, line 29. Replace:

```
  "task":"<=15 words","outcome":"ok|retried|escalated|failed","notes":"" }
```
with:
```
  "task":"<=15 words","outcome":"pending|ok|retried|escalated|failed","notes":"" }
```

Then insert these six comment lines immediately after line 30
(`// agent: add "coordinator" for the main session itself.`):

```
// outcome: automatic writers emit "pending" only — they fire before any verdict exists
//   (a background claude-code spawn logs at launch). Wrapup resolves every "pending" row
//   into ok|retried|escalated|failed; check.sh warns while any remain. Resolve them the
//   same session: once the ledger passes 100 entries check.sh calls for compaction, and
//   compact.py is then run to squash all but the newest 30 into the "(compacted)" rollup, and an unresolved "pending" row vanishes
//   into it silently — the warning stops without anyone having adjudicated the spawn.
```

Acceptance: SCHEMAS.md goes 37 → 43 lines (no budget applies; `flywheel/check.sh`'s
`check_budget` list, lines 19-31, does not include SCHEMAS.md).
Verify:
```bash
grep -n 'pending|ok|retried|escalated|failed' flywheel/state/SCHEMAS.md && wc -l < flywheel/state/SCHEMAS.md
```
(expect a hit on line 29 and `43`)

Then mirror:
```bash
cp flywheel/state/SCHEMAS.md distribution/managed/flywheel/state/SCHEMAS.md
cmp flywheel/state/SCHEMAS.md distribution/managed/flywheel/state/SCHEMAS.md && echo IDENTICAL
```

---

### Step 4 — `check.sh` mechanically validates the field

**Yes, `check.sh` should validate it** — this is the IMPROVE.md:56-58 prose-to-check
conversion that makes this improvement worth doing at all. Two behaviours, deliberately
different in severity:

- **✗ FAIL** on any spawn row whose `outcome` is missing or outside
  `pending|ok|retried|escalated|failed`. Rationale: a typo/drift guard. Always fixable in
  seconds by whoever wrote the row, so blocking the wrapup commit costs nothing.
- **⚠ WARN (never fail)** on rows still `pending`. Rationale: `flywheel/wrapup.sh:36`
  aborts the whole wrapup on a ✗, and "uncommitted = lost" (INDEX.md §Session protocol).
  A background agent that is still running at wrapup time is a state the coordinator
  genuinely cannot adjudicate; blocking the session's only commit on it would be a worse
  failure than the one being fixed. The warning still fires only when curation was
  skipped, because the wrapup skill resolves rows in step 2 and runs `check.sh` in step 5.

File: `flywheel/check.sh`. Two parallel edits — the python3 branch and the node fallback
branch must print **identical strings** (they are mutually exclusive at runtime, so no
test can catch divergence).

> **QUOTING HAZARD — read before typing either insert.** Neither insert lives in a real
> `.py` or `.js` file; both are embedded in shell strings, so the shell strips quotes
> before the interpreter ever sees the code.
> - The python code sits inside `JSON_SRC='…'` (opens at `flywheel/check.sh:84`, closes at
>   `:104`). That body contains **zero** `'` characters today. A `'` in your insert ends
>   the shell string early: bash silently concatenates the fragments and the printed text
>   loses the quotes — so the two runner branches emit different strings while the
>   acceptance check ("prints the ⚠ line") still passes and nobody notices.
>   **Use no `'` anywhere in the python insert.** Double quotes are safe there.
> - The node code sits inside `node -e "…"` (`flywheel/check.sh:109-126`). A `"` in your
>   insert closes that string and turns `check.sh` into a **shell syntax error** that
>   aborts the entire `if/elif/fi` compound — every `✓ state/*.json` line disappears and
>   all ledger validation stops running.
>   **Use no `"` anywhere in the node insert.** Single quotes are safe there.
>
> Consequence: the shared message text below deliberately writes `outcome pending`
> unquoted rather than `outcome 'pending'`. Do not "fix" it back.

4a. In the `JSON_SRC` python heredoc, insert immediately after the compaction warning
(current lines 96-97, the `if f in ("activity.json", "spawns.json") and len(data) > 100:`
block) and before `for item in data:` (line 98), at the same indentation as the `if`:

```python
        if f == "spawns.json":
            allowed = {"pending", "ok", "retried", "escalated", "failed"}
            bad = [i for i, item in enumerate(data)
                   if not isinstance(item, dict) or item.get("outcome") not in allowed]
            if bad:
                print(f"✗ state/spawns.json: {len(bad)} row(s) with outcome outside "
                      f"pending|ok|retried|escalated|failed (first at index {bad[0]})")
                ok = False
            n_pending = sum(1 for item in data if isinstance(item, dict)
                            and item.get("outcome") == "pending")
            if n_pending:
                print(f"⚠ state/spawns.json: {n_pending} row(s) still outcome pending "
                      f"— resolve each at wrapup (wrapup skill step 2)")
```

4b. In the node fallback, insert immediately after the compaction warning (current lines
119-120) and before `for (const item of data) hashes.push(...)` (line 121):

```js
    if (f === 'spawns.json') {
      const allowed = new Set(['pending','ok','retried','escalated','failed']);
      const bad = [];
      data.forEach((it, i) => { if (!it || typeof it !== 'object' || !allowed.has(it.outcome)) bad.push(i); });
      if (bad.length) { console.log('✗ state/spawns.json: '+bad.length+' row(s) with outcome outside pending|ok|retried|escalated|failed (first at index '+bad[0]+')'); ok=false; }
      const nPending = data.filter(it => it && typeof it === 'object' && it.outcome === 'pending').length;
      if (nPending) console.log('⚠ state/spawns.json: '+nPending+' row(s) still outcome pending — resolve each at wrapup (wrapup skill step 2)');
    }
```

Acceptance:
- `bash -n flywheel/check.sh` exits 0 (guards the node-branch quoting hazard above).
- `bash flywheel/check.sh` still prints a `✓ state/spawns.json: N entries` line and still
  exits 0 against the unmodified ledger. Do not hardcode the row count — the hook appends
  rows continuously; re-measure with the command in §5. Every value in the ledger today is
  terminal, so no ⚠ should appear on the baseline run.
- An injected out-of-enum row makes it print the ✗ line and exit 1.
- An injected `pending` row makes it print the ⚠ line and still exit 0.
- `flywheel/check.sh` has no `check_budget` entry, so no line budget applies. It must not
  reference `tests/`, `dev/`, `installer/`, or `distribution/` — `dev/check.sh:54-59`
  fails on repository-only paths inside `distribution/managed/flywheel`.

Verify (probe, then **restore immediately** — do this before staging anything):

```bash
# 0. shell syntax must survive both inserts, and BOTH state-JSON branches must still run
bash -n flywheel/check.sh && echo "SYNTAX OK"
bash flywheel/check.sh | grep 'state/spawns.json'   # must show the ✓ line, not nothing

# baseline
bash flywheel/check.sh >/dev/null && echo "BASELINE PASS"

# out-of-enum -> must FAIL
python3 - <<'PY'
import json, pathlib
p = pathlib.Path("flywheel/state/spawns.json"); rows = json.loads(p.read_text())
rows.append({"ts":"1970-01-01T00:00","agent":"utility","adapter":"claude-code","model":"x",
             "level":"-","task":"probe","outcome":"bogus","notes":"probe"})
p.write_text(json.dumps(rows, indent=1, ensure_ascii=False) + "\n")
PY
bash flywheel/check.sh | grep 'outcome outside'; bash flywheel/check.sh >/dev/null; echo "exit=$?  (expect 1)"
git checkout -- flywheel/state/spawns.json

# pending -> must WARN but still pass
python3 - <<'PY'
import json, pathlib
p = pathlib.Path("flywheel/state/spawns.json"); rows = json.loads(p.read_text())
rows.append({"ts":"1970-01-01T00:00","agent":"utility","adapter":"claude-code","model":"x",
             "level":"-","task":"probe","outcome":"pending","notes":"probe"})
p.write_text(json.dumps(rows, indent=1, ensure_ascii=False) + "\n")
PY
bash flywheel/check.sh | grep 'still outcome pending'; bash flywheel/check.sh >/dev/null; echo "exit=$?  (expect 0)"
git checkout -- flywheel/state/spawns.json

# MUST be empty before continuing
git status --porcelain flywheel/state/spawns.json
```

Then mirror:
```bash
cp flywheel/check.sh distribution/managed/flywheel/check.sh
cmp flywheel/check.sh distribution/managed/flywheel/check.sh && echo IDENTICAL
```

---

### Step 5 — dashboard must not paint `pending` as a failure

`flywheel/dashboard/template.html:305-309` has:
```js
function outcomeClass(o) {
  if (o === "ok") return "ok";
  if (o === "retried" || o === "escalated") return "caution";
  return "negative";
}
```
Without this step a `pending` row renders in the red `negative` chip
(`template.html:322`), i.e. the CEO-visible dashboard would replace one false claim
("succeeded") with another ("failed"). In scope by necessity, not by bundling.

5a. After line 82 (`.outcome.negative { ... }`) add:
```css
  .outcome.pending { background: var(--border); color: var(--muted); }
```
(`--border` / `--muted` are the same pair already used by `.badge.zero`, line 46.)

5b. In the filter select, lines 172-173, add a `pending` option so the CEO can list
un-adjudicated spawns. Replace line 172:
```html
        <option value="ok">ok</option><option value="retried">retried</option>
```
with:
```html
        <option value="pending">pending</option>
        <option value="ok">ok</option><option value="retried">retried</option>
```

5c. In `outcomeClass`, add as the first branch (line 306):
```js
  if (o === "pending") return "pending";
```

Acceptance: `check.sh`'s build.py/build.mjs parity check (lines 267-298) still reports
`✓ dashboard build.py/build.mjs parity: identical output` — both builders read the same
template and neither touches `outcome` (`grep -n outcome flywheel/dashboard/build.py
flywheel/dashboard/build.mjs` returns nothing today and must still return nothing).

Verify:
```bash
grep -n 'outcome.pending\|value="pending"\|o === "pending"' flywheel/dashboard/template.html
bash flywheel/check.sh | grep 'dashboard build.py/build.mjs parity'
cp flywheel/dashboard/template.html distribution/managed/flywheel/dashboard/template.html
cmp flywheel/dashboard/template.html distribution/managed/flywheel/dashboard/template.html && echo IDENTICAL
```
(expect 3 grep hits, then the `✓ ... identical output` line)

---

### Step 6 — IMPROVE.md:22-24 (the dead input)

File: `flywheel/IMPROVE.md`. Replace lines 22-24:

```
2. **Gather inputs:** `flywheel/LESSONS.md`; `state/issues.json` where
   `type == "friction"`; latest `flywheel/check.sh` output; `state/spawns.json` rows
   with outcome `retried|escalated|failed`.
```
with:
```
2. **Gather inputs:** `flywheel/LESSONS.md`; `state/issues.json` where
   `type == "friction"`; latest `flywheel/check.sh` output; `state/spawns.json` rows
   with outcome `retried|escalated|failed` — plus any row still `pending`, which means
   a wrapup never adjudicated that spawn and is itself a friction signal.
```

Acceptance: the query is now reachable — automatic rows land as `pending`, and wrapup is
obliged (step 8) to resolve each into a terminal value, so `retried|escalated|failed` can
actually occur. IMPROVE.md goes 64 → 65 lines against the `check_budget IMPROVE.md 75`
limit (`flywheel/check.sh:26`).

Verify:
```bash
sed -n '22,25p' flywheel/IMPROVE.md; wc -l < flywheel/IMPROVE.md
bash flywheel/check.sh | grep 'IMPROVE.md:'
cp flywheel/IMPROVE.md distribution/managed/flywheel/IMPROVE.md
cmp flywheel/IMPROVE.md distribution/managed/flywheel/IMPROVE.md && echo IDENTICAL
```
(expect `65`, then `✓ IMPROVE.md: 65/75 lines`)

---

### Step 7 — DELEGATION.md spawn-provenance line

File: `flywheel/DELEGATION.md`, lines 28-29. Replace:
```
provenance and `Pending verification` when unavailable. At wrapup, correct child
outcomes/notes and ensure the coordinator has exactly one row.
```
with:
```
provenance and `Pending verification` when unavailable. Automatic rows land with
`outcome: pending`; at wrapup resolve every one, correct notes, and ensure the
coordinator has exactly one row.
```

Acceptance: DELEGATION.md goes 29 → 30 lines against `check_budget DELEGATION.md 45`
(`flywheel/check.sh:30`).

Verify:
```bash
sed -n '26,30p' flywheel/DELEGATION.md; wc -l < flywheel/DELEGATION.md
cp flywheel/DELEGATION.md distribution/managed/flywheel/DELEGATION.md
cmp flywheel/DELEGATION.md distribution/managed/flywheel/DELEGATION.md && echo IDENTICAL
```

---

### Step 8 — wrapup skill (what fills the final outcome)

**The skill body is where the resolution duty lives, not `wrapup.sh`.** `wrapup.sh` is
purely mechanical (its header, line 2: "the skill's judgment half stays prose") and has
no way to know whether a delegation retried. Its only involvement is indirect and already
correct: step 2 of `wrapup.sh` (line 36) runs `check.sh`, which now surfaces the ⚠.
**No edit to `flywheel/wrapup.sh` is required or permitted by this plan.**

Edit these four files, then copy them identically into `.agents/skills/wrapup/` and
`.claude/skills/wrapup/`. Canonical tree is `distribution/shared/skills/wrapup/`;
`tests/test_adapter_lifecycle.sh:28` diffs it against `.agents/skills/wrapup/`, and
`.claude/skills/wrapup/` is currently byte-identical to both and must stay so.

8a. `distribution/shared/skills/wrapup/SKILL.md`, lines 19-21. Replace:
```
- `spawns.json`: verify any automatically appended subagent rows and correct wrong
  `outcome`/`notes` values; a default successful outcome must be changed when a spawn
  actually retried, escalated, or failed. Add the coordinator row as directed by the
```
with:
```
- `spawns.json`: automatically appended subagent rows arrive with `outcome: "pending"`
  — a placeholder, not a verdict. Resolve EVERY pending row to `ok`, `retried`,
  `escalated`, or `failed` from this session's own record, and correct wrong `notes`.
  If a spawn is genuinely still running, leave it `pending` and say so in STATUS.md;
  never guess `ok`. A `pending` row from an earlier session that this session cannot
  adjudicate: resolve it from the agent's committed output if it exists, otherwise set
  `outcome: failed` and `notes: unadjudicated (session N)` — a spawn nobody can account
  for did not succeed. Add the coordinator row as directed by the
```
Keep lines 22-25 (the remaining bullet text) unchanged.

Without that last clause the enum is decorative for exactly the case i30 names: a
`pending` row left for a still-running agent survives into the next session, where no
coordinator holds the record needed to resolve it. Nothing would ever retire it — a
permanent ⚠ and, per Step 6, a permanent unclearable friction signal — until
`compact.py` silently swallowed it (Step 3). `failed` + a dated `unadjudicated` note is
the honest terminal value: it records that the system lost track, which is a real
finding the improve pass should see, not a fabricated success.

Constraint check: `tests/test_adapter_lifecycle.sh:23-27` requires SKILL.md to keep the
literal string `` read exactly one file in `references/` `` (line 17, untouched) and
forbids the tokens `Codex|Claude|Antigravity|.codex|.claude` anywhere in it — the
replacement above contains none.

8b. `distribution/shared/skills/wrapup/references/claude-code.md`, lines 4-6. Replace:
```
subagent spawned this session. Its default is `outcome:"ok"`; correct that value for
any retry, escalation, or failure. Append one row by hand for the coordinator itself
```
with:
```
subagent spawned this session. It fires when the Agent tool CALL returns — for a
BACKGROUND spawn that is at launch, before any result exists — so every row it writes
carries the placeholder `outcome:"pending"`. Resolve each one yourself. Append one row
by hand for the coordinator itself
```

8c. `distribution/shared/skills/wrapup/references/codex.md`, lines 9-11. Replace:
```
Adapter hooks may have auto-appended subagent rows; their default is
`outcome:"ok"`, so correct retries, escalations, and failures. Append one coordinator
```
with:
```
Adapter hooks may have auto-appended subagent rows; their placeholder is
`outcome:"pending"`, so resolve each into ok/retried/escalated/failed. Append one coordinator
```

8d. `distribution/shared/skills/wrapup/references/antigravity.md`, lines 4-5. Replace:
```
Adapter hooks may have auto-appended subagent rows; their default is
`outcome:"ok"`, so correct retries, escalations, and failures. Append one row by hand
```
with:
```
Adapter hooks may have auto-appended subagent rows; their placeholder is
`outcome:"pending"`, so resolve each into ok/retried/escalated/failed. Append one row by hand
```

8e. Project all four into both dogfood trees:
```bash
for t in .agents .claude; do
  cp distribution/shared/skills/wrapup/SKILL.md "$t/skills/wrapup/SKILL.md"
  cp distribution/shared/skills/wrapup/references/*.md "$t/skills/wrapup/references/"
done
```

Acceptance: all three trees identical; the `<!-- flywheel-managed -->` marker on line 1
of every file is preserved (`tests/test_adapter_lifecycle.sh:31-33` fails otherwise).

Verify:
```bash
diff -rq distribution/shared/skills/wrapup .agents/skills/wrapup && \
diff -rq distribution/shared/skills/wrapup .claude/skills/wrapup && echo "ALL THREE IDENTICAL"
grep -rn 'outcome:"ok"' distribution/shared/skills .agents/skills .claude/skills
head -1 distribution/shared/skills/wrapup/references/*.md
```
(expect `ALL THREE IDENTICAL`, no `outcome:"ok"` hits, and `<!-- flywheel-managed -->` first in each file)

---

### Step 9 — tests

File: `tests/test_resolve_spawn.py`. Baseline before any change: `Ran 37 tests ... OK`
in ~4.5 s (measured 2026-07-29).

9a. **Change `"outcome": "ok"` → `"outcome": "pending"` at exactly these seven lines**,
all of which assert the row an automatic writer produced:

| line | test |
|---|---|
| 165 | `test_codex_rows_ignore_agent_and_session_identifiers` |
| 478 | `test_codex_coordinator_uses_newest_runtime_context_and_short_hash` |
| 770 | `test_claude_code_*` golden (researcher, override requested) |
| 793 | `test_claude_resolved_model_mismatch_and_config_fallback_goldens` |
| 807 | `test_claude_unknown_agent_golden` |
| 836 | `test_antigravity_invoke_subagent_multi_row_order_and_truncation_golden` |
| 859 | `test_antigravity_parent_resolution_precedence_and_config_fallback_goldens` |

9b. **Do NOT touch these `outcome` references** — they are the curation-survives-rerun
guarantees and must keep their human-written terminal values:

| line | why |
|---|---|
| 104 | `assert_terminal_row` key set — the 8-key shape is unchanged |
| 494, 508 | `test_codex_coordinator_is_idempotent_and_preserves_human_fields` — proves a human `"retried"` survives a resolver rerun |
| 546, 553 | `test_codex_coordinator_reconciles_one_manual_pending_but_not_ambiguous` — same for the manual-reconcile path |

(The asserted `"retried"` literals themselves sit on lines 509 and 554, which contain no
`outcome` token and so never appear in the grep below. Leave them alone too.)

9c. **Add one regression test** at the end of the class, immediately before line 864
(`if __name__ == "__main__":` — the file is 865 lines), guarding the actual i30 defect
across every adapter path:

```python
    def test_auto_logged_rows_never_assert_a_terminal_outcome(self):
        """i30: hooks fire before a verdict exists (background claude-code spawns log
        at launch), so no automatic writer may emit ok/retried/escalated/failed."""
        cases = [
            ("codex", {"agent_type": "utility", "cwd": str(self.root)}),
            ("claude-code", {"tool_input": {"subagent_type": "engineer", "description": "x"},
                             "tool_response": {}, "cwd": str(self.root)}),
            ("antigravity", {"tool_input": {"Subagents": [{"TypeName": "utility", "Prompt": "x"},
                                                          {"TypeName": "verifier", "Prompt": "y"}]},
                             "cwd": str(self.root)}),
        ]
        for adapter, payload in cases:
            with self.subTest(adapter=adapter):
                before = len(self.spawns())
                self.run_hook(payload, adapter=adapter)
                new = self.spawns()[before:]
                self.assertTrue(new)
                for row in new:
                    self.assertEqual(row["outcome"], "pending")

        thread_id = "42345678-1234-1234-1234-123456789abc"
        home, _ = self.coordinator_rollout(
            thread_id, self.coordinator_records(thread_id, [{"model": "m", "effort": "high"}]))
        before = len(self.spawns())
        self.run_coordinator(thread_id, home)
        self.assertEqual(self.spawns()[before]["outcome"], "pending")
```

Acceptance: `Ran 38 tests ... OK`.

Verify:
```bash
python3 -m unittest tests.test_resolve_spawn 2>&1 | tail -4
grep -n outcome tests/test_resolve_spawn.py
```
(expect `Ran 38 tests` + `OK`; and the grep must show `pending` at 165/478/770/793/807/836/859
and `retried` still at 494/508/546/553)

---

### Step 10 — full gate, then commit

```bash
bash -n flywheel/check.sh                    # shell syntax intact after the Step 4 inserts
bash flywheel/check.sh                       # expect: ✓ all checks passed
bash flywheel/check.sh | grep 'state/'       # all five ✓ state/*.json lines still present
python3 -m unittest tests.test_resolve_spawn # expect: Ran 38 tests ... OK
bash tests/test_adapter_lifecycle.sh         # expect: exit 0
python3 -m unittest tests.test_codex_adapter_repair_spec
bash dev/check.sh                            # expect: PASS repository distribution checks
python3 flywheel/dashboard/build.py          # dashboard is gitignored; do not stage it
git status --porcelain                       # confirm ONLY the §3 file list is modified
```

`dev/check.sh` is the authoritative mirror gate: line 12-17 asserts every file under
`distribution/managed/flywheel` is byte-identical to `flywheel/`, and lines 54-59 assert
those files reference no repository-only paths.

Commit — exactly the §3 files, named explicitly (GIT.md: never `-A`, never `.`):

```bash
git add flywheel/resolve-spawn.py flywheel/state/SCHEMAS.md flywheel/check.sh \
  flywheel/dashboard/template.html flywheel/IMPROVE.md flywheel/DELEGATION.md \
  tests/test_resolve_spawn.py \
  distribution/managed/flywheel/resolve-spawn.py distribution/managed/flywheel/state/SCHEMAS.md \
  distribution/managed/flywheel/check.sh distribution/managed/flywheel/dashboard/template.html \
  distribution/managed/flywheel/IMPROVE.md distribution/managed/flywheel/DELEGATION.md \
  distribution/shared/skills/wrapup .agents/skills/wrapup .claude/skills/wrapup
git commit -m "improve(flywheel): spawn rows log outcome pending until wrapup adjudicates" \
  -m "i30: resolve-spawn.py hardcoded outcome=ok on every auto-logged row, so IMPROVE.md's
'gather spawns with outcome retried|escalated|failed' input was empty by construction; and
the claude-code PostToolUse(Agent) hook fires at tool-call return, which for a background
spawn is at launch (observed 2026-07-29T16:59 verifier row). Automatic writers now emit
the non-terminal 'pending'; wrapup resolves it; check.sh enforces the enum and warns on
unresolved rows."
```

`git status --porcelain` must show no staged path outside that list —
`flywheel/wrapup.sh:14-28` will hard-abort the later bookkeeping commit if an
implementation path is left staged.

---

## 5. The existing rows in `flywheel/state/spawns.json`

Measured 2026-07-29 (`python3 -c "import json,collections; d=json.load(open('flywheel/state/spawns.json')); print(len(d), collections.Counter(r.get('outcome') for r in d))"`):

```
33 Counter({'ok': 31, 'failed': 1, 'retried': 1})
```

At `HEAD` (`git show HEAD:flywheel/state/spawns.json | python3 -c "import json,sys,collections;
d=json.load(sys.stdin); print(len(d), collections.Counter(r.get('outcome') for r in d))"`):

```
31 Counter({'ok': 29, 'failed': 1, 'retried': 1})
```

**Every number above is already stale — the auditor measured 35 rows
(`Counter({'ok': 33, 'failed': 1, 'retried': 1})`) minutes later.** The hook appends a row
on every spawn, so the count grows while this plan is being read. Re-measure with the
command above; never hardcode it. Nothing in this plan depends on the exact count, only on
the two invariants below, both of which the engineer should confirm still hold:

```bash
# invariant A: every existing value is already inside the new enum (expect: empty output)
python3 -c "import json;d=json.load(open('flywheel/state/spawns.json'));print([r.get('outcome') for r in d if r.get('outcome') not in {'pending','ok','retried','escalated','failed'}])"
# invariant B: no row is 'pending' yet, so the baseline check.sh run emits no ⚠ (expect: 0)
python3 -c "import json;d=json.load(open('flywheel/state/spawns.json'));print(sum(1 for r in d if r.get('outcome')=='pending'))"
```

- 1 `failed` (index 1), 1 `retried` (index 18), all others `ok`.
- Roughly 7 rows carry `auto-logged` in `notes`; the rest were written or curated by hand.
- Index 0 is the `agent:"(compacted)"` rollup written by `flywheel/compact.py:57`.

**Decision: leave every existing row exactly as it is. No migration, no backfill, and
nothing touching `spawns.json` in the implementation commit.** Three reasons:

1. `flywheel/state/SCHEMAS.md:26` declares spawns.json an *append-only* record.
   Retroactively rewriting historical rows to `pending` would replace one unbacked claim
   with a different unbacked claim — we cannot now tell which of the `ok` rows were
   genuinely adjudicated at their wrapup and which merely inherited the hardcoded default.
   Fabricating "we don't know" over rows a human did verify is not an improvement.
2. Every existing value is already inside the new enum (`ok|retried|failed` ⊂
   `pending|ok|retried|escalated|failed`), so the new `check.sh` validation passes against
   the untouched ledger on day one. No migration is technically required.
3. Ledger edits are **out of scope for this commit by rule**: IMPROVE.md:33-37 permits one
   implementation commit plus at most one bookkeeping-only commit limited to `STATUS.md`,
   `LESSONS.md`, state ledgers, and generated output, and `flywheel/wrapup.sh:16-17`
   enforces that allowlist mechanically.

**The one row that should be corrected** — `{"ts": "2026-07-29T16:59", "agent": "verifier",
"task": "Verify i29 compact indent fix", "outcome": "ok"}`, named in i30 as demonstrably
premature — is a *curation*, not a migration. That verifier has since finished, so the
coordinator now knows its real verdict. It belongs in the wrapup bookkeeping commit
(wrapup skill step 2), **not** in this branch's implementation commit. Recorded here so
the coordinator does not lose it.

---

## 6. Merge gate

AUTONOMY.md row "Merge flywheel self-improvement branch" (IMPROVE.md:38-42). The engineer
must **not** merge. Report the branch name and commit hash to the coordinator, which
applies the row for the configured autonomy level. Close `i30` and record the commit in
`flywheel/state/issues.json` only after the merge decision resolves.

---

## 7. Deferred / follow-up (NOT part of this branch)

**Record the claude-code hook-timing fact in `flywheel/FACTS.md`.** An earlier draft of
this plan added a §Adapter capabilities row to `flywheel/FACTS.md` and
`distribution/defaults/flywheel/FACTS.md` capturing that `PostToolUse`/matcher `Agent`
fires at Agent-tool return — for a background spawn, at launch — and that no claude-code
subagent-completion hook event is verified in this repo.

**Cut, deliberately.** It is the one genuinely separable edit in the set: nothing in
Steps 1-10 reads it, and the fix works identically without it. Bundling it would make
this branch two improvements in one commit, which IMPROVE.md:48-49 forbids. It also packs
a *verified* observation and a *`Pending verification`* gap into a single table cell,
which deserves its own review rather than riding along.

Action for the coordinator: open a new `type: "debt"` issue — "record claude-code
Agent-hook timing (and the unverified completion-hook gap) in FACTS.md" — citing this
section and i30. Per MAINTENANCE.md:12, *adding* a new verified fact is autonomous, so
that issue needs no plan; it does need someone to decide whether the unverified half is
worth a live verification attempt first. Budget note for whoever takes it: both files
were 77/80 lines on 2026-07-29, so a one-row addition fits under
`check_budget FACTS.md 80` (`flywheel/check.sh:31`) — re-measure before writing.

---

## Found

- `flywheel/resolve-spawn.py:547` and `:572` hardcode `"outcome": "ok"` on every
  auto-logged row; there is no other write site (`grep -n '"outcome"' flywheel/resolve-spawn.py`
  → 547, 572, plus the read-only preservation comment at :498).
- `flywheel/IMPROVE.md:22-24` instructs the improve pass to gather `state/spawns.json` rows
  with outcome `retried|escalated|failed`.
- `.claude/settings.json:4` — the only claude-code hook is
  `PostToolUse` / matcher `Agent` → `python3 flywheel/resolve-spawn.py`. No completion-time
  event is wired.
- `.codex/hooks.json` wires `SubagentStop`; `.agents/hooks.json` wires
  `PostToolUse`/`invoke_subagent`. Codex logs from a completion event and *still* writes
  `"ok"` — evidence that completion timing alone does not solve the truth-claim defect.
- `flywheel/FACTS.md:48` documents only the claude-code `PostToolUse(Agent)` payload;
  `flywheel/state/decisions.json:85` records the shipped design as "single PostToolUse hook
  (matcher \"Agent\")" after a claude-code `SubagentStop` was considered.
- `flywheel/state/spawns.json`: 33 rows in the working tree / 31 at `HEAD`,
  `Counter({'ok': 31, 'failed': 1, 'retried': 1})` at the time of writing; the auditor
  re-measured 35 / `Counter({'ok': 33, 'failed': 1, 'retried': 1})` minutes later
  (commands in §5). The count is a moving target — every value is terminal and inside the
  proposed enum, which is the only property the plan relies on. ~7 rows contain
  `auto-logged`.
- `cmp flywheel/resolve-spawn.py distribution/managed/flywheel/resolve-spawn.py` → identical.
  All eight managed files I compared (`resolve-spawn.py`, `IMPROVE.md`, `DELEGATION.md`,
  `check.sh`, `wrapup.sh`, `compact.py`, `state/SCHEMAS.md`, `dashboard/template.html`) are
  byte-identical today, and `dev/check.sh:12-17` enforces that for the whole tree.
- `diff -rq` shows `distribution/shared/skills/wrapup`, `.agents/skills/wrapup`, and
  `.claude/skills/wrapup` are byte-identical today; `tests/test_adapter_lifecycle.sh:28`
  enforces the first two.
- `flywheel/check.sh` does **not** validate `outcome` today — its spawns.json handling
  (lines 96-99) checks only array-ness, entry count, and commit hashes.
- `flywheel/dashboard/template.html:305-309` maps any unrecognised outcome to the red
  `negative` chip; the filter (lines 170-174) offers only ok/retried/escalated/failed.
  `grep -n outcome flywheel/dashboard/build.py flywheel/dashboard/build.mjs` → no hits.
- Line counts (`wc -l`): IMPROVE.md 64/75, DELEGATION.md 29/45, FACTS.md 77/80,
  `distribution/defaults/flywheel/FACTS.md` 77, SCHEMAS.md 37 (no budget), check.sh 357
  (no budget), template.html 415 (no budget).
- Test baseline: `python3 -m unittest tests.test_resolve_spawn` → `Ran 37 tests in 4.517s
  OK`. `grep -n outcome tests/test_resolve_spawn.py` → lines 104, 165, 478, 494, 508, 546,
  553, 770, 793, 807, 836, 859.
- `flywheel/wrapup.sh:16-17` restricts the bookkeeping commit to
  `STATUS.md|LESSONS.md|state/*.json|dashboard.html|docs/flywheel/ARCHITECTURE.md`, and
  line 36 aborts the wrapup on a `check.sh` ✗.
- `dev/check.sh:54-59` fails if any file under `distribution/managed/flywheel` references
  `distribution/`, `installer/`, `dev/`, or `tests/`.

## Assumed

- **`pending` over `unknown`.** No source prefers either; chosen because it matches the
  repo's existing `Pending verification` idiom and reads as non-terminal rather than as a
  verdict of ignorance.
- **Warn (not fail) on leftover `pending`.** Assumed that blocking the session's only
  commit is worse than a visible warning, because `wrapup.sh:36` aborts on ✗ and
  INDEX.md's session protocol says "Uncommitted = lost". A genuinely still-running
  background agent is a state no coordinator can adjudicate on demand.
- **`flywheel/compact.py:57` left alone.** Assumed the `(compacted)` rollup row's `ok`
  means "the compaction ran", not "a spawn succeeded"; changing it would make the pending
  warning fire forever on a row no wrapup can resolve.
- **The dashboard edit is in scope, not a bundle.** Assumed that introducing a value the
  CEO dashboard paints red would substitute a new false claim for the old one, so the
  three-line template change belongs to the same atomic improvement.
- **`.claude/skills/wrapup/` must be updated too.** Only `.agents/skills/wrapup/` is
  test-enforced against the canonical tree; the `.claude` copy's parity is currently a
  fact, not a guarantee, and is assumed to be intended.
- **The 2026-07-29T16:59 verifier row's true outcome.** Not asserted here — the
  coordinator must supply it during wrapup curation. This plan only says where the edit
  belongs.
- **`failed` + `unadjudicated (session N)` for a cross-session orphan** (Step 8a, added on
  auditor blocker 4). Assumed that "the system lost track of this spawn" is better
  recorded as a failure the improve pass can see than as an eternal `pending` that
  `compact.py` eventually swallows. It will occasionally mark a spawn that actually
  succeeded — accepted, because the alternative is an enum that stays decorative for
  exactly the case i30 names.
- **`bash -n flywheel/check.sh` added to Steps 4 and 10.** Not requested by the auditor;
  added because the blocker it found (a `"` in the node insert turning check.sh into a
  shell syntax error) is invisible to every other acceptance check in this plan.

## Could not find

- Any verified claude-code hook event that fires when a **background** subagent finishes.
  Not in `flywheel/FACTS.md` §Adapter capabilities, not in `.claude/settings.json`, not in
  `flywheel/ADAPTERS.md`. Status: **`Pending verification`** — candidate 3 cannot be
  costed, let alone implemented, until someone verifies this live and dates a FACTS row.
- Whether the antigravity `PostToolUse`/`invoke_subagent` hook fires at subagent
  completion or at dispatch. `.agents/hooks.json` shows only the wiring; no FACTS row
  covers the timing. Status: **`Pending verification`**. (Immaterial to this plan — the
  fix is timing-independent.)
- Any existing test covering `flywheel/check.sh` behaviour. There is none
  (`tests/` holds only `test_adapter_lifecycle.sh`, `test_codex_adapter_repair_spec.py`,
  `test_resolve_spawn.py`), which is why Step 4's verification is an inject-and-restore
  probe rather than a unit test. Adding a check.sh test harness would be a separate
  improvement and is deliberately out of scope (IMPROVE.md:48-49).
- Any mechanism that keeps `flywheel/check.sh`'s python3 branch and node fallback in sync.
  They are mutually exclusive at runtime and untested against each other; Step 4 relies on
  the engineer transcribing identical strings.

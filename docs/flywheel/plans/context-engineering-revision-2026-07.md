# Plan — context-engineering revision of the always-loaded doc set (2026-07-28)

Strategist plan (tier: strategist). Applies the ranked revisions in
`docs/flywheel/research/context-engineering-guide-implications-2026-07.md`.

**Status: VALIDATED** (2026-07-29, session 33). Fresh-context `plan-auditor` audit
history: initial verdict FAILED (4 blockers, 6 majors, 2 minors); plan revised in
place; re-audit VERIFIED — every fix independently re-probed, cascaded arithmetic
recomputed, proposed check.sh block executed against simulated post-Phase-4 files.
Re-audit surfaced 5 non-blocking minor text defects with exact prescriptions; applied
verbatim by `utility` after the verdict and grep-verified (edits at plan lines ~178,
~223, ~669, ~742, §6.1 K10 step). Verdicts live in the session 33 coordinator
transcript; recorded here + activity.json per HR3 (author never self-validates —
strategist wrote this plan, auditor issued the verdict).
Amendment 2026-07-29 (coordinator, content-preserving): §6.2 fence prose rewrapped so
"operating as <tier>" sits unbroken on one line — engineer STOP exposed a fence/B3
self-contradiction (verbatim fence made its own grep criterion unsatisfiable). Words
unchanged, still 8 fence lines; no other section affected.
Amendment 2, 2026-07-29 (coordinator, content-restoring): Phase 2 verifier word-level
diff found the fence had silently dropped "(see your adapter block)" from the original
ORCHESTRATION.md §8 first line — a plan-inception defect both audit passes missed
(they compared fence-to-file, never fence-to-source). Phrase restored; still 5 prose
lines, 8 fence lines, "operating as <tier>" unbroken.

**Merge gate:** `flywheel/config.json` `autonomy: 3`. AUTONOMY.md:16 row "Merge
flywheel self-improvement branch" is **A** at L3 → each phase branch gets a `pending`
`state/decisions.json` entry; the coordinator does not merge. Five phases = five
gates. Do not ask for a level change to avoid them (AUTONOMY.md:24, level-invariant).

**Branch topology (read before cutting Phase 1's branch).** The phases are
*cumulative*: every line count from Phase 2 onward assumes the previous phases' edits
are present. Because merges are gated (**A** at L3) they may still be unmerged when the
next phase starts, so **each phase branches off the previous phase's branch, not off
`main`** — Phase 1 off `main`, Phase 2 off `flywheel/improve-scaffold-density`, and so
on. If the human merges an earlier gate first, `git rebase main` the pending branch(es)
before continuing; the diff is disjoint per phase, so the rebase is expected to be
clean. Each phase still contains exactly one implementation commit, so every phase
remains individually revertible after merge (IMPROVE.md:45-46). If the human *rejects*
an earlier gate, stop: the later phases' arithmetic no longer holds and this plan must
be re-issued, not improvised.

---

## 0. Decision list (revisions 1-8)

| # | Revision | Decision | One-line rationale |
|---|---|---|---|
| 1 | Kill HR1-4 duplication | **Execute now — narrowed to the claude-code block** (Phase 4) | claude-code `@flywheel/INDEX.md` (CLAUDE.md:7) mechanically loads the canonical list; codex/opencode/antigravity blocks only *instruct* a read, so their copies stay and get a stronger mechanical guard. |
| 2a | Move ORCHESTRATION §8 (degraded mode) out of always-loaded | **Execute now** (Phase 2) | Read once per adapter port; ADAPTERS.md is its subject-matter home. −7 always-loaded lines. |
| 2b | Move ORCHESTRATION §4 escalation detail + §6 spawn-provenance out | **Execute now** (Phase 3) | Choreography needed only mid-delegation; the binding invariants (two retries, parallel/serial, >100-line delegation trigger) stay in place. −16 always-loaded lines. |
| 2c | Slim FACTS.md (provenance/payload archaeology out) | **Defer** | Worth only ≈ −4 lines and it perturbs differentiation-rank-#1 (`strategy-2026-07.md:36`) plus forces a repo/`distribution/defaults` divergence. **Trigger:** FACTS.md reaches 78/80 lines, or the Phase 5 managed-region cap needs more headroom. |
| 3 | "Scaffold density scales with the weakest reader" principle | **Execute now — first** (Phase 1) | It is the guard rail that stops Phases 2-4's momentum from reaching TEMPLATES.md; it must exist *before* the cuts, not after. |
| 4 | Accelerate A1 prose→interfaces | **Execute now — partial** (Phase 5) | Land it as a *preference ordering* in IMPROVE.md + the budget ratchet in check.sh. The SCHEMAS.md machine-validation piece is a separate engineering task (see §7 bookkeeping). |
| 5 | A2 hierarchy collapse knob (`full/lean/solo`) | **Defer** | Touches `config.json` schema, `sync.py`, `check.sh`, four adapter blocks and ORCHESTRATION §1 — cannot be one revertible improve branch, and has no measured baseline yet. **Trigger:** Phases 1-5 merged AND issue i6 (benchmark with/without flywheel) produces per-tier overhead numbers. |
| 6 | Measure before cutting | **Execute now — as this plan's method, not a doc edit** | Realised as Phase 0 (baseline capture) + one branch per variable + a fresh `verifier` per phase. The standing eval-substrate work becomes a new issue (§7). |
| 7 | Absorption events / lean on `/doctor` | **Defer the absorption note; reject the `/doctor` dependency for core** | No verified fact about `/doctor` exists — FACTS.md §Adapter capabilities has no row for it, so HR2 forbids building on it. Rejecting the core dependency is permanent (vendor-specific, breaks A3 portability); the claude-code *adapter note* is deferrable. **Trigger:** a dated `/doctor` row lands in FACTS.md §Adapter capabilities with a source URL. |
| 8 | Rich reference files (rubrics) for verifier/auditor | **Defer to its own strategist plan** | It adds files and behaviour (rubric docs + dashboard debt scores) — it is a feature, not a doc cut, and bundling it would violate IMPROVE.md:45-46. **Trigger:** the dashboard dual-persona work (positioning doc §3) starts. |

Net effect of the "execute now" set: always-loaded **265 → 238** lines (claude-code)
and **268 → 246** (AGENTS.md), with a new flywheel-owned cap in `check.sh` (Phase 5)
so the win cannot be silently re-spent.

## 0.1 Out of scope (considered, deliberately excluded)

Recorded so the auditor can see these were weighed, not overlooked. Each is
independent of the doc cuts — none of them changes a line count in Phases 1-5, and
bundling any of them would violate IMPROVE.md:45-46.

| Excluded | Source | Why it is not in this plan |
|---|---|---|
| CEO/CTO dashboard view modes | positioning doc §5 Q4 | Dashboard rendering work; touches `template.html`/`build.py`/`build.mjs`, not the doc set. |
| Q1 ad-hoc utility execution mechanics (running a scan mid-session without a full wrapup) | positioning doc §5 Q1 | A protocol question, not a cut. Phase 3's `flywheel/DELEGATION.md` gives it an on-demand home to land in later, and Phase 5 reserves 10 lines for whatever it needs always-loaded. |
| Q2 auditor-only architectural debt/depth scores | positioning doc §5 Q2 | This is deferred revision 8 (rubric files) under another name — same trigger, same follow-up issue in §7. |
| Q3 cognitive SLA metric | positioning doc §5 Q3 | A measurement definition; belongs with the revision-6 eval-substrate issue, which it should be merged into when picked up. |
| `CONTEXT.md` domain glossary | positioning doc §4C | Not built here, but **budgeted** here: Phase 5 reserves 40 always-loaded lines for it and makes `check.sh`'s file list extensible so it is counted the day it lands. |

---

## 1. Never-touch set (no phase below softens any of these)

| Protected | Canonical location | Why it is out of scope |
|---|---|---|
| **HR2** anti-fabrication + the `Pending verification` convention | `flywheel/INDEX.md:17-18`; FACTS.md:1-8 | Differentiation rank #1 (`strategy-2026-07.md:36-38`). Phase 4 deletes only the claude-code *copy*; the canonical text is byte-unchanged. |
| **HR3** never-self-verify | `flywheel/INDEX.md:19`; `ORCHESTRATION.md:70-82` (§5) | Differentiation rank #2. §5 falls in no phase's edit range; `dev/check.sh:32-40` guard is *strengthened* in Phase 4, never removed. |
| **HR1** big-file rule, **HR4** autonomy pointer | `flywheel/INDEX.md:15-16, 21-22` | Same treatment as HR2 — canonical text untouched. |
| `flywheel/AUTONOMY.md` in full, especially the level-invariant rows | `AUTONOMY.md:23-24` (spend money / change the dial) and `AUTONOMY.md:27-28` | No phase opens this file. |
| `flywheel/TEMPLATES.md` scaffolding — 4 templates + 4 worked examples | `TEMPLATES.md:13-224` | Phase 2 edits exactly one cross-reference string at `TEMPLATES.md:9`; nothing else. Phase 1 exists to make this protection a written rule. |
| Weak-model-facing rule restatements in skill bodies | `.claude/skills/delegate/SKILL.md:36`, `.agents/skills/delegate/SKILL.md:36`, `distribution/shared/skills/delegate/SKILL.md:36` | These duplicate "max two retries" on purpose for utility-class readers — Phase 1's new principle explicitly keeps them. Do **not** treat them as Phase 4 targets. |
| ORCHESTRATION §2 (three delegation elements) and §3 (reporting contract) | `ORCHESTRATION.md:27-49` | Outside every edit range. |

Auditor probe for this section: `grep -n "HR3" docs/flywheel/plans/context-engineering-revision-2026-07.md`
and confirm no phase's edit range in §4-§6 below overlaps `ORCHESTRATION.md:70-82`.

---

## 2. Pre-execution amendments (conflicts that must be fixed *inside* the phase that
creates them, or the repo self-contradicts)

| ID | Conflict | Where | Resolution |
|---|---|---|---|
| K1 | INDEX.md heading asserts the adapter block duplicates HR1-4 and they are kept identical | `flywheel/INDEX.md:14` | Reword **in the Phase 4 commit** (see §6.4 step 3). Not a separate branch — a heading that contradicts the same commit's diff is worse than the duplication. |
| K2 | ADAPTERS.md says the four hard rules are "deliberate point-of-use duplicates … there is no mechanical check yet" | `flywheel/ADAPTERS.md:62-64` | Two errors: it will be false for claude-code after Phase 4, and the "no mechanical check" claim is **already false** — `dev/check.sh:32-40` diffs the HR3 line verbatim across five files today. Rewrite in the Phase 4 commit. |
| K3 | `dev/check.sh` HR3-identity loop includes the claude-code block | `dev/check.sh:33-39` | Phase 4 must drop that path from the loop *and* widen the check from HR3-only to all four HR lines for the three remaining blocks + INDEX.md. Otherwise `dev/check.sh` fails and the guard silently weakens. |
| K4 | Managed dogfood parity: `distribution/managed/flywheel/*` must be byte-identical to `flywheel/*` | `dev/check.sh:12-17` | **Every** phase that edits `flywheel/INDEX.md`, `ORCHESTRATION.md`, `MAINTENANCE.md`, `ADAPTERS.md`, `IMPROVE.md`, `TEMPLATES.md`, `check.sh` or adds `DELEGATION.md` must copy the file into `distribution/managed/flywheel/` in the same commit. |
| K5 | `check.sh` requires every `flywheel/*.md` path named in INDEX.md to exist | `flywheel/check.sh:60-69` | Phase 3 must create `flywheel/DELEGATION.md` **and** add its INDEX.md row in one commit. |
| K6 | IMPROVE.md forbids bundling improvements | `flywheel/IMPROVE.md:45-46` | Mandates the one-phase-one-branch-one-commit structure below. It also matches the GPT-feedback rule "never delete 80% blind — one variable at a time." |
| K7 | IMPROVE.md: "If two consecutive improve passes propose nothing, that is fine. Zero is a valid count." vs revision 4's "≥ 1 mechanization per pass" | `flywheel/IMPROVE.md:50-51` | Do **not** write a quota. Phase 5 lands revision 4 as a *preference ordering* ("when ranking candidate improvements, prefer the one that converts a prose rule into a check"). Exact wording in §6.5. |
| K8 | The 500-line always-loaded cap is stated in two places | `flywheel/check.sh:55-56` and `flywheel/MAINTENANCE.md:31-32` | Phase 5 changes both in the same commit. |
| K9 | Loosening rules need a LESSONS.md justification | `flywheel/IMPROVE.md:47-49` | **Exactly one budget raise in the whole plan** — `MAINTENANCE.md` 80 → 90, in Phase 1, with the LESSONS.md line written in the same commit (§6.1 steps 2-3). It buys room for the scaffold-density + information-hierarchy rules on an **on-demand** file while the always-loaded set drops 27 lines. Everywhere else: Phase 2 uses ADAPTERS.md's existing headroom, Phase 3 adds a fresh budget for a new file, Phase 5 only tightens. If any other phase overruns its budget, STOP and report — do not raise it to fit. |
| K10 | Structural changes without an ARCHITECTURE.md update trip a check.sh warning | `flywheel/check.sh:147-156` | **The warning is unavoidable and must be accepted, not "fixed".** `gen_architecture.py` discovers only `*.sh` and `*.py` in `flywheel/` (`_discover_scripts`, `flywheel/dashboard/gen_architecture.py:22-28`) — it has no `.md` discovery, and `docs/flywheel/ARCHITECTURE.md` enumerates no doc files (`grep -n "TEMPLATES\|JUDGMENT\|AUTONOMY" docs/flywheel/ARCHITECTURE.md` → no output). Regenerating therefore produces **no diff** for any phase here. Each affected phase must: run `python3 flywheel/dashboard/gen_architecture.py .`, confirm `git status --porcelain docs/flywheel/ARCHITECTURE.md` is **empty**, do **not** hand-edit the file (it is generated — header marker `<!-- flywheel-generated:architecture -->` — a manual edit is overwritten on the next run), and record the expected warn-only notice in the commit body. ARCHITECTURE.md appears in **no** phase's file count. See §7 for the follow-up issue. |
| K11 | `install.sh` cannot target the flywheel repo itself (open issue i1) | `flywheel/state/issues.json` i1 | Phase 4 cannot refresh the dogfood `CLAUDE.md` by re-running the installer. Hand-edit `CLAUDE.md` to match the new block, preserving line 4's seeded `Project:` line (installer/lifecycle/common.sh:45-48 does exactly this on a real target). |

**Backlog overlaps — noted, not re-planned:** i3 (INDEX.md on-demand row for the
strategy doc) uses the same row-add mechanics as Phase 3 but is a different
improvement — do not bundle it (K6). i9 (single AGENTS.md block conflicts across
codex/opencode/antigravity) is why Phase 4 is claude-code-only: the AGENTS.md block is
already contested and must not be perturbed in the same pass.

---

## 3. Phase 0 — baseline (do this first, on `main`, no commit)

Capture the numbers every later phase is measured against.

```bash
cd /Users/jjting/Documents/projects/flywheel
git rev-parse --short HEAD
bash flywheel/check.sh   2>&1 | tee /tmp/fw-baseline-check.txt
bash dev/check.sh        2>&1 | tail -5
bash tests/test_adapter_lifecycle.sh 2>&1 | tail -3
wc -l CLAUDE.md AGENTS.md flywheel/INDEX.md flywheel/ORCHESTRATION.md flywheel/FACTS.md \
      flywheel/MAINTENANCE.md flywheel/ADAPTERS.md flywheel/IMPROVE.md flywheel/TEMPLATES.md
```

Verified baseline (2026-07-28, commit `f48d2c3`, commands above):

```
✓ INDEX.md: 42/50 lines            ✓ MAINTENANCE.md: 70/80 lines
✓ ORCHESTRATION.md: 113/120 lines  ✓ ADAPTERS.md: 66/85 lines
✓ FACTS.md: 77/80 lines            ✓ IMPROVE.md: 57/75 lines
✓ TEMPLATES.md: 224/230 lines      ✓ docs/flywheel/ARCHITECTURE.md: 84/150 lines
✓ always-loaded set (CLAUDE.md+INDEX+ORCHESTRATION+FACTS): 265/500 lines
✓ always-loaded set (AGENTS.md+INDEX+ORCHESTRATION+FACTS): 268/500 lines
✓ all checks passed
CLAUDE.md 33   AGENTS.md 36
```

**Acceptance:** all three suites green before any branch is cut. If `check.sh` is not
green on `main`, stop and report — do not cut on a red baseline.

---

## 4. Phase order and why

1. **Phase 1 — MAINTENANCE.md §5 scaffold-density principle.** No cut. Establishes the
   floor before anything is removed.
2. **Phase 2 — ORCHESTRATION §8 → ADAPTERS.md.** Smallest pure move; proves the
   move-and-fix-cross-references mechanic on a 7-line section.
3. **Phase 3 — ORCHESTRATION §4/§6 → new `flywheel/DELEGATION.md`.** Largest cut;
   also the first new managed file, exercising K4/K5/K10 together.
4. **Phase 4 — claude-code adapter-block HR pointer + guard strengthening.** Touches
   the moat's neighbourhood; goes last among the cuts, after the mechanic is proven.
5. **Phase 5 — ratchet the budgets + IMPROVE.md preference line.** Locks the win in
   `check.sh` so a future session cannot silently re-spend it.

Each phase: one `flywheel/improve-<slug>` branch **cut from the previous phase's
branch** (Phase 1 from `main`) per the branch-topology note in the header, **one**
implementation commit (`improve(flywheel): <slug>`, GIT.md:8-14 + IMPROVE.md:30-31),
one fresh `verifier` dispatch, one `pending` decisions.json entry. The verifier runs on
that phase's branch, so it sees the cumulative state the expected numbers assume.
Rebase onto `main` whenever an earlier gate merges. Never `git add -A` (GIT.md:13).
Never `--no-verify` (GIT.md:14).

---

## 5. Per-phase verification harness (run for every phase)

```bash
bash flywheel/check.sh               # expect the per-phase deltas below, "✓ all checks passed"
bash dev/check.sh                    # expect "PASS repository distribution checks"
bash tests/test_adapter_lifecycle.sh # expect "PASS adapter lifecycle matrix"
git diff --stat                      # expect exactly the file count stated per phase
```

`dev/check.sh` already invokes `flywheel/check.sh` (dev/check.sh:9) and installs into a
scratch repo (dev/check.sh:76-84), so it is the phase gate; the standalone
`flywheel/check.sh` run is for reading the line-budget deltas.

**Line numbers drift between phases — always re-locate.** Every `file:line` in §6 is
measured against the repo as of commit `f48d2c3`, but the phases are cumulative, so an
earlier phase's insert shifts a later phase's targets. Known shifts: Phase 3 step 5a
adds one line to `flywheel/check.sh` above the `struct_changes` line and above the
always-loaded block, so Phase 5's `check.sh` always-loaded block becomes `19-31` (lines
19-29 do not move; step 5a inserts after line 29), and `47-58` becomes `48-59`;
Phase 2's 8-line insert into `flywheel/ADAPTERS.md` pushes the Exception paragraph from
62-64 to 70-72. Before any edit, confirm the target with the `grep -n` probe given in
that step (each shifting target has one); if the grep does not find the expected text,
STOP and report rather than editing by line number.

---

## 6. Phases

### 6.1 Phase 1 — `flywheel/improve-scaffold-density`

**Goal.** Write down the principle that protects weak-model-facing scaffolding before
any cutting starts (revision 3).

**Edits.**

1. `flywheel/MAINTENANCE.md` — append after the current last line (70), as a new §5:

```markdown

## 5. Scaffold density scales with the weakest reader

Docs read only by coordinator/architect/strategist tiers (INDEX, ORCHESTRATION,
JUDGMENT) stay lean principles — cut those first. Docs *executed* by utility- and
engineer-class models (TEMPLATES.md, skill bodies, checklists) keep full scaffolding
and worked examples. Hard boundaries (HR2, HR3, AUTONOMY.md) never soften for anyone.
Inside such a doc, order by information hierarchy: (1) steps with exhaustive, checkable
completion criteria, (2) flat peer-set reference rules, (3) pointers to external files
loaded only when needed. Push detail down a tier before deleting it.
```

   Exactly **10** added lines (1 leading blank + heading + blank + 7 prose) → 70 + 10
   = **80**. The last three prose lines are the information-hierarchy tier ordering
   from `docs/flywheel/research/positioning-and-cognitive-dashboard-2026-07.md:75-79`
   — the same scaffold-density principle applied to skill authoring. It lands **now**,
   not later, because there is no second cheap window: MAINTENANCE.md is at 70/80 today
   and Phases 3+5 both touch it.

2. `flywheel/check.sh:24` — raise `check_budget MAINTENANCE.md 80` to `90`.
   **This is the plan's only budget raise, and it is deliberate.** Rationale to state
   in the commit body: MAINTENANCE.md is an **on-demand** file (INDEX.md's table), not
   always-loaded; the scarce resource this whole plan defends is the always-loaded set,
   which drops 27 lines across Phases 2-4. Trading +10 on-demand lines for −27
   always-loaded lines is a net tightening of the metric that matters. Post-plan the
   file sits at 83/90 (Phase 5 adds 3), leaving real headroom instead of the 0-1 lines
   an 80-cap would leave — which is what forces the next session to cut prose it should
   keep.
3. `flywheel/LESSONS.md` — append the justification line required by IMPROVE.md:47-49
   for any rule-loosening change (a raised budget counts):
   `2026-07-28 | always-loaded revision Phase 1 | strategist→engineer | MAINTENANCE.md budget 80→90 to seat §5 scaffold-density + information-hierarchy rules | on-demand file traded against −27 always-loaded lines (plan: context-engineering-revision-2026-07.md §6.1)`
   Put it in the **implementation commit**, not the wrapup bookkeeping commit — the
   justification must be reviewable alongside the diff it justifies. (IMPROVE.md:32-34
   *permits* a bookkeeping commit for LESSONS.md; it does not require one.)
4. Mirror to distribution (K4): `cp flywheel/MAINTENANCE.md flywheel/check.sh
   distribution/managed/flywheel/`.
5. Run `python3 flywheel/dashboard/gen_architecture.py .`; expect **no diff** and do
   not stage `docs/flywheel/ARCHITECTURE.md` (K10). The `⚠ Structural changes
   detected … but docs/flywheel/ARCHITECTURE.md was not updated` notice from
   `check.sh:149-155` is expected and warn-only; note it in the commit body.

**Expected deltas.** `MAINTENANCE.md: 80/90`. Always-loaded unchanged (265/268).
No sync.py change. Managed-block refresh unaffected (MAINTENANCE.md is a managed
*file*, copied wholesale by `installer/lifecycle/core.sh:7-12` — not a marker block),
so nothing here can be lost to a refresh.

**Acceptance criteria.**
- A1. `bash flywheel/check.sh 2>&1 | grep MAINTENANCE` → `✓ MAINTENANCE.md: 80/90 lines`.
- A2. `bash dev/check.sh 2>&1 | grep "managed dogfood"` → `PASS managed dogfood files are byte-identical`.
- A3. `git diff --stat` → exactly **5** files: `flywheel/MAINTENANCE.md`,
  `flywheel/check.sh`, `flywheel/LESSONS.md`, and the two
  `distribution/managed/flywheel/` mirrors.
- A4. `grep -c "HR3" flywheel/MAINTENANCE.md` → `1` (the new section names it; nothing else in the file changed).
- A5. Loosening is justified, not silent: `grep -c "MAINTENANCE.md budget 80→90" flywheel/LESSONS.md` → `1`.
- A6. Budget raise is the only one: `git diff flywheel/check.sh | grep -c "^[-+]check_budget"` → `2` (the single MAINTENANCE line, before and after).

**Commit.** `improve(flywheel): scaffold density scales with weakest reader`
Body cites `docs/flywheel/research/context-engineering-guide-implications-2026-07.md:37-40`
and `docs/flywheel/research/positioning-and-cognitive-dashboard-2026-07.md:70-79`, and
states the budget-raise rationale above.

---

### 6.2 Phase 2 — `flywheel/improve-degraded-mode-to-adapters`

**Goal.** Remove degraded-mode choreography from always-loaded context; it is
port-time knowledge (revision 2a).

**Edits.**

1. `flywheel/ORCHESTRATION.md` — **delete lines 107-113 inclusive and nothing else**
   (the whole `## 8. Adapters without subagents (degraded mode)` section: heading +
   blank + 5 prose lines). Line 106 is the single blank line that already separated §7
   from §8; **keep it** — the file then ends at line 106 → `wc -l` = **106**.
   Sections §1-§7 keep their numbers; do not renumber anything.
2. `flywheel/ADAPTERS.md` — insert before line 55 (`## Rules for adapter authors`) a
   new section carrying the deleted prose verbatim:

```markdown
## Degraded mode (adapter cannot spawn subagents)

If your adapter cannot spawn subagents (see your adapter block), the tiers become
sequential roles in one session: adopt a tier by pasting its TEMPLATES.md template
and announcing "operating as <tier>". Verification-never-self-performed then means:
a FRESH session (new context) runs Template 4. Model switching is done by the human
per config.json. What is lost: context isolation and parallelism — say so in reports.

```
   **8** added lines (heading + blank + 5 prose + trailing blank) → 66 + 8 = **74**.
3. Update the four live cross-references to the retired `ORCHESTRATION.md §8`:
   - `flywheel/TEMPLATES.md:9` → `(ADAPTERS.md §Degraded mode)`
   - `flywheel/ADAPTERS.md:20` → `degraded mode (see §Degraded mode below)`
   - `docs/SEED-PROMPT.md:46` → `(see flywheel/ADAPTERS.md §Degraded mode)`
   - `docs/flywheel/research/strategy-2026-07.md:44` → `(ADAPTERS.md §Degraded mode)`
   Leave `docs/flywheel/plans/*` and `flywheel/LESSONS.md` historical references alone.
4. `flywheel/INDEX.md:33` — widen the ADAPTERS.md trigger cell in the on-demand table
   from `Porting flywheel to another adapter` to
   `Porting flywheel to another adapter; adapter cannot spawn subagents`.
   In-place edit, **0 line delta** (verify INDEX.md stays at 42).
5. Mirror to distribution (K4): `cp flywheel/ORCHESTRATION.md flywheel/ADAPTERS.md
   flywheel/TEMPLATES.md flywheel/INDEX.md distribution/managed/flywheel/`.
6. Run `python3 flywheel/dashboard/gen_architecture.py .`; expect **no diff** and do
   not stage `docs/flywheel/ARCHITECTURE.md` (K10). The `⚠ Structural changes
   detected … but docs/flywheel/ARCHITECTURE.md was not updated` notice from
   `check.sh:149-155` is expected and warn-only; note it in the commit body.

**Expected deltas.** `ORCHESTRATION.md: 106/120`, `ADAPTERS.md: 74/85`,
`INDEX.md: 42/50`, `TEMPLATES.md: 224/230` (unchanged count),
always-loaded `258/500` (CLAUDE) and `261/500` (AGENTS).

**Acceptance criteria.**
- B1. `bash flywheel/check.sh 2>&1 | grep -E "ORCHESTRATION|ADAPTERS|always-loaded"` shows `106/120`, `74/85`, `258/500`, `261/500`.
- B2. Removed-duplication probe: `grep -rn "ORCHESTRATION.md §8" flywheel/ docs/SEED-PROMPT.md docs/flywheel/research/strategy-2026-07.md distribution/managed/` → **no output** (exit 1).
- B3. Content preserved: `grep -c "operating as <tier>" flywheel/ADAPTERS.md` → `1`.
- B4. `bash dev/check.sh` → `PASS repository distribution checks`.
- B5. `bash tests/test_adapter_lifecycle.sh` → `PASS`. (This suite greps
  `AGENTS.md` for ``Read `flywheel/INDEX.md` now`` at
  `tests/test_adapter_lifecycle.sh:406` — no phase may remove that string.)
- B6. `git diff --stat` → **10** files: 4 under `flywheel/` (ORCHESTRATION, ADAPTERS,
  TEMPLATES, INDEX), the same 4 under `distribution/managed/flywheel/`,
  `docs/SEED-PROMPT.md`, `docs/flywheel/research/strategy-2026-07.md`.
  `docs/flywheel/ARCHITECTURE.md` must **not** appear (K10).

**Commit.** `improve(flywheel): move degraded mode to ADAPTERS.md`

---

### 6.3 Phase 3 — `flywheel/improve-delegation-mechanics-file`

**Goal.** Take mid-delegation choreography out of always-loaded context while leaving
every binding invariant in ORCHESTRATION (revision 2b).

**Edits.**

1. Create `flywheel/DELEGATION.md` — the fenced block below is **29 lines** (`wc -l`
   counts 29 with the file's single trailing newline):

```markdown
# Delegation mechanics — escalation paths, spawn provenance

On-demand (see INDEX.md). ORCHESTRATION.md §2-§4 and §6 hold the binding rules; this
file holds the choreography needed only while a delegation is in flight.

## Escalation paths (ORCHESTRATION.md §4)

Escalate UP after the two retries are exhausted:
- `utility` fails an easy task → send to `engineer` with the failure attached.
- `engineer` fails a coding task → back to `strategist` to refine the plan, then
  re-issue to `engineer`.
- A `strategist` plan fails in execution **twice** → escalate to `architect` with the
  complete failure trace: both plans, both failure reports, verifier output. Also route
  to `architect`: irreversible architectural forks and flywheel rule conflicts that
  `auditor` cannot resolve. Nothing else — it is the scarcest tier.

De-escalate DOWN once a pattern is solved: first instance fixed by a higher tier →
document the pattern (in the plan or LESSONS.md) → batch-apply remaining instances
via `utility`/`engineer`.

## Spawn provenance (ORCHESTRATION.md §6)

Model provenance is adapter-specific: Claude Code children use the Agent response;
Codex children use config pins (its stop payload lacks child runtime telemetry);
Antigravity children inherit the parent model or configured fallback. Codex
coordinators resolve current-turn rollout telemetry at wrapup. All automatic rows
go through `flywheel/resolve-spawn.py`; otherwise log manually with best verified
provenance and `Pending verification` when unavailable. At wrapup, correct child
outcomes/notes and ensure the coordinator has exactly one row.
```

   Constraint from `dev/check.sh:46-51`: this file must not mention `distribution/`,
   `installer/`, `dev/` or `tests/` — the text above complies.

2. `flywheel/ORCHESTRATION.md` — replace §4 (**lines 50-69**, 20 lines) with these
   exactly 9 lines:

```markdown
## 4. Escalation / de-escalation

Max **two retries per tier**, and a retry must change something (better spec, more
context, smaller scope) — never resend the same prompt verbatim. After that, escalate
one tier up; paths and de-escalation live in `flywheel/DELEGATION.md`. `architect` is
reached only by a twice-failed strategist plan, an irreversible architectural fork, or
a rule conflict `auditor` cannot resolve — nothing else. Log every escalation in
`flywheel/LESSONS.md` (one line: date, task, tier path, cause).

```

3. `flywheel/ORCHESTRATION.md` — replace §6 (**lines 83-98 in the original file**,
   16 lines) with these exactly 11 lines:

```markdown
## 6. Parallelism & budget

- Independent delegations: launch in one message (parallel). Dependent: strictly serial —
  never guess a dependency's output.
- Before delegating, state (to yourself, one line) which tier and why. If tempted to do
  it inline in the main session, check §1 routing table first.
- Main-session context is the scarcest resource. When a task will generate > ~100 lines
  of tool output, that alone is reason to delegate.
- Spawn rows carry adapter-specific provenance and are never invented (HR2); the
  per-adapter rules are in `flywheel/DELEGATION.md`.

```

   Apply edit 3 **before** edit 2, or recompute §6's line numbers after §4 shrinks.
   Section headings §4 and §6 are preserved, so the 8 live cross-references to
   `ORCHESTRATION.md §4` (`flywheel/MAINTENANCE.md:20,49`, `flywheel/JUDGMENT.md:10`,
   `.claude/skills/{delegate,wrapup}/SKILL.md`, `.agents/skills/…`,
   `distribution/shared/skills/…`, `flywheel/LESSONS.md:7`) stay valid — **do not
   touch them.** The `delegate` skill's restatement of the two-retry rule is a
   deliberate weak-model duplicate protected by Phase 1's §5.

4. `flywheel/INDEX.md` — add one row to the on-demand table (after the
   `flywheel/TEMPLATES.md` row, line 28):

```markdown
| `flywheel/DELEGATION.md` | A delegation escalated, was retried, or needs a spawn row |
```
   +1 line → 43.

5. `flywheel/check.sh` — two edits, both required for the new file to be governed like
   its siblings:
   a. add after line 29 (`check_budget TEMPLATES.md 230`): `check_budget DELEGATION.md 45`;
   b. the `struct_changes` line (148 before edit 5a, **149 after** — locate it with
      `grep -n struct_changes flywheel/check.sh`) — add `DELEGATION` to the filename
      alternation, i.e.
      `flywheel/(INDEX|ORCHESTRATION|AUTONOMY|MAINTENANCE|TEMPLATES|FACTS|DIAGNOSIS|JUDGMENT|GIT|IMPROVE|ADAPTERS|DELEGATION)\.md`.
      Without (b) a future edit to DELEGATION.md is invisible to the structural-change
      guard.

6. `flywheel/MAINTENANCE.md:15` — add `DELEGATION.md` **and** `ADAPTERS.md` to the
   structural-file list in the permission matrix row (ADAPTERS.md is missing today —
   verify with `grep -c "ADAPTERS" flywheel/MAINTENANCE.md` → `0` before the edit).
   It is a single table row: the edit is in-place, **0 line delta** (MAINTENANCE.md
   stays at 80/90). Without this, DELEGATION.md would not formally require the strategist
   plan + auditor process that governs every other rule file.

7. Mirror to distribution (K4): copy `flywheel/DELEGATION.md`,
   `flywheel/ORCHESTRATION.md`, `flywheel/INDEX.md`, `flywheel/check.sh`,
   `flywheel/MAINTENANCE.md` into `distribution/managed/flywheel/`. No installer change
   is needed — the installer copies the managed tree with `find`
   (`installer/lifecycle/core.sh:7-12`), so a new file ships automatically.

8. Run `python3 flywheel/dashboard/gen_architecture.py .`; expect **no diff**, do not
   stage `docs/flywheel/ARCHITECTURE.md`, note the warn-only structural notice in the
   commit body (K10). `gen_architecture.py` discovers only `*.sh`/`*.py`
   (`flywheel/dashboard/gen_architecture.py:22-28`), so DELEGATION.md will **not**
   appear in ARCHITECTURE.md — that gap is tracked as a follow-up issue in §7.

**Expected deltas.** `ORCHESTRATION.md: 90/120`, `INDEX.md: 43/50`,
`DELEGATION.md: 29/45`, `MAINTENANCE.md: 80/90` (unchanged count),
always-loaded `243/500` (CLAUDE) and `246/500` (AGENTS).

**Acceptance criteria.**
- C1. `bash flywheel/check.sh 2>&1 | grep -E "ORCHESTRATION|INDEX.md:|DELEGATION|always-loaded"` shows `90/120`, `43/50`, `29/45`, `243/500`, `246/500`.
- C2. `bash flywheel/check.sh 2>&1 | grep "all referenced .md files exist"` → present (K5 satisfied).
- C3. Invariants survived the cut: each of these greps returns ≥ 1 hit in `flywheel/ORCHESTRATION.md` — `grep -c "two retries per tier"`, `grep -c "launch in one message"`, `grep -c "~100 lines"`.
- C4. Moved content is not lost: `grep -c "scarcest tier" flywheel/DELEGATION.md` → `1`; `grep -c "resolve-spawn.py" flywheel/DELEGATION.md` → `1`.
- C5. Nothing moved out of §5: `sed -n '/## 5. Verification/,/## 6./p' flywheel/ORCHESTRATION.md | grep -c "never issues the verdict"` → `1`.
- C6. `bash dev/check.sh` → `PASS repository distribution checks` (proves the managed copy and the scratch-repo install both work with the new file).
- C7. `bash tests/test_adapter_lifecycle.sh` → `PASS`.
- C8. `git diff --stat` (plus `git status --porcelain` for the new file) → **10** files:
  4 changed + 1 new under `flywheel/` (ORCHESTRATION, INDEX, check.sh, MAINTENANCE,
  DELEGATION.md) and the same 5 under `distribution/managed/flywheel/`.
  `docs/flywheel/ARCHITECTURE.md` must **not** appear (K10).
- C9. Governance wired: `grep -c "DELEGATION" flywheel/check.sh` → `2` (budget row +
  `struct_changes` alternation); `grep -c "DELEGATION" flywheel/MAINTENANCE.md` → `1`;
  `grep -c "ADAPTERS" flywheel/MAINTENANCE.md` → `1`.

**Commit.** `improve(flywheel): split delegation mechanics out of always-loaded`

---

### 6.4 Phase 4 — `flywheel/improve-claude-block-hr-pointer`

**Goal.** State HR1-4 once for the adapter that mechanically loads INDEX.md, and make
the remaining duplication mechanically enforced instead of prose-enforced
(revision 1 + A1).

**Why claude-code only.** `distribution/adapters/claude-code/CLAUDE.md.block:6-9`
declares `@flywheel/INDEX.md` under "Always loaded" — the canonical HR list is in
context by construction. The codex, opencode and antigravity blocks instead say
"Read `flywheel/INDEX.md` now" (an instruction that can be skipped), so their copies
**stay**. Hard boundaries do not get downgraded to "the model will probably read it."

**Edits.**

1. `distribution/adapters/claude-code/CLAUDE.md.block` — replace lines 18-25 (heading
   + 4 rules, 8 lines) with exactly 3 lines:

```markdown
## Hard rules
HR1-HR4 are stated once in `flywheel/INDEX.md` §Hard rules, always loaded above, and
bind every session. Never restate them here — a copy drifts from its source.
```
   Block 30 → 25 lines.

2. `CLAUDE.md` (repo dogfood instance) — apply the identical edit inside the marker
   region, preserving line 4's seeded `Project:` line. Do **not** run `install.sh` on
   this repo (K11 / issue i1). 33 → 28 lines.

3. `flywheel/INDEX.md:14` — replace the heading
   `## Hard rules (duplicated in the adapter block at point of use — keep identical)`
   with
   `## Hard rules (canonical; blocks that cannot load this file duplicate them verbatim)`.
   In-place, 0 line delta (INDEX.md stays at 43).

4. `flywheel/ADAPTERS.md` — replace **only the 3 "Exception" lines** (live 62-64;
   after Phase 2's 8-line insert they sit at **70-72**). Do not touch the two lines
   above them (`- The adapter never duplicates doctrine …` / `into an adapter block
   will drift …`) — they open the bullet and replacing them orphans the indented
   paragraph. **Re-locate before editing:**
   `grep -n 'Exception: the four hard rules' flywheel/ADAPTERS.md` → replace that line
   and the two following it with:

```markdown
  Exception: adapter blocks that cannot mechanically load `flywheel/INDEX.md` (codex,
  opencode, antigravity — they only instruct a read) carry the four hard rules as
  point-of-use duplicates, verbatim-identical to INDEX.md. Blocks that do load it
  (claude-code, via `@flywheel/INDEX.md`) point at INDEX.md instead. The repository
  distribution check diffs the remaining copies line-by-line.
```
   **The replacement text must not contain the literal strings `dev/`,
   `distribution/`, `installer/` or `tests/`** — `flywheel/ADAPTERS.md` is mirrored
   into `distribution/managed/flywheel/`, which `dev/check.sh:46-52` rg-scans for
   repo-only paths; naming the script there fails
   `installed managed files reference repository-only paths`. (Same constraint already
   applied to DELEGATION.md in Phase 3.) Hence "the repository distribution check".
   5 lines replacing 3 → **+2**: ADAPTERS.md 74 → **76/85**.

5. `dev/check.sh:32-40` — replace the HR3-only loop with an all-four-rules check that
   no longer includes the claude-code block:

```bash
hr_lines=(
'- HR1. Never Read a file listed in `flywheel/FACTS.md` §Big files (or any file > 200 KB)'
'- HR2. Model names / level values / API params come from `flywheel/config.json` +'
'- HR3. No agent declares its own work complete — dispatch `verifier` / `plan-auditor`.'
'- HR4. Ask-vs-act is governed by `flywheel/AUTONOMY.md`; its level-invariant rows bind'
)
for file in "$ROOT/distribution/managed/flywheel/INDEX.md" \
  "$ROOT/distribution/adapters/codex/AGENTS.md.block" \
  "$ROOT/distribution/adapters/opencode/AGENTS.md.block" \
  "$ROOT/distribution/adapters/antigravity/AGENTS.md.block"; do
  for hr in "${hr_lines[@]}"; do
    grep -Fxq -- "$hr" "$file" || fail "HR mismatch: ${file#"$ROOT/"} :: ${hr:0:8}"
  done
done
grep -Fxq -- '@flywheel/INDEX.md' "$ROOT/distribution/adapters/claude-code/CLAUDE.md.block" ||
  fail "claude-code block lost its @flywheel/INDEX.md always-loaded import"
[ "$FAIL" = 0 ] && pass "hard-rule duplicates are identical and the claude-code block imports INDEX.md"
```
   **`-Fxq` with the leading `@` is load-bearing.** The whole safety argument for this
   phase is that `@flywheel/INDEX.md` is a real always-loaded import, not prose. A
   substring match on `flywheel/INDEX.md` would be satisfied by the new pointer
   sentence itself, so the guard would still pass with the import line deleted — a
   vacuous check guarding the plan's single riskiest assumption. `-x` (whole-line)
   plus the `@` prefix matches only the import directive at
   `distribution/adapters/claude-code/CLAUDE.md.block:7`.

6. Mirror `flywheel/INDEX.md` and `flywheel/ADAPTERS.md` into
   `distribution/managed/flywheel/` (K4). `dev/check.sh` is repo-only — not mirrored.
7. Run `python3 flywheel/dashboard/gen_architecture.py .`; expect **no diff**, do not
   stage `docs/flywheel/ARCHITECTURE.md`, note the warn-only structural notice in the
   commit body (K10).

**Expected deltas.** `CLAUDE.md` 33 → 28; block 30 → 25; `ADAPTERS.md: 76/85`;
always-loaded `238/500` (CLAUDE), `246/500` (AGENTS, unchanged from Phase 3).

**Acceptance criteria.**
- D1. `bash flywheel/check.sh 2>&1 | grep always-loaded` → `238/500` and `246/500`.
- D2. Managed-block-refresh survival: the repo instance and the shipped block differ
  only by the seeded Project line —
  `diff <(sed -n '/flywheel:begin/,/flywheel:end/p' CLAUDE.md) distribution/adapters/claude-code/CLAUDE.md.block`
  → exactly one hunk, `4c4`, `Project:`. Anything else means the next `install.sh`
  refresh would overwrite the cut (`installer/lifecycle/common.sh:41-49` replaces the
  whole region).
- D3. Duplication actually gone from always-loaded claude-code context:
  `grep -c "^- HR" CLAUDE.md` → `0`; `grep -c "^- HR" AGENTS.md` → `4` (untouched).
- D4. Canonical text byte-unchanged: `git diff flywheel/INDEX.md` shows **only** the
  line-14 heading; `git diff -U0 flywheel/INDEX.md | grep -c "^[-+]- HR"` → `0`.
- D5. Guard strengthened, not weakened: `bash dev/check.sh 2>&1 | grep "hard-rule"` →
  `PASS hard-rule duplicates are identical and the claude-code block imports INDEX.md`;
  and a negative fixture proves it is not vacuous —
  `sed -i.bak 's/^- HR3\./- HR3x./' distribution/adapters/codex/AGENTS.md.block && bash dev/check.sh; echo "expect FAIL"; mv distribution/adapters/codex/AGENTS.md.block.bak distribution/adapters/codex/AGENTS.md.block`
  must print `FAIL HR mismatch: …` and then restore cleanly (`git status --porcelain
  distribution/adapters/codex/` → empty).
- D6. `bash tests/test_adapter_lifecycle.sh` → `PASS` (`:406`'s AGENTS.md string is untouched).
- D6b. The import guard is not vacuous: delete the import line and confirm the check
  fails —
  `sed -i.bak '/^@flywheel\/INDEX\.md$/d' distribution/adapters/claude-code/CLAUDE.md.block && bash dev/check.sh 2>&1 | grep "always-loaded import"; mv distribution/adapters/claude-code/CLAUDE.md.block.bak distribution/adapters/claude-code/CLAUDE.md.block`
  must print `FAIL claude-code block lost its @flywheel/INDEX.md always-loaded import`,
  then restore clean (`git status --porcelain distribution/adapters/claude-code/` → empty).
  **If this probe passes silently, the phase is unsafe — stop and report.**
- D7. No AUTONOMY/TEMPLATES collateral: `git diff --name-only | grep -cE "AUTONOMY|TEMPLATES"` → `0`.
- D8. `git diff --stat` → **7** files: `distribution/adapters/claude-code/CLAUDE.md.block`,
  `CLAUDE.md`, `flywheel/INDEX.md`, `flywheel/ADAPTERS.md`, `dev/check.sh`, and the two
  `distribution/managed/flywheel/` mirrors (INDEX.md, ADAPTERS.md).
  `docs/flywheel/ARCHITECTURE.md` must **not** appear (K10).

**Commit.** `improve(flywheel): claude-code block points at canonical HR list`

---

### 6.5 Phase 5 — `flywheel/improve-always-loaded-ratchet`

**Goal.** Convert the earned headroom into an enforced ceiling, and make
prose→interface conversion a standing preference (revisions 4 + 6, assumptions A1/A4).

**Edits.**

**The ratchet is a principle, not a number.** State it this way in the commit body and
in MAINTENANCE.md: *the cap on the flywheel-owned always-loaded set equals the
post-cut worst case plus an explicitly named reserve for features already queued.* A
bare number invites two failures — a cap so tight that the next planned feature must
either be rejected or trigger another budget fight, and a cap so loose it records
nothing. Named reserve, from
`docs/flywheel/research/positioning-and-cognitive-dashboard-2026-07.md`:

| Reserved for | Source | Lines |
|---|---|---|
| `CONTEXT.md` domain glossary (only pays off if always-loaded) | positioning §4C:87-88 | 40 |
| Skill-whitelist growth in the adapter block (model-invoked skills cost context every turn) | positioning §4A:71-76 | 6 |
| Q1 ad-hoc-execution protocol lines in INDEX/ORCHESTRATION | positioning §5 Q1:96-98 | 10 |
| FACTS.md growth to its existing 80-line budget | `check.sh` `check_budget FACTS.md 80` | 3 |
| **Total reserve** | | **59** |

Worst-case owned total after Phase 4 is the codex block: 36 + 43 + 90 + 77 = **246**.
246 + 59 = 305 → **flywheel-owned cap = 305**. Spending that reserve on anything not
in the table above is a finding for the next improve pass, not a reason to raise the
cap.

**The whole-file cap stays at 500 — do not lower it.** `check.sh` counts whole files,
and everything a downstream project writes in its own `CLAUDE.md`/`AGENTS.md` outside
the marker block counts against it. Lowering it (the 350 in this plan's first draft)
would cut a user's own headroom from 232 lines to 104 and could turn existing installs
red for content flywheel does not own — punishing users for flywheel's savings. The
ratchet flywheel is accountable for is the **owned** cap; that is the one being added.

**Edits.**

1. `flywheel/check.sh` — lower `check_budget ORCHESTRATION.md 120` to `95` (locate with
   `grep -n "check_budget ORCHESTRATION" flywheel/check.sh`; it is line 21 today, 21
   still after Phase 3's insert at line 30).
   Leave every other per-file budget as is (lowering others would be a second
   variable). Do **not** re-touch `check_budget MAINTENANCE.md 90` from Phase 1.
2. `flywheel/check.sh` — replace the always-loaded block (47-58 today, **48-59** after
   Phase 3; locate with `grep -n "always-loaded set" flywheel/check.sh`). Two changes: the file
   list moves into **one** variable so a future always-loaded file (e.g. `CONTEXT.md`)
   is counted by both caps the day it is added, and the owned cap is introduced.

```bash
# Always-loaded set. To add a newly always-loaded file, append its name HERE and
# nowhere else — both caps below read this list.
ALWAYS_LOADED="INDEX.md ORCHESTRATION.md FACTS.md"
# Whole-file cap: includes project-authored prose outside the marker block, which
# flywheel does not own. Owned cap: marker block + $ALWAYS_LOADED only — the ratchet.
for adapter_file in CLAUDE.md AGENTS.md; do
  if [ -f "$REPO_ROOT/$adapter_file" ]; then
    label="$adapter_file"
    total=$(wc -l < "$REPO_ROOT/$adapter_file" | tr -d ' ')
    owned=$(awk '/<!-- flywheel:begin -->/,/<!-- flywheel:end -->/' "$REPO_ROOT/$adapter_file" | wc -l | tr -d ' ')
    for f in $ALWAYS_LOADED; do
      label="$label+${f%.md}"
      [ -f "$FLYWHEEL_DIR/$f" ] || continue
      n=$(wc -l < "$FLYWHEEL_DIR/$f" | tr -d ' ')
      total=$((total + n)); owned=$((owned + n))
    done
    if [ "$total" -le 500 ]; then echo "✓ always-loaded set ($label): $total/500 lines";
    else echo "✗ always-loaded set ($label): $total lines exceeds 500"; FAIL=1; fi
    if [ "$owned" -le 305 ]; then echo "✓ flywheel-owned always-loaded ($adapter_file block+${label#*.md}): $owned/305 lines";
    else echo "✗ flywheel-owned always-loaded ($adapter_file block+${label#*.md}): $owned lines exceeds 305"; FAIL=1; fi
  fi
done
```

   The `label` string is built from `$ALWAYS_LOADED` rather than hardcoded, so the
   output line stays truthful when the list changes — a hardcoded label that says
   `+INDEX+ORCHESTRATION+FACTS` while summing four files is exactly the kind of
   silent drift `check.sh` exists to prevent.

3. `flywheel/MAINTENANCE.md:31-32` — replace the two cap lines with four (K8), stating
   the principle, not just the numbers:

```markdown
- Always-loaded set (adapter file + every file named in check.sh's `ALWAYS_LOADED`)
  ≤ 500 lines total; the flywheel-owned part (marker block + those files) ≤ 305 —
  check.sh sums both. 305 = the post-cut worst case (246) plus a reserve named in
  check.sh's comment and the Phase 5 plan; spending it elsewhere is an improve finding.
  Keep new adapter blocks ≤ 50 lines (audit-pass check).
```
   5 lines replacing 2 → MAINTENANCE.md 80 → **83/90** (Phase 1 raised this budget to
   90 precisely so this line and the §5 rules both fit). The final clause is carried
   over verbatim from the old line 32 — **do not drop it**; silently deleting an
   existing rule while rewording its neighbour is the exact failure this plan's audit
   trail exists to catch. If it lands above 83, re-trim the new prose — do not raise
   the budget a second time (K9).

4. `flywheel/IMPROVE.md` — append to §Rules (after line 51), as a preference, not a
   quota (K7):

```markdown
- When two candidate improvements are otherwise equal, prefer the one that converts a
  prose rule into a mechanical check (check.sh, a hook, a schema). Docs teach, checks
  enforce; a rule that can be checked and is not is debt. This ranks candidates — it
  never manufactures one (the zero-improvement rule above still stands).
```
   4 lines → IMPROVE.md 57 → 61/75.
5. Mirror `flywheel/check.sh`, `flywheel/MAINTENANCE.md`, `flywheel/IMPROVE.md` into
   `distribution/managed/flywheel/` (K4).
6. Run `python3 flywheel/dashboard/gen_architecture.py .`; expect **no diff**, do not
   stage `docs/flywheel/ARCHITECTURE.md`, note the warn-only notice in the commit body
   (K10).

**Expected deltas.** `ORCHESTRATION.md: 90/95`, `MAINTENANCE.md: 83/90`,
`IMPROVE.md: 61/75`, `always-loaded set …: 238/500` (CLAUDE) and `246/500` (AGENTS),
`flywheel-owned always-loaded …: 235/305` (CLAUDE) and `246/305` (AGENTS).

**Acceptance criteria.**
- E1. `bash flywheel/check.sh 2>&1 | grep -E "always-loaded|flywheel-owned"` shows the four lines above and `all checks passed`.
- E2. The ratchet bites — a negative fixture must fail:
  `printf '\n%.0s' $(seq 60) >> flywheel/ORCHESTRATION.md && bash flywheel/check.sh | grep -E "exceeds"; git checkout flywheel/ORCHESTRATION.md`
  → 90+60 = 150 and 246+60 = 306, so this prints both an `ORCHESTRATION.md … exceeds budget 95` line and a `flywheel-owned … exceeds 305` line, then restores clean (`git status --porcelain flywheel/ORCHESTRATION.md` empty).
- E3. Fresh-install headroom: `bash dev/check.sh 2>&1 | grep "installed check runs in isolated target"` → `PASS` (dev/check.sh:76-84 installs into a scratch repo and runs the new caps against the shipped defaults).
- E3b. **A populated user file is counted but does not consume the ratchet** (the case
  the first draft got wrong):
  ```bash
  probe=$(mktemp -d); git -C "$probe" init -q
  bash install.sh "$probe" --adapters codex --yes >/dev/null
  printf 'user prose line\n%.0s' $(seq 120) >> "$probe/AGENTS.md"
  (cd "$probe" && bash flywheel/check.sh | grep -E "always-loaded|flywheel-owned"); rm -rf "$probe"
  ```
  → `✓ always-loaded set (AGENTS.md+INDEX+ORCHESTRATION+FACTS): 366/500 lines` **and**
  `✓ flywheel-owned always-loaded (…): 246/305 lines`. The owned figure must be
  unchanged by the 120 user lines; if it moved, the marker-region extraction is wrong.
- E3c. **The list is genuinely extensible** (so a future `CONTEXT.md` is counted the
  day it lands): temporarily append `JUDGMENT.md` (129 lines) to `ALWAYS_LOADED`, re-run
  `bash flywheel/check.sh | grep -E "always-loaded|flywheel-owned"`, then
  `git checkout flywheel/check.sh`. Expect the label to become
  `…+INDEX+ORCHESTRATION+FACTS+JUDGMENT`, `total` to rise by 129, and the owned sum to
  hit 375 → `✗ … exceeds 305`. Both caps must react to the one-line edit; if either
  ignores it, the file list is still effectively hardcoded.

  Run E3b and E3c only after the phase's implementation commit — the final `git checkout flywheel/check.sh` discards uncommitted check.sh edits.
- E4. No quota introduced: `grep -c "Zero is a valid count" flywheel/IMPROVE.md` → `1` (the escape hatch survived).
- E5. `bash tests/test_adapter_lifecycle.sh` → `PASS`.
- E6. `git diff --stat` → **6** files: `flywheel/check.sh`, `flywheel/MAINTENANCE.md`,
  `flywheel/IMPROVE.md` and their three `distribution/managed/flywheel/` mirrors.
  `docs/flywheel/ARCHITECTURE.md` must **not** appear (K10).
- E7. Existing rule not silently dropped: `grep -c "adapter blocks ≤ 50 lines" flywheel/MAINTENANCE.md` → `1`.

**Commit.** `improve(flywheel): ratchet always-loaded budgets`

---

## 7. Post-plan bookkeeping (coordinator, autonomous per MAINTENANCE.md:10)

Append to `flywheel/state/issues.json` (these are the deferred items' homes — without
them the deferrals become forgetting):

| id | type | title | note |
|---|---|---|---|
| next | question | Eval substrate for rule value: which rules earn their tokens | Revision 6. Inputs: spawns.json outcomes, LESSONS.md, activity.json always-loaded size trend. Overlaps i5 (compliance half-life) — merge if i5 is picked up first. |
| next | debt | FACTS.md provenance split (adapter payload archaeology → research doc) | Revision 2c, deferred. Trigger: FACTS.md ≥ 78/80 lines. |
| next | question | Hierarchy collapse knob: config.json `full/lean/solo` | Revision 5, deferred. Trigger: i6 benchmark numbers exist. |
| next | question | Rubric files for verifier/auditor + auditor-only dashboard debt scores | Revision 8, deferred to its own strategist plan. Trigger: dashboard dual-persona work starts. |
| next | question | `/doctor` capability: verify and record in FACTS.md §Adapter capabilities | Revision 7. Until a dated row with a source URL exists, HR2 forbids depending on it. |
| next | debt | `gen_architecture.py` ignores the `flywheel/*.md` doc set | Found while planning Phase 3: `_discover_scripts` globs only `*.sh`/`*.py` (`flywheel/dashboard/gen_architecture.py:22-28`), so `DELEGATION.md` — and every other rule file — is invisible to `docs/flywheel/ARCHITECTURE.md`, and `check.sh:147-156`'s structural warning can never be satisfied by regenerating. Fix by adding `.md` discovery, then the warning becomes actionable again. |
| next | question | Cognitive SLA metric (positioning §5 Q3) | Merge into the eval-substrate issue above when either is picked up — one measurement workstream, not two. |

Also add a dated line to `docs/flywheel/research/strategy-2026-07.md` §Update
2026-07-28 pointing at this plan once Phase 5 merges — that file is the standing
roadmap reference (CLAUDE.md:33).

---

## 8. Found / Assumed / Could not find

### Found
- Baseline line counts and budgets: `bash flywheel/check.sh` → `✓ ORCHESTRATION.md: 113/120 lines`, `✓ INDEX.md: 42/50 lines`, `✓ FACTS.md: 77/80 lines`, `✓ MAINTENANCE.md: 70/80 lines`, `✓ ADAPTERS.md: 66/85 lines`, `✓ IMPROVE.md: 57/75 lines`, `✓ TEMPLATES.md: 224/230 lines`, `✓ always-loaded set (CLAUDE.md+INDEX+ORCHESTRATION+FACTS): 265/500 lines`, `✓ always-loaded set (AGENTS.md+…): 268/500 lines`, `✓ all checks passed`.
- `wc -l CLAUDE.md AGENTS.md` → `33`, `36`.
- HR1-4 exist in five files: `flywheel/INDEX.md:15-22` plus all four
  `distribution/adapters/*/[CLAUDE|AGENTS].md.block` blocks (grep for `^- HR`), and are
  re-emitted into the repo's `CLAUDE.md:19-25` / `AGENTS.md:22-28`.
- The claude-code block is the only one that always-loads INDEX.md:
  `distribution/adapters/claude-code/CLAUDE.md.block:6-9` (`@flywheel/INDEX.md`); the
  other three say `Read \`flywheel/INDEX.md\` now`
  (`codex/AGENTS.md.block:6`, `antigravity/AGENTS.md.block:6`, `opencode/AGENTS.md.block:6`).
- Managed-block refresh replaces the whole marker region and preserves only a
  non-placeholder `Project:` line: `installer/lifecycle/common.sh:41-49` (python) and
  `:65-75` (node) — so the block source of truth is
  `distribution/adapters/*/…block`, not the repo copies.
- `sync.py` does **not** generate adapter blocks — it only rewrites model/effort in
  `.claude/agents/*.md`, `.codex/agents/*.toml` and `opencode.json`
  (`flywheel/sync.py:20-61`). **No sync.py change is required by any phase.**
- New managed files ship automatically: `installer/lifecycle/core.sh:7-12` copies
  `distribution/managed/flywheel` with `find … -print0`; `dev/check.sh:12-17` requires
  byte-identical copies of every managed file.
- The HR3 identity guard is already mechanical, contradicting `flywheel/ADAPTERS.md:64`
  ("there is no mechanical check yet"): `dev/check.sh:32-40` `grep -Fxq` the HR3 line
  across INDEX.md + all four blocks.
- `check.sh:60-69` fails if INDEX.md names a non-existent `flywheel/*.md`;
  `check.sh:147-156` warns when structural files change without ARCHITECTURE.md.
- `gen_architecture.py` does **NOT** discover `.md` files: `_discover_scripts` globs
  only `*.sh` and `*.py` (`flywheel/dashboard/gen_architecture.py:22-28`), and
  `grep -n "TEMPLATES\|JUDGMENT\|AUTONOMY" docs/flywheel/ARCHITECTURE.md` returns no
  output — the generated doc enumerates no rule files at all. So regenerating produces
  no diff for any phase here, and `check.sh:147-156`'s structural warning cannot be
  satisfied by regeneration (K10; follow-up issue in §7). `docs/flywheel/ARCHITECTURE.md`
  is at 84/150 and is fully generated (`<!-- flywheel-generated:architecture -->`).
- `dev/sync-distribution.py:22-27` parses `distribution/defaults/flywheel/FACTS.md`
  model rows and requires the row to **end** with `| YYYY-MM-DD |` — this is the
  constraint that makes the deferred revision-2c FACTS restructure risky.
- `flywheel/FACTS.md` and `distribution/defaults/flywheel/FACTS.md` are currently
  byte-identical (`diff -q` → identical), so a repo-only FACTS edit creates a divergence.
- Live cross-references to the sections being moved (full list from
  `grep -rn "ORCHESTRATION.md §[0-9]"`): §8 → `flywheel/TEMPLATES.md:9`,
  `flywheel/ADAPTERS.md:20`, `docs/SEED-PROMPT.md:46`,
  `docs/flywheel/research/strategy-2026-07.md:44`; §4 → `flywheel/MAINTENANCE.md:20,49`,
  `flywheel/JUDGMENT.md:10`, three `skills/delegate/SKILL.md:36` copies,
  `skills/wrapup/SKILL.md:36`, `flywheel/LESSONS.md:7` (all remain valid — the §4
  heading stays).
- `tests/test_adapter_lifecycle.sh:406` asserts the refreshed AGENTS.md contains
  ``Read `flywheel/INDEX.md` now`` — a string no phase may remove.
- Autonomy level is 3 (`flywheel/config.json`), making self-improvement merges **A**
  (`flywheel/AUTONOMY.md:16`) and the structural process mandatory regardless
  (`flywheel/AUTONOMY.md:30-32`, `flywheel/MAINTENANCE.md:15`).
- Open backlog overlaps: i1 (installer cannot target this repo), i3 (INDEX row for the
  strategy doc), i9 (single AGENTS.md block contested across three adapters) — from
  `flywheel/state/issues.json`.

### Assumed
- **Removing HR1-4 from the claude-code block does not weaken them**, because
  `@flywheel/INDEX.md` is loaded on every session. Evidence is structural (the block
  declares the import; this session's own context shows INDEX.md loaded), not a
  measured compliance experiment. If a future claude-code release stops honouring
  `@`-imports, Phase 4 must be reverted — the branch exists for exactly that.
- **Line count is a usable proxy for context cost.** Deltas below are line-based
  because `check.sh` budgets are line-based; no token measurement was taken.
- **A 305-line flywheel-owned cap leaves enough room for downstream projects and for
  the features already queued.** Derived from arithmetic (worst-case owned total after
  Phase 4 = codex block 36 + INDEX 43 + ORCHESTRATION 90 + FACTS 77 = 246, plus the
  59-line named reserve in §6.5), not from observing a real downstream install. The
  reserve sizes themselves (40 for `CONTEXT.md`, 6 for skill-whitelist growth, 10 for
  Q1) are estimates — those features are unbuilt, so no measured size exists.
- **The engineer applies §6.3 edit 3 before edit 2** (or recomputes line numbers);
  the stated ORCHESTRATION line numbers are from the pre-Phase-2 file.
- **Phase 1's 10-line insert lands MAINTENANCE.md at 80/90 and Phase 5's 5-for-2
  rewrite at 83/90.** Counted from the literal fenced blocks above; if the engineer
  reflows the prose the counts change — re-trim rather than raise the budget a second
  time (K9 allows exactly one raise, Phase 1's).
- **The per-phase `git diff --stat` counts assume no incidental edits.** They are
  derived from each phase's own edit list, and every phase now explicitly excludes
  `docs/flywheel/ARCHITECTURE.md`. A count that is one high usually means
  ARCHITECTURE.md was staged against K10.

### Could not find
- Any verified fact about `/doctor` (revision 7): no row exists in FACTS.md §Adapter
  capabilities, and no source was consulted in this session — recorded as
  `Pending verification`, which is why revision 7 is deferred rather than planned.
- Any measurement of prose-rule violation rate or per-tier delegation overhead
  (`strategy-2026-07.md:58-60, 68-69` list both as OPEN RESEARCH). Without them,
  revision 5's collapse-knob default cannot be chosen, which is the stated trigger.
- Any existing eval harness over `spawns.json` / `LESSONS.md` — revision 6's "eval
  substrate" is a named idea in the implications doc, not code that exists.
- Whether Anthropic's ">80% system-prompt cut with no measured loss" result generalises
  to repo-resident policy files. The guide URL is cited in the implications doc but was
  not fetched in this session; every claim attributed to it here is second-hand via
  `docs/flywheel/research/context-engineering-guide-implications-2026-07.md:1-13`.

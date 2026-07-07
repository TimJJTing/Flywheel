# Maintenance — who may change what, when to trim, when to log

This file is STRUCTURAL (see matrix below). Read before touching flywheel/ files or
adapter files, and before any consistency audit.

## 1. File permission matrix

| Path | Any tier, autonomous | Requires |
|---|---|---|
| `flywheel/STATUS.md`, `flywheel/LESSONS.md`, `flywheel/state/*.json`, `docs/plans/*`, `docs/research/*` | Yes — append/update | — |
| Adapter skill bodies, project code, tests | engineer+ per approved plan | utility only for explicit mechanical batch edits |
| `flywheel/FACTS.md` | Add a new verified fact | Changing/removing an existing fact → `auditor` check first |
| `flywheel/config.json` — model/effort cells | No | Verified value (source + date in FACTS.md) + `auditor` check. Then run `python3 flywheel/sync.py` to regenerate the projections — config.json is the source of truth; agent frontmatter and `opencode.json.merge` are generated from it, never hand-edited. `check.sh` fails on drift. |
| `flywheel/config.json` — `autonomy` value | Never by an agent | Human instruction only (AUTONOMY.md, level-invariant row) |
| `flywheel/ORCHESTRATION.md`, `JUDGMENT.md`, `AUTONOMY.md`, `MAINTENANCE.md`, `TEMPLATES.md`, `DIAGNOSIS.md`, `GIT.md`, `IMPROVE.md`, `INDEX.md`, adapter blocks, agent frontmatter (prose only — model/effort are generated, see the config.json row above) | No | Written `strategist` plan + `auditor` approval, applied on a `flywheel/improve-*` branch per IMPROVE.md |
| `flywheel/dashboard/template.html`, `build.py`, `build.mjs`, `check.sh`, `wrapup.sh`, `compact.py` | No | Same structural process (these enforce the rules mechanically) |

✓ Correct: `utility` appends a decided-by-llm entry to state/decisions.json after a
batch rename — in the autonomous set, no approval needed.
✗ Incorrect: `engineer` edits ORCHESTRATION.md §4 retry counts mid-task to "unblock
itself" — structural; requires strategist plan + auditor sign-off on an improve branch.

## 2. Line budgets & streamlining thresholds

Enforced mechanically by `flywheel/check.sh` (wrapup runs it; a red check blocks
committing doc changes until fixed or consciously overridden with a LESSONS.md entry).

- Per-file budgets: the authoritative table is the `check_budget` list at the top of
  `flywheel/check.sh` (INDEX 50, STATUS 40, ORCHESTRATION 120, and so on) — edit
  budgets there, via the structural process, never by letting a file grow past one.
- Always-loaded set (CLAUDE.md/AGENTS.md + INDEX + ORCHESTRATION + FACTS) ≤ 500 lines
  total — check.sh sums it. Keep new adapter blocks ≤ 50 lines (audit-pass check).
- `flywheel/LESSONS.md` > 80 lines → dispatch `strategist` (structural process) to
  consolidate recurring lessons into JUDGMENT.md rules, archive the raw log to
  `docs/research/lessons-archive-YYYYMM.md`.
- `state/activity.json` / `spawns.json` > 100 entries (check.sh warns) → run
  `python3 flywheel/compact.py` during the next improve pass: squashes all but the
  newest 30 into one summary entry keeping milestone hashes; git keeps full history.

✓ Correct: check.sh shows LESSONS.md at 84 lines → strategist pulls the 3 recurring
"escalated on import errors" entries into a JUDGMENT.md R1 example, archives the rest.
✗ Incorrect: STATUS.md hits 150 lines across sessions and nobody notices because
"it's just a log" — this exact rot occurred in flywheel's ancestor repo; check.sh
exists because a budget nobody executes is not a budget.

## 3. Lesson-logging rule

Log an entry in `flywheel/LESSONS.md` when ANY of:
- An escalation happened (ORCHESTRATION.md §4).
- A rule in this system was misread by a tier (ambiguity found, not just an error).
- A fact in FACTS.md was wrong and had to be corrected.
- A pivot occurred per JUDGMENT.md R5.
- An auditor pass surfaced an honesty disclosure (low-confidence output worth flagging
  to future sessions) — append it dated.

Format (one line each):
`YYYY-MM-DD | task | tier path | cause | rule to update (if any)`

✓ `2026-07-12 | csv importer | engineer→strategist | e2: duplicate-ID rule undefined in plan | JUDGMENT R1 e2 example`
✗ `2026-07-12 | fixed a bug` — no tier path, no cause, no rule reference; unusable
input for the consolidation pass in §2 and the improve pass in IMPROVE.md.

## 4. Consistency audit cadence

Every `audit_cadence_sessions` sessions (config.json, default 5) or before any
release, dispatch `auditor` over `flywheel/*.md` + the adapter block, checking:
contradictions, ground truth (paths/tools/models exist), ambiguity for smaller
models, executability. Fix BLOCKER/MAJOR findings via the structural process in §1
before proceeding. This pass is folded into the IMPROVE.md cadence — same trigger,
audit first, then improvements.

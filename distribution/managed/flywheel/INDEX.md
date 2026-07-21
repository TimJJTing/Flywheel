# Flywheel index — adapter-neutral entry point

Your adapter block loaded this file. It is an index only; rules live in the files below.

## Session protocol
1. Read `flywheel/STATUS.md` — current state, in-flight work, next actions. Resume from
   it. Then `bash flywheel/check.sh`: ledger-untracked-commit warnings mean someone
   worked outside the framework — triage, backfill ledgers/docs, note it in STATUS.md.
2. Route work per `flywheel/ORCHESTRATION.md` §1. The coordinator routes; tiers execute.
3. Before ending / when context runs low: run the wrapup procedure (update STATUS.md
   + `flywheel/state/*.json`, then `bash flywheel/wrapup.sh` for the mechanical rest).
   Uncommitted = lost.

## Hard rules (duplicated in the adapter block at point of use — keep identical)
- HR1. Never Read a file listed in `flywheel/FACTS.md` §Big files (or any file > 200 KB)
  wholesale — slice via grep/jq/python, or delegate to `utility`.
- HR2. Model names / level values / API params come from `flywheel/config.json` +
  `flywheel/FACTS.md` only. Missing → write `Pending verification`, never invent.
- HR3. No agent declares its own work complete — dispatch `verifier` / `plan-auditor`.
- HR4. Ask-vs-act is governed by `flywheel/AUTONOMY.md`; its level-invariant rows bind
  at every autonomy level.

## On-demand references (read when the trigger applies)
| File | Read when |
|---|---|
| `flywheel/DIAGNOSIS.md` | Session start of any long task; before reading big files |
| `flywheel/JUDGMENT.md` | Deciding: escalate? complete? pivot? quality floor? User interrupts with a new/conflicting task? |
| `flywheel/AUTONOMY.md` | Any decision that might need the human; merges; deletes |
| `flywheel/TEMPLATES.md` | Composing any delegation prompt |
| `flywheel/MAINTENANCE.md` | Before modifying any flywheel/ or adapter file |
| `flywheel/GIT.md` | Before any commit, branch, or merge |
| `flywheel/IMPROVE.md` | Improve pass due (wrapup says so) or friction accumulating |
| `flywheel/ADAPTERS.md` | Porting flywheel to another adapter |
| `flywheel/LESSONS.md` | After any escalation or surprising failure (append) |
| `docs/flywheel/ARCHITECTURE.md` | Understanding current repo structure or architecture diagram |

## State (the CEO dashboard's source of truth)
`flywheel/state/{projects,issues,decisions,activity,spawns}.json` — schemas in
`flywheel/state/SCHEMAS.md` (ships with the payload). Detailed history lives in these
ledgers; `flywheel/STATUS.md` is only the ≤ 40-line handover summary.
Rebuild the dashboard with `python3 flywheel/dashboard/build.py` (or `node
flywheel/dashboard/build.mjs`); output: `flywheel/dashboard/dashboard.html`.

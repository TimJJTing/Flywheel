# Flywheel

A portable operating system for LLM-assisted software projects. Install it into any
repo — greenfield or legacy, any tech stack — and every AI coding session gains:

- **A model hierarchy** ("the Commander does not step onto the battlefield"): expensive
  models decide, cheap models execute, with explicit delegation contracts, escalation
  budgets, and never-self-verified completion.
- **A 5-level autonomy dial**: from micromanagement to autopilot, defined as a concrete
  decision matrix — you (the CEO) always keep money, credentials, and the dial itself.
- **A CEO dashboard**: one offline HTML file showing projects, progress, open issues,
  decisions awaiting you, and exactly which agent (model, effort) did what.
- **A self-improvement flywheel**: every N sessions the harness reviews its own
  friction log and improves itself — each change one branch, one commit, individually
  revertible.
- **Clean git history as a feature**: conventional commits, branch scheme, and ledger
  entries cross-linked to hashes so the dashboard is an audit trail.

Works with **Claude Code** (full), **Codex CLI** (degraded mode), and **OpenCode**;
porting to another harness is a five-question exercise (`flywheel/ADAPTERS.md`).

## Quickstart

```bash
git clone <this repo> && cd flywheel
./install.sh /path/to/your/project --adapters claude-code
# then, inside your project's harness, paste docs/SEED-PROMPT.md
```

The seed prompt makes the LLM adopt the system, survey your codebase (if legacy),
verify model IDs against live docs (never from memory), seed the state ledgers, and
build your first dashboard: `flywheel/dashboard/dashboard.html` — double-click it.

## Reading map

| Want to… | Read |
|---|---|
| Understand the idea (CEO/COO analogy) | [docs/PHILOSOPHY.md](docs/PHILOSOPHY.md) |
| See what it does day-to-day | [docs/BEHAVIORS.md](docs/BEHAVIORS.md), [docs/USAGE.md](docs/USAGE.md) |
| Install / uninstall / upgrade | [docs/INSTALL.md](docs/INSTALL.md) |
| The bootstrap prompt | [docs/SEED-PROMPT.md](docs/SEED-PROMPT.md) |
| Make it succeed / not fail | [docs/KEYS-TO-SUCCESS.md](docs/KEYS-TO-SUCCESS.md) |
| Know what stays your job | [docs/HUMAN-ATTENTION.md](docs/HUMAN-ATTENTION.md) |
| Configure models, autonomy, dashboard, adapters | [docs/config/](docs/config/) |
| Companion skills/plugins | [docs/COMPANIONS.md](docs/COMPANIONS.md) |

The portable payload itself lives in [`flywheel/`](flywheel/) — a dozen budgeted
markdown doctrine files, a JSON config, five state ledgers, a dashboard, and a
mechanical rule-checker (`check.sh`). No runtime dependencies beyond git and
python3-or-node.

## What to .gitignore (in your project)

- `flywheel/dashboard/dashboard.html` — if you rebuild on demand; **commit it instead**
  if teammates without python3/node should open it from the repo.
- `.claude/settings.local.json` — local-only harness settings (conventional).
- Not recommended: ignoring `flywheel/state/*.json`, `STATUS.md`, `LESSONS.md` — that
  breaks session continuity and the dashboard on fresh clones; throwaway experiments
  only.
- Solo-dev-only flywheel in a team repo: ignore `flywheel/` entirely (tradeoff:
  teammates' sessions lose all orchestration rules).
- **Never ignore `flywheel/config.json`** — the autonomy level and model mapping are
  shared truth.

## Requirements

git · python3 (3.9+) or node · one supported harness. Nothing else.

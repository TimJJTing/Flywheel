> Disclaimer: Note: This project is in need of a major architectural overhaul—use with caution.

> It was originally designed during the Claude Opus 4 era, when models still required hands-on scaffolding and active guidance to stay on track. While this framework served me reliably for a long time, modern frontier models—and the native harnesses built by model providers—have largely absorbed these patterns internally. Much like capabilities that once felt like superpowers, explicit external scaffolding that used to be essential can now add unnecessary overhead or even hinder performance when paired with the latest models. 

# Flywheel

> **Heroes come and go; policies compound.**

A hero model may one-shot a brilliant fix, but only good policies carry a project
across hundreds of sessions. Flywheel is not another agent framework — it is a
**self-amending operating policy** for LLM-run projects: facts are verified or marked
`Pending verification` (never recalled), completion is never self-graded, and the
rules amend themselves session by session from a friction log. The repo itself is the
harness — portable to Claude Code, Codex CLI, OpenCode, and Antigravity, bound to none.

Install it into any repo — greenfield or legacy, any tech stack — and every AI coding
session gains:

- **A model hierarchy** ("the Commander does not step onto the battlefield"): expensive
  models decide, cheap models execute, with explicit delegation contracts, escalation
  budgets, and never-self-verified completion.
- **A 5-level autonomy dial**: from micromanagement to autopilot, defined as a concrete
  decision matrix — you (the CEO) always keep money, credentials, and the dial itself.
- **A CEO dashboard**: one offline HTML file showing projects, progress, open issues,
  decisions awaiting you, and exactly which agent (model, effort) did what.
- **A self-improvement flywheel**: every N sessions the framework reviews its own
  friction log and improves itself — each change has one branch and one implementation
  commit, followed only by optional bookkeeping.
- **Clean git history as a feature**: conventional commits, branch scheme, and ledger
  entries cross-linked to hashes so the dashboard is an audit trail.

Works with **Claude Code**, **Codex CLI** (full custom subagents), **OpenCode**, and
**Antigravity CLI**; porting another adapter is a five-question exercise
(`flywheel/ADAPTERS.md`).

Codex installs six agents under `.codex/agents`, adapter-neutral skills under
`.agents/skills`, and a project hook under `.codex/hooks.json`. Project trust is
required before local config/hooks load; actual model availability and runtime
model/effort telemetry remain account/version/UI dependent.

## Quickstart

```bash
git clone <this repo> && cd flywheel
./install.sh /path/to/your/project --adapters claude-code
# then, inside your project's adapter, paste docs/SEED-PROMPT.md
```

The installer previews its write scope and asks for confirmation before changing any
files. See [the install safety and restoration details](docs/INSTALL.md); use `--yes`
only for already-reviewed automation.

The seed prompt makes the LLM adopt the system, survey your codebase (if legacy),
verify model IDs against live docs (never from memory), seed the state ledgers, and
build your first dashboard: `flywheel/dashboard/dashboard.html` — double-click it.

## Reading map

| Want to… | Read |
|---|---|
| Understand the idea (CEO/COO analogy) | [docs/PHILOSOPHY.md](docs/PHILOSOPHY.md) |
| Strategy / competitive positioning | [docs/flywheel/research/strategy-2026-07.md](docs/flywheel/research/strategy-2026-07.md) |
| See what it does day-to-day | [docs/BEHAVIORS.md](docs/BEHAVIORS.md), [docs/USAGE.md](docs/USAGE.md) |
| Install / uninstall / upgrade | [docs/INSTALL.md](docs/INSTALL.md) |
| The bootstrap prompt | [docs/SEED-PROMPT.md](docs/SEED-PROMPT.md) |
| Make it succeed / not fail | [docs/KEYS-TO-SUCCESS.md](docs/KEYS-TO-SUCCESS.md) |
| Know what stays your job | [docs/HUMAN-ATTENTION.md](docs/HUMAN-ATTENTION.md) |
| Configure models, autonomy, dashboard, adapters | [docs/config/](docs/config/) |
| Companion skills/plugins | [docs/COMPANIONS.md](docs/COMPANIONS.md) |

Canonical release inputs live in [`distribution/`](distribution/); this repository's
[`flywheel/`](flywheel/) is a real dogfood installation with the same mutable layout
an adopter receives. Repository-only lifecycle and validation code lives under
`installer/`, `dev/`, and `tests/`. No runtime dependencies beyond git and
python3-or-node.

## What to .gitignore (in your project)

- `flywheel/dashboard/dashboard.html` — if you rebuild on demand; **commit it instead**
  if teammates without python3/node should open it from the repo. Rebuild anytime:
  `python3 flywheel/dashboard/build.py` (or `node flywheel/dashboard/build.mjs`).
- `.claude/settings.local.json` — local-only adapter settings (conventional).
- Not recommended: ignoring `flywheel/state/*.json`, `STATUS.md`, `LESSONS.md` — that
  breaks session continuity and the dashboard on fresh clones; throwaway experiments
  only.
- Solo-dev-only flywheel in a team repo: ignore `flywheel/` entirely (tradeoff:
  teammates' sessions lose all orchestration rules).
- **Never ignore `flywheel/config.json`** — the autonomy level and model mapping are
  shared truth.

## Requirements

git · python3 (3.9+) or node · one supported adapter. Nothing else.

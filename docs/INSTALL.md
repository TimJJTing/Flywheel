# Install / Uninstall

## Requirements

- git (strongly recommended; the ledger↔commit linking and improve branches need it)
- python3 (3.9+) or node — for the dashboard build; nothing else
- One supported harness: Claude Code, Codex CLI, or OpenCode (or port your own —
  `flywheel/ADAPTERS.md`)

## Install

```bash
cd /path/to/flywheel        # this repo
./install.sh /path/to/your/project --adapters claude-code
# multiple: --adapters claude-code,codex,opencode
```

What it does:
- Copies the `flywheel/` payload into your project. Doctrine files are **managed**
  (overwritten on reinstall/upgrade); `config.json`, `FACTS.md`, `STATUS.md`,
  `LESSONS.md`, `state/*.json` are **yours** (created once, never overwritten).
- Wires the adapter: adds a marker block (`<!-- flywheel:begin/end -->`) to
  CLAUDE.md / AGENTS.md — creating the file if absent, appending if it exists,
  replacing only between markers on re-runs. **Your existing content is never
  touched.** Claude Code also gets `.claude/agents/` + `.claude/skills/` files, each
  tagged `flywheel-managed` (unmanaged same-named files are skipped with a warning).
- Idempotent: running it twice changes nothing.

Then: open your harness in the project and paste `docs/SEED-PROMPT.md` (from this
repo). That single prompt makes the LLM adopt the system and fill in the
project-specific facts — including on a legacy codebase, which it surveys first.

## Greenfield vs legacy

Identical install. The difference is inside the seed prompt: on a legacy repo the LLM
first maps the structure, detects the toolchain by running version commands, lists
files > 200 KB into FACTS.md (so no session ever bulk-reads them), and notes existing
conventions. Greenfield instead interviews you (≤ 6 questions).

## Upgrade

Re-run install.sh. Managed doctrine updates; your config/facts/state stay. Diff the
managed files afterwards if you had local improvements — better: make local
improvements via the improve protocol so they live in your repo's history.

## Uninstall

```bash
./uninstall.sh /path/to/your/project        # add --yes for non-interactive
```

Strips the marker blocks (leaving your CLAUDE.md/AGENTS.md content), removes only
`flywheel-managed` agent/skill files, restores `opencode.json` from backup, and
offers to archive your state (ledgers, STATUS, LESSONS, FACTS, config) to
`flywheel-archive/` before deleting `flywheel/`.

## What to .gitignore (in YOUR project)

- `flywheel/dashboard/dashboard.html` — ignore if you rebuild on demand; **commit it
  instead** if teammates without python3/node should open it straight from the repo.
- `.claude/settings.local.json` — conventional local-only harness settings.
- **Not recommended:** ignoring `flywheel/state/*.json`, `STATUS.md`, or `LESSONS.md`.
  That breaks session continuity and the dashboard on fresh clones; only for
  throwaway experiments.
- Team keeping flywheel private to one dev: ignore `flywheel/` (and optionally the
  CLAUDE.md block). Tradeoff: teammates' sessions lose all orchestration rules.
- **Never ignore `flywheel/config.json`** — autonomy level + model config is shared
  truth.

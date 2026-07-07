# Configuring & porting adapters (deep dive)

The in-project primer is `flywheel/ADAPTERS.md` (the five porting questions). This is
the flywheel-repo-side detail.

## What ships

| Adapter | Files | Mode |
|---|---|---|
| claude-code | `CLAUDE.md.block`, 6 agents, 3 skills | Full reference: subagents, per-agent model/level pinning, skills |
| codex | `AGENTS.md.block` | Degraded: no subagents; in-session role adoption + fresh-session verification + human model switching |
| opencode | `AGENTS.md.block`, `opencode.json.merge` | Subagents via opencode.json `"agent"` entries (`mode: "subagent"`) |

Verified facts about adapter schemas (keep current, re-verify on adapter upgrades):
- OpenCode agent config: `"agent"` key in opencode.json; fields `description`
  (required), `mode` (`primary|subagent|all`), `model` (`"provider/model-id"`),
  `prompt`, `temperature`, `permission`. Source: opencode.ai/docs/agents, 2026-07-06.
- Codex CLI: treated as no-subagents; its AGENTS.md is read as project instructions.
  Model/reasoning switching is human-performed. Anything finer:
  `Pending verification` — re-check Codex docs when installing.
- Claude Code agent frontmatter fields used: `name`, `description`, `model`, `effort`.
  `effort` is the native key — flywheel's config.json stores this as `level` and
  `sync.py` projects it to `effort:` at write time (see docs/config/MODELS.md).
  Effort-per-agent behavior varies by version: `Unconfirmed, recommended to test live`
  (the seed prompt's Step 4 does exactly that).

## Selecting adapters at install

`./install.sh <target> --adapters claude-code,codex,opencode` — any subset. Codex and
OpenCode share AGENTS.md; when both are selected only one flywheel block is written
(OpenCode's, which is a superset — the degraded-mode rules matter only when subagents
are missing, and install prints a note).

## Writing a new adapter

1. Answer the five questions in `flywheel/ADAPTERS.md`; that IS the design.
2. Create `adapters/<adapter>/` with a `*.block` file (always-loaded surface ≤ 50
   lines: pointer to INDEX.md + session protocol + the four hard rules verbatim) and
   whatever agent/skill definitions the adapter supports, each containing the string
   `flywheel-managed`.
3. Add the adapter's per-tier config shape under `tiers.<tier>.adapters.<name>` in
   config.json (the map is open; see docs/config/MODELS.md).
4. Wire it into install.sh (block target file + copy rules) — follow the existing
   three cases.
5. Test: install into a scratch repo, run the seed prompt, confirm FACTS gets filled
   and the dashboard builds. Record adapter facts you verified (with source + date)
   in this file.

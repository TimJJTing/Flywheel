# Adapters — porting flywheel to any adapter

The flywheel core (this directory) is adapter-neutral markdown + JSON + two scripts.
An adapter is the thin wiring that makes a specific tool (Claude Code, Codex CLI, OpenCode) load it. Budget: the
always-loaded adapter surface ≤ 50 lines.

## The five porting questions

Answer these for the target tool; the answers ARE the adapter.

1. **Where does the always-loaded prompt live?** (Claude Code: `CLAUDE.md`; Codex CLI
   & OpenCode: `AGENTS.md`; others: their system-prompt file.) Put the marker block
   there: `<!-- flywheel:begin -->` … `<!-- flywheel:end -->` containing the pointer
   to `flywheel/INDEX.md`, the four hard rules, and the session protocol. install.sh
   only ever touches text between the markers — that is what makes install/uninstall
   safe on legacy repos.

2. **Does it have subagents?** Yes → define the six tiers as agents (model/effort
   from `flywheel/config.json`; mark each file `# flywheel-managed` so installs can
   upgrade them safely). No → degraded mode (ORCHESTRATION.md §8): templates as
   in-session role adoptions; verification via a FRESH session running Template 4;
   state honestly in reports that context isolation and parallelism are lost.

3. **Can models/efforts be pinned per agent?** Yes → mirror config.json into the
   agent definitions (a check should cross-verify they match — see check.sh for the
   Claude Code example). No → the block instructs: quote config.json and tell the
   human which model to switch to; never name a model from memory.

4. **Does it have skills/commands?** Yes → port the three skills (delegate, wrapup,
   improve) as thin wrappers around TEMPLATES.md / the wrapup procedure / IMPROVE.md.
   No → inline a 5-line summary of each into the marker block; the full procedures
   stay in the flywheel files.

5. **Does it have hooks/automation?** Optional hardening only. The reference design
   works without hooks. If sessions repeatedly skip wrapup (check LESSONS.md), add a
   session-end hook that runs `flywheel/check.sh` — that is the documented upgrade
   path, not the default. Per-spawn auto-log (d7): claude-code wires
   `flywheel/resolve-spawn.py` as a PostToolUse hook (see
   `adapters/claude-code/settings.json.merge`). codex is NOT the "no subagents" case
   it was assumed to be: codex documents `SubagentStart`/`SubagentStop` hook events
   (with `agent_id`/`agent_type`, matcher-capable) and a `SessionStart` event carrying
   the active model slug — see `docs/research/codex-hooks.md` (fetched 2026-07-08).
   Per-spawn auto-logging is wired the same way as claude-code: `SubagentStop` →
   shared `resolve-spawn.py codex` (see `adapters/codex/hooks.json.merge`,
   `docs/plans/codex-adapter-dogfood.md` Part A). The hooks.json skeleton and payload
   field names are doc-verified (Rev 2 of that research doc) but sourced via a WebFetch
   summarizer, not a live codex session — status is "VERIFIED (WebFetch summary;
   live-Pending)"; end-to-end proof (real spawn, real hook fire, real row) is still
   owed and tracked as Part C of the dogfood plan.

## Rules for adapter authors

- Adapter-specific config keys and capabilities are FACTS: verify against the
  adapter's live docs, record in FACTS.md §Adapter capabilities with source + date,
  or write `Pending verification`. This system's own adapters obey this too.
- The adapter never duplicates doctrine — it points at flywheel/ files. A rule copied
  into an adapter block will drift from its source within ten sessions.
  Exception: the four hard rules in the block are deliberate point-of-use duplicates;
  keep them verbatim-identical to INDEX.md's list (the MAINTENANCE.md §4 audit pass
  diffs them — there is no mechanical check yet).
- Test the port with the phase-style check: install into a scratch repo, run one
  session with the seed prompt, confirm FACTS.md gets filled and the dashboard builds.

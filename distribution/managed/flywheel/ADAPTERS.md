# Adapters — porting flywheel to any adapter

The flywheel core (this directory) is adapter-neutral markdown + JSON + two scripts.
An adapter is the thin wiring that makes a specific tool (Claude Code, Codex CLI, OpenCode, Antigravity CLI) load it. Budget: the
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
   upgrade them safely). No → degraded mode (see §Degraded mode below): templates as
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
   the Claude settings merge input). Codex is a full custom-subagent
   adapter: six definitions live in `.codex/agents`, shared skills in
   `.agents/skills`, and `model` / `model_reasoning_effort` are projected from
   `flywheel/config.json` by `python3 flywheel/sync.py`. Its `SubagentStop` hook is
   documented at https://developers.openai.com/codex/hooks and invokes the shipped
   `flywheel/resolve-spawn.py codex`. Project hooks/config load only after project
   trust; review non-managed commands before trusting. CLI 0.144.5 reports custom
   agents as `agent_type:"default"`; the resolver derives the validated tier from the
   child transcript's bounded first `session_meta`, then records config pins. Hook
   rows do not prove the child's runtime model/effort. Account/version model
   availability remains a live check.
   Antigravity CLI implements
   `PostToolUse` for tool `invoke_subagent` (see the Antigravity hook merge input)
   which logs the list of subagents spawned via `resolve-spawn.py antigravity`.
   *(Note: The agy CLI has a known limitation where all spawned subagents run on the same model as the parent session, ignoring tier-specific model overrides).*

## Degraded mode (adapter cannot spawn subagents)

If your adapter cannot spawn subagents (see your adapter block), the tiers become
sequential roles in one session: adopt a tier by pasting its TEMPLATES.md template
and announcing "operating as <tier>". Verification-never-self-performed then means:
a FRESH session (new context) runs Template 4. Model switching is done by the human
per config.json. What is lost: context isolation and parallelism — say so in reports.

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

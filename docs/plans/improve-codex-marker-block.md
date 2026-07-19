# Plan: project Codex marker block into `AGENTS.md`

## Conclusion

Apply one projection-only structural improvement: replace the complete managed block
in repository-root `AGENTS.md` byte-for-byte with the already-correct canonical
`adapters/codex/AGENTS.md.block`. Do not edit the canonical template, installer,
sync logic, tests, model configuration, or any other adapter. The motivating MAJOR is
`AGENTS.md:12-15`, which currently directs a Codex coordinator to Antigravity's
`.agents/agents/{agent_name}/agent.json` and TypeName mechanism.

`AGENTS.md` is an installer-wired projection, not a `flywheel/sync.py`-generated
model projection. `scripts/lifecycle/shared.sh:18-25` selects the Codex block and
passes it to `wire_block`; `flywheel/sync.py:2-12,38-40,95-134` lists and implements
only model/effort projection targets, with no `AGENTS.md` target.

## Atomic edit set

Implementation path:

- `AGENTS.md` only: replace everything from `<!-- flywheel:begin -->` through
  `<!-- flywheel:end -->` with `adapters/codex/AGENTS.md.block` exactly. In this
  repository the file currently contains only that managed block, so the decisive
  result is byte equality.

Required process artifact in the same implementation commit:

- `docs/plans/improve-codex-marker-block.md`: include this approved strategist plan
  alongside `AGENTS.md`. It is not a second implementation path; it records the
  structural authorization and executable scope. Prior improve commit `7350d44`
  packages its approved plan with the implementation, and `AGENTS.md:17-19` requires
  work to be committed rather than left uncommitted.

Canonical source (inspect, do not edit):

- `adapters/codex/AGENTS.md.block`. Its required semantics are already present at
  lines 12-16: the six tiers are Codex custom subagents in
  `.codex/agents/*.toml`; explicitly name one native agent from `architect`,
  `researcher`, `engineer`, `utility`, `verifier`, or `plan-auditor`; fill the
  matching `flywheel/TEMPLATES.md` template; use the `delegate` skill. Preserve its
  Codex model-projection note at lines 33-35.

Generated/install target and boundary:

- `AGENTS.md` is the target wired from the selected adapter block by
  `scripts/lifecycle/shared.sh:10-25`. `wire_block` preserves text outside the
  markers (`scripts/lifecycle/common.sh:24-62`). The normal install projection is
  `bash install.sh <target> --adapters codex` (`install.sh:48-57`). For this branch,
  use `apply_patch` to install the exact block because running the full installer
  against the source repository also revisits agents, skills, hooks, and architecture;
  those are outside this atomic fix. Installer behavior remains covered in scratch
  repositories by `tests/test_adapter_lifecycle.sh:135-150`.

Explicitly excluded:

- `adapters/codex/AGENTS.md.block` (already correct).
- `adapters/antigravity/**`, `adapters/claude-code/**`, and `adapters/opencode/**`.
- `.codex/agents/**`, `adapters/codex/agents/**`, `flywheel/config.json`, and
  `flywheel/sync.py`; this improvement changes coordinator instructions, not
  model/effort projections.
- `scripts/lifecycle/**`, `install.sh`, and tests; existing selection and lifecycle
  coverage already have the desired Codex source-to-target behavior.
- All other `docs/plans/**` and `docs/research/**`; the only process artifact in the
  implementation commit is `docs/plans/improve-codex-marker-block.md`.
- User text outside the managed markers, if any appears before implementation.

Rationale: correcting only the stale repository projection fixes the active Codex
coordinator while leaving every adapter's canonical behavior independently
installable and revertible.

## Implementation sequence

1. On the approved `flywheel/improve-codex-marker-block` branch, record the
   pre-existing worktree and do not stage unrelated bookkeeping changes:

   ```sh
   git status --short
   ```

2. Use `apply_patch` to replace the full root `AGENTS.md` marker block with the exact
   contents of `adapters/codex/AGENTS.md.block`. Do not hand-reword the canonical
   text and do not run the installer against `.` as the editing mechanism.

3. Prove exact projection and semantics:

   ```sh
   cmp -s AGENTS.md adapters/codex/AGENTS.md.block
   rg -n "codex custom|\.codex/agents/\*\.toml|name the agent to spawn" AGENTS.md
   ! rg -n "Antigravity custom|\.agents/agents|TypeName" AGENTS.md
   ```

   Decisive outcome: `cmp` exits 0; the positive search reports the Codex routing
   stanza; the negative search emits no matches and exits successfully via `!`.

4. Confirm model projections remain idempotent without treating sync as the marker
   generator:

   ```sh
   python3 flywheel/sync.py
   git diff --exit-code -- .claude/agents adapters/claude-code/agents \
     adapters/opencode/opencode.json.merge .codex/agents adapters/codex/agents
   ```

   Decisive outcome: sync reports unchanged projections and `git diff` exits 0.

5. Exercise both installer runners, exact Codex block installation, Codex agent
   projection/drift checks, reinstall idempotency, and the multi-adapter matrix:

   ```sh
   bash tests/test_adapter_lifecycle.sh
   ```

   Decisive outcome: exit 0 with `PASS ... runner=python3`,
   `PASS ... runner=node`, `PASS lifecycle sync/drift all six projections`, and
   `PASS adapter lifecycle matrix`. This protects Claude Code and Antigravity hook
   paths and OpenCode block precedence (`tests/test_adapter_lifecycle.sh:311-320`),
   while exact Codex block installation is asserted at lines 137-139.

6. Run the mandatory structural checks and dashboard rebuild:

   ```sh
   bash flywheel/check.sh
   python3 flywheel/dashboard/build.py
   ```

   Decisive outcome: check exits 0 with `all checks passed`; dashboard build exits
   0. Because this prose-only marker change does not alter dashboard inputs, the
   generated dashboard should have no content change except any separately approved
   bookkeeping rebuild.

7. Before the one implementation commit, enforce implementation and process-artifact
   scope explicitly:

   ```sh
   git diff -- AGENTS.md
   git diff -- docs/plans/improve-codex-marker-block.md
   git add -- AGENTS.md docs/plans/improve-codex-marker-block.md
   git diff --cached --name-only
   ```

   Decisive outcome: the unstaged review shows only the managed block changing from
   Antigravity routing to the canonical Codex block, plus this approved plan as the
   process artifact. The staged-name output is exactly these two lines (Git's normal
   path order):

   ```text
   AGENTS.md
   docs/plans/improve-codex-marker-block.md
   ```

   No other implementation path may be staged. Commit both files as
   `improve(flywheel): project codex marker block`, with a body citing
   `AGENTS.md:12-15` as the motivating audit line. This ensures the plan is not lost
   as uncommitted work and follows the packaging precedent in commit `7350d44`. Any
   later wrapup commit remains bookkeeping-only per `flywheel/IMPROVE.md:24-34`.

## Found

- The required audit search found the defect only in root `AGENTS.md:12-13`, and
  found the same Antigravity-specific strings in their legitimate canonical owner,
  `adapters/antigravity/AGENTS.md.block:12-13`.
- Its `.agents/agents` matches are adapter-private and must remain unchanged:
  `adapters/antigravity/lifecycle.sh:5,9,16-17,21,25`. No matching text occurred in
  `defaults/` or `install.sh` (command: `rg -n "Antigravity custom|\.agents/agents|\.codex/agents" AGENTS.md adapters defaults flywheel install.sh`).
- The same audit search's Codex matches establish the desired paths:
  `adapters/codex/AGENTS.md.block:13,33`,
  `adapters/shared/skills/delegate/references/codex.md:5`,
  `flywheel/ADAPTERS.md:40`, `flywheel/sync.py:9`,
  `flywheel/check.sh:217-218`, `adapters/codex/lifecycle.sh:5,8,14`, and line 2 of
  all six `adapters/codex/agents/{architect,researcher,engineer,utility,verifier,plan-auditor}.toml` files.
- `scripts/lifecycle/shared.sh:13-24` defines AGENTS-block precedence as OpenCode,
  then Codex, then Antigravity; Codex therefore remains unchanged for a combined
  Codex+Antigravity install, while OpenCode intentionally wins when selected.
- Current evidence: `cmp AGENTS.md adapters/antigravity/AGENTS.md.block` exited 0,
  while comparison with the Codex block exited 1. `bash flywheel/check.sh` passed,
  showing it does not currently detect this marker-content mismatch.
- Current regression evidence: `bash tests/test_adapter_lifecycle.sh` exited 0 with
  both runner passes, the six-projection sync/drift pass, and the full lifecycle
  matrix pass.
- Packaging precedent: `git show --stat --oneline 7350d44` shows
  `docs/plans/codex-adapter-robustness-repair.md` committed with that improve
  implementation; `flywheel/GIT.md:13,26` requires specifically staged logical
  changes and one commit per improve branch.

## Assumed

- Codex is the active adapter for this repository improvement, as stated by the
  delegated task; therefore the repository-root installed projection should select
  the canonical Codex block.
- The improve branch and auditor approval are coordinated outside this plan, as
  required by `flywheel/MAINTENANCE.md:15` and `flywheel/IMPROVE.md:22-34`.

## Could not find

- No repository mechanism records one persistent “active adapter” or automatically
  checks root `AGENTS.md` against that adapter's canonical block; adapter selection
  is supplied to `install.sh` and block precedence is procedural
  (`scripts/lifecycle/shared.sh:10-25`). This atomic fix does not invent such state.
- No reason to modify the correct Codex template, any non-Codex adapter, or sync
  projection logic was found.

# Isolated Codex Adapter Robustness Repair

## Summary

Keep `/root/<role>` labels and all identity behavior unchanged. Do not add Agent IDs,
nicknames, `SubagentStart`, ledger fields, or dashboard presentation.

Fix Codex-specific defects behind the Codex adapter boundary. Fix shared defects only
where their intended behavior is universal. Any other Claude Code or Antigravity
behavior difference is a release blocker.

## Implementation changes

### Codex-only

- Retain exactly one native `SubagentStop` hook using:
  `python3 "$(git rev-parse --show-toplevel)/flywheel/resolve-spawn.py" codex`
- Derive the Codex project root from the installed resolver's real path, ignoring
  payload `cwd`, so nested-directory sessions reach the correct config and ledger.
- Preserve current safe transcript-based role recovery when Codex reports
  `agent_type:"default"`.
- Migrate the legacy relative Codex hook without duplicating handlers.
- Keep Codex ledger rows terminal and ID-free. Model/reasoning values remain
  configuration pins, not runtime telemetry.

### Universal fixes

- Remove Flywheel hooks at individual-handler granularity during migration and
  uninstall: preserve sibling user handlers and matcher groups; correctly handle
  legacy-only, mixed, backed-up, and Flywheel-created files; maintain Python and Node
  fallback parity.
- Correct shared documentation: include `antigravity` in the adapter enum; describe
  per-adapter auto-logging accurately; replace universal `PostToolUse` wording with
  adapter-neutral wording; clarify config pins versus actual runtime telemetry.
- Permit one `improve(flywheel)` implementation commit followed by one bookkeeping-only
  wrapup commit.
- Make wrapup reject any staged path outside STATUS, LESSONS, state ledgers, generated
  dashboard, and generated architecture.

### Adapter isolation

- Do not change Claude or Agy agent definitions/model selection, hook sources/event
  selection, payload parsing/spawn construction, truncation, notes, ordering,
  fallback behavior, stdout, or adapter-specific skills, except the intentionally
  universal improve-doctrine update.
- Add a path-scope check rejecting changes to Claude/Agy agent or hook assets.
- Any Claude/Agy behavioral delta outside the named universal fixes requires separate
  user approval.

## Compatibility verification

Create characterization tests before implementation. Freeze Claude Code payload
parsing, stdout, complete rows, model overrides, mismatch notes, task truncation, and
unknown agents. Freeze Antigravity payload parsing, ordering, truncation, parent-model
resolution, fallback, unknown-agent handling, notes, stdout, and complete rows.

Cover Claude-only, Agy-only, Claude+Agy, Codex+Claude, Codex+Agy, and all adapters;
install, reinstall, and uninstall through Python and Node. Untouched normal cases must
remain byte/JSON-equivalent. Mixed user hooks may change only by preserving handlers
previously at risk.

Also cover nested-cwd Codex logging; known/default roles; malformed transcripts,
config, and ledger; concurrency and safe failure; absence of Agent ID/session ID;
handler migration and backup restoration; wrapup allowlist in a temporary Git repo;
dashboard parity, shell syntax, check.sh, diff-check, secrets scan, and clean status.

The verifier reports independently on Codex repair, universal fixes, Claude
non-regression, Antigravity non-regression, and combined lifecycle non-regression.

## Dogfooding and delivery

Reconcile audit ledger rows; keep main clean; work on
`flywheel/improve-codex-adapter-robustness`; characterize before implementation; run
deterministic dual-runner suites; dogfood utility/verifier routing in a disposable
installed repository and then this repository after human `/hooks` review/trust; save
redacted evidence; obtain fresh verifier and plan-auditor verdicts; finish with an
allowlisted bookkeeping-only wrapup commit and no later spawns. At autonomy level 3,
leave the verified branch unmerged pending the human merge decision.

## Assumptions

- `/root/<role>` is Codex's canonical task label.
- No identity or presentation enhancement is required.
- Claude/Agy need deterministic non-regression, not new live dogfood.
- Existing Claude/Agy capability facts remain unchanged.
- Any unapproved Claude/Agy functional difference fails the repair.

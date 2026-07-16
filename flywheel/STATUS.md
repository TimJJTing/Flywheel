# STATUS — session handover. Budget: ≤ 40 lines (check.sh enforces). Trim, don't grow.
Decisions history lives in `flywheel/state/decisions.json` (rendered by the dashboard).

Updated: 2026-07-16 (session 16, paused mid Codex-adapter repair)

## Current state
- Work is checkpointed on `flywheel/improve-codex-adapter`; do not merge yet.
- `docs/plans/codex-adapter-full-verification.md` passed an independent plan audit
  after one REVISE cycle; implementation was interrupted at the user's request.
- Confirmed defects: installed ADAPTERS.md has dangling repo-only references; Codex
  skills use the obsolete `.codex/skills` path; reinstall/uninstall can restore a
  dangling hook; sync cannot regenerate Codex TOML; docs and dogfood are stale.
- Partial, UNVERIFIED edits touch install/uninstall ownership, Codex sync, JSON-only
  spawn output, adapter-neutral skills, ADAPTERS.md, and two new test files.
- No full suite, live CLI verification, verifier review, or limitations report ran.
- User requires every newly spawned agent to use its corresponding GPT-5.6 model;
  current `config.json` still contains GPT-5.5/GPT-5.4 entries.

## In flight
- Paused: Codex adapter user payload + dogfood repair (issue i16, plan above).

## Next actions (in order)
1. Re-read the approved plan and review every checkpoint diff/test hunk.
2. Verify official GPT-5.6 tier mappings; update FACTS/config, audit, then sync.
3. Finish lifecycle tests, docs/limitations, `.codex` dogfood, and protected shared
   `.agents/skills` projection (may require scoped filesystem approval).
4. Run syntax/unit/lifecycle/check/install/live-Codex verification; dispatch a fresh
   GPT-5.6 verifier and resolve every finding.
5. Ask the human before merging this self-improvement branch (decision d12).

## Blockers / decisions pending the human
- d12: merge/reject only after independent verification; autonomy level 3 requires
  human approval. Protected `.agents` writes may require scoped approval.

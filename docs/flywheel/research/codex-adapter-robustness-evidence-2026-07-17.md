# Codex adapter robustness evidence — 2026-07-17

## Environment and scope

- CLI: `codex-cli 0.144.5` (`codex --version`).
- Disposable Git repository: `/private/tmp/flywheel-codex-robustness.<redacted>`.
- Live hook trust bypass was used only in that vetted disposable repository.
- The repository was installed twice from this branch with `--adapters codex`, then
  Codex was launched from `<scratch>/nested/deeper`.

## Deterministic gates

- `python3 -m unittest tests.test_resolve_spawn tests.test_codex_adapter_repair_spec`
  → `Ran 30 tests`, `OK`.
- `bash tests/test_adapter_lifecycle.sh` → Python and Node lifecycle passes,
  sync/drift pass, adapter lifecycle matrix pass.
- Before deletion, the one-time adapter-isolation checker was run against
  `$(git merge-base main HEAD)` → `PASS adapter isolation path scope`. It was an
  audit aid, not a permanent command gate, and was deleted after this result.
- `bash flywheel/check.sh` → `✓ all checks passed`.
- Shell syntax, `git diff --check`, dashboard Python/Node parity, and the targeted
  secrets scan passed.

## Disposable live run

Command shape (random path redacted):

```text
codex exec --dangerously-bypass-hook-trust -s workspace-write \
  -C <scratch>/nested/deeper \
  "spawn exactly utility then verifier; return DOGFOOD_OK only after both finish"
```

The successful non-ephemeral run returned `DOGFOOD_OK`. The installed ledger contained
exactly two terminal eight-field rows, in order:

1. `utility` / `codex` / `gpt-5.6-luna` / `low`
2. `verifier` / `codex` / `gpt-5.6-sol` / `high`

Both notes say the role was derived from transcript `session_meta`; both model/level
values are configuration pins, not runtime-child telemetry. Neither row contains an
agent ID or session ID field. The installed hook file contained exactly one native
Codex command plus the seeded user handler.

An initial `--ephemeral` probe was not accepted as evidence: Codex reported a missing
custom thread and produced two safe `default` / `Pending verification` rows because
the transcript role could not be recovered. Those rows were cleared in the disposable
fixture before the successful non-ephemeral rerun. This confirms safe fallback but
does not establish ephemeral-mode custom-agent compatibility.

After the live run, uninstall restored the seeded `echo keep-user-handler` and
`echo keep-user-session` commands and removed every Flywheel handler/sidecar from the
active adapter paths.

## Remaining human gate

Persisted trust in this real repository still requires a fresh interactive session
and human `/hooks` review. The disposable bypass does not satisfy that gate. Runtime
child model/effort telemetry remains unavailable, consistent with `flywheel/FACTS.md`.

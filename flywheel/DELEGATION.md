# Delegation mechanics — escalation paths, spawn provenance

On-demand (see INDEX.md). ORCHESTRATION.md §2-§4 and §6 hold the binding rules; this
file holds the choreography needed only while a delegation is in flight.

## Escalation paths (ORCHESTRATION.md §4)

Escalate UP after retries are exhausted:
- `utility` fails an easy task → send to `engineer` with the failure attached.
- `engineer` fails a coding task → back to `strategist` to refine the plan, then
  re-issue to `engineer`.
- A `strategist` plan fails in execution **twice** → escalate to `architect` with the
  complete failure trace: both plans, both failure reports, verifier output. Also route
  to `architect`: irreversible architectural forks and flywheel rule conflicts that
  `auditor` cannot resolve. Nothing else — it is the scarcest tier.

De-escalate DOWN once a pattern is solved: first instance fixed by a higher tier →
document the pattern (in the plan or LESSONS.md) → batch-apply remaining instances
via `utility`/`engineer`.

## Spawn provenance (ORCHESTRATION.md §6)

Model provenance is adapter-specific: Claude Code children use the Agent response;
Codex children use config pins (its stop payload lacks child runtime telemetry);
Antigravity children inherit the parent model or configured fallback. Codex
coordinators resolve current-turn rollout telemetry at wrapup. All automatic rows
go through `flywheel/resolve-spawn.py`; otherwise log manually with best verified
provenance and `Pending verification` when unavailable. At wrapup, correct child
outcomes/notes and ensure the coordinator has exactly one row.

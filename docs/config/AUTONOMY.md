# Configuring autonomy

The matrix itself lives in `flywheel/AUTONOMY.md` (in your project after install);
the current level in `flywheel/config.json` `"autonomy"`. This doc is the CEO-side
deep dive.

## Changing the level

Tell any session: "set autonomy to N". That instruction is the ONLY path — the matrix
makes the level itself a never-delegated decision, so no improve pass or "helpful"
session can loosen its own leash. The change lands as a config edit + a decisions.json
entry, and the dashboard dial updates on next build.

## Choosing a level

- Start at **3** (the default) unless: the repo is high-stakes/production → 2; you're
  evaluating whether to trust the system at all → 1; you've watched several weeks of
  clean verifier verdicts and merged improvements → 4; the project is a sandbox → 5.
- Move ONE level at a time. Each level converts a specific set of matrix cells; read
  the column diff in flywheel/AUTONOMY.md before moving.

## Customizing the matrix

The matrix is doctrine (MAINTENANCE.md structural class): edit via the improve
protocol (strategist plan + auditor approval, on a `flywheel/improve-*` branch) so
every change is reviewed and revertible. Typical customizations:
- Add project-specific rows ("run DB migrations", "modify CI config").
- Tighten a cell (e.g., dependency adds A even at L5 for compliance-bound repos).
- Never loosen the two level-invariant rows; they are the design's floor.

## Policy vs enforcement

The matrix is policy the LLM obeys, not a sandbox. For rows you need GUARANTEED
(no pushes, no credential access), also configure your adapter's permission system
to deny those operations — then the matrix decides "should", the adapter enforces
"can". docs/HUMAN-ATTENTION.md says this too; it bears repeating.

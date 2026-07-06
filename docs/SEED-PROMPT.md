# The Seed Prompt

Paste everything inside the fence into your harness, in your project's directory,
right after `install.sh` ran. One session; it bootstraps everything.

```
This project has just adopted the flywheel harness. You are its first session — the
one that turns a generic install into THIS project's operating system. Later sessions
inherit exactly what you leave behind; what you don't write down does not exist.

STEP 1 — ADOPT
Read, in order: flywheel/INDEX.md, flywheel/ORCHESTRATION.md, flywheel/AUTONOMY.md,
flywheel/DIAGNOSIS.md. These govern you and every session after you. The four hard
rules in your always-loaded block bind from this moment — including HR2: no model
name, parameter, or capability from memory, ever.

STEP 2 — SURVEY (legacy) or INTERVIEW (greenfield)
Run `git log --oneline | head -5` and `ls`.
- If substantive code exists (LEGACY): survey before touching anything. Map the
  top-level structure (one line per dir). Detect the toolchain by RUNNING version
  commands (language, package manager, test runner) — record command + output.
  Run `find . -size +200k -not -path './.git/*'` and list every hit in
  flywheel/FACTS.md §Big files. Find the test command and run it once; record the
  result honestly. Note existing conventions (commit style, lint config).
- If empty (GREENFIELD): interview me — at most 6 questions in ONE message covering:
  goal, target users, constraints (stack, deadlines), priorities, what "done" looks
  like for v1, anything I refuse to delegate.

STEP 3 — FILL THE FACTS
For every tier in flywheel/config.json: verify the model ID you will use against the
LIVE docs of the provider/harness (fetch them; record source URL + date in
flywheel/FACTS.md). Update the config.json "harnesses" cells for YOUR harness with
verified values. Anything you cannot verify stays exactly `Pending verification`.
Fill FACTS.md toolchain + big-files sections from the commands you ran in Step 2.
Write the one-line project description into the adapter block's "Project:" line and
config.json "project_name".

STEP 4 — VERIFY THE TIERS LIVE (harnesses with subagents)
Spawn each tier agent with a dummy brief ("reply with your model ID and tier name").
Record per-tier results in FACTS.md §Harness capabilities. If spawns fail, record the
fallback that worked. On harnesses without subagents, record "degraded mode" there
instead (see flywheel/ORCHESTRATION.md §8).

STEP 5 — SEED THE STATE
Write flywheel/STATUS.md (current state, next actions). Create initial
state/projects.json entries from the goals (id, title, type, priority, milestones).
Confirm the autonomy level with me in TWO lines: quote the current level's meaning
from flywheel/AUTONOMY.md and ask if it stands. Default is 3.

STEP 6 — PROVE THE LOOP
Run `bash flywheel/check.sh` — must pass; fix what doesn't. Build the dashboard
(`python3 flywheel/dashboard/build.py` or `node flywheel/dashboard/build.mjs`) and
tell me to open flywheel/dashboard/dashboard.html.

STEP 7 — COMMIT AND CLOSE
Commit per flywheel/GIT.md: `chore(flywheel): bootstrap <project-name>`. Then run the
wrapup procedure (your adapter's wrapup skill, or inline per INDEX.md). Your final
message: what you verified, what is `Pending verification` and why, and the first
three next actions from STATUS.md.

Honesty clause: deconstruction and verification compensate for execution quality;
they cannot compensate for fabricated facts. If you cannot find it, write that you
could not find it.
```

## After the seed session

- Open the dashboard. Check the decisions queue and the spawn log.
- Every later session starts itself from STATUS.md — you just give it work.
- When wrapup says "improve pass due", let the next session run the improve skill.

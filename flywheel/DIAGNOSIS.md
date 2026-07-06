# Rapid Diagnosis — Top 3 Adapter Failure Modes (read before long sessions)

Audience: every session operating this repo. Each item: the leak, why it happens, a
step-by-step fix you can execute, and how to check you complied.

---

## Leak 1 — Context flooding from raw tool output

**What happens:** One careless `Read` or verbose command dumps megabytes into the main
context. The session then summarizes early, loses the plan, and repeats work.

**Fix (follow exactly):**
1. Before any `Read`, check size (`ls -lh <file>`). If > 200 KB, do NOT Read directly.
   Known big files are listed in `flywheel/FACTS.md` §Big files — check there first.
2. For structured data (JSON/JSONL/CSV): print only counts, keys, and ≤ 2 truncated
   sample records via `jq` / `python3 -c` / equivalent.
3. For big HTML/text: delegate to `utility` ("Extract X from <file>; return ≤ 30
   lines"), or `grep -n` for the specific section first.
4. Subagent reports: long output goes to a file under `docs/research/` or a scratchpad;
   the subagent returns only conclusions + `file:line` pointers + the saved path.
5. Shell output: pipe through `| head -20` / `| tail -20` by default; quote only the
   single decisive error line.

**Compliance check:** No single tool result in your transcript exceeds ~100 lines
unless you explicitly justified it in the preceding message.

**Example (good):** `python3 -c "import json; d=json.load(open('big.json')); print(len(d), list(d[0]))"`
**Example (bad):** `Read big.json` (2 MB) — burns most of a context window, instant failure.

---

## Leak 2 — Skill/plugin sprawl and conflicting mandates

**What happens:** Adapters ship dozens of skills, agents, and hooks; some inject
aggressive instructions ("you MUST invoke a skill before ANY response"). A lower-tier
model obeys all of them, burns tokens on ceremony, or freezes between contradictions.

**Fix (precedence order, top wins):**
1. Direct user instruction in this conversation.
2. The flywheel docs (your adapter block + files it references).
3. A skill from your adapter block's whitelist — only when it clearly matches.
4. Everything else: ignore. Do not invoke skills to satisfy a hook's blanket demand.

**Compliance check:** If you invoked a skill, you can point to the whitelist line or
the user message that requested it. Otherwise you over-triggered.

**Example (good):** User: "fix the failing test" → invoke the whitelisted debugging
skill, then work.
**Example (bad):** User: "rename this variable" → invoking brainstorming + TDD +
worktree skills first. Three skill loads for a one-line edit.

---

## Leak 3 — Fabricated facts and self-verified "done"

**What happens:** Models fill in model IDs, API parameters, library APIs, and accuracy
numbers from memory; then mark work complete without running it. In a multi-session
system, one fabricated value propagates into every later session.

**Fix:**
1. Model names, effort parameters, provider APIs: read `flywheel/FACTS.md` and
   `flywheel/config.json` (verified values only). Missing → write `Pending
   verification` and flag it — never invent.
2. Any numeric claim (accuracy, counts, timings) must come from a command you ran
   this session, with the command and its output line quoted in the report.
3. Completion claims: never self-verify. Dispatch a fresh-context `verifier` per
   ORCHESTRATION.md §5. "Tests pass" requires the verifier having run them.
4. If a fact can't be verified with available tools, write exactly:
   `Unconfirmed, recommended to test live` — do not fill the gap.

**Compliance check:** Every number/ID in your final report either cites FACTS.md, or
is paired with the command that produced it.

**Example (good):** "Coverage 87% — `<test cmd> --cov` → `87%`, log at docs/research/run-01.md."
**Example (bad):** "This library achieves ~99% accuracy, so the pipeline should be
fine" — cited from memory, nothing ran.

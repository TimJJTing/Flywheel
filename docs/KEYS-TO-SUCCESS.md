# Keys to success — what makes flywheel work, what kills it

## Do these

1. **Run the seed prompt properly.** A bootstrap that skips FACTS verification plants
   fabricated model IDs that every later session inherits. Ten minutes there saves
   hours later.
2. **Read the dashboard, not the transcript.** The system is built so state lives in
   ledgers. If you find yourself scrolling chat history to know where things stand,
   file that as a friction issue — it means wrapups are being skipped.
3. **Answer the decisions queue.** Pending decisions don't block other work, but an
   ignored queue silently converts your L3 into "LLM waits forever." Approve or
   reject; both are fine.
4. **Let the improve pass run.** The compounding is the point. Review its branches —
   they are deliberately small enough to read in a minute each.
5. **Keep wrapup sacred.** If a session ends without it, the next session starts
   blind. "Wrap up" is always a valid instruction, even mid-task.

## Avoid these

1. **Editing doctrine files by hand casually.** MAINTENANCE.md §1 exists because a
   rule edited to "unblock" one session degrades every future one. Route changes
   through the improve protocol — you get revertibility for free.
2. **Cranking autonomy to 5 on week one.** Trust the dashboard first. L3 → L4 after
   you've reviewed a few merges and the verifier verdicts held up.
3. **Letting LESSONS.md and STATUS.md rot.** check.sh warns; heed it. A 150-line
   STATUS.md is how flywheel's ancestor project quietly broke its own rules.
4. **Skill/plugin sprawl.** Keep the adapter block's whitelist short (DIAGNOSIS.md
   Leak 2). Every always-on instruction competes with your actual rules.
5. **Trusting "done" without a verifier line.** If a session claims complete and no
   VERIFIED verdict exists, that is JUDGMENT.md R2 ✗ — the most common failure in
   the wild. Ask "was this verified, by whom?"

## The one-sentence version

Verify facts, externalize state, let nobody grade their own homework, and improve
the process in small revertible steps — the rest is commentary.

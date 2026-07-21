# Codex resolver safe-transcript follow-up

## Decision

Authorize `agent_transcript_path` only as a sibling of the payload's absolute
`transcript_path`: both paths must be absolute `.jsonl` entries, their parent
directories must resolve by descriptor-relative no-symlink walks to the same directory
inode, and both distinct entries must validate as stable regular files. Never read the parent
transcript. Read only one bounded metadata row from the validated child descriptor.

Rationale: live Codex supplies both paths while the captured session places them
outside and cross-tree from project `cwd`. A same-directory sibling rule retains that
real shape, rejects unrelated absolute files, and does not invent a Codex storage root.

## Concrete open and validation sequence

Keep the implementation local to `codex_agent_from_transcript`; pass the whole payload
as today and do not change ledger behavior.

1. Before filesystem access require `transcript_path` and `agent_transcript_path` to be
   non-empty, distinct absolute strings ending in `.jsonl`. Inspect the original path
   components and reject `.` or `..`; normalize only redundant separators afterward.
   Do not use `realpath()` as authorization.
   `cwd` is not a path-scope anchor.
2. Fail closed unless `O_NOFOLLOW`, `O_NONBLOCK`, and `O_DIRECTORY` exist; add
   `O_CLOEXEC` when present. Explicitly require `os.open in os.supports_dir_fd`,
   `os.stat in os.supports_dir_fd`, and `os.stat in
   os.supports_follow_symlinks`. Catch `NotImplementedError` as well as `OSError`,
   `ValueError`, `TypeError`, and `json.JSONDecodeError`. If capability checks or calls
   fail, return `None`; never fall back to a pathname open.
3. Open `/` once with `O_RDONLY | O_DIRECTORY | O_CLOEXEC`. For each candidate path,
   walk every parent component from that root fd using
   `os.open(component, O_RDONLY | O_DIRECTORY | O_NOFOLLOW | O_CLOEXEC,
   dir_fd=current_fd)`, closing superseded fds. This rejects symlink parents and pins
   the reached directories against rename races.
4. `fstat` both resulting parent-directory fds and require identical
   `(st_dev, st_ino)` plus directory type. This is the authorization relationship; a
   lexical dirname comparison alone is insufficient.
5. Validate the parent transcript basename without reading it. Call
   `pre = os.stat(name, dir_fd=parent_fd, follow_symlinks=False)` and reject unless
   regular. Then open descriptor-relatively with
   `O_RDONLY | O_NONBLOCK | O_NOFOLLOW | O_CLOEXEC`; immediately `fstat`, require
   regular and require `(st_dev, st_ino)` to equal the pre-open identity. Close it
   without `read`, `readline`, decoding, or JSON parsing.
6. Apply the identical pre-stat/open/fstat sequence to the child basename. Existing
   directories, FIFOs, sockets, devices, and symlinks are rejected before open.
   `O_NONBLOCK` prevents a swapped-in FIFO from waiting; `O_NOFOLLOW` rejects a
   swapped symlink; post-open type and inode checks reject swapped objects. Do not open
   any non-regular object observed by the pre-check. Require the validated child and
   parent `(st_dev, st_ino)` identities to differ, so the anchor itself cannot be parsed
   by supplying it in both fields.
7. Read from the validated child fd only. Wrap it as binary and call
   `stream.readline(TRANSCRIPT_META_MAX_BYTES + 1)` exactly once. Reject empty input,
   no newline within the limit, or a row longer than 128 KiB. Parse only that row, so
   consumption is at most 131,073 bytes and one JSONL record.
8. Preserve current metadata validation: a dict of type `session_meta`, dict payload,
   nested `source.subagent.thread_spawn.agent_path` with top-level
   `payload.agent_path` fallback, and exact `/root/<known TIER_MAP key>`. Manage all fds
   with `ExitStack` or complete `finally` cleanup.

The platform fallback is deliberately no derivation. This resolver is POSIX-only
already (`fcntl`), but any Python/OS without the required flags, `dir_fd`, or no-follow
stat support records `default`/`unknown` safely and continues the normal hook result.

### Blocking and TOCTOU boundary

An existing FIFO/device/socket is never opened because no-follow `stat` rejects it.
A FIFO exchanged after stat is opened nonblocking and rejected by `fstat`; a symlink or
regular-file exchange is rejected by no-follow/inode comparison. POSIX cannot promise
that every malicious device driver honors `O_NONBLOCK` if an attacker races a regular
file into a device between stat and open. This is the practical hook-safe boundary for
a minimal patch; strict defense against a privileged malicious device-race would
require an isolated helper with parent timeout and is outside this patch.

## Authorization scope and alternatives

The sibling anchor limits accidental or opportunistic arbitrary reads: a payload that
names the genuine parent transcript can derive only from a regular `.jsonl` in that
same pinned directory, and the resolver never exposes or parses the parent. It cannot
be a cryptographic trust boundary because hook stdin is forgeable by a direct caller:
an attacker able to invoke the script can forge both paths into the same chosen
directory. The hook therefore assumes Codex is the payload producer; this patch limits
scope and blocks unsafe file kinds but does not authenticate stdin. Do not claim more.

Runner-up 1, `cwd` containment, is rejected: the live captured parent and child
transcripts are cross-tree from project `cwd`, so it disables the required fallback;
`cwd` is equally forgeable in stdin. Runner-up 2, any absolute child path after safe
type/bounds checks, is rejected because it provides no relationship at all and permits
reading the first row of any regular `.jsonl`. Do not invent a
`~/.codex/sessions` allowlist; no cited evidence establishes one.

## Exact regression tests

Modify `tests/test_resolve_spawn.py` in the implementation run. Extend
`run_hook(..., timeout=2)` to pass the timeout to `subprocess.run`; a
`TimeoutExpired` is a failure. Every rejection assertion includes exit `0`, empty
stderr, exactly one JSON stdout object whose only key is `systemMessage`, one fallback
ledger row `(default, Pending verification, "-")`, and no path/content leakage.

1. `test_captured_cross_tree_payload_derives_utility`: replay the captured payload's
   exact relation: project `cwd` is not an ancestor of either absolute transcript path;
   parent `transcript_path` and child `agent_transcript_path` are sibling `.jsonl`
   files in the captured session directory; child first row has the captured nested
   and top-level `/root/utility` fields; `agent_type` is `default` and payload model is
   the parent model. Use the exact captured path components/JSON fields from the live
   artifact when adding the fixture, not invented Codex directory guarantees. Expected:
   utility config model/level, parent model ignored, derivation note, one JSON stdout,
   exit zero. The repository currently records the relation/shape but not raw path
   strings; preserve raw values if the coordinator supplies them before implementation.
2. `test_fifo_in_authorized_transcript_directory_never_blocks`: create a regular
   sibling parent transcript and `os.mkfifo()` the child in the same directory, with
   cross-tree `cwd`. No writer. Expected: return before two seconds and fallback.
3. `test_outside_parent_directory_regular_jsonl_falls_back`: make parent regular in
   directory A and a valid child session_meta regular file in directory B. Expected:
   no derivation even though both are absolute `.jsonl` files.
4. `test_parent_anchor_is_regular_but_never_parsed`: parent is regular `.jsonl` with
   malformed/sensitive bytes; valid sibling child derives. Expected: success without
   parent content in output/ledger, proving parent is type/identity anchor only.
5. `test_non_regular_parent_or_child_falls_back`: cover directory; no-writer FIFO; an
   open Unix socket when `socket.AF_UNIX` exists; and a character device created with
   `os.mknod(..., stat.S_IFCHR, os.stat('/dev/null').st_rdev)` when portable/permitted
   (skip only that device subcase). Test non-regular parent and child placements.
6. `test_symlink_entry_and_parent_directory_fall_back`: retain final-entry symlink
   coverage and add a path through `linkdir -> realdir` for either parent or child.
   Expected: fail closed even if both lexical dirnames appear equal.
7. `test_malformed_and_bounded_child_metadata_falls_back`: malformed JSON, wrong
   type/shape, empty, valid JSON without newline, first row over 128 KiB, and malformed
   first plus valid second row. Expected: fallback; never scan row two.
8. `test_known_agent_precedence_skips_all_transcript_io`: known `engineer` with both
   transcript fields pointing at no-writer FIFOs. Expected: completes under timeout and
   uses the engineer config cell.
9. `test_missing_anchor_or_capability_falls_back_one_json_exit_zero`: omit/invalid
   either transcript field and mock each capability set/check or operation to fail with
   `NotImplementedError`. Expected: one JSON object, exit zero, no stderr, fallback.
   This explicitly verifies the platform behavior rather than only documenting it.

Run exactly:

```sh
python3 -m unittest -v tests/test_resolve_spawn.py
python3 -m unittest -v tests.test_resolve_spawn.ResolveSpawnTests.test_fifo_in_authorized_transcript_directory_never_blocks
bash flywheel/check.sh
git diff --check
```

No command may hang. Both unit commands exit zero and report `OK`; check ends with
`all checks passed`; `git diff --check` is silent.

## Core contract invariants

- Known string `agent_type` has precedence and performs no transcript I/O.
- A tier is derived only from validated child `session_meta` and exact known
  `agent_path`; validation failure retains `default`/`unknown`.
- Codex model and level/effort always come from `flywheel/config.json`; parent and
  transcript telemetry are ignored (`flywheel/resolve-spawn.py:143-149`).
- Every success/error path emits exactly one JSON stdout object, no stderr/path/content
  leak, and exits `0` (`flywheel/resolve-spawn.py:253-266`).

## Evidence ledger

### Found

- Current `os.open` occurs before `fstat`, so a no-writer FIFO blocks:
  `flywheel/resolve-spawn.py:54-65` and the verifier's supplied FIFO reproducer.
- Current code accepts any absolute `.jsonl` and does not relate it to parent
  `transcript_path`: `flywheel/resolve-spawn.py:54-60`.
- Codex hook research records common absolute `transcript_path`, `cwd`, and the
  SubagentStop `agent_transcript_path`: `docs/flywheel/research/codex-hooks.md:83-93`.
- Live CLI 0.144.5 recorded `agent_type:"default"`, parent model, and nested plus
  top-level child agent paths: `flywheel/FACTS.md:46-54` and
  `docs/flywheel/research/codex-adapter-verification-2026-07-16.md:143-156`.
- Auditor feedback establishes that the captured parent/child transcript directory is
  cross-tree from `cwd`; therefore `cwd` containment rejects the real payload.

### Assumed

- Codex, not an untrusted direct caller, produces hook stdin. Same-directory sibling
  identity is a scope reduction, not payload authentication.
- Parent and child transcript paths in the live event are siblings; the revised test
  must preserve the raw captured relationship when that artifact is available.
- Required POSIX/Python descriptor operations have normal semantics; capability absence
  or `NotImplementedError` fails closed.

### Could not find

- Raw captured absolute path strings or a complete SubagentStop fixture in the repo;
  only the recorded live relation and metadata shape are present.
- A documented stable Codex transcript root or a statement authenticating hook stdin.
- A portable guarantee against a privileged malicious device-driver replacement race;
  the plan states the residual rather than overstating `O_NONBLOCK`.

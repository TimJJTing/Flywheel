#!/usr/bin/env python3
"""Hook: notify the user of the resolved model/level for a spawned subagent and
auto-append the row to flywheel/state/spawns.json (implements decision d7).
Reads the hook JSON payload from stdin. Adapter selector is sys.argv[1] (default
"claude-code" — the existing claude-code settings.json.merge command passes no arg,
so that behavior is unchanged).

claude-code: PostToolUse(Agent) hook. tool_input.subagent_type is the agent name;
tool_response.resolvedModel is the ACTUAL resolved subagent model (trustworthy).

codex: SubagentStop hook. CLI 0.144.5 reports a custom agent as agent_type="default";
the bounded first session_meta row at agent_transcript_path supplies
payload.source.subagent.thread_spawn.agent_path. payload["model"] is the PARENT
session's model — never used as the row's model. model/level are resolved ENTIRELY
from flywheel/config.json by the validated derived agent -> tier.

Branches per-adapter (payload shapes differ, must not run unmodified against the
other): build_row_claude_code / build_row_codex. Shared across both: TIER_MAP, the
cwd-resolution fallback, the ts/outcome row fields, the file-locking append to
spawns.json, and exit-0-on-any-error (a hook failure must never block a spawn).

ponytail: one script, adapter branch via argv — no flag-parsing library needed.
"""
import fcntl
import hashlib
import json
import os
import re
import stat
import sys
from contextlib import ExitStack
from datetime import datetime
from pathlib import Path

# researcher/plan-auditor are agent-file names that map to a different tier name;
# all others (architect/engineer/utility/verifier) are already tier names.
TIER_MAP = {
    "researcher": "strategist",
    "plan-auditor": "auditor",
    "architect": "architect",
    "engineer": "engineer",
    "utility": "utility",
    "verifier": "verifier",
}

TRANSCRIPT_META_MAX_BYTES = 128 * 1024
TRANSCRIPT_FILE_MAX_BYTES = 32 * 1024 * 1024
TELEMETRY_VALUE_MAX_CHARS = 256
CODEX_THREAD_ID_RE = re.compile(
    r"^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$"
)
COORDINATOR_NOTES_PREFIX = "auto-resolved from Codex turn_context; session-key:"
COORDINATOR_KEY_MARKER = "session-key:"


def _repo_contains(repo_root, candidate):
    """Return whether candidate's canonical path is repo_root or below it."""
    if not isinstance(candidate, str) or not candidate or not os.path.isabs(candidate):
        return False
    try:
        repo = os.path.realpath(repo_root)
        path = os.path.realpath(candidate)
        return os.path.commonpath((repo, path)) == repo
    except (OSError, ValueError, TypeError):
        return False


def _coordinator_rollout_matches(sessions_root, thread_id):
    """Find exact rollout basenames without following symlink directories."""
    suffix = f"-{thread_id}.jsonl"
    matches = []
    try:
        root = os.fspath(sessions_root)
        root_stat = os.lstat(root)
        if not stat.S_ISDIR(root_stat.st_mode) or stat.S_ISLNK(root_stat.st_mode):
            return []
        pending = [root]
        while pending:
            directory = pending.pop()
            with os.scandir(directory) as entries:
                for entry in entries:
                    if entry.name in (".", ".."):
                        continue
                    if entry.name.endswith(suffix):
                        matches.append(entry.path)
                        if len(matches) > 1:
                            return matches
                    try:
                        if entry.is_dir(follow_symlinks=False):
                            pending.append(entry.path)
                    except OSError:
                        return []
        return matches
    except (OSError, TypeError, ValueError):
        return []


def _scan_fixed_transcript_snapshot(path, repo_root, thread_id):
    """Validate and scan one fixed transcript without retaining transcript records.

    The return value distinguishes an invalid transcript (``None``) from a valid
    coordinator identity with no usable current-repo turn context (a pair whose
    second item is ``None``).
    """
    if not hasattr(os, "O_NOFOLLOW"):
        return None
    flags = os.O_RDONLY | os.O_NOFOLLOW | getattr(os, "O_CLOEXEC", 0)
    try:
        pre = os.lstat(path)
        if not stat.S_ISREG(pre.st_mode) or stat.S_ISLNK(pre.st_mode):
            return None
        fd = os.open(path, flags)
        try:
            opened = os.fstat(fd)
            identity = (opened.st_dev, opened.st_ino)
            if (not stat.S_ISREG(opened.st_mode)
                    or identity != (pre.st_dev, pre.st_ino)
                    or opened.st_size <= 0
                    or opened.st_size > TRANSCRIPT_FILE_MAX_BYTES):
                return None
            snapshot_size = opened.st_size
            remaining = snapshot_size
            meta_valid = False
            newest_context = None
            record_number = 0
            with os.fdopen(fd, "rb", closefd=False) as stream:
                while remaining:
                    line = stream.readline(min(TRANSCRIPT_META_MAX_BYTES + 1, remaining + 1))
                    if (not line or len(line) > remaining
                            or len(line) > TRANSCRIPT_META_MAX_BYTES
                            or not line.endswith(b"\n")):
                        return None
                    remaining -= len(line)
                    try:
                        record = json.loads(line)
                    except (UnicodeDecodeError, json.JSONDecodeError):
                        return None
                    if not isinstance(record, dict):
                        return None
                    if record_number == 0:
                        meta = record.get("payload")
                        if (record.get("type") != "session_meta"
                                or not isinstance(meta, dict)
                                or meta.get("id") != thread_id
                                or meta.get("source") != "cli"
                                or meta.get("thread_source") != "user"
                                or "agent_path" in meta
                                or not _repo_contains(repo_root, meta.get("cwd"))):
                            return None
                        meta_valid = True
                    elif record.get("type") == "turn_context":
                        payload = record.get("payload")
                        if (isinstance(payload, dict)
                                and _repo_contains(repo_root, payload.get("cwd"))):
                            # Retain only the three bounded fields needed by the
                            # resolver; prompt/response and other metadata die with
                            # the current loop iteration.
                            newest_context = (
                                payload.get("model"), payload.get("effort")
                            )
                    record_number += 1
            post = os.fstat(fd)
            if ((post.st_dev, post.st_ino) != identity
                    or not stat.S_ISREG(post.st_mode)
                    or post.st_size != snapshot_size):
                return None
            if not meta_valid:
                return None
            return True, newest_context
        finally:
            os.close(fd)
    except (OSError, TypeError, ValueError):
        return None


def codex_coordinator_telemetry(cwd, environ, sessions_root=None):
    """Resolve current-turn Codex coordinator telemetry without config fallback."""
    thread_id = environ.get("CODEX_THREAD_ID")
    if not isinstance(thread_id, str) or not CODEX_THREAD_ID_RE.fullmatch(thread_id):
        return None, None, None
    root = sessions_root if sessions_root is not None else Path.home() / ".codex" / "sessions"
    matches = _coordinator_rollout_matches(root, thread_id)
    if len(matches) != 1:
        return None, None, None
    scan = _scan_fixed_transcript_snapshot(matches[0], cwd, thread_id)
    if scan is None:
        return None, None, None
    _, newest = scan
    session_key = hashlib.sha256(thread_id.encode("ascii")).hexdigest()[:12]
    if newest is None:
        return None, None, session_key
    model, effort = newest
    if any(not isinstance(value, str) or not value.strip()
           or value != value.strip() or len(value) > TELEMETRY_VALUE_MAX_CHARS
           for value in (model, effort)):
        return None, None, session_key
    return model, effort, session_key


def build_row_codex_coordinator(cwd, environ, sessions_root=None):
    model, effort, session_key = codex_coordinator_telemetry(
        cwd, environ, sessions_root=sessions_root
    )
    if session_key is None:
        return None, None
    return {
        "agent": "coordinator",
        "adapter": "codex",
        "model": model or "Pending verification",
        "level": effort or "-",
        "task": "",
        "notes": COORDINATOR_NOTES_PREFIX + session_key,
    }, session_key


def codex_agent_from_transcript(payload):
    """Derive a named Codex agent from bounded first-line session metadata.

    Codex CLI 0.144.5 reports custom agents as agent_type="default" in
    SubagentStop. Its child transcript's first session_meta row carries the selected
    custom agent as /root/<agent>. The parent transcript is validated only as a
    descriptor-relative sibling identity anchor; only the child metadata row is read.
    Symlinks/non-regular files, oversized first rows, malformed JSON, and unexpected
    shapes safely return no derivation.
    """
    parent_path = payload.get("transcript_path")
    child_path = payload.get("agent_transcript_path")
    paths = (parent_path, child_path)
    if any(not isinstance(path, str) or not path or not os.path.isabs(path)
           or not path.endswith(".jsonl") for path in paths):
        return None
    components = []
    for path in paths:
        parts = path.split("/")
        if any(part in (".", "..") for part in parts):
            return None
        normalized = os.path.normpath(path)
        normalized_parts = [part for part in normalized.split("/") if part]
        if not normalized_parts:
            return None
        components.append((normalized_parts[:-1], normalized_parts[-1], normalized))
    if parent_path == child_path or components[0][2] == components[1][2]:
        return None

    required_flags = ("O_NOFOLLOW", "O_NONBLOCK", "O_DIRECTORY")
    if any(not hasattr(os, flag) for flag in required_flags):
        return None
    supports_dir_fd = getattr(os, "supports_dir_fd", ())
    supports_follow_symlinks = getattr(os, "supports_follow_symlinks", ())
    if (os.open not in supports_dir_fd or os.stat not in supports_dir_fd
            or os.stat not in supports_follow_symlinks):
        return None

    cloexec = getattr(os, "O_CLOEXEC", 0)
    directory_flags = os.O_RDONLY | os.O_DIRECTORY | os.O_NOFOLLOW | cloexec
    file_flags = os.O_RDONLY | os.O_NONBLOCK | os.O_NOFOLLOW | cloexec

    def walk_parent(root_fd, parent_components):
        current_fd = os.dup(root_fd)
        try:
            for component in parent_components:
                next_fd = os.open(component, directory_flags, dir_fd=current_fd)
                os.close(current_fd)
                current_fd = next_fd
            return current_fd
        except Exception:
            os.close(current_fd)
            raise

    def validate_regular(parent_fd, name):
        pre = os.stat(name, dir_fd=parent_fd, follow_symlinks=False)
        if not stat.S_ISREG(pre.st_mode):
            return None, None
        fd = os.open(name, file_flags, dir_fd=parent_fd)
        try:
            post = os.fstat(fd)
            if (not stat.S_ISREG(post.st_mode)
                    or (pre.st_dev, pre.st_ino) != (post.st_dev, post.st_ino)):
                os.close(fd)
                return None, None
            return fd, (post.st_dev, post.st_ino)
        except Exception:
            os.close(fd)
            raise

    try:
        with ExitStack() as stack:
            root_fd = os.open("/", os.O_RDONLY | os.O_DIRECTORY | cloexec)
            stack.callback(os.close, root_fd)
            parent_dir_fd = walk_parent(root_fd, components[0][0])
            stack.callback(os.close, parent_dir_fd)
            child_dir_fd = walk_parent(root_fd, components[1][0])
            stack.callback(os.close, child_dir_fd)

            parent_dir_stat = os.fstat(parent_dir_fd)
            child_dir_stat = os.fstat(child_dir_fd)
            if (not stat.S_ISDIR(parent_dir_stat.st_mode)
                    or not stat.S_ISDIR(child_dir_stat.st_mode)
                    or (parent_dir_stat.st_dev, parent_dir_stat.st_ino)
                    != (child_dir_stat.st_dev, child_dir_stat.st_ino)):
                return None

            parent_fd, parent_identity = validate_regular(parent_dir_fd, components[0][1])
            if parent_fd is None:
                return None
            os.close(parent_fd)

            child_fd, child_identity = validate_regular(child_dir_fd, components[1][1])
            if child_fd is None:
                return None
            if parent_identity == child_identity:
                os.close(child_fd)
                return None
            try:
                stream = os.fdopen(child_fd, "rb")
            except Exception:
                os.close(child_fd)
                raise
            with stream:
                first_line = stream.readline(TRANSCRIPT_META_MAX_BYTES + 1)
        if not first_line or len(first_line) > TRANSCRIPT_META_MAX_BYTES or not first_line.endswith(b"\n"):
            return None
        record = json.loads(first_line)
        if not isinstance(record, dict) or record.get("type") != "session_meta" or not isinstance(record.get("payload"), dict):
            return None
        meta = record["payload"]
        source = meta.get("source") if isinstance(meta.get("source"), dict) else {}
        subagent = source.get("subagent") if isinstance(source.get("subagent"), dict) else {}
        nested = subagent.get("thread_spawn") if isinstance(subagent.get("thread_spawn"), dict) else {}
        agent_path = nested.get("agent_path") if isinstance(nested, dict) else None
        if not isinstance(agent_path, str):
            agent_path = meta.get("agent_path")
        if not isinstance(agent_path, str):
            return None
        candidate = os.path.basename(agent_path)
        if agent_path != f"/root/{candidate}" or candidate not in TIER_MAP:
            return None
        return candidate
    except (OSError, ValueError, TypeError, NotImplementedError, json.JSONDecodeError):
        return None


def resolve_config(cwd, tier, adapter):
    """Look up (model, level) for a tier x adapter cell in flywheel/config.json."""
    if not tier:
        return None, None
    try:
        config = json.load(open(os.path.join(cwd, "flywheel", "config.json"), encoding="utf-8"))
        cell = config.get("tiers", {}).get(tier, {}).get("adapters", {}).get(adapter, {})
        return cell.get("model"), cell.get("level")
    except Exception:
        return None, None


def build_row_claude_code(payload, cwd):
    tool_input = payload.get("tool_input") or {}
    tool_response = payload.get("tool_response") or {}
    subagent_type = tool_input.get("subagent_type") or "unknown"
    tier = TIER_MAP.get(subagent_type)
    config_model, config_level = resolve_config(cwd, tier, "claude-code")

    model = tool_response.get("resolvedModel") or config_model or "Pending verification"
    level = config_level if tier else "-"

    notes = "auto-logged"
    override_input = tool_input.get("model")
    if override_input:
        notes += f"; override requested: {override_input}"
    elif config_model and model != config_model:
        notes += f"; resolved model differs from config ({config_model})"

    task = " ".join((tool_input.get("description") or "").split()[:15])

    return {
        "agent": subagent_type,
        "adapter": "claude-code",
        "model": model,
        "level": level,
        "task": task,
        "notes": notes,
    }


def build_row_codex(payload, cwd):
    # SubagentStop payload is top-level (no tool_input/tool_response wrapper).
    subagent_type = payload.get("agent_type") or "unknown"
    if not isinstance(subagent_type, str):
        subagent_type = "unknown"
    transcript_derived = False
    if subagent_type == "default" or subagent_type == "unknown":
        derived = codex_agent_from_transcript(payload)
        if derived:
            subagent_type = derived
            transcript_derived = True
    tier = TIER_MAP.get(subagent_type)
    config_model, config_level = resolve_config(cwd, tier, "codex")

    # payload["model"] is the PARENT session's model, not the subagent's — never use
    # it (official Codex hooks docs). model/level come from config.json only.
    model = config_model or "Pending verification"
    level = config_level if tier else "-"

    # last_assistant_message is the subagent's RESULT, not the task it was given —
    # there is no clean task field in this payload, so task stays manual-at-wrapup.
    task = ""
    notes = "auto-logged (codex; model from config, payload model is parent's)"
    if transcript_derived:
        notes += "; agent derived from transcript session_meta"

    return {
        "agent": subagent_type,
        "adapter": "codex",
        "model": model,
        "level": level,
        "task": task,
        "notes": notes,
    }


def build_rows_antigravity(payload, cwd):
    tool_input = payload.get("tool_input") or {}
    tool_response = payload.get("tool_response") or {}
    subagents = tool_input.get("Subagents") or []
    if not isinstance(subagents, list):
        subagents = [subagents]

    # Known limitation: agy CLI subagents always run on the same model as the main (parent) agent session.
    # We attempt to find the parent session model from the payload, falling back to the
    # config's utility (coordinator) model.
    parent_model = payload.get("model") or payload.get("parent_model") or tool_response.get("resolvedModel")
    if not parent_model:
        parent_model, _ = resolve_config(cwd, "utility", "antigravity")

    rows = []
    for sub in subagents:
        subagent_type = sub.get("TypeName") or "unknown"
        tier = TIER_MAP.get(subagent_type)
        _, config_level = resolve_config(cwd, tier, "antigravity")

        model = parent_model or "Pending verification"
        level = config_level if tier else "-"
        task = " ".join((sub.get("Prompt") or "").split()[:15])

        rows.append({
            "agent": subagent_type,
            "adapter": "antigravity",
            "model": model,
            "level": level,
            "task": task,
            "notes": "auto-logged (antigravity; same model as parent)",
        })
    return rows


def build_rows_claude_code(payload, cwd):
    return [build_row_claude_code(payload, cwd)]


def build_rows_codex(payload, cwd):
    return [build_row_codex(payload, cwd)]


BUILDERS = {
    "claude-code": build_rows_claude_code,
    "codex": build_rows_codex,
    "antigravity": build_rows_antigravity,
}


def append_or_update_rows(cwd, rows, coordinator_session_key=None):
    """Append ordinary rows, or idempotently upsert one Codex coordinator row."""
    spawns_path = os.path.join(cwd, "flywheel", "state", "spawns.json")
    if not os.path.exists(spawns_path):
        open(spawns_path, "a", encoding="utf-8").close()
    with open(spawns_path, "r+", encoding="utf-8") as f:
        fcntl.flock(f, fcntl.LOCK_EX)
        content = f.read()
        data = json.loads(content) if content.strip() else []
        if not isinstance(data, list):
            raise ValueError("spawn ledger must be a list")
        if coordinator_session_key is None:
            data.extend(rows)
        else:
            key_pattern = re.compile(
                re.escape(COORDINATOR_KEY_MARKER + coordinator_session_key)
                + r"(?![0-9a-f])"
            )
            matches = [i for i, existing in enumerate(data)
                       if isinstance(existing, dict)
                       and existing.get("agent") == "coordinator"
                       and existing.get("adapter") == "codex"
                       and isinstance(existing.get("notes"), str)
                       and key_pattern.search(existing["notes"])]
            if len(matches) > 1:
                raise ValueError("duplicate coordinator session rows")
            if matches:
                existing = data[matches[0]]
                # Task, outcome, notes, and timestamp may have been curated during
                # wrapup. Only runtime provenance is resolver-owned on a rerun.
                existing["agent"] = "coordinator"
                existing["adapter"] = "codex"
                existing["model"] = rows[0]["model"]
                existing["level"] = rows[0]["level"]
            else:
                # A manual pending row may have been written immediately before
                # this command. Reconcile it only when the minute timestamp makes
                # the candidate unique; ambiguity must append, never guess.
                manual = [i for i, existing in enumerate(data)
                          if isinstance(existing, dict)
                          and existing.get("agent") == "coordinator"
                          and existing.get("adapter") == "codex"
                          and existing.get("model") == "Pending verification"
                          and existing.get("level") == "-"
                          and existing.get("ts") == rows[0]["ts"]
                          and (not isinstance(existing.get("notes"), str)
                               or COORDINATOR_KEY_MARKER not in existing["notes"])]
                if len(manual) == 1:
                    existing = data[manual[0]]
                    existing["model"] = rows[0]["model"]
                    existing["level"] = rows[0]["level"]
                    notes = existing.get("notes")
                    marker = COORDINATOR_KEY_MARKER + coordinator_session_key
                    existing["notes"] = (f"{notes}; {marker}"
                                           if isinstance(notes, str) and notes
                                           else marker)
                else:
                    data.append(rows[0])
        f.seek(0)
        f.truncate()
        json.dump(data, f, indent=2)
        f.write("\n")


def main():
    adapter = sys.argv[1] if len(sys.argv) > 1 else "claude-code"
    installed_root = os.path.dirname(os.path.dirname(os.path.realpath(__file__)))
    if adapter == "codex-coordinator":
        fields, session_key = build_row_codex_coordinator(installed_root, os.environ)
        if fields is None:
            print(json.dumps({"systemMessage":
                              "Codex coordinator telemetry unavailable; retain manual Pending verification row"}))
            return
        rows = [{
            "ts": datetime.now().strftime("%Y-%m-%dT%H:%M"),
            "agent": fields["agent"], "adapter": fields["adapter"],
            "model": fields["model"], "level": fields["level"],
            "task": fields["task"], "outcome": "ok", "notes": fields["notes"],
        }]
        append_or_update_rows(installed_root, rows, session_key)
        print(json.dumps({"systemMessage":
                          f"spawn coordinator -> {fields['model']} / {fields['level']}"}))
        return

    payload = json.load(sys.stdin)
    # A Codex session may start below the project root, so payload cwd is session
    # context rather than the installed adapter's identity. Other adapters retain
    # their established cwd resolution unchanged.
    cwd = installed_root if adapter == "codex" else (payload.get("cwd") or installed_root)

    builder = BUILDERS.get(adapter, build_rows_claude_code)
    rows_fields = builder(payload, cwd)

    rows = []
    for fields in rows_fields:
        rows.append({
            "ts": datetime.now().strftime("%Y-%m-%dT%H:%M"),
            "agent": fields["agent"],
            "adapter": fields["adapter"],
            "model": fields["model"],
            "level": fields["level"],
            "task": fields["task"],
            "outcome": "ok",
            "notes": fields["notes"],
        })

    append_or_update_rows(cwd, rows)

    if len(rows) == 1:
        row = rows[0]
        message = f"spawn {row['agent']} -> {row['model']} / {row['level']}"
    else:
        message = f"spawn log appended {len(rows)} rows"
    print(json.dumps({"systemMessage": message}))


if __name__ == "__main__":
    try:
        main()
    except Exception:
        print(json.dumps({"systemMessage": "spawn log skipped"}))
    sys.exit(0)

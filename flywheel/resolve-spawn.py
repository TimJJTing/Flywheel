#!/usr/bin/env python3
"""Hook: notify the user of the resolved model/level for a spawned subagent and
auto-append the row to flywheel/state/spawns.json (implements decision d7).
Reads the hook JSON payload from stdin. Adapter selector is sys.argv[1] (default
"claude-code" — the existing claude-code settings.json.merge command passes no arg,
so that behavior is unchanged).

claude-code: PostToolUse(Agent) hook. tool_input.subagent_type is the agent name;
tool_response.resolvedModel is the ACTUAL resolved subagent model (trustworthy).

codex: SubagentStop hook. Top-level agent_type is the agent name; payload["model"] is
the PARENT session's model, not the subagent's (docs/research/codex-hooks.md Rev 2) —
never used as the row's model. model/level are resolved ENTIRELY from
flywheel/config.json by agent_type -> tier.

Branches per-adapter (payload shapes differ, must not run unmodified against the
other): build_row_claude_code / build_row_codex. Shared across both: TIER_MAP, the
cwd-resolution fallback, the ts/outcome row fields, the file-locking append to
spawns.json, and exit-0-on-any-error (a hook failure must never block a spawn).

ponytail: one script, adapter branch via argv — no flag-parsing library needed.
"""
import fcntl
import json
import os
import sys
from datetime import datetime

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
    tier = TIER_MAP.get(subagent_type)
    config_model, config_level = resolve_config(cwd, tier, "codex")

    # payload["model"] is the PARENT session's model, not the subagent's — never use
    # it (docs/research/codex-hooks.md Rev 2). model/level come from config.json only.
    model = config_model or "Pending verification"
    level = config_level if tier else "-"

    # last_assistant_message is the subagent's RESULT, not the task it was given —
    # there is no clean task field in this payload, so task stays manual-at-wrapup.
    task = ""
    notes = "auto-logged (codex; model from config, payload model is parent's)"

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


def main():
    adapter = sys.argv[1] if len(sys.argv) > 1 else "claude-code"
    payload = json.load(sys.stdin)
    cwd = payload.get("cwd") or os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

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

    spawns_path = os.path.join(cwd, "flywheel", "state", "spawns.json")
    if not os.path.exists(spawns_path):
        open(spawns_path, "a", encoding="utf-8").close()
    with open(spawns_path, "r+", encoding="utf-8") as f:
        fcntl.flock(f, fcntl.LOCK_EX)
        content = f.read()
        data = json.loads(content) if content.strip() else []
        for row in rows:
            data.append(row)
        f.seek(0)
        f.truncate()
        json.dump(data, f, indent=1)
        f.write("\n")

    for row in rows:
        print(json.dumps({"systemMessage": f"spawn {row['agent']} → {row['model']} / {row['level']}"}))


if __name__ == "__main__":
    try:
        main()
    except Exception:
        pass
    sys.exit(0)


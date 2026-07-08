#!/usr/bin/env python3
"""PostToolUse hook (matcher "Agent"): notify the user of the resolved model/level
for a spawned subagent and auto-append the row to flywheel/state/spawns.json
(implements decision d7). Reads the hook JSON payload from stdin.

ponytail: one script, no flags — this is the only mode there is. Any failure to
parse/resolve must never block a spawn, so all errors are swallowed (exit 0).
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


def main():
    payload = json.load(sys.stdin)
    tool_input = payload.get("tool_input") or {}
    tool_response = payload.get("tool_response") or {}
    subagent_type = tool_input.get("subagent_type") or "unknown"
    cwd = payload.get("cwd") or os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

    tier = TIER_MAP.get(subagent_type)
    config_model = config_level = None
    if tier:
        try:
            config = json.load(open(os.path.join(cwd, "flywheel", "config.json"), encoding="utf-8"))
            cell = config.get("tiers", {}).get(tier, {}).get("adapters", {}).get("claude-code", {})
            config_model, config_level = cell.get("model"), cell.get("level")
        except Exception:
            pass

    model = tool_response.get("resolvedModel") or config_model or "Pending verification"
    level = config_level if tier else "-"

    notes = "auto-logged"
    override_input = tool_input.get("model")
    if override_input:
        notes += f"; override requested: {override_input}"
    elif config_model and model != config_model:
        notes += f"; resolved model differs from config ({config_model})"

    task = " ".join((tool_input.get("description") or "").split()[:15])

    row = {
        "ts": datetime.now().strftime("%Y-%m-%dT%H:%M"),
        "agent": subagent_type,
        "adapter": "claude-code",
        "model": model,
        "level": level,
        "task": task,
        "outcome": "ok",
        "notes": notes,
    }

    spawns_path = os.path.join(cwd, "flywheel", "state", "spawns.json")
    if not os.path.exists(spawns_path):
        # ponytail: "a" mode is create-if-missing and non-truncating, so a racing
        # concurrent creator is harmless — both end up with an openable file.
        open(spawns_path, "a", encoding="utf-8").close()
    with open(spawns_path, "r+", encoding="utf-8") as f:
        fcntl.flock(f, fcntl.LOCK_EX)
        content = f.read()
        data = json.loads(content) if content.strip() else []
        data.append(row)
        f.seek(0)
        f.truncate()
        json.dump(data, f, indent=1)
        f.write("\n")
        # no manual LOCK_UN: releasing via the `with` block's close() guarantees the
        # buffered write is flushed to disk BEFORE the lock is released — that ordering
        # (not the lock itself) was the actual bug (flush raced unlock).

    print(json.dumps({"systemMessage": f"spawn {subagent_type} → {model} / {level}"}))


if __name__ == "__main__":
    try:
        main()
    except Exception:
        pass
    sys.exit(0)

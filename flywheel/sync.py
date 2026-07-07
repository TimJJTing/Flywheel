#!/usr/bin/env python3
"""Regenerate per-adapter projection files from flywheel/config.json.

config.json is the source of truth for tier->model/effort. This script writes
that truth into the files each adapter actually reads at runtime:
  - .claude/agents/<agent>.md            (claude-code frontmatter)
  - adapters/claude-code/agents/<agent>.md (claude-code frontmatter, mirrored)
  - adapters/opencode/opencode.json.merge  (opencode .agent.<tier>.model)

codex has no per-agent projection file (prose-only AGENTS.md.block) - nothing
to write there.

Idempotent: run twice, second run is a no-op diff.
"""
import json
import re
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
CONFIG_PATH = REPO_ROOT / "flywheel" / "config.json"

# config tier key -> claude-code agent .md basename (no extension)
TIER_TO_AGENT_FILE = {
    "architect": "architect",
    "strategist": "researcher",
    "engineer": "engineer",
    "utility": "utility",
    "verifier": "verifier",
    "auditor": "plan-auditor",
}

CLAUDE_CODE_AGENT_DIRS = [
    REPO_ROOT / ".claude" / "agents",
    REPO_ROOT / "adapters" / "claude-code" / "agents",
]

OPENCODE_MERGE_PATH = REPO_ROOT / "adapters" / "opencode" / "opencode.json.merge"

PENDING = "Pending verification"


def sync_claude_code_frontmatter(tiers: dict) -> None:
    for tier_key, agent_file in TIER_TO_AGENT_FILE.items():
        cell = tiers.get(tier_key, {}).get("adapters", {}).get("claude-code", {})
        model, effort = cell.get("model"), cell.get("effort")
        if model == PENDING or effort == PENDING or model is None or effort is None:
            print(f"skip {agent_file}.md: config tiers.{tier_key}.adapters.claude-code pending/missing")
            continue
        for agents_dir in CLAUDE_CODE_AGENT_DIRS:
            path = agents_dir / f"{agent_file}.md"
            if not path.is_file():
                print(f"skip {path}: not found")
                continue
            text = path.read_text(encoding="utf-8")
            new_text = re.sub(r"^model:\s*\S+", f"model: {model}", text, count=1, flags=re.M)
            new_text = re.sub(r"^effort:\s*\S+", f"effort: {effort}", new_text, count=1, flags=re.M)
            if new_text != text:
                path.write_text(new_text, encoding="utf-8")
                print(f"wrote {path}")
            else:
                print(f"unchanged {path}")


def sync_opencode_merge(tiers: dict) -> None:
    if not OPENCODE_MERGE_PATH.is_file():
        print(f"skip {OPENCODE_MERGE_PATH}: not found")
        return
    data = json.loads(OPENCODE_MERGE_PATH.read_text(encoding="utf-8"))
    agents = data.get("agent", {})
    for tier_key in TIER_TO_AGENT_FILE:
        cell = tiers.get(tier_key, {}).get("adapters", {}).get("opencode", {})
        provider, model = cell.get("provider"), cell.get("model")
        if provider == PENDING or model == PENDING or provider is None or model is None:
            print(f"skip opencode.json.merge .agent.{tier_key}: config tiers.{tier_key}.adapters.opencode pending/missing")
            continue
        if tier_key not in agents:
            print(f"skip opencode.json.merge .agent.{tier_key}: key not present")
            continue
        agents[tier_key]["model"] = f"{provider}/{model}"
    new_text = json.dumps(data, indent=2, ensure_ascii=False) + "\n"
    old_text = OPENCODE_MERGE_PATH.read_text(encoding="utf-8")
    if new_text != old_text:
        OPENCODE_MERGE_PATH.write_text(new_text, encoding="utf-8")
        print(f"wrote {OPENCODE_MERGE_PATH}")
    else:
        print(f"unchanged {OPENCODE_MERGE_PATH}")


def main() -> None:
    config = json.loads(CONFIG_PATH.read_text(encoding="utf-8"))
    tiers = config.get("tiers", {})
    sync_claude_code_frontmatter(tiers)
    sync_opencode_merge(tiers)


if __name__ == "__main__":
    main()

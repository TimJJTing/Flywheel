#!/usr/bin/env python3
"""Project preserved config values into installed adapter artifacts only."""
import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
CONFIG = ROOT / "flywheel" / "config.json"
PENDING = "Pending verification"
TIER_FILES = {
    "architect": "architect", "strategist": "researcher", "engineer": "engineer",
    "utility": "utility", "verifier": "verifier", "auditor": "plan-auditor",
}


def cell(tiers, tier, adapter):
    return tiers.get(tier, {}).get("adapters", {}).get(adapter, {})


def sync_text(tiers):
    for tier, name in TIER_FILES.items():
        c = cell(tiers, tier, "claude-code")
        path = ROOT / ".claude" / "agents" / f"{name}.md"
        if path.is_file() and "flywheel-managed" in path.read_text(encoding="utf-8"):
            model, level = c.get("model"), c.get("level")
            if model not in (None, PENDING) and level not in (None, PENDING):
                text = path.read_text(encoding="utf-8")
                text = re.sub(r"^model:\s*\S+", f"model: {model}", text, count=1, flags=re.M)
                text = re.sub(r"^effort:\s*\S+", f"effort: {level}", text, count=1, flags=re.M)
                path.write_text(text, encoding="utf-8")
        c = cell(tiers, tier, "codex")
        path = ROOT / ".codex" / "agents" / f"{name}.toml"
        if path.is_file() and "flywheel-managed" in path.read_text(encoding="utf-8"):
            model, level = c.get("model"), c.get("level")
            if model not in (None, PENDING) and level not in (None, PENDING):
                text = path.read_text(encoding="utf-8")
                text = re.sub(r'^model\s*=\s*"[^"]*"', f'model = "{model}"', text, count=1, flags=re.M)
                text = re.sub(r'^model_reasoning_effort\s*=\s*"[^"]*"',
                              f'model_reasoning_effort = "{level}"', text, count=1, flags=re.M)
                path.write_text(text, encoding="utf-8")


def sync_opencode(tiers):
    path = ROOT / "opencode.json"
    if not path.is_file():
        return
    data = json.loads(path.read_text(encoding="utf-8"))
    changed = False
    for tier in TIER_FILES:
        agent = data.get("agent", {}).get(tier)
        c = cell(tiers, tier, "opencode")
        if not isinstance(agent, dict) or not str(agent.get("description", "")).startswith("Flywheel "):
            continue
        provider, model = c.get("provider"), c.get("model")
        if provider not in (None, PENDING) and model not in (None, PENDING):
            value = f"{provider}/{model}"
            if agent.get("model") != value:
                agent["model"] = value
                changed = True
    if changed:
        path.write_text(json.dumps(data, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")


def main():
    tiers = json.loads(CONFIG.read_text(encoding="utf-8")).get("tiers", {})
    sync_text(tiers)
    sync_opencode(tiers)


if __name__ == "__main__":
    main()

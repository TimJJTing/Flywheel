#!/usr/bin/env python3
"""Generate release adapter templates from distribution release config and FACTS."""
import argparse
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
DIST = ROOT / "distribution"
NAMES = {"architect":"architect", "strategist":"researcher", "engineer":"engineer",
         "utility":"utility", "verifier":"verifier", "auditor":"plan-auditor"}
PENDING = "Pending verification"


def validate_facts(config, facts_text):
    missing = []
    for tier, data in config.get("tiers", {}).items():
        for adapter, cell in data.get("adapters", {}).items():
            model = cell.get("model")
            if not model or model == PENDING:
                continue
            rows = [line for line in facts_text.splitlines()
                    if line.startswith("|") and f"| {tier} |" in line and
                    f"| {adapter} |" in line and f"| {model} |" in line]
            if not any(re.search(r"\| \d{4}-\d{2}-\d{2} \|$", row) for row in rows):
                missing.append(f"{tier}.{adapter}={model}")
    if missing:
        raise ValueError("model IDs missing dated FACTS verification: " + ", ".join(missing))


def replace(path, model_pattern, model_value, level_pattern=None, level_value=None):
    text = path.read_text(encoding="utf-8")
    rendered, n = re.subn(model_pattern, model_value, text, count=1, flags=re.M)
    if n != 1:
        raise ValueError(f"projection key missing: {path}")
    if level_pattern:
        rendered, n = re.subn(level_pattern, level_value, rendered, count=1, flags=re.M)
        if n != 1:
            raise ValueError(f"projection level missing: {path}")
    return text, rendered


def outputs(config):
    result = []
    for tier, name in NAMES.items():
        adapters = config["tiers"][tier]["adapters"]
        claude = adapters["claude-code"]
        p = DIST / "adapters/claude-code/agents" / f"{name}.md"
        if claude.get("model") != PENDING:
            old, new = replace(p, r"^model:\s*\S+", f"model: {claude['model']}",
                               r"^effort:\s*\S+", f"effort: {claude['level']}")
            result.append((p, old, new))
        codex = adapters["codex"]
        p = DIST / "adapters/codex/agents" / f"{name}.toml"
        if codex.get("model") != PENDING:
            old, new = replace(p, r'^model\s*=\s*"[^"]*"', f'model = "{codex["model"]}"',
                               r'^model_reasoning_effort\s*=\s*"[^"]*"',
                               f'model_reasoning_effort = "{codex["level"]}"')
            result.append((p, old, new))
    p = DIST / "adapters/opencode/opencode.json.merge"
    old = p.read_text(encoding="utf-8")
    data = json.loads(old)
    for tier in NAMES:
        c = config["tiers"][tier]["adapters"]["opencode"]
        if c.get("provider") != PENDING and c.get("model") != PENDING:
            data["agent"][tier]["model"] = f"{c['provider']}/{c['model']}"
    result.append((p, old, json.dumps(data, indent=2, ensure_ascii=False) + "\n"))
    return result


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--check", action="store_true")
    parser.add_argument("--config", type=Path, default=DIST / "defaults/flywheel/config.json")
    parser.add_argument("--facts", type=Path, default=DIST / "defaults/flywheel/FACTS.md")
    args = parser.parse_args()
    config = json.loads(args.config.read_text(encoding="utf-8"))
    try:
        validate_facts(config, args.facts.read_text(encoding="utf-8"))
        generated = outputs(config)
    except (ValueError, KeyError, json.JSONDecodeError) as exc:
        print(f"error: {exc}", file=sys.stderr)
        return 1
    drift = [str(path.relative_to(ROOT)) for path, old, new in generated if old != new]
    if args.check:
        if drift:
            print("distribution projection drift: " + ", ".join(drift), file=sys.stderr)
            return 1
        print("PASS distribution templates match release config and dated FACTS")
        return 0
    for path, old, new in generated:
        if old != new:
            path.write_text(new, encoding="utf-8")
            print(f"wrote {path.relative_to(ROOT)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

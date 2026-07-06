#!/usr/bin/env python3
"""Build flywheel/dashboard/dashboard.html from config.json + state/*.json.

Run from anywhere: python3 flywheel/dashboard/build.py
Override the "generated" timestamp for deterministic builds:
    FLYWHEEL_BUILD_TS=2026-07-06T00:00 python3 flywheel/dashboard/build.py
"""
import json
import os
import sys
from datetime import datetime

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
FLYWHEEL_DIR = os.path.dirname(SCRIPT_DIR)
CONFIG_PATH = os.path.join(FLYWHEEL_DIR, "config.json")
STATE_DIR = os.path.join(FLYWHEEL_DIR, "state")
TEMPLATE_PATH = os.path.join(SCRIPT_DIR, "template.html")
OUTPUT_PATH = os.path.join(SCRIPT_DIR, "dashboard.html")

PLACEHOLDER = "/*__FLYWHEEL_DATA__*/ null"


def load_json(path):
    if not os.path.isfile(path):
        sys.exit(f"flywheel dashboard build: missing file: {path}")
    try:
        with open(path, "r", encoding="utf-8") as f:
            return json.load(f)
    except (ValueError, OSError) as e:
        sys.exit(f"flywheel dashboard build: invalid JSON in {path}: {e}")


def main():
    config = load_json(CONFIG_PATH)
    projects = load_json(os.path.join(STATE_DIR, "projects.json"))
    issues = load_json(os.path.join(STATE_DIR, "issues.json"))
    decisions = load_json(os.path.join(STATE_DIR, "decisions.json"))
    activity = load_json(os.path.join(STATE_DIR, "activity.json"))
    spawns = load_json(os.path.join(STATE_DIR, "spawns.json"))

    generated = os.environ.get("FLYWHEEL_BUILD_TS") or datetime.now().strftime("%Y-%m-%dT%H:%M")

    blob = {
        "generated": generated,
        "config": {
            "project_name": config.get("project_name"),
            "autonomy": config.get("autonomy"),
            "flywheel_version": config.get("flywheel_version"),
        },
        "projects": projects,
        "issues": issues,
        "decisions": decisions,
        "activity": activity,
        "spawns": spawns,
    }
    json_text = json.dumps(blob, separators=(",", ":"), ensure_ascii=False)

    if not os.path.isfile(TEMPLATE_PATH):
        sys.exit(f"flywheel dashboard build: missing template: {TEMPLATE_PATH}")
    with open(TEMPLATE_PATH, "r", encoding="utf-8") as f:
        template = f.read()
    if PLACEHOLDER not in template:
        sys.exit("flywheel dashboard build: placeholder not found in template.html")
    output = template.replace(PLACEHOLDER, json_text)

    with open(OUTPUT_PATH, "w", encoding="utf-8") as f:
        f.write(output)
    print(f"wrote {OUTPUT_PATH}")


if __name__ == "__main__":
    main()

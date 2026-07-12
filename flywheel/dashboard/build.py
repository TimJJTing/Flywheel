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


def md_to_html(md_text):
    html_lines = []
    in_list = False
    for line in md_text.splitlines():
        line = line.strip()
        if not line:
            continue
        if line.startswith("# "):
            if in_list:
                html_lines.append("</ul>")
                in_list = False
            html_lines.append(f"<h3>{line[2:]}</h3>")
        elif line.startswith("## "):
            if in_list:
                html_lines.append("</ul>")
                in_list = False
            html_lines.append(f"<h4>{line[3:]}</h4>")
        elif line.startswith("- "):
            if not in_list:
                html_lines.append("<ul style='margin-top:4px; margin-bottom:12px;'>")
                in_list = True
            parts = line[2:].split("`")
            formatted = ""
            for i, p in enumerate(parts):
                if i % 2 == 1:
                    formatted += f"<code>{p}</code>"
                else:
                    formatted += p
            html_lines.append(f"<li>{formatted}</li>")
        else:
            if in_list:
                html_lines.append("</ul>")
                in_list = False
            parts = line.split("`")
            formatted = ""
            for i, p in enumerate(parts):
                if i % 2 == 1:
                    formatted += f"<code>{p}</code>"
                else:
                    formatted += p
            html_lines.append(f"<p>{formatted}</p>")
    if in_list:
        html_lines.append("</ul>")
    return "\n".join(html_lines)


def main():
    config = load_json(CONFIG_PATH)
    projects = load_json(os.path.join(STATE_DIR, "projects.json"))
    issues = load_json(os.path.join(STATE_DIR, "issues.json"))
    decisions = load_json(os.path.join(STATE_DIR, "decisions.json"))
    activity = load_json(os.path.join(STATE_DIR, "activity.json"))
    spawns = load_json(os.path.join(STATE_DIR, "spawns.json"))

    arch_path = os.path.abspath(os.path.join(FLYWHEEL_DIR, "..", "docs", "ARCHITECTURE.md"))
    arch_html = ""
    mermaid_text = ""
    if os.path.isfile(arch_path):
        try:
            with open(arch_path, "r", encoding="utf-8") as f:
                arch_content = f.read()
            import re
            mermaid_match = re.search(r"```mermaid\n([\s\S]*?)\n```", arch_content)
            text_without_mermaid = arch_content
            if mermaid_match:
                mermaid_text = mermaid_match.group(1)
                mermaid_text = mermaid_text.replace('"../', '"../../').replace("'../", "'../../")
                text_without_mermaid = arch_content.replace(mermaid_match.group(0), "")
            arch_html = md_to_html(text_without_mermaid)
        except Exception as e:
            print(f"warning: failed to parse docs/ARCHITECTURE.md: {e}")

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
        "architecture_html": arch_html,
        "architecture_mermaid": mermaid_text
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

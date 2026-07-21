#!/usr/bin/env python3
"""Auto-generate docs/flywheel/ARCHITECTURE.md based on flywheel/config.json and repo structure.

Discovers tiers, scripts, state ledgers, and dashboard artifacts dynamically
from the filesystem — nothing is hardcoded. Re-run to reflect the current repo.

Run from anywhere: python3 flywheel/dashboard/gen_architecture.py [target-dir]
"""
import glob
import json
import os
import re
import sys
from collections import OrderedDict


def _safe_id(name):
    """Turn a filename into a Mermaid-safe node ID (alphanum + underscore)."""
    return re.sub(r"[^a-zA-Z0-9]", "_", name)


def _discover_scripts(flywheel_dir):
    """Find *.sh and *.py directly in flywheel/."""
    scripts = []
    for ext in ("*.sh", "*.py"):
        for path in sorted(glob.glob(os.path.join(flywheel_dir, ext))):
            scripts.append(os.path.basename(path))
    return scripts


def _discover_state_ledgers(state_dir):
    """Find *.json files in flywheel/state/."""
    ledgers = []
    if os.path.isdir(state_dir):
        for path in sorted(glob.glob(os.path.join(state_dir, "*.json"))):
            ledgers.append(os.path.basename(path))
    return ledgers


def _discover_dashboard(dashboard_dir):
    """Find build scripts and the compiled dashboard in flywheel/dashboard/."""
    builders = []
    outputs = []
    if not os.path.isdir(dashboard_dir):
        return builders, outputs
    for f in sorted(os.listdir(dashboard_dir)):
        if f.startswith("build."):
            builders.append(f)
        elif f == "dashboard.html":
            outputs.append(f)
    return builders, outputs


_SCRIPT_LABELS = {
    "check.sh": "Consistency Check",
    "wrapup.sh": "Session Wrapup",
    "sync.py": "Config Sync",
    "compact.py": "Ledger Compactor",
    "resolve-spawn.py": "Spawn Hook Handler",
}

# Maps file extensions to human-readable language names for the tech-stack.
_EXT_LANGUAGES = OrderedDict([
    (".sh", "POSIX Bash"),
    (".py", "Python 3"),
    (".mjs", "Node.js"),
    (".js", "Node.js"),
])

# Maps adapter directory names to display names.
_ADAPTER_DISPLAY = {
    "claude-code": "Claude Code",
    "codex": "Codex",
    "opencode": "OpenCode",
    "antigravity": "Google Antigravity",
}


def _label_for_script(name):
    return _SCRIPT_LABELS.get(name, name)


def _build_tech_stack(target_dir, flywheel_dir, config, tier_count, scripts,
                      ledgers, builders, dash_outputs):
    """Build the Tech-Stack Overview bullets from discovered repo state."""
    bullets = []

    # 1. Core Orchestrator — adapter keys from the installed config.
    adapters_dir = os.path.join(target_dir, "adapters")
    adapter_names = set()
    if os.path.isdir(adapters_dir):
        for entry in os.listdir(adapters_dir):
            if os.path.isdir(os.path.join(adapters_dir, entry)):
                adapter_names.add(entry)
    # Also pull adapter keys from config tiers.
    for tdata in config.get("tiers", {}).values():
        for a in tdata.get("adapters", {}):
            adapter_names.add(a)
    # Build display list, preserving a stable order.
    display_order = ["claude-code", "codex", "opencode", "antigravity"]
    adapter_display = []
    for name in display_order:
        if name in adapter_names:
            adapter_display.append(_ADAPTER_DISPLAY.get(name, name.title()))
            adapter_names.discard(name)
    # Append any remaining unknown adapters.
    for name in sorted(adapter_names):
        adapter_display.append(_ADAPTER_DISPLAY.get(name, name.title()))

    adapter_list = ", ".join(adapter_display[:-1]) + ", and " + adapter_display[-1] \
        if len(adapter_display) > 1 else (adapter_display[0] if adapter_display else "none")
    bullets.append(
        f"- **Core Orchestrator**: {tier_count}-tier agentic wrapper supporting {adapter_list}."
    )

    # 2. Automation Engine — languages inferred from script file extensions.
    all_scripts = list(scripts)  # flywheel-level scripts
    # Also scan dashboard dir for build scripts.
    all_scripts.extend(builders)
    seen_langs = []
    seen_set = set()
    for s in all_scripts:
        ext = os.path.splitext(s)[1]
        lang = _EXT_LANGUAGES.get(ext)
        if lang and lang not in seen_set:
            seen_langs.append(lang)
            seen_set.add(lang)
    # Fallback: if nothing found, keep it generic.
    if not seen_langs:
        seen_langs = ["shell scripts"]
    lang_str = " + ".join(f"{l}" for l in seen_langs) + " utility scripts"
    bullets.append(f"- **Automation Engine**: {lang_str}.")

    # 3. State Store — derived from ledger count.
    if ledgers:
        bullets.append(
            f"- **State Store**: {len(ledgers)} flat JSON ledger files (schema-validated)."
        )

    # 4. Dashboard — derived from discovered dashboard artifacts.
    if dash_outputs:
        template_path = os.path.join(flywheel_dir, "dashboard", "template.html")
        has_template = os.path.isfile(template_path)
        parts = ["single-page web dashboard"]
        if has_template:
            parts.append("template-driven")
        bullets.append(f"- **Dashboard**: {', '.join(parts)}.")

    return "\n".join(bullets)


def _infer_wrapup_edges(flywheel_dir, script_ids, ledger_ids, builder_id):
    """Read wrapup.sh to figure out what it runs/commits.

    Returns a list of (source_id, target_id, label) tuples.
    Detects both bare filenames and path-based references (e.g. dashboard/build.py),
    as well as glob patterns like state/*.json.
    """
    edges = []
    wrapup_path = os.path.join(flywheel_dir, "wrapup.sh")
    wrapup_id = _safe_id("wrapup.sh")
    if wrapup_id not in script_ids.values() or not os.path.isfile(wrapup_path):
        return edges

    try:
        with open(wrapup_path, "r", encoding="utf-8") as f:
            content = f.read()
    except OSError:
        return edges

    # Detect which scripts wrapup.sh invokes.
    for script_name, sid in script_ids.items():
        if sid == wrapup_id:
            continue
        # Look for the script being called (e.g. check.sh, build.py, gen_architecture.py)
        if script_name in content:
            edges.append((wrapup_id, sid, "Runs"))

    # Detect which builders wrapup.sh invokes.
    if builder_id:
        for builder_name in ("build.py", "build.mjs"):
            if builder_name in content:
                edges.append((wrapup_id, builder_id, "Runs"))
                break

    # Detect which state ledgers wrapup.sh git-adds / references.
    # wrapup.sh typically uses globs like "state/*.json" — treat as all ledgers.
    all_ledgers_glob = "state/*.json" in content or "state/ *.json" in content
    for ledger_name, lid in ledger_ids.items():
        if all_ledgers_glob or ledger_name in content:
            edges.append((wrapup_id, lid, "Commits"))

    return edges


def main():
    target_dir = (
        sys.argv[1]
        if len(sys.argv) > 1
        else os.path.dirname(
            os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
        )
    )
    flywheel_dir = os.path.join(target_dir, "flywheel")
    config_path = os.path.join(flywheel_dir, "config.json")
    if not os.path.isfile(config_path):
        print(f"Error: config.json not found at {config_path}")
        sys.exit(1)

    try:
        with open(config_path, "r", encoding="utf-8") as f:
            config = json.load(f)
    except Exception as e:
        print(f"Error reading config.json: {e}")
        sys.exit(1)

    project_name = config.get("project_name", "flywheel")

    # ── Discover tiers from config ─────────────────────────────────────
    tiers = config.get("tiers", {})
    # Map display names used in the diagram; config key -> (display, agent_name)
    tier_display = {
        "architect": ("Architect", "architect"),
        "strategist": ("Strategist", "researcher"),
        "engineer": ("Engineer", "engineer"),
        "utility": ("Utility", "utility"),
        "verifier": ("Verifier", "verifier"),
        "auditor": ("Auditor", "plan-auditor"),
    }

    tier_entries = []  # (node_id, label, role, model)
    for key in tiers:
        display, agent = tier_display.get(key, (key.title(), key))
        tdata = tiers[key]
        role = tdata.get("role", "")
        # Pick the first available model across adapters.
        model = "Unknown"
        for adapter_name in ("antigravity", "claude-code", "codex", "opencode"):
            adapters = tdata.get("adapters", {})
            if adapter_name in adapters:
                model = adapters[adapter_name].get("model", "Unknown")
                break
        tier_entries.append((_safe_id(key), display, agent, role, model))

    # ── Discover scripts ───────────────────────────────────────────────
    scripts = _discover_scripts(flywheel_dir)
    script_ids = {s: _safe_id(s) for s in scripts}

    # ── Discover state ledgers ─────────────────────────────────────────
    state_dir = os.path.join(flywheel_dir, "state")
    ledgers = _discover_state_ledgers(state_dir)
    ledger_ids = {l: "state_" + _safe_id(l) for l in ledgers}

    # ── Discover dashboard artifacts ───────────────────────────────────
    dashboard_dir = os.path.join(flywheel_dir, "dashboard")
    builders, dash_outputs = _discover_dashboard(dashboard_dir)
    builder_label = " / ".join(builders) if builders else None
    builder_id = "build_scripts" if builders else None
    dashboard_id = "dashboard_html" if dash_outputs else None

    # ── Build Mermaid diagram ──────────────────────────────────────────
    lines = ["```mermaid", "flowchart TD"]

    # Coordinator node
    lines.append('    coord["Coordinator<br>(Main Session)"]')

    # Tier nodes
    for nid, display, agent, _role, _model in tier_entries:
        lines.append(f'    {nid}["{display} Tier<br>({agent})"]')

    lines.append("")

    # Script nodes
    for name in scripts:
        sid = script_ids[name]
        label = _label_for_script(name)
        lines.append(f'    {sid}["{name}<br>({label})"]')

    lines.append("")

    # State ledger nodes
    for name in ledgers:
        lid = ledger_ids[name]
        lines.append(f'    {lid}["state/{name}"]')

    lines.append("")

    # Dashboard nodes
    if builder_id:
        lines.append(f'    {builder_id}["{builder_label}<br>(Dashboard Builder)"]')
    if dashboard_id:
        lines.append(f'    {dashboard_id}["dashboard.html<br>(CEO Dashboard)"]')

    lines.append("")

    # ── Edges ──────────────────────────────────────────────────────────
    # Coordinator -> tiers
    for nid, *_ in tier_entries:
        lines.append(f"    coord -->|Delegates to| {nid}")

    lines.append("")

    # Coordinator -> scripts it directly invokes (check.sh, wrapup.sh)
    for name in ("check.sh", "wrapup.sh"):
        if name in script_ids:
            lines.append(f"    coord -->|Runs| {script_ids[name]}")

    lines.append("")

    # Wrapup -> things it invokes/commits (inferred from wrapup.sh content)
    wrapup_edges = _infer_wrapup_edges(
        flywheel_dir, script_ids, ledger_ids, builder_id
    )
    for src, tgt, label in wrapup_edges:
        lines.append(f"    {src} -->|{label}| {tgt}")

    lines.append("")

    # Build scripts -> state ledgers (reads) and dashboard (generates)
    if builder_id:
        for name in ledgers:
            lid = ledger_ids[name]
            lines.append(f"    {builder_id} -->|Reads| {lid}")
        if dashboard_id:
            lines.append(f"    {builder_id} -->|Generates| {dashboard_id}")

    lines.append("")

    # Click links for navigability
    lines.append('    click coord "../../flywheel/INDEX.md" "View framework index"')
    for name in scripts:
        sid = script_ids[name]
        lines.append(f'    click {sid} "../../flywheel/{name}" "View {name}"')
    for name in ledgers:
        lid = ledger_ids[name]
        lines.append(
            f'    click {lid} "../../flywheel/state/{name}" "View {name}"'
        )
    if dashboard_id:
        lines.append(
            f'    click {dashboard_id} "../../flywheel/dashboard/dashboard.html" "View compiled dashboard"'
        )

    lines.append("```")

    # ── Build tiers table ──────────────────────────────────────────────
    tiers_section_lines = []
    for _nid, display, _agent, role, model in tier_entries:
        tiers_section_lines.append(
            f"- **{display.lower()}**: {role} (Model: `{model}`)"
        )

    # ── Build Tech-Stack Overview ───────────────────────────────────────
    tech_stack_block = _build_tech_stack(
        target_dir, flywheel_dir, config, len(tiers),
        scripts, ledgers, builders, dash_outputs,
    )

    # ── Assemble final document ────────────────────────────────────────
    mermaid_block = "\n".join(lines)
    tiers_block = "\n".join(tiers_section_lines)

    doc_content = f"""\
<!-- flywheel-generated:architecture -->
# Flywheel Architecture & Tech-Stack

This document is automatically generated by `gen_architecture.py`. It describes the layout, components, and communication pathways of the **{project_name}** framework instance.

## Tech-Stack Overview
{tech_stack_block}

## Component Architecture

{mermaid_block}

## Active Tiers & Models
{tiers_block}
"""

    output_docs_dir = os.path.join(target_dir, "docs", "flywheel")
    os.makedirs(output_docs_dir, exist_ok=True)
    output_path = os.path.join(output_docs_dir, "ARCHITECTURE.md")
    with open(output_path, "w", encoding="utf-8") as f:
        f.write(doc_content)
    print(f"wrote {output_path}")


if __name__ == "__main__":
    main()

#!/usr/bin/env python3
"""JSON operations shared by Flywheel lifecycle entry points."""

import json
import os
import sys


FLYWHEEL_COMMANDS = {
    "python3 flywheel/resolve-spawn.py",
    'python3 "$(git rev-parse --show-toplevel)/flywheel/resolve-spawn.py" codex',
    "python3 flywheel/resolve-spawn.py antigravity",
}


def load(path):
    with open(path, encoding="utf-8") as handle:
        return json.load(handle)


def write(path, value):
    with open(path, "w", encoding="utf-8") as handle:
        json.dump(value, handle, indent=2)
        handle.write("\n")


def stable(value):
    return json.dumps(value, sort_keys=True)


def deep_merge(dest, src, path=""):
    changed = False
    if isinstance(dest, dict) and isinstance(src, dict):
        for key, value in src.items():
            child_path = f"{path}.{key}" if path else key
            if key not in dest:
                dest[key] = value
                changed = True
            else:
                child_changed, dest[key] = deep_merge(dest[key], value, child_path)
                changed = changed or child_changed
        return changed, dest
    if isinstance(dest, list) and isinstance(src, list):
        for item in src:
            if not any(stable(item) == stable(existing) for existing in dest):
                dest.append(item)
                changed = True
        return changed, dest
    if dest != src:
        print(f"  skip (differs): {path}", file=sys.stderr)
    return False, dest


def clean_flywheel(value):
    if isinstance(value, dict):
        result = {}
        removed_any = False
        for key, child in value.items():
            if key == "flywheel-spawn-log":
                removed_any = True
                continue
            new_child, removed = clean_flywheel(child)
            removed_any = removed_any or removed
            if removed and new_child in ({}, []):
                continue
            result[key] = new_child
        return result, removed_any
    if isinstance(value, list):
        result = []
        removed_any = False
        for item in value:
            if isinstance(item, dict) and str(item.get("command", "")) in FLYWHEEL_COMMANDS:
                removed_any = True
                continue
            new_item, removed = clean_flywheel(item)
            removed_any = removed_any or removed
            if (removed and isinstance(item, dict) and isinstance(item.get("hooks"), list)
                    and (not isinstance(new_item, dict) or not new_item.get("hooks"))):
                continue
            result.append(new_item)
        return result, removed_any
    return value, False


def effectively_empty(value):
    if isinstance(value, dict):
        return all(effectively_empty(child) for child in value.values())
    if isinstance(value, list):
        return not value
    return False


def has_flywheel_command(value):
    if isinstance(value, dict):
        return value.get("command") in FLYWHEEL_COMMANDS or any(
            has_flywheel_command(child) for child in value.values())
    if isinstance(value, list):
        return any(has_flywheel_command(child) for child in value)
    return False


def main():
    operation = sys.argv[1]
    if operation == "valid":
        load(sys.argv[2])
        return
    if operation == "equal":
        print("yes" if load(sys.argv[2]) == load(sys.argv[3]) else "no")
        return
    if operation == "deep-merge":
        merge_path, dest_path = sys.argv[2:4]
        changed, result = deep_merge(load(dest_path), load(merge_path))
        if changed:
            write(dest_path, result)
        print("merged" if changed else "already-merged")
        return
    if operation == "unmerge":
        path = sys.argv[2]
        result, removed = clean_flywheel(load(path))
        if not removed:
            print("no-flywheel-entries-found")
        elif effectively_empty(result):
            os.remove(path)
            print("removed (empty after unmerge)")
        else:
            write(path, result)
            print("unmerged")
        return
    if operation == "has-command":
        print("yes" if has_flywheel_command(load(sys.argv[2])) else "no")
        return
    if operation == "opencode-merge":
        merge_path, dest_path = sys.argv[2:4]
        merge_agents = load(merge_path).get("agent", {})
        dest = load(dest_path)
        dest_agents = dest.setdefault("agent", {})
        changed = False
        for key, value in merge_agents.items():
            if key not in dest_agents:
                dest_agents[key] = value
                changed = True
            elif dest_agents[key] != value:
                print(f"  skip (differs): agent.{key}", file=sys.stderr)
        if changed:
            write(dest_path, dest)
        print("merged" if changed else "already-merged")
        return
    if operation == "opencode-only":
        # Legacy installs had no ownership marker. Only exact content equality is
        # safe evidence that deleting the destination cannot lose a user edit.
        print("yes" if load(sys.argv[2]) == load(sys.argv[3]) else "no")
        return
    raise SystemExit(f"unknown JSON lifecycle operation: {operation}")


if __name__ == "__main__":
    main()

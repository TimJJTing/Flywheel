#!/usr/bin/env python3
"""Compact activity.json / spawns.json: squash all but the newest KEEP entries into
one summary entry. Full history stays recoverable via git history of the ledger file.
Milestone commit hashes (referenced by projects.json) are preserved in the summary.
Usage: python3 flywheel/compact.py [--keep N]"""
import argparse
import json
import os

STATE = os.path.join(os.path.dirname(os.path.abspath(__file__)), "state")


def load(name):
    with open(os.path.join(STATE, name), encoding="utf-8") as f:
        return json.load(f)


def save(name, data):
    with open(os.path.join(STATE, name), "w", encoding="utf-8") as f:
        json.dump(data, f, indent=2, ensure_ascii=False)
        f.write("\n")


def compact(name, keep, milestone_hashes):
    entries = load(name)
    # A prior run's summary (marked by ts_range) stays out of the squash candidates
    # and is merged into the new summary instead — makes reruns idempotent.
    prior = entries[0] if entries and "ts_range" in entries[0] else None
    tail = entries[1:] if prior else entries
    if len(tail) <= keep:
        print(f"✓ {name}: {len(tail)} entries ≤ keep={keep}, nothing to do")
        return
    old, recent = tail[:-keep], tail[-keep:]
    ts = [e.get("ts", "") for e in old if e.get("ts")]
    sessions = len(old)
    hashes = {h for e in old for h in (e.get("commits") or [])} & milestone_hashes
    lo, hi = min(ts, default=""), max(ts, default="")
    if prior:
        sessions += prior.get("sessions", 1)
        plo, phi = (prior.get("ts_range") or ["", ""])[:2]
        lo = min((x for x in (plo, lo) if x), default="")
        hi = max(phi, hi)
        hashes |= set(prior.get("commits") or [])
    text = f"compacted {sessions} entries — full history in git log of this file"
    summary = {
        "ts": hi,
        "ts_range": [lo, hi],
        "sessions": sessions,
        "summary": text,
        "commits": sorted(hashes),
    }
    # Fill required schema fields (SCHEMAS.md) so the dashboard renders cleanly.
    if name == "activity.json":
        summary["session"] = 0
    elif name == "spawns.json":
        summary.update({"agent": "(compacted)", "model": "", "effort": "",
                        "task": text, "outcome": "ok", "notes": ""})
    save(name, [summary] + recent)
    print(f"✓ {name}: {len(entries)} → {keep + 1} entries "
          f"({len(old)} squashed; kept {len(summary['commits'])} milestone hashes)")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--keep", type=int, default=30, help="recent entries to keep (default 30)")
    args = ap.parse_args()
    projects = load("projects.json")
    milestone_hashes = {h for p in projects for h in (p.get("commits") or [])}
    for name in ("activity.json", "spawns.json"):
        compact(name, args.keep, milestone_hashes)
    print("run: bash flywheel/check.sh && rebuild dashboard, then commit the ledgers")


if __name__ == "__main__":
    main()

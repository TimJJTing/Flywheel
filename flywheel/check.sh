#!/usr/bin/env bash
# Mechanical rule-checker for flywheel doc budgets + ledger integrity.
# Run from anywhere: bash flywheel/check.sh
set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FLYWHEEL_DIR="$SCRIPT_DIR"
REPO_ROOT="$(dirname "$FLYWHEEL_DIR")"
FAIL=0

check_budget() {
  local file="$1" limit="$2" path="$FLYWHEEL_DIR/$1" n
  if [ ! -f "$path" ]; then echo "✗ $file: missing"; FAIL=1; return; fi
  n=$(wc -l < "$path" | tr -d ' ')
  if [ "$n" -le "$limit" ]; then echo "✓ $file: $n/$limit lines";
  else echo "✗ $file: $n lines exceeds budget $limit"; FAIL=1; fi
}

check_budget INDEX.md 50
check_budget STATUS.md 40
check_budget ORCHESTRATION.md 120
check_budget AUTONOMY.md 75
check_budget JUDGMENT.md 130
check_budget MAINTENANCE.md 80
check_budget GIT.md 55
check_budget IMPROVE.md 75
check_budget ADAPTERS.md 85
check_budget DIAGNOSIS.md 85
check_budget TEMPLATES.md 230
check_budget FACTS.md 80

if [ -f "$REPO_ROOT/docs/ARCHITECTURE.md" ]; then
  n=$(wc -l < "$REPO_ROOT/docs/ARCHITECTURE.md" | tr -d ' ')
  limit=150
  if [ "$n" -le "$limit" ]; then echo "✓ docs/ARCHITECTURE.md: $n/$limit lines";
  else echo "✗ docs/ARCHITECTURE.md: $n lines exceeds budget $limit"; FAIL=1; fi
else
  echo "✗ docs/ARCHITECTURE.md: missing"; FAIL=1
fi

if [ -f "$FLYWHEEL_DIR/LESSONS.md" ]; then
  n=$(wc -l < "$FLYWHEEL_DIR/LESSONS.md" | tr -d ' ')
  if [ "$n" -gt 80 ]; then echo "⚠ LESSONS.md: $n lines (>80) — consolidation due";
  else echo "✓ LESSONS.md: $n/80 lines"; fi
fi

# Always-loaded set (adapter file + INDEX + ORCHESTRATION + FACTS) ≤ 500 lines.
for adapter_file in CLAUDE.md AGENTS.md; do
  if [ -f "$REPO_ROOT/$adapter_file" ]; then
    total=0
    for f in "$REPO_ROOT/$adapter_file" "$FLYWHEEL_DIR/INDEX.md" \
             "$FLYWHEEL_DIR/ORCHESTRATION.md" "$FLYWHEEL_DIR/FACTS.md"; do
      [ -f "$f" ] && total=$((total + $(wc -l < "$f")))
    done
    if [ "$total" -le 500 ]; then echo "✓ always-loaded set ($adapter_file+INDEX+ORCHESTRATION+FACTS): $total/500 lines";
    else echo "✗ always-loaded set ($adapter_file+INDEX+ORCHESTRATION+FACTS): $total lines exceeds 500"; FAIL=1; fi
  fi
done

# Every flywheel/*.md path referenced in INDEX.md must exist.
missing_refs=0
for ref in $(grep -oE 'flywheel/[A-Za-z0-9_./-]*\.md' "$FLYWHEEL_DIR/INDEX.md" | sort -u); do
  if [ ! -f "$REPO_ROOT/$ref" ]; then
    echo "✗ INDEX.md references missing file: $ref"; FAIL=1; missing_refs=1
  fi
done
[ "$missing_refs" -eq 0 ] && echo "✓ INDEX.md: all referenced .md files exist"

# state/*.json must parse as JSON arrays; collect commit hashes for the git check.
HASHES_FILE=$(mktemp)
JSON_SRC='
import json, sys
state_dir, hashes_file = sys.argv[1], sys.argv[2]
files = ["projects.json", "issues.json", "decisions.json", "activity.json", "spawns.json"]
ok = True
hashes = []
for f in files:
    try:
        data = json.load(open(f"{state_dir}/{f}", encoding="utf-8"))
        if not isinstance(data, list):
            print(f"✗ state/{f}: not a JSON array"); ok = False; continue
        print(f"✓ state/{f}: valid JSON array ({len(data)} entries)")
        if f in ("activity.json", "spawns.json") and len(data) > 100:
            print(f"⚠ state/{f}: {len(data)} entries (>100) — compaction due (python3 flywheel/compact.py)")
        for item in data:
            hashes += item.get("commits") or []
    except Exception as e:
        print(f"✗ state/{f}: invalid JSON ({e})"); ok = False
open(hashes_file, "w").write("\n".join(hashes))
sys.exit(0 if ok else 1)
'
if command -v python3 >/dev/null 2>&1; then
  python3 -c "$JSON_SRC" "$FLYWHEEL_DIR/state" "$HASHES_FILE"
  [ $? -ne 0 ] && FAIL=1
elif command -v node >/dev/null 2>&1; then
  node -e "
const fs=require('fs');
const [stateDir,hashesFile]=process.argv.slice(1);
const files=['projects.json','issues.json','decisions.json','activity.json','spawns.json'];
let ok=true, hashes=[];
for (const f of files) {
  try {
    const data=JSON.parse(fs.readFileSync(stateDir+'/'+f,'utf-8'));
    if (!Array.isArray(data)) { console.log('✗ state/'+f+': not a JSON array'); ok=false; continue; }
    console.log('✓ state/'+f+': valid JSON array ('+data.length+' entries)');
    if ((f==='activity.json'||f==='spawns.json') && data.length>100)
      console.log('⚠ state/'+f+': '+data.length+' entries (>100) — compaction due (python3 flywheel/compact.py)');
    for (const item of data) hashes.push(...(item.commits||[]));
  } catch (e) { console.log('✗ state/'+f+': invalid JSON ('+e.message+')'); ok=false; }
}
fs.writeFileSync(hashesFile, hashes.join('\n'));
process.exit(ok?0:1);
" "$FLYWHEEL_DIR/state" "$HASHES_FILE"
  [ $? -ne 0 ] && FAIL=1
else
  echo "✗ state/*.json: neither python3 nor node available"; FAIL=1; : > "$HASHES_FILE"
fi

if git -C "$REPO_ROOT" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  bad=0
  while IFS= read -r h || [ -n "$h" ]; do
    [ -z "$h" ] && continue
    git -C "$REPO_ROOT" cat-file -e "$h" 2>/dev/null || { echo "✗ commit hash not found: $h"; bad=1; }
  done < "$HASHES_FILE"
  [ "$bad" -eq 0 ] && echo "✓ all ledger commit hashes exist in git history" || FAIL=1

  # Drift (warn-only): recent commits no ledger references — usually a human working
  # outside the framework. Triage at session start: backfill ledgers, note in STATUS.md.
  # The wrapup commit itself can never be in the ledger it writes, so it is skipped.
  drift=$(git -C "$REPO_ROOT" log --format='%h %s' --abbrev=7 -n 100 2>/dev/null | \
    { while IFS=' ' read -r h s; do
        grep -q "^$h" "$HASHES_FILE" && break
        [ "$s" = "chore(flywheel): update state ledgers + dashboard" ] && continue
        echo "$h $s"
      done; })
  if [ -n "$drift" ]; then
    echo "⚠ $(printf '%s\n' "$drift" | wc -l | tr -d ' ') commit(s) untracked by ledgers (human/off-framework work?):"
    printf '%s\n' "$drift" | sed 's/^/    /'
    nc=$(printf '%s\n' "$drift" | grep -cvE '^[0-9a-f]+ (feat|fix|docs|refactor|test|chore|improve)(\(|:)' || true)
    [ "$nc" -gt 0 ] && echo "    ($nc of them off the Conventional Commits scheme — see flywheel/GIT.md)"
  else
    echo "✓ no ledger-untracked commits since last recorded session"
  fi

  # Check if structural files have changed without updating ARCHITECTURE.md
  struct_changes=$(git -C "$REPO_ROOT" status --porcelain 2>/dev/null | grep -E '^( M| A|\?\?) (flywheel/(INDEX|ORCHESTRATION|AUTONOMY|MAINTENANCE|TEMPLATES|FACTS|DIAGNOSIS|JUDGMENT|GIT|IMPROVE|ADAPTERS)\.md|flywheel/check\.sh|flywheel/wrapup\.sh|flywheel/config\.json|\.agents/|\.claude/|\.codex/)' || true)
  if [ -n "$struct_changes" ]; then
    arch_changed=$(git -C "$REPO_ROOT" status --porcelain docs/ARCHITECTURE.md 2>/dev/null)
    if [ -z "$arch_changed" ]; then
      echo "⚠ Structural changes detected in:"
      printf '%s\n' "$struct_changes" | cut -c4- | sed 's/^/    /'
      echo "  but docs/ARCHITECTURE.md was not updated. Please review if the architecture needs updating or run gen_architecture.py."
    fi
  fi
else
  echo "⚠ not a git repo — skipping commit hash check"
fi
rm -f "$HASHES_FILE"

# Agent frontmatter (model/effort) vs config.json, only if .claude/agents/ exists.
AGENTS_DIR="$REPO_ROOT/.claude/agents"
if [ -d "$AGENTS_DIR" ] && command -v python3 >/dev/null 2>&1; then
  python3 -c '
import json, re, os, sys
agents_dir, config_path = sys.argv[1], sys.argv[2]
tiers = json.load(open(config_path, encoding="utf-8")).get("tiers", {})

# Regression guard: warn (never fail) on any tier x adapter cell that is still
# the "Pending verification" placeholder, or missing outright. Covers all three
# adapters (claude-code, codex, opencode) even though only claude-code gets the
# per-file frontmatter check below (the other two have no per-agent files to check).
TIER_NAMES = ["architect", "strategist", "engineer", "utility", "verifier", "auditor"]
ADAPTER_NAMES = ["claude-code", "codex", "opencode", "antigravity"]
unset_found = False
for tier_name in TIER_NAMES:
    tier_adapters = tiers.get(tier_name, {}).get("adapters", {})
    for adapter_name in ADAPTER_NAMES:
        cell = tier_adapters.get(adapter_name)
        if cell is None or any(v == "Pending verification" for v in cell.values()):
            print(f"⚠ config.json tiers.{tier_name}.adapters.{adapter_name} still unset (Pending verification)")
            unset_found = True
if not unset_found:
    print("✓ all tier×adapter models set")

mapping = {"architect": "architect", "researcher": "strategist", "engineer": "engineer",
           "utility": "utility", "verifier": "verifier", "plan-auditor": "auditor"}
ok = True
for agent, tier_key in mapping.items():
    path = os.path.join(agents_dir, agent + ".md")
    if not os.path.isfile(path):
        continue
    text = open(path, encoding="utf-8").read()
    fm = text.split("---")[1] if text.startswith("---") else ""
    m_model = re.search(r"^model:\s*(\S+)", fm, re.M)
    # frontmatter native key is "effort" (see plan section 0 boundary); config key is "level".
    m_effort = re.search(r"^effort:\s*(\S+)", fm, re.M)
    expect = tiers.get(tier_key, {}).get("adapters", {}).get("claude-code", {})
    exp_model, exp_level = expect.get("model"), expect.get("level")
    if exp_model == "Pending verification":
        print(f"⚠ {agent}.md frontmatter check skipped (config model still Pending verification)")
        continue
    got_model = m_model.group(1) if m_model else None
    got_effort = m_effort.group(1) if m_effort else None
    if got_model != exp_model or got_effort != exp_level:
        print(f"✗ {agent}.md frontmatter ({got_model}/{got_effort}) != config.json {tier_key} ({exp_model}/{exp_level})")
        ok = False
    else:
        print(f"✓ {agent}.md frontmatter matches config.json")
if not ok:
    print("  → config.json is source of truth; run: python3 flywheel/sync.py")
sys.exit(0 if ok else 1)
' "$AGENTS_DIR" "$FLYWHEEL_DIR/config.json"
  [ $? -ne 0 ] && FAIL=1
fi

# Codex agent TOML (model/model_reasoning_effort) vs config.json, only if
# .codex/agents/ exists.
CODEX_AGENTS_DIR="$REPO_ROOT/.codex/agents"
if [ -d "$CODEX_AGENTS_DIR" ] && command -v python3 >/dev/null 2>&1; then
  python3 -c '
import json, re, os, sys
agents_dir, config_path = sys.argv[1], sys.argv[2]
tiers = json.load(open(config_path, encoding="utf-8")).get("tiers", {})

mapping = {"architect": "architect", "researcher": "strategist", "engineer": "engineer",
           "utility": "utility", "verifier": "verifier", "plan-auditor": "auditor"}
ok = True
for agent, tier_key in mapping.items():
    path = os.path.join(agents_dir, agent + ".toml")
    if not os.path.isfile(path):
        continue
    text = open(path, encoding="utf-8").read()
    m_model = re.search(r"^model\s*=\s*\"([^\"]*)\"", text, re.M)
    m_effort = re.search(r"^model_reasoning_effort\s*=\s*\"([^\"]*)\"", text, re.M)
    expect = tiers.get(tier_key, {}).get("adapters", {}).get("codex", {})
    exp_model, exp_level = expect.get("model"), expect.get("level")
    if exp_model == "Pending verification":
        print(f"⚠ {agent}.toml frontmatter check skipped (config model still Pending verification)")
        continue
    got_model = m_model.group(1) if m_model else None
    got_effort = m_effort.group(1) if m_effort else None
    if got_model != exp_model or got_effort != exp_level:
        print(f"✗ {agent}.toml frontmatter ({got_model}/{got_effort}) != config.json {tier_key} ({exp_model}/{exp_level})")
        ok = False
    else:
        print(f"✓ {agent}.toml frontmatter matches config.json")
if not ok:
    print("  → config.json is source of truth; edit .codex/agents/*.toml to match")
sys.exit(0 if ok else 1)
' "$CODEX_AGENTS_DIR" "$FLYWHEEL_DIR/config.json"
  [ $? -ne 0 ] && FAIL=1
fi

# --- dashboard builder parity (i10): build.py and build.mjs must emit the ---
# same dashboard.html for the same state. Builds into temp copies; restores
# whatever was at dashboard.html before this check ran (it's gitignored, but
# don't clobber a developer's local build regardless).
DASH_DIR="$FLYWHEEL_DIR/dashboard"
DASH_OUT="$DASH_DIR/dashboard.html"
if command -v python3 >/dev/null 2>&1 && command -v node >/dev/null 2>&1; then
  DASH_BACKUP=""
  [ -f "$DASH_OUT" ] && { DASH_BACKUP=$(mktemp); cp "$DASH_OUT" "$DASH_BACKUP"; }
  PY_OUT=$(mktemp)
  JS_OUT=$(mktemp)
  FLYWHEEL_BUILD_TS="1970-01-01T00:00" python3 "$DASH_DIR/build.py" >/dev/null 2>&1
  py_rc=$?
  [ "$py_rc" -eq 0 ] && cp "$DASH_OUT" "$PY_OUT"
  FLYWHEEL_BUILD_TS="1970-01-01T00:00" node "$DASH_DIR/build.mjs" >/dev/null 2>&1
  js_rc=$?
  [ "$js_rc" -eq 0 ] && cp "$DASH_OUT" "$JS_OUT"
  if [ -n "$DASH_BACKUP" ]; then cp "$DASH_BACKUP" "$DASH_OUT"; rm -f "$DASH_BACKUP";
  else rm -f "$DASH_OUT"; fi
  if [ "$py_rc" -ne 0 ] || [ "$js_rc" -ne 0 ]; then
    echo "✗ dashboard build.py/build.mjs parity: one or both builds failed (py=$py_rc js=$js_rc)"
    FAIL=1
  elif diff -q "$PY_OUT" "$JS_OUT" >/dev/null 2>&1; then
    echo "✓ dashboard build.py/build.mjs parity: identical output"
  else
    echo "✗ dashboard build.py/build.mjs parity: outputs differ — keep build.py and build.mjs in sync"
    FAIL=1
  fi
  rm -f "$PY_OUT" "$JS_OUT"
else
  echo "⚠ dashboard build.py/build.mjs parity check skipped (python3 and/or node not both available)"
fi

# opencode agent model pinning (i12) vs config.json. opencode has no per-repo
# "installed" agent dir here (no .opencode/); the source of truth that ships
# to every install is adapters/opencode/opencode.json.merge, so check that.
OPENCODE_MERGE="$REPO_ROOT/adapters/opencode/opencode.json.merge"
if [ -f "$OPENCODE_MERGE" ] && command -v python3 >/dev/null 2>&1; then
  python3 -c '
import json, sys
merge_path, config_path = sys.argv[1], sys.argv[2]
tiers = json.load(open(config_path, encoding="utf-8")).get("tiers", {})
agents = json.load(open(merge_path, encoding="utf-8")).get("agent", {})
ok = True
for tier_key, agent in agents.items():
    expect = tiers.get(tier_key, {}).get("adapters", {}).get("opencode", {})
    exp_provider, exp_model = expect.get("provider"), expect.get("model")
    if exp_model == "Pending verification":
        print(f"⚠ opencode.json.merge[{tier_key}] check skipped (config model still Pending verification)")
        continue
    exp = f"{exp_provider}/{exp_model}" if exp_provider else exp_model
    got = agent.get("model")
    if got != exp:
        print(f"✗ opencode.json.merge[{tier_key}] model ({got}) != config.json {tier_key} ({exp})")
        ok = False
    else:
        print(f"✓ opencode.json.merge[{tier_key}] model matches config.json")
if not ok:
    print("  → config.json is source of truth; edit adapters/opencode/opencode.json.merge to match")
sys.exit(0 if ok else 1)
' "$OPENCODE_MERGE" "$FLYWHEEL_DIR/config.json"
  [ $? -ne 0 ] && FAIL=1
else
  echo "⚠ opencode.json.merge drift check skipped (python3 not available)"
fi

# antigravity (i12): adapters/antigravity/agents/*/agent.json carry no model or
# level field at all — verified (FACTS.md, 2026-07-12): Antigravity subagents
# inherit the parent session's model and cannot be routed to a different one.
# There is nothing per-agent here that could drift from config.json, so this
# adapter is exempt from the drift check by design, not by oversight.

# --- resolve-spawn.py presence guard ----------------------------------------
# Every adapter hook file that references resolve-spawn.py must find it at
# flywheel/resolve-spawn.py, or spawn auto-logging silently no-ops (see
# docs/plans/architecture-audit-2026-07.md Plan 2, Finding A).
RESOLVE_SPAWN_REFERENCED=0
for hook_file in "$REPO_ROOT/.codex/hooks.json" "$REPO_ROOT/.agents/hooks.json" "$REPO_ROOT/.claude/settings.json"; do
  if [ -f "$hook_file" ] && grep -q "resolve-spawn.py" "$hook_file"; then
    RESOLVE_SPAWN_REFERENCED=1
  fi
done
if [ "$RESOLVE_SPAWN_REFERENCED" -eq 1 ]; then
  if [ -f "$FLYWHEEL_DIR/resolve-spawn.py" ]; then
    echo "✓ flywheel/resolve-spawn.py present (referenced by an installed hook)"
  else
    echo "✗ flywheel/resolve-spawn.py missing but referenced by an installed hook — run: bash install.sh . (or) restore the file"
    FAIL=1
  fi
fi

if [ "$FAIL" -eq 0 ]; then echo "✓ all checks passed"; exit 0;
else echo "✗ one or more checks failed"; exit 1; fi

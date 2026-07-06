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
check_budget STATUS.md 60
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

if [ -f "$FLYWHEEL_DIR/LESSONS.md" ]; then
  n=$(wc -l < "$FLYWHEEL_DIR/LESSONS.md" | tr -d ' ')
  if [ "$n" -gt 80 ]; then echo "⚠ LESSONS.md: $n lines (>80) — consolidation due";
  else echo "✓ LESSONS.md: $n/80 lines"; fi
fi

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
  while IFS= read -r h; do
    [ -z "$h" ] && continue
    git -C "$REPO_ROOT" cat-file -e "$h" 2>/dev/null || { echo "✗ commit hash not found: $h"; bad=1; }
  done < "$HASHES_FILE"
  [ "$bad" -eq 0 ] && echo "✓ all ledger commit hashes exist in git history" || FAIL=1
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
    m_effort = re.search(r"^effort:\s*(\S+)", fm, re.M)
    expect = tiers.get(tier_key, {}).get("harnesses", {}).get("claude-code", {})
    exp_model, exp_effort = expect.get("model"), expect.get("effort")
    if exp_model == "Pending verification":
        continue
    got_model = m_model.group(1) if m_model else None
    got_effort = m_effort.group(1) if m_effort else None
    if got_model != exp_model or got_effort != exp_effort:
        print(f"✗ {agent}.md frontmatter ({got_model}/{got_effort}) != config.json {tier_key} ({exp_model}/{exp_effort})")
        ok = False
    else:
        print(f"✓ {agent}.md frontmatter matches config.json")
sys.exit(0 if ok else 1)
' "$AGENTS_DIR" "$FLYWHEEL_DIR/config.json"
  [ $? -ne 0 ] && FAIL=1
fi

if [ "$FAIL" -eq 0 ]; then echo "✓ all checks passed"; exit 0;
else echo "✗ one or more checks failed"; exit 1; fi

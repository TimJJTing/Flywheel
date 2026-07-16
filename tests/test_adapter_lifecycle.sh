#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMPROOT="$(mktemp -d)"
trap 'rm -rf "$TMPROOT"' EXIT

fail() { echo "FAIL: $*" >&2; exit 1; }
assert_file() { [ -f "$1" ] || fail "missing file: $1"; }
assert_no_file() { [ ! -e "$1" ] || fail "unexpected file: $1"; }
assert_eq() { [ "$1" = "$2" ] || fail "expected '$1' == '$2' ($3)"; }

json_count_hooks() {
  python3 - "$1" <<'PY'
import json, sys
data = json.load(open(sys.argv[1], encoding="utf-8"))
count = 0
for groups in data.get("hooks", {}).values():
    for group in groups:
        for hook in group.get("hooks", []):
            if hook.get("command", "").startswith("python3 flywheel/resolve-spawn.py"):
                count += 1
print(count)
PY
}

new_repo() {
  local d="$TMPROOT/$1"
  mkdir -p "$d"
  git -C "$d" init -q
  printf '%s\n' "$d"
}

run_install() {
  local runner="$1" target="$2" adapters="$3"
  FLYWHEEL_RUNNER="$runner" bash "$ROOT/install.sh" "$target" --adapters "$adapters" >/dev/null
}

run_uninstall() {
  local runner="$1" target="$2"
  FLYWHEEL_RUNNER="$runner" bash "$ROOT/uninstall.sh" "$target" --yes >/dev/null
}

exercise_runner() {
  local runner="$1"
  if ! command -v "$runner" >/dev/null 2>&1; then
    echo "SKIP $runner runner not available"
    return 0
  fi

  local t
  t="$(new_repo "clean-$runner")"
  run_install "$runner" "$t" codex
  assert_file "$t/AGENTS.md"
  assert_eq "$(find "$t/.codex/agents" -name '*.toml' | wc -l | tr -d ' ')" "6" "six Codex agents"
  assert_eq "$(find "$t/.agents/skills" -name SKILL.md | wc -l | tr -d ' ')" "3" "three shared skills"
  [ ! -d "$t/.codex/skills" ] || fail "legacy .codex/skills created"
  assert_file "$t/.codex/hooks.json"
  assert_file "$t/.codex/hooks.json.flywheel-created"
  assert_no_file "$t/.codex/hooks.json.flywheel-bak"
  python3 -m json.tool "$t/.codex/hooks.json" >/dev/null
  ! grep -R "docs/plans/codex-adapter-dogfood.md\\|docs/research/codex-hooks.md" "$t/flywheel/ADAPTERS.md" >/dev/null
  run_install "$runner" "$t" codex
  assert_no_file "$t/.codex/hooks.json.flywheel-bak"
  assert_eq "$(json_count_hooks "$t/.codex/hooks.json")" "1" "reinstall hook count"
  run_uninstall "$runner" "$t"
  assert_no_file "$t/.codex/hooks.json"
  assert_no_file "$t/.agents/skills/delegate/SKILL.md"

  t="$(new_repo "merge-$runner")"
  mkdir -p "$t/.codex"
  printf '{"hooks":{"Stop":[{"matcher":"*","hooks":[{"type":"command","command":"echo user"}]}]}}\n' > "$t/.codex/hooks.json"
  cp "$t/.codex/hooks.json" "$t/original-hooks.json"
  run_install "$runner" "$t" codex
  assert_file "$t/.codex/hooks.json.flywheel-bak"
  assert_file "$t/.codex/hooks.json.flywheel-merged"
  assert_eq "$(json_count_hooks "$t/.codex/hooks.json")" "1" "merged hook count"
  python3 - "$t/.codex/hooks.json" <<'PY'
import json, sys
data = json.load(open(sys.argv[1], encoding="utf-8"))
assert "Stop" in data["hooks"]
assert "SubagentStop" in data["hooks"]
PY
  run_install "$runner" "$t" codex
  assert_eq "$(json_count_hooks "$t/.codex/hooks.json")" "1" "merged hook idempotency"
  python3 - "$t/.codex/hooks.json" <<'PY'
import json, sys
path = sys.argv[1]
data = json.load(open(path, encoding="utf-8"))
data["hooks"]["SessionStart"] = [{"matcher":"startup","hooks":[{"type":"command","command":"echo later"}]}]
open(path, "w", encoding="utf-8").write(json.dumps(data, indent=2) + "\n")
PY
  run_uninstall "$runner" "$t"
  cmp -s "$t/.codex/hooks.json" "$t/original-hooks.json" || fail "backup not restored"
  assert_file "$t/.codex/hooks.json.flywheel-uninstalled"
  ! find "$t" \( -name '*.flywheel-created' -o -name '*.flywheel-bak' -o -name '*.flywheel-merged' \) -print | grep . >/dev/null

  t="$(new_repo "malformed-$runner")"
  mkdir -p "$t/.codex"
  printf '{not json\n' > "$t/.codex/hooks.json"
  run_install "$runner" "$t" codex 2>/dev/null || fail "malformed install failed"
  assert_eq "$(cat "$t/.codex/hooks.json")" "{not json" "malformed left byte-identical except trailing trim"
  assert_no_file "$t/.codex/hooks.json.flywheel-bak"
  assert_no_file "$t/.codex/hooks.json.flywheel-created"

  t="$(new_repo "legacy-$runner")"
  mkdir -p "$t/.codex/skills/delegate" "$t/.codex/skills/wrapup" "$t/.codex/skills/improve"
  cp "$ROOT/adapters/codex/skills/delegate/SKILL.md" "$t/.codex/skills/delegate/SKILL.md"
  printf 'user skill\n' > "$t/.codex/skills/wrapup/SKILL.md"
  run_install "$runner" "$t" codex
  assert_no_file "$t/.codex/skills/delegate/SKILL.md"
  assert_file "$t/.codex/skills/wrapup/SKILL.md"
  assert_file "$t/.agents/skills/delegate/SKILL.md"

  t="$(new_repo "combo-$runner")"
  run_install "$runner" "$t" codex
  run_install "$runner" "$t" antigravity
  for s in delegate improve wrapup; do
    cmp -s "$ROOT/adapters/codex/skills/$s/SKILL.md" "$ROOT/adapters/antigravity/skills/$s/SKILL.md" || fail "source skill mismatch $s"
    cmp -s "$ROOT/adapters/codex/skills/$s/SKILL.md" "$t/.agents/skills/$s/SKILL.md" || fail "installed skill mismatch $s"
  done
  run_uninstall "$runner" "$t"
  assert_no_file "$t/.agents/skills/delegate/SKILL.md"

  t="$(new_repo "sync-$runner")"
  run_install "$runner" "$t" codex
  python3 - "$t/flywheel/config.json" <<'PY'
import json, sys
path = sys.argv[1]
data = json.load(open(path, encoding="utf-8"))
data["tiers"]["engineer"]["adapters"]["codex"]["model"] = "local-engineer-model"
data["tiers"]["engineer"]["adapters"]["codex"]["level"] = "low"
data["tiers"]["utility"]["adapters"]["codex"]["model"] = "Pending verification"
open(path, "w", encoding="utf-8").write(json.dumps(data, indent=2) + "\n")
PY
  before_utility="$(grep '^model = ' "$t/.codex/agents/utility.toml")"
  (cd "$t" && python3 flywheel/sync.py >/tmp/flywheel-sync-"$runner".log)
  grep -q 'model = "local-engineer-model"' "$t/.codex/agents/engineer.toml"
  grep -q 'model_reasoning_effort = "low"' "$t/.codex/agents/engineer.toml"
  after_utility="$(grep '^model = ' "$t/.codex/agents/utility.toml")"
  assert_eq "$before_utility" "$after_utility" "pending utility untouched"
  (cd "$t" && python3 flywheel/sync.py >/tmp/flywheel-sync-"$runner"-2.log)
  ! git -C "$t" diff -- .codex/agents >/dev/null || true

  echo "PASS lifecycle runner=$runner"
}

exercise_runner python3
exercise_runner node

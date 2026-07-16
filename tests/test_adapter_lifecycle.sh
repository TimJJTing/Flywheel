#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMPROOT="$(mktemp -d)"
HOST_PYTHON="$(command -v python3)"
NODE_PATH="$TMPROOT/node-path"
trap 'rm -rf "$TMPROOT"' EXIT

fail() { echo "FAIL: $*" >&2; exit 1; }
assert_file() { [ -f "$1" ] || fail "missing file: $1"; }
assert_no_file() { [ ! -e "$1" ] || fail "unexpected file: $1"; }
assert_eq() { [ "$1" = "$2" ] || fail "expected '$1' == '$2' ($3)"; }

mkdir -p "$NODE_PATH"
for command_name in bash node git dirname mkdir cp ls rm grep rmdir basename mv wc tr; do
  command_path="$(command -v "$command_name" || true)"
  [ -n "$command_path" ] && ln -s "$command_path" "$NODE_PATH/$command_name"
done

new_repo() {
  local d="$TMPROOT/$1"
  mkdir -p "$d"
  git -C "$d" init -q
  printf '%s\n' "$d"
}

run_install() {
  local runner="$1" target="$2" adapters="$3" log="${4:-$TMPROOT/install.log}"
  if [ "$runner" = node ]; then
    PATH="$NODE_PATH" FLYWHEEL_RUNNER=node "$NODE_PATH/bash" "$ROOT/install.sh" "$target" --adapters "$adapters" >"$log" 2>&1
  else
    FLYWHEEL_RUNNER=python3 bash "$ROOT/install.sh" "$target" --adapters "$adapters" >"$log" 2>&1
  fi
}

run_uninstall() {
  local runner="$1" target="$2" log="${3:-$TMPROOT/uninstall.log}"
  if [ "$runner" = node ]; then
    PATH="$NODE_PATH" FLYWHEEL_RUNNER=node "$NODE_PATH/bash" "$ROOT/uninstall.sh" "$target" --yes >"$log" 2>&1
  else
    FLYWHEEL_RUNNER=python3 bash "$ROOT/uninstall.sh" "$target" --yes >"$log" 2>&1
  fi
}

json_hook_count() {
  "$HOST_PYTHON" - "$1" <<'PY'
import json, sys
commands = {'python3 "$(git rev-parse --show-toplevel)/flywheel/resolve-spawn.py" codex'}
def count(v):
    if isinstance(v, dict): return (1 if v.get("command") in commands else 0) + sum(count(x) for x in v.values())
    if isinstance(v, list): return sum(count(x) for x in v)
    return 0
print(count(json.load(open(sys.argv[1], encoding="utf-8"))))
PY
}

assert_no_managed_sidecars() {
  local t="$1" f suffix
  for f in "$t/.codex/hooks.json" "$t/.agents/hooks.json" "$t/.claude/settings.json" "$t/opencode.json"; do
    for suffix in .flywheel-created .flywheel-bak .flywheel-merged; do
      [ ! -e "$f$suffix" ] || fail "stale managed sidecar: $f$suffix"
    done
  done
}

assert_no_flywheel_commands() {
  local t="$1"
  "$HOST_PYTHON" - "$t" <<'PY'
import json, pathlib, sys
commands = {"python3 flywheel/resolve-spawn.py", "python3 flywheel/resolve-spawn.py codex", 'python3 "$(git rev-parse --show-toplevel)/flywheel/resolve-spawn.py" codex', "python3 flywheel/resolve-spawn.py antigravity"}
def found(v):
    if isinstance(v, dict): return v.get("command") in commands or any(found(x) for x in v.values())
    if isinstance(v, list): return any(found(x) for x in v)
    return False
for rel in (".codex/hooks.json", ".agents/hooks.json", ".claude/settings.json"):
    p = pathlib.Path(sys.argv[1], rel)
    if p.is_file():
        try: data = json.loads(p.read_text())
        except json.JSONDecodeError: continue
        assert not found(data), rel
PY
}

exercise_runner() {
  local runner="$1" t before after tree_before tree_after warning
  if ! command -v "$runner" >/dev/null 2>&1; then
    echo "SKIP lifecycle runner=$runner unavailable"
    return
  fi

  # 1,4,5: clean layout, exact managed block, idempotent reinstall, one/two uninstall.
  t="$(new_repo "clean-$runner")"
  run_install "$runner" "$t" codex
  cmp -s "$ROOT/adapters/codex/AGENTS.md.block" "$t/AGENTS.md" || fail "managed block differs"
  assert_eq "$(find "$t/.codex/agents" -name '*.toml' | wc -l | tr -d ' ')" 6 "six agents"
  assert_eq "$(find "$t/.agents/skills" -name SKILL.md | wc -l | tr -d ' ')" 3 "three skills"
  assert_eq "$(json_hook_count "$t/.codex/hooks.json")" 1 "one Codex hook"
  assert_file "$t/.codex/hooks.json.flywheel-created"
  assert_no_file "$t/.codex/hooks.json.flywheel-bak"
  [ ! -d "$t/.codex/skills" ] || fail "legacy skill directory created"
  ! rg -n 'docs/(plans/codex-adapter-dogfood|research/codex-hooks)\.md' "$t/flywheel/ADAPTERS.md" >/dev/null || fail "installed doc has repo-only reference"
  tree_before="$(find "$t/.codex" "$t/.agents/skills" -type f -exec shasum {} \; | sort)"
  run_install "$runner" "$t" codex
  tree_after="$(find "$t/.codex" "$t/.agents/skills" -type f -exec shasum {} \; | sort)"
  assert_eq "$tree_before" "$tree_after" "reinstall byte-idempotency"
  assert_no_file "$t/.codex/hooks.json.flywheel-bak"
  run_uninstall "$runner" "$t"
  assert_no_file "$t/.codex/hooks.json"
  assert_no_file "$t/.agents/skills/delegate/SKILL.md"
  assert_no_managed_sidecars "$t"
  assert_no_flywheel_commands "$t"

  t="$(new_repo "one-$runner")"
  run_install "$runner" "$t" codex
  printf 'unrelated user backup\n' > "$t/notes.flywheel-bak"
  "$HOST_PYTHON" - "$t/.codex/hooks.json" <<'PY'
import json, sys
p=sys.argv[1]; d=json.load(open(p)); d["hooks"]["Stop"]=[{"matcher":"*","hooks":[{"type":"command","command":"echo keep"}]}]
open(p,"w").write(json.dumps(d,indent=2)+"\n")
PY
  run_uninstall "$runner" "$t"
  grep -q 'echo keep' "$t/.codex/hooks.json" || fail "created-file user addition lost"
  assert_file "$t/notes.flywheel-bak"
  assert_no_managed_sidecars "$t"
  assert_no_flywheel_commands "$t"

  t="$(new_repo "corrupt-after-install-$runner")"
  run_install "$runner" "$t" codex
  "$HOST_PYTHON" - "$t/.codex/hooks.json" <<'PY'
import pathlib, sys
p=pathlib.Path(sys.argv[1]); data=p.read_bytes(); last=data.rfind(b"}")
assert last >= 0 and b'python3 \\"$(git rev-parse --show-toplevel)/flywheel/resolve-spawn.py\\" codex' in data
p.write_bytes(data[:last] + data[last + 1:] + b"user-malformed-tail\n")
PY
  cp "$t/.codex/hooks.json" "$t/expected-malformed-recovery"
  run_uninstall "$runner" "$t" "$TMPROOT/corrupt-uninstall-$runner.log"
  assert_no_file "$t/.codex/hooks.json"
  assert_file "$t/.codex/hooks.json.flywheel-uninstalled"
  cmp -s "$t/expected-malformed-recovery" "$t/.codex/hooks.json.flywheel-uninstalled" || fail "malformed recovery bytes changed"
  grep -q 'removed from the active path' "$TMPROOT/corrupt-uninstall-$runner.log" || fail "malformed quarantine warning missing"
  grep -q 'git rev-parse --show-toplevel' "$t/.codex/hooks.json.flywheel-uninstalled" || fail "reproducer did not retain command in recovery artifact"
  assert_no_managed_sidecars "$t"
  assert_no_flywheel_commands "$t"

  # 2,6: valid pre-existing JSON, exact backup/snapshot, reinstall, edit preservation.
  t="$(new_repo "merge-$runner")"
  mkdir -p "$t/.codex"
  printf '{"hooks":{"Stop":[{"matcher":"*","hooks":[{"type":"command","command":"echo user"}]}]}}\n' > "$t/.codex/hooks.json"
  cp "$t/.codex/hooks.json" "$t/original-hooks.json"
  run_install "$runner" "$t" codex
  cmp -s "$t/original-hooks.json" "$t/.codex/hooks.json.flywheel-bak" || fail "backup bytes differ"
  cmp -s "$t/.codex/hooks.json" "$t/.codex/hooks.json.flywheel-merged" || fail "snapshot bytes differ"
  assert_eq "$(json_hook_count "$t/.codex/hooks.json")" 1 "merged hook"
  run_install "$runner" "$t" codex
  cmp -s "$t/original-hooks.json" "$t/.codex/hooks.json.flywheel-bak" || fail "backup refreshed on reinstall"
  "$HOST_PYTHON" - "$t/.codex/hooks.json" <<'PY'
import json, sys
p=sys.argv[1]; d=json.load(open(p)); d["hooks"]["SessionStart"]=[{"matcher":"startup","hooks":[{"type":"command","command":"echo later"}]}]
open(p,"w").write(json.dumps(d,indent=2)+"\n")
PY
  run_uninstall "$runner" "$t"
  cmp -s "$t/.codex/hooks.json" "$t/original-hooks.json" || fail "original not restored"
  assert_file "$t/.codex/hooks.json.flywheel-uninstalled"
  grep -q 'echo later' "$t/.codex/hooks.json.flywheel-uninstalled" || fail "edit not preserved"
  assert_no_managed_sidecars "$t"
  assert_no_flywheel_commands "$t"

  # Legacy unmarked Flywheel-only JSON is claimed without backup; ambiguous legacy
  # content is backed up but exact-command-cleaned on uninstall.
  t="$(new_repo "legacy-json-$runner")"
  mkdir -p "$t/.codex"
  "$HOST_PYTHON" - "$ROOT/adapters/codex/hooks.json.merge" "$t/.codex/hooks.json" <<'PY'
import json, sys
def reversed_keys(v):
    if isinstance(v, dict): return {k: reversed_keys(v[k]) for k in reversed(list(v))}
    if isinstance(v, list): return [reversed_keys(x) for x in v]
    return v
d=reversed_keys(json.load(open(sys.argv[1])))
open(sys.argv[2],"w").write(json.dumps(d,indent=2)+"\n")
PY
  run_install "$runner" "$t" codex
  assert_file "$t/.codex/hooks.json.flywheel-created"
  assert_no_file "$t/.codex/hooks.json.flywheel-bak"
  run_uninstall "$runner" "$t"
  assert_no_file "$t/.codex/hooks.json"

  t="$(new_repo "ambiguous-json-$runner")"
  mkdir -p "$t/.codex"
  "$HOST_PYTHON" - "$ROOT/adapters/codex/hooks.json.merge" "$t/.codex/hooks.json" <<'PY'
import json, sys
d=json.load(open(sys.argv[1])); d["hooks"]["Stop"]=[{"matcher":"*","hooks":[{"type":"command","command":"echo keep"}]}]
open(sys.argv[2],"w").write(json.dumps(d,indent=2)+"\n")
PY
  run_install "$runner" "$t" codex
  assert_file "$t/.codex/hooks.json.flywheel-bak"
  run_uninstall "$runner" "$t"
  grep -q 'echo keep' "$t/.codex/hooks.json" || fail "ambiguous legacy user addition lost"
  assert_no_flywheel_commands "$t"

  # 3: malformed input is byte-identical, warns, and never gains sidecars.
  t="$(new_repo "malformed-$runner")"
  mkdir -p "$t/.codex"
  printf '{not json\n\n' > "$t/.codex/hooks.json"
  cp "$t/.codex/hooks.json" "$t/original-malformed"
  warning="$TMPROOT/malformed-$runner.log"
  run_install "$runner" "$t" codex "$warning"
  cmp -s "$t/.codex/hooks.json" "$t/original-malformed" || fail "malformed JSON bytes changed"
  grep -q 'not valid JSON' "$warning" || fail "malformed warning missing"
  assert_no_file "$t/.codex/hooks.json.flywheel-bak"
  assert_no_file "$t/.codex/hooks.json.flywheel-created"
  assert_no_file "$t/.codex/hooks.json.flywheel-merged"
  run_uninstall "$runner" "$t"
  cmp -s "$t/.codex/hooks.json" "$t/original-malformed" || fail "malformed uninstall changed user file"

  # 5,7: unmanaged collision safety and legacy managed migration contract.
  t="$(new_repo "skills-$runner")"
  mkdir -p "$t/.agents/skills/delegate" "$t/.codex/skills/delegate" "$t/.codex/skills/improve" "$t/.codex/skills/wrapup"
  printf 'user destination\n' > "$t/.agents/skills/delegate/SKILL.md"
  for s in delegate improve wrapup; do cp "$ROOT/adapters/codex/skills/$s/SKILL.md" "$t/.codex/skills/$s/SKILL.md"; done
  printf 'user legacy\n' > "$t/.codex/skills/wrapup/SKILL.md"
  run_install "$runner" "$t" codex
  grep -q 'user destination' "$t/.agents/skills/delegate/SKILL.md" || fail "unmanaged destination overwritten"
  assert_file "$t/.codex/skills/delegate/SKILL.md"
  assert_no_file "$t/.codex/skills/improve/SKILL.md"
  grep -q 'user legacy' "$t/.codex/skills/wrapup/SKILL.md" || fail "unmanaged legacy removed"
  run_uninstall "$runner" "$t"
  grep -q 'user destination' "$t/.agents/skills/delegate/SKILL.md" || fail "unmanaged shared skill removed"

  # 10: both shared-skill orders, reinstalls, and Claude/OpenCode combinations.
  for order in codex-antigravity antigravity-codex; do
    t="$(new_repo "$order-$runner")"
    run_install "$runner" "$t" "${order%-*}"
    run_install "$runner" "$t" "${order#*-}"
    run_install "$runner" "$t" "${order%-*}"
    run_install "$runner" "$t" "${order#*-}"
    for s in delegate improve wrapup; do
      cmp -s "$ROOT/adapters/codex/skills/$s/SKILL.md" "$ROOT/adapters/antigravity/skills/$s/SKILL.md" || fail "source skill mismatch $s"
      cmp -s "$ROOT/adapters/codex/skills/$s/SKILL.md" "$t/.agents/skills/$s/SKILL.md" || fail "installed skill mismatch $s/$order"
    done
    run_uninstall "$runner" "$t"
    assert_no_managed_sidecars "$t"
    assert_no_flywheel_commands "$t"
  done
  # Characterization matrix for the three auto-logging adapters: each adapter,
  # each relevant pair, and all together. Every case installs, reinstalls, and
  # uninstalls under both JSON runners.
  for adapters in claude-code antigravity claude-code,antigravity codex,claude-code codex,antigravity codex,claude-code,antigravity codex,opencode codex,claude-code,opencode,antigravity; do
    t="$(new_repo "combo-${adapters//,/-}-$runner")"
    run_install "$runner" "$t" "$adapters"
    run_install "$runner" "$t" "$adapters"
    case ",$adapters," in *,codex,*) assert_file "$t/.codex/hooks.json";; esac
    case ",$adapters," in *,claude-code,*) assert_file "$t/.claude/settings.json";; esac
    case ",$adapters," in *,antigravity,*) assert_file "$t/.agents/hooks.json";; esac
    case "$adapters" in *opencode*) cmp -s "$ROOT/adapters/opencode/AGENTS.md.block" "$t/AGENTS.md" || fail "OpenCode AGENTS precedence missing";; esac
    run_uninstall "$runner" "$t"
    assert_no_managed_sidecars "$t"
    assert_no_flywheel_commands "$t"
  done

  echo "PASS lifecycle ownership/migration/combinations runner=$runner"
}

exercise_sync_and_drift() {
  local t before second agent tier model level
  t="$(new_repo sync)"
  run_install python3 "$t" codex
  mkdir -p "$t/adapters/codex"
  cp -R "$ROOT/adapters/codex/agents" "$t/adapters/codex/agents"
  "$HOST_PYTHON" - "$t/flywheel/config.json" <<'PY'
import json, sys
p=sys.argv[1]; d=json.load(open(p));
for i,tier in enumerate(("architect","strategist","engineer","utility","verifier","auditor")):
    d["tiers"][tier]["adapters"]["codex"]={"model":f"test-model-{i}","level":["minimal","low","medium","high","xhigh","low"][i]}
open(p,"w").write(json.dumps(d,indent=2)+"\n")
PY
  (cd "$t" && python3 flywheel/sync.py >"$TMPROOT/sync.log")
  for item in architect:architect researcher:strategist engineer:engineer utility:utility verifier:verifier plan-auditor:auditor; do
    agent="${item%%:*}"; tier="${item#*:}"
    case "$tier" in architect) model=test-model-0; level=minimal;; strategist) model=test-model-1; level=low;; engineer) model=test-model-2; level=medium;; utility) model=test-model-3; level=high;; verifier) model=test-model-4; level=xhigh;; auditor) model=test-model-5; level=low;; esac
    for dir in "$t/.codex/agents" "$t/adapters/codex/agents"; do
      grep -q "model = \"$model\"" "$dir/$agent.toml" || fail "sync model missing $dir/$agent"
      grep -q "model_reasoning_effort = \"$level\"" "$dir/$agent.toml" || fail "sync level missing $dir/$agent"
    done
  done
  before="$(find "$t/.codex/agents" "$t/adapters/codex/agents" -type f -exec shasum {} \; | sort)"
  (cd "$t" && python3 flywheel/sync.py >"$TMPROOT/sync-second.log")
  second="$(find "$t/.codex/agents" "$t/adapters/codex/agents" -type f -exec shasum {} \; | sort)"
  assert_eq "$before" "$second" "second sync no diff"
  "$HOST_PYTHON" - "$t/flywheel/config.json" <<'PY'
import json, sys
p=sys.argv[1]; d=json.load(open(p)); d["tiers"]["utility"]["adapters"]["codex"]["model"]="Pending verification"
open(p,"w").write(json.dumps(d,indent=2)+"\n")
PY
  before="$(shasum "$t/.codex/agents/utility.toml")"
  (cd "$t" && python3 flywheel/sync.py >"$TMPROOT/sync-pending.log")
  assert_eq "$before" "$(shasum "$t/.codex/agents/utility.toml")" "pending local retained"
  grep -q 'pending/missing' "$TMPROOT/sync-pending.log" || fail "pending skip not reported"
  sed -i.bak 's/model = "test-model-2"/model = "drift"/' "$t/.codex/agents/engineer.toml"
  if (cd "$t" && bash flywheel/check.sh >"$TMPROOT/drift.log" 2>&1); then fail "drift check unexpectedly passed"; fi
  grep -q 'python3 flywheel/sync.py' "$TMPROOT/drift.log" || fail "drift repair hint missing"
  echo "PASS lifecycle sync/drift all six projections"
}

exercise_runner python3
exercise_runner node
exercise_sync_and_drift
echo "PASS adapter lifecycle matrix"

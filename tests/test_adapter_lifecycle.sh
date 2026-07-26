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

assert_lifecycle_boundaries() {
  local skill file
  if rg -n 'shared_skills|\.agents/skills' \
      "$ROOT/installer/adapters/codex.sh" "$ROOT/installer/adapters/antigravity.sh"; then
    fail "Codex/Antigravity module owns shared skill destination"
  fi
  for skill in delegate improve wrapup; do
    grep -q 'read exactly one file in `references/`' \
      "$ROOT/distribution/shared/skills/$skill/SKILL.md" || fail "$skill does not route through exactly one adapter reference"
    if rg -n 'Codex|Claude|Antigravity|\.codex|\.claude' \
        "$ROOT/distribution/shared/skills/$skill/SKILL.md"; then
      fail "$skill common entry point contains adapter-specific execution details"
    fi
    diff -ru "$ROOT/distribution/shared/skills/$skill" "$ROOT/.agents/skills/$skill" ||
      fail "$skill dogfood projection differs from canonical tree"
  done
  while IFS= read -r file; do
    grep -q 'flywheel-managed' "$file" || fail "managed marker missing: $file"
  done < <(find "$ROOT/distribution/shared/skills" "$ROOT/.agents/skills" -type f -name '*.md' | sort)
}

mkdir -p "$NODE_PATH"
for command_name in bash node git dirname mkdir cp diff find ls mktemp rm sed grep rmdir basename mv wc tr; do
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
    PATH="$NODE_PATH" FLYWHEEL_RUNNER=node "$NODE_PATH/bash" "$ROOT/install.sh" "$target" --adapters "$adapters" --yes >"$log" 2>&1
  else
    FLYWHEEL_RUNNER=python3 bash "$ROOT/install.sh" "$target" --adapters "$adapters" --yes >"$log" 2>&1
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

run_check() {
  local runner="$1" target="$2" adapters="$3" log="${4:-$TMPROOT/check.log}"
  if [ "$runner" = node ]; then
    PATH="$NODE_PATH" FLYWHEEL_RUNNER=node "$NODE_PATH/bash" "$ROOT/install.sh" "$target" --adapters "$adapters" --check >"$log" 2>&1
  else
    FLYWHEEL_RUNNER=python3 bash "$ROOT/install.sh" "$target" --adapters "$adapters" --check >"$log" 2>&1
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
commands = {"python3 flywheel/resolve-spawn.py", 'python3 "$(git rev-parse --show-toplevel)/flywheel/resolve-spawn.py" codex', "python3 flywheel/resolve-spawn.py antigravity"}
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

exercise_install_confirmation() {
  local t log agents_before claude_before
  t="$(new_repo confirmation-decline)"
  log="$TMPROOT/confirmation-decline.log"
  printf '# Existing AGENTS\r\n\r\nKeep these bytes.\r\n' > "$t/AGENTS.md"
  printf '# Existing CLAUDE\n\nKeep these bytes.\n' > "$t/CLAUDE.md"
  agents_before="$(shasum "$t/AGENTS.md")"
  claude_before="$(shasum "$t/CLAUDE.md")"
  if printf 'n\n' | FLYWHEEL_RUNNER=python3 bash "$ROOT/install.sh" "$t" --adapters codex >"$log" 2>&1; then
    fail "declined install unexpectedly succeeded"
  fi
  grep -q 'Proceed with installation? \[y/N\]' "$log" || fail "confirmation prompt missing"
  grep -q 'Installation cancelled; no files were changed.' "$log" || fail "decline result missing"
  assert_no_file "$t/flywheel"
  assert_no_file "$t/.codex"
  assert_no_file "$t/.agents"
  assert_no_file "$t/docs"
  assert_eq "$agents_before" "$(shasum "$t/AGENTS.md")" "decline changed AGENTS.md"
  assert_eq "$claude_before" "$(shasum "$t/CLAUDE.md")" "decline changed CLAUDE.md"

  t="$(new_repo confirmation-accept)"
  log="$TMPROOT/confirmation-accept.log"
  printf 'y\n' | FLYWHEEL_RUNNER=python3 bash "$ROOT/install.sh" "$t" --adapters codex >"$log" 2>&1
  assert_file "$t/flywheel/INDEX.md"
  assert_file "$t/AGENTS.md"
  run_uninstall python3 "$t"
  echo "PASS install confirmation gate"
}

exercise_runner() {
  local runner="$1" t before after tree_before tree_after warning log source_file relative count
  if ! command -v "$runner" >/dev/null 2>&1; then
    echo "SKIP lifecycle runner=$runner unavailable"
    return
  fi

  # Unknown adapter names fail before writing.
  t="$(new_repo "unknown-$runner")"
  if run_install "$runner" "$t" future-adapter; then fail "unknown adapter accepted"; fi
  assert_no_file "$t/flywheel"
  assert_no_file "$t/AGENTS.md"

  # The shared coordinator writes each canonical .agents skill file exactly once,
  # even when both consumers are selected together.
  t="$(new_repo "single-shared-owner-$runner")"
  log="$TMPROOT/single-shared-owner-$runner.log"
  run_install "$runner" "$t" codex,antigravity "$log"
  while IFS= read -r source_file; do
    relative="${source_file#"$ROOT/distribution/shared/skills/"}"
    count="$(grep -Fxc "  updated: .agents/skills/$relative" "$log" || true)"
    assert_eq "$count" 1 "single shared write for $relative"
  done < <(find "$ROOT/distribution/shared/skills" -type f | sort)
  run_uninstall "$runner" "$t"
  assert_no_file "$t/.agents/skills"

  # 1,4,5: clean layout, exact managed block, idempotent reinstall, one/two uninstall.
  t="$(new_repo "clean-$runner")"
  run_install "$runner" "$t" codex
  cmp -s "$ROOT/distribution/adapters/codex/AGENTS.md.block" "$t/AGENTS.md" || fail "managed block differs"
  assert_eq "$(find "$t/.codex/agents" -name '*.toml' | wc -l | tr -d ' ')" 6 "six agents"
  assert_eq "$(find "$t/.agents/skills" -name SKILL.md | wc -l | tr -d ' ')" 3 "three skills"
  assert_eq "$(json_hook_count "$t/.codex/hooks.json")" 1 "one Codex hook"
  assert_file "$t/.codex/hooks.json.flywheel-created"
  assert_no_file "$t/.codex/hooks.json.flywheel-bak"
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
  "$HOST_PYTHON" - "$ROOT/distribution/adapters/codex/hooks.json.merge" "$t/.codex/hooks.json" <<'PY'
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
  "$HOST_PYTHON" - "$ROOT/distribution/adapters/codex/hooks.json.merge" "$t/.codex/hooks.json" <<'PY'
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

  # 5: unmanaged shared-skill collision safety.
  t="$(new_repo "skills-$runner")"
  mkdir -p "$t/.agents/skills/delegate"
  printf 'user destination\n' > "$t/.agents/skills/delegate/SKILL.md"
  run_install "$runner" "$t" codex
  grep -q 'user destination' "$t/.agents/skills/delegate/SKILL.md" || fail "unmanaged destination overwritten"
  assert_file "$t/.agents/skills/improve/SKILL.md"
  assert_file "$t/.agents/skills/wrapup/SKILL.md"
  run_uninstall "$runner" "$t"
  grep -q 'user destination' "$t/.agents/skills/delegate/SKILL.md" || fail "unmanaged shared skill removed"

  # Recursive shared skills: every file owns itself. Unmanaged nested collisions
  # survive install/uninstall, while stale managed references are removed even when
  # they are no longer present in the canonical source tree.
  t="$(new_repo "recursive-skills-$runner")"
  for root in .agents/skills .claude/skills; do
    mkdir -p "$t/$root/delegate/references"
    printf 'user adapter notes\n' > "$t/$root/delegate/references/codex.md"
  done
  run_install "$runner" "$t" codex,claude-code
  for root in .agents/skills .claude/skills; do
    assert_file "$t/$root/delegate/SKILL.md"
    grep -q 'user adapter notes' "$t/$root/delegate/references/codex.md" || fail "unmanaged reference overwritten: $root"
    assert_file "$t/$root/delegate/references/claude-code.md"
    printf '<!-- flywheel-managed -->\nstale\n' > "$t/$root/delegate/references/removed-adapter.md"
    printf 'keep sibling\n' > "$t/$root/delegate/references/user-notes.md"
  done
  run_uninstall "$runner" "$t"
  for root in .agents/skills .claude/skills; do
    assert_no_file "$t/$root/delegate/SKILL.md"
    assert_no_file "$t/$root/delegate/references/removed-adapter.md"
    assert_no_file "$t/$root/delegate/references/claude-code.md"
    grep -q 'user adapter notes' "$t/$root/delegate/references/codex.md" || fail "unmanaged reference removed: $root"
    grep -q 'keep sibling' "$t/$root/delegate/references/user-notes.md" || fail "unmanaged nested sibling removed: $root"
  done

  # 10: both shared-skill orders, reinstalls, and Claude/OpenCode combinations.
  for order in codex-antigravity antigravity-codex; do
    t="$(new_repo "$order-$runner")"
    run_install "$runner" "$t" "${order%-*}"
    run_install "$runner" "$t" "${order#*-}"
    run_install "$runner" "$t" "${order%-*}"
    run_install "$runner" "$t" "${order#*-}"
    for s in delegate improve wrapup; do
      cmp -s "$ROOT/distribution/shared/skills/$s/SKILL.md" "$t/.agents/skills/$s/SKILL.md" || fail "installed skill mismatch $s/$order"
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
    case "$adapters" in *opencode*) cmp -s "$ROOT/distribution/adapters/opencode/AGENTS.md.block" "$t/AGENTS.md" || fail "OpenCode AGENTS precedence missing";; esac
    run_uninstall "$runner" "$t"
    assert_no_managed_sidecars "$t"
    assert_no_flywheel_commands "$t"
  done

  # Flywheel-created OpenCode files are marker-owned, snapshotted only after target
  # config projection, and preserve nested post-install edits on uninstall.
  t="$(new_repo "opencode-ownership-$runner")"
  run_install "$runner" "$t" opencode
  assert_file "$t/opencode.json.flywheel-created"
  assert_file "$t/opencode.json.flywheel-merged"
  "$HOST_PYTHON" - "$t/flywheel/config.json" <<'PY'
import json,sys
p=sys.argv[1]; d=json.load(open(p));
d['tiers']['engineer']['adapters']['opencode']={'provider':'target-provider','model':'target-model'}
open(p,'w').write(json.dumps(d,indent=2)+'\n')
PY
  run_install "$runner" "$t" opencode
  grep -q 'target-provider/target-model' "$t/opencode.json" || fail "OpenCode target projection missing"
  cmp -s "$t/opencode.json" "$t/opencode.json.flywheel-merged" || fail "OpenCode snapshot precedes projection"
  before="$(tree_hash "$t")"
  run_check "$runner" "$t" opencode "$TMPROOT/opencode-check-$runner.log"
  assert_eq "$before" "$(tree_hash "$t")" "OpenCode clean --check wrote target"
  grep -q '^PASS --check:' "$TMPROOT/opencode-check-$runner.log" || fail "OpenCode clean --check drifted"
  "$HOST_PYTHON" - "$t/opencode.json" <<'PY'
import json,sys
p=sys.argv[1]; d=json.load(open(p)); d['agent']['engineer']['description']='user nested description edit'
open(p,'w').write(json.dumps(d,indent=2)+'\n')
PY
  run_uninstall "$runner" "$t"
  assert_no_file "$t/opencode.json"
  assert_file "$t/opencode.json.flywheel-uninstalled"
  grep -q 'user nested description edit' "$t/opencode.json.flywheel-uninstalled" || fail "edited OpenCode content not recovered"

  echo "PASS lifecycle ownership/current-skills/combinations runner=$runner"
}

exercise_project_line_preservation() {
  local runner="$1" t sentinel
  t="$(new_repo "project-line-$runner")"
  run_install "$runner" "$t" codex
  sentinel='Project: sentinel $& value \1 backslash-and-amp'
  "$HOST_PYTHON" - "$t/AGENTS.md" "$sentinel" <<'PY'
import re, sys
path, sentinel = sys.argv[1], sys.argv[2]
content = open(path, encoding="utf-8").read()
content = re.sub(r"^Project: .*$", lambda _: sentinel, content, count=1, flags=re.MULTILINE)
content = content.replace("<!-- flywheel:end -->", "managed drift\n<!-- flywheel:end -->", 1)
open(path, "w", encoding="utf-8").write(content)
PY
  run_install "$runner" "$t" codex
  grep -Fxq "$sentinel" "$t/AGENTS.md" || fail "project line not preserved across refresh (runner=$runner)"
  grep -q 'Read `flywheel/INDEX.md` now' "$t/AGENTS.md" || fail "managed block did not refresh (runner=$runner)"
  ! grep -q 'managed drift' "$t/AGENTS.md" || fail "managed drift survived refresh (runner=$runner)"
  echo "PASS project line preserved across refresh runner=$runner"
}

exercise_sync_and_drift() {
  local t before second agent tier model level
  t="$(new_repo sync)"
  run_install python3 "$t" codex
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
    for dir in "$t/.codex/agents"; do
      grep -q "model = \"$model\"" "$dir/$agent.toml" || fail "sync model missing $dir/$agent"
      grep -q "model_reasoning_effort = \"$level\"" "$dir/$agent.toml" || fail "sync level missing $dir/$agent"
    done
  done
  before="$(find "$t/.codex/agents" -type f -exec shasum {} \; | sort)"
  (cd "$t" && python3 flywheel/sync.py >"$TMPROOT/sync-second.log")
  second="$(find "$t/.codex/agents" -type f -exec shasum {} \; | sort)"
  assert_eq "$before" "$second" "second sync no diff"
  "$HOST_PYTHON" - "$t/flywheel/config.json" <<'PY'
import json, sys
p=sys.argv[1]; d=json.load(open(p)); d["tiers"]["utility"]["adapters"]["codex"]["model"]="Pending verification"
open(p,"w").write(json.dumps(d,indent=2)+"\n")
PY
  before="$(shasum "$t/.codex/agents/utility.toml")"
  (cd "$t" && python3 flywheel/sync.py >"$TMPROOT/sync-pending.log")
  assert_eq "$before" "$(shasum "$t/.codex/agents/utility.toml")" "pending local retained"
  sed -i.bak 's/model = "test-model-2"/model = "drift"/' "$t/.codex/agents/engineer.toml"
  if (cd "$t" && bash flywheel/check.sh >"$TMPROOT/drift.log" 2>&1); then fail "drift check unexpectedly passed"; fi
  grep -q 'python3 flywheel/sync.py' "$TMPROOT/drift.log" || fail "drift repair hint missing"
  echo "PASS lifecycle sync/drift all six projections"
}

tree_hash() {
  local t="$1"
  find "$t" -type f -not -path "$t/.git/*" -exec shasum {} \; | sort | shasum | awk '{print $1}'
}

exercise_cli_contract() {
  local t before after log restricted="$TMPROOT/runnerless-path"
  t="$(new_repo check-contract)"
  run_install python3 "$t" codex
  before="$(tree_hash "$t")"
  log="$TMPROOT/check-clean.log"
  FLYWHEEL_RUNNER=python3 bash "$ROOT/install.sh" "$t" --adapters codex --check >"$log" 2>&1
  grep -q '^PASS --check:' "$log" || fail "clean --check PASS line missing"
  after="$(tree_hash "$t")"
  assert_eq "$before" "$after" "clean --check wrote target"
  ! grep -q 'Proceed with installation' "$log" || fail "--check prompted"

  printf '\ndrift\n' >> "$t/flywheel/INDEX.md"
  before="$(tree_hash "$t")"
  if FLYWHEEL_RUNNER=python3 bash "$ROOT/install.sh" "$t" --adapters codex --check >"$log" 2>&1; then
    fail "drifting --check unexpectedly passed"
  fi
  grep -q 'installation drift detected' "$log" || fail "drift diagnostics missing"
  assert_eq "$before" "$(tree_hash "$t")" "drifting --check wrote target"

  before="$(tree_hash "$t")"
  if bash "$ROOT/install.sh" "$t" --adapters codex --check --yes >"$log" 2>&1; then
    fail "--check --yes unexpectedly passed"
  fi
  grep -q 'mutually exclusive' "$log" || fail "mutual exclusion message missing"
  assert_eq "$before" "$(tree_hash "$t")" "--check --yes wrote target"

  mkdir -p "$restricted"
  for command_name in bash dirname; do ln -s "$(command -v "$command_name")" "$restricted/$command_name"; done
  t="$(new_repo runnerless)"
  before="$(tree_hash "$t")"
  if PATH="$restricted" "$restricted/bash" "$ROOT/install.sh" "$t" --adapters codex --yes >"$log" 2>&1; then
    fail "runnerless install unexpectedly passed"
  fi
  grep -q 'requires python3 or node' "$log" || fail "runnerless error missing"
  assert_eq "$before" "$(tree_hash "$t")" "runnerless probe wrote target"
  echo "PASS CLI --check zero-write/noninteractive/mutual-exclusion/runnerless"
}

exercise_preservation_and_architecture() {
  local t
  t="$(new_repo preservation)"
  run_install python3 "$t" codex
  printf '# user status\n' > "$t/flywheel/STATUS.md"
  printf '[{"id":"keep"}]\n' > "$t/flywheel/state/projects.json"
  printf '\nmanaged drift\n' >> "$t/flywheel/INDEX.md"
  "$HOST_PYTHON" - "$t/flywheel/config.json" <<'PY'
import json,sys
p=sys.argv[1]; d=json.load(open(p)); d['project_name']='target';
d['tiers']['engineer']['adapters']['codex']={'model':'target-model','level':'low'}
open(p,'w').write(json.dumps(d,indent=2)+'\n')
PY
  run_install python3 "$t" codex
  grep -q '^# user status' "$t/flywheel/STATUS.md" || fail "STATUS was not preserved"
  grep -q '"id":"keep"' "$t/flywheel/state/projects.json" || fail "state was not preserved"
  ! grep -q 'managed drift' "$t/flywheel/INDEX.md" || fail "managed core did not refresh"
  grep -q 'model = "target-model"' "$t/.codex/agents/engineer.toml" || fail "target config projection lost"
  assert_file "$t/docs/flywheel/ARCHITECTURE.md"
  grep -q '^<!-- flywheel-generated:architecture -->$' "$t/docs/flywheel/ARCHITECTURE.md" || fail "architecture marker missing"
  mkdir -p "$t/docs/flywheel/plans" "$t/docs/flywheel/research"
  printf 'keep plan\n' > "$t/docs/flywheel/plans/keep.md"
  printf 'keep research\n' > "$t/docs/flywheel/research/keep.md"
  printf '# mutable lessons\nentry\n' > "$t/flywheel/LESSONS.md"
  run_uninstall python3 "$t"
  assert_no_file "$t/docs/flywheel/ARCHITECTURE.md"
  assert_file "$t/docs/flywheel/plans/keep.md"
  assert_file "$t/docs/flywheel/research/keep.md"
  for file in STATUS.md LESSONS.md FACTS.md config.json state/projects.json; do assert_file "$t/flywheel-archive/$file"; done

  t="$(new_repo unmarked-architecture)"
  run_install python3 "$t" codex
  printf '# user architecture\n' > "$t/docs/flywheel/ARCHITECTURE.md"
  run_uninstall python3 "$t"
  grep -q 'user architecture' "$t/docs/flywheel/ARCHITECTURE.md" || fail "unmarked architecture removed"
  echo "PASS create-once preservation/managed refresh/architecture ownership/archive recovery"
}

assert_lifecycle_boundaries
exercise_install_confirmation
exercise_runner python3
exercise_runner node
exercise_project_line_preservation python3
exercise_project_line_preservation node
exercise_sync_and_drift
exercise_cli_contract
exercise_preservation_and_architecture
echo "PASS adapter lifecycle matrix"

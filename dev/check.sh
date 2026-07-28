#!/usr/bin/env bash
# Repository-only distribution, dogfood, and ownership checks.
set -u
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FAIL=0
pass() { echo "PASS $*"; }
fail() { echo "FAIL $*" >&2; FAIL=1; }

bash "$ROOT/flywheel/check.sh" || FAIL=1
python3 "$ROOT/dev/sync-distribution.py" --check || FAIL=1

bad=0
while IFS= read -r -d '' src; do
  rel="${src#"$ROOT/distribution/managed/flywheel/"}"
  cmp -s "$src" "$ROOT/flywheel/$rel" || { echo "managed dogfood drift: flywheel/$rel" >&2; bad=1; }
done < <(find "$ROOT/distribution/managed/flywheel" -type f -print0)
[ "$bad" = 0 ] && pass "managed dogfood files are byte-identical" || FAIL=1

python3 - "$ROOT" <<'PY' || FAIL=1
import json, pathlib, sys
root=pathlib.Path(sys.argv[1])
release=json.loads((root/'distribution/defaults/flywheel/config.json').read_text())
dogfood=json.loads((root/'flywheel/config.json').read_text())
allowed={'project_name','autonomy','improve_cadence_sessions','audit_cadence_sessions'}
for key in allowed:
    release.pop(key, None); dogfood.pop(key, None)
if release != dogfood:
    raise SystemExit('FAIL dogfood config diverges outside allowlist')
print('PASS dogfood config divergence is allowlisted')
PY

hr_lines=(
'- HR1. Never Read a file listed in `flywheel/FACTS.md` §Big files (or any file > 200 KB)'
'- HR2. Model names / level values / API params come from `flywheel/config.json` +'
'- HR3. No agent declares its own work complete — dispatch `verifier` / `plan-auditor`.'
'- HR4. Ask-vs-act is governed by `flywheel/AUTONOMY.md`; its level-invariant rows bind'
)
for file in "$ROOT/distribution/managed/flywheel/INDEX.md" \
  "$ROOT/distribution/adapters/codex/AGENTS.md.block" \
  "$ROOT/distribution/adapters/opencode/AGENTS.md.block" \
  "$ROOT/distribution/adapters/antigravity/AGENTS.md.block"; do
  for hr in "${hr_lines[@]}"; do
    grep -Fxq -- "$hr" "$file" || fail "HR mismatch: ${file#"$ROOT/"} :: ${hr:0:8}"
  done
done
grep -Fxq -- '@flywheel/INDEX.md' "$ROOT/distribution/adapters/claude-code/CLAUDE.md.block" ||
  fail "claude-code block lost its @flywheel/INDEX.md always-loaded import"
[ "$FAIL" = 0 ] && pass "hard-rule duplicates are identical and the claude-code block imports INDEX.md"

for old in adapters defaults scripts "docs/"plans "docs/"research "docs/"ARCHITECTURE.md; do
  [ ! -e "$ROOT/$old" ] || fail "retired path still exists: $old"
done

if rg -n 'distribution/|installer/|(^|[^/])dev/|tests/' "$ROOT/distribution/managed/flywheel" \
    --glob '!dashboard/dashboard.html'; then
  fail "installed managed files reference repository-only paths"
else
  pass "installed managed files have no repository-only dependencies"
fi

if rg -n 'docs/(plans|research)/|docs/ARCHITECTURE\.md|(^|[^A-Za-z0-9_/-])(adapters|defaults|scripts)/|distribution/adapters/(antigravity|claude-code|codex|opencode)/(lifecycle\.sh|skills/|plugin/)' \
    "$ROOT/flywheel" "$ROOT/distribution" "$ROOT/docs" "$ROOT/README.md" "$ROOT/AGENTS.md" "$ROOT/CLAUDE.md" \
    --glob '!flywheel/dashboard/dashboard.html' \
    --glob '!docs/flywheel/plans/2026-07-21-file-boundaries.md'; then
  fail "retired source or unqualified Flywheel documentation references remain"
else
  pass "retired sources are absent and Flywheel documentation is namespaced"
fi

fixture="$(mktemp -d)"
cp "$ROOT/distribution/defaults/flywheel/config.json" "$fixture/config.json"
cp "$ROOT/distribution/defaults/flywheel/FACTS.md" "$fixture/FACTS.md"
sed '/| architect | codex |/d' "$fixture/FACTS.md" > "$fixture/FACTS.bad"
if python3 "$ROOT/dev/sync-distribution.py" --check --config "$fixture/config.json" \
    --facts "$fixture/FACTS.bad" >"$fixture/log" 2>&1; then
  fail "mismatched FACTS fixture unexpectedly passed"
elif grep -q 'missing dated FACTS verification' "$fixture/log"; then
  pass "mismatched FACTS negative fixture rejected"
else
  fail "mismatched FACTS fixture failed for the wrong reason"
fi
rm -rf "$fixture"

probe="$(mktemp -d)"
git -C "$probe" init -q
if bash "$ROOT/install.sh" "$probe" --adapters codex --yes >/dev/null &&
   (cd "$probe" && bash flywheel/check.sh >/dev/null); then
  pass "installed check runs in isolated target"
else
  fail "installed check isolation probe"
fi
rm -rf "$probe"

if [ "$FAIL" = 0 ]; then echo "PASS repository distribution checks"; exit 0; fi
echo "FAIL repository distribution checks" >&2
exit 1

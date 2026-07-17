"""Red specifications for the approved Codex adapter robustness repair.

These tests intentionally fail against the pre-repair implementation. Keep them
separate from test_resolve_spawn.py so characterization goldens remain runnable
while the production changes are being developed.
"""
import json
import os
import shutil
import subprocess
import tempfile
import unittest
from pathlib import Path


REPO = Path(__file__).resolve().parents[1]
RESOLVER = REPO / "flywheel" / "resolve-spawn.py"
NEW_CODEX_COMMAND = 'python3 "$(git rev-parse --show-toplevel)/flywheel/resolve-spawn.py" codex'


def hook_commands(value):
    found = []
    if isinstance(value, dict):
        if isinstance(value.get("command"), str):
            found.append(value["command"])
        for child in value.values():
            found.extend(hook_commands(child))
    elif isinstance(value, list):
        for child in value:
            found.extend(hook_commands(child))
    return found


class CodexRootSpec(unittest.TestCase):
    def test_nested_payload_cwd_uses_installed_resolver_root(self):
        with tempfile.TemporaryDirectory(dir=REPO) as tmp:
            root = Path(tmp)
            (root / "flywheel" / "state").mkdir(parents=True)
            (root / "nested" / "deeper").mkdir(parents=True)
            shutil.copy(RESOLVER, root / "flywheel" / "resolve-spawn.py")
            shutil.copy(REPO / "flywheel" / "config.json", root / "flywheel" / "config.json")
            ledger = root / "flywheel" / "state" / "spawns.json"
            ledger.write_text("[]\n", encoding="utf-8")
            payload = {"agent_type": "utility", "cwd": str(root / "nested" / "deeper")}
            proc = subprocess.run(
                ["python3", str(root / "flywheel" / "resolve-spawn.py"), "codex"],
                input=json.dumps(payload), text=True, capture_output=True, check=False,
            )
            self.assertEqual(proc.returncode, 0)
            rows = json.loads(ledger.read_text(encoding="utf-8"))
            self.assertEqual(len(rows), 1, proc.stdout)
            self.assertEqual(rows[0]["agent"], "utility")
            self.assertNotIn("agent_id", rows[0])
            self.assertNotIn("session_id", rows[0])


class HandlerLifecycleSpec(unittest.TestCase):
    def test_hook_sources_omit_noop_matcher_and_keep_one_current_command(self):
        for path in (REPO / ".codex" / "hooks.json",
                     REPO / "adapters" / "codex" / "hooks.json.merge"):
            with self.subTest(path=path):
                data = json.loads(path.read_text(encoding="utf-8"))
                groups = data["hooks"]["SubagentStop"]
                self.assertEqual(len(groups), 1)
                self.assertNotIn("matcher", groups[0])
                self.assertEqual(hook_commands(data).count(NEW_CODEX_COMMAND), 1)

    def install(self, target, runner):
        env = {**os.environ, "FLYWHEEL_RUNNER": runner}
        return subprocess.run(
            ["bash", str(REPO / "install.sh"), str(target), "--adapters", "codex"],
            text=True, capture_output=True, env=env, check=False,
        )

    def uninstall(self, target, runner):
        env = {**os.environ, "FLYWHEEL_RUNNER": runner}
        return subprocess.run(
            ["bash", str(REPO / "uninstall.sh"), str(target), "--yes"],
            text=True, capture_output=True, env=env, check=False,
        )

    def seed_repo(self, root, hooks):
        subprocess.run(["git", "-C", str(root), "init", "-q"], check=True)
        (root / ".codex").mkdir()
        (root / ".codex" / "hooks.json").write_text(
            json.dumps(hooks, indent=2) + "\n", encoding="utf-8")

    def test_backup_restore_removes_only_flywheel_handler(self):
        for runner in ("python3", "node"):
            with self.subTest(runner=runner), tempfile.TemporaryDirectory(dir=REPO) as tmp:
                root = Path(tmp)
                self.seed_repo(root, {"hooks": {"SubagentStop": [{
                    "hooks": [
                        {"type": "command", "command": NEW_CODEX_COMMAND, "timeout": 30},
                        {"type": "command", "command": "echo keep-user-handler"},
                    ],
                }]}})
                self.assertEqual(self.install(root, runner).returncode, 0)
                proc = self.uninstall(root, runner)
                self.assertEqual(proc.returncode, 0, proc.stderr)
                path = root / ".codex" / "hooks.json"
                self.assertTrue(path.is_file())
                commands = hook_commands(json.loads(path.read_text()))
                self.assertEqual(commands, ["echo keep-user-handler"])


class WrapupAllowlistSpec(unittest.TestCase):
    def test_wrapup_rejects_pre_staged_non_bookkeeping_path(self):
        with tempfile.TemporaryDirectory(dir=REPO) as tmp:
            root = Path(tmp)
            flywheel = root / "flywheel"
            (flywheel / "dashboard").mkdir(parents=True)
            (flywheel / "state").mkdir()
            shutil.copy(REPO / "flywheel" / "wrapup.sh", flywheel / "wrapup.sh")
            (flywheel / "check.sh").write_text("#!/usr/bin/env bash\nexit 0\n")
            (flywheel / "dashboard" / "build.py").write_text("# deterministic no-op\n")
            (flywheel / "state" / "activity.json").write_text("[]\n")
            (flywheel / "config.json").write_text('{"improve_cadence_sessions": 5}\n')
            (flywheel / "STATUS.md").write_text("status\n")
            (root / "deleted-outside.txt").write_text("baseline\n")
            subprocess.run(["git", "-C", str(root), "init", "-q"], check=True)
            env = {**os.environ, "GIT_AUTHOR_NAME": "Test", "GIT_AUTHOR_EMAIL": "test@example.invalid",
                   "GIT_COMMITTER_NAME": "Test", "GIT_COMMITTER_EMAIL": "test@example.invalid"}
            subprocess.run(["git", "-C", str(root), "add", "deleted-outside.txt"], check=True)
            subprocess.run(["git", "-C", str(root), "commit", "-qm", "baseline"], env=env, check=True)
            (root / "forbidden.txt").write_text("must not be committed\n")
            (root / "deleted-outside.txt").unlink()
            subprocess.run(["git", "-C", str(root), "add", "forbidden.txt", "deleted-outside.txt"], check=True)
            proc = subprocess.run(
                ["bash", str(flywheel / "wrapup.sh")], cwd=root, text=True,
                capture_output=True, env=env, check=False,
            )
            self.assertNotEqual(proc.returncode, 0, proc.stdout + proc.stderr)
            self.assertRegex(proc.stdout + proc.stderr, r"(?i)(staged|allowlist|outside)")


if __name__ == "__main__":
    unittest.main()

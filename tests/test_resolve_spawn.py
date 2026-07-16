import json
import shutil
import subprocess
import tempfile
import unittest
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path


REPO = Path(__file__).resolve().parents[1]
SCRIPT = REPO / "flywheel" / "resolve-spawn.py"


class ResolveSpawnTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.root = Path(self.tmp.name)
        (self.root / "flywheel" / "state").mkdir(parents=True)
        shutil.copy(REPO / "flywheel" / "config.json", self.root / "flywheel" / "config.json")
        (self.root / "flywheel" / "state" / "spawns.json").write_text("[]\n", encoding="utf-8")

    def tearDown(self):
        self.tmp.cleanup()

    def run_hook(self, payload, adapter="codex"):
        stdin = payload if isinstance(payload, str) else json.dumps(payload)
        proc = subprocess.run(
            ["python3", str(SCRIPT), adapter],
            input=stdin,
            text=True,
            capture_output=True,
            cwd=REPO,
            check=False,
        )
        self.assertEqual(proc.returncode, 0)
        self.assertEqual(proc.stderr, "")
        lines = [line for line in proc.stdout.splitlines() if line.strip()]
        self.assertEqual(len(lines), 1, proc.stdout)
        json.loads(lines[0])
        return proc

    def spawns(self):
        return json.loads((self.root / "flywheel" / "state" / "spawns.json").read_text(encoding="utf-8"))

    def test_codex_known_agent_ignores_parent_model(self):
        self.run_hook({"agent_type": "engineer", "model": "parent-model", "cwd": str(self.root)})
        row = self.spawns()[-1]
        self.assertEqual(row["adapter"], "codex")
        self.assertEqual(row["agent"], "engineer")
        self.assertEqual(row["model"], "gpt-5.5")
        self.assertEqual(row["level"], "high")

    def test_unknown_agent_and_missing_config_do_not_crash(self):
        (self.root / "flywheel" / "config.json").unlink()
        self.run_hook({"agent_type": "mystery", "cwd": str(self.root)})
        row = self.spawns()[-1]
        self.assertEqual(row["agent"], "mystery")
        self.assertEqual(row["model"], "Pending verification")
        self.assertEqual(row["level"], "-")

    def test_malformed_payload_stdout_json_no_ledger_change(self):
        self.run_hook("{not json")
        self.assertEqual(self.spawns(), [])

    def test_concurrent_writes_keep_valid_json(self):
        def once(i):
            self.run_hook({"agent_type": "utility", "cwd": str(self.root), "turn_id": str(i)})

        with ThreadPoolExecutor(max_workers=8) as pool:
            list(pool.map(once, range(20)))
        rows = self.spawns()
        self.assertEqual(len(rows), 20)
        self.assertTrue(all(row["agent"] == "utility" for row in rows))


if __name__ == "__main__":
    unittest.main()

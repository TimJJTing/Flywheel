import json
import importlib.util
import os
import socket
import stat
import shutil
import subprocess
import tempfile
import unittest
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path
from unittest import mock


REPO = Path(__file__).resolve().parents[1]
SCRIPT = REPO / "flywheel" / "resolve-spawn.py"
AGENT_TO_TIER = {
    "architect": "architect",
    "researcher": "strategist",
    "engineer": "engineer",
    "utility": "utility",
    "verifier": "verifier",
    "plan-auditor": "auditor",
}


class ResolveSpawnTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory(dir=REPO)
        self.root = Path(self.tmp.name)
        (self.root / "flywheel" / "state").mkdir(parents=True)
        shutil.copy(REPO / "flywheel" / "config.json", self.root / "flywheel" / "config.json")
        self.ledger.write_text("[]\n", encoding="utf-8")

    def tearDown(self):
        self.tmp.cleanup()

    @property
    def ledger(self):
        return self.root / "flywheel" / "state" / "spawns.json"

    def run_hook(self, payload, adapter="codex", timeout=2):
        before = self.ledger.read_bytes() if self.ledger.exists() else None
        stdin = payload if isinstance(payload, str) else json.dumps(payload)
        proc = subprocess.run(
            ["python3", str(SCRIPT), adapter], input=stdin, text=True,
            capture_output=True, cwd=REPO, check=False, timeout=timeout,
        )
        self.assertEqual(proc.returncode, 0)
        self.assertEqual(proc.stderr, "")
        lines = [line for line in proc.stdout.splitlines() if line.strip()]
        self.assertEqual(len(lines), 1, proc.stdout)
        output = json.loads(lines[0])
        self.assertEqual(set(output), {"systemMessage"})
        after = self.ledger.read_bytes() if self.ledger.exists() else None
        return output, before != after

    def spawns(self):
        return json.loads(self.ledger.read_text(encoding="utf-8"))

    def expected_cell(self, tier):
        config = json.loads((self.root / "flywheel" / "config.json").read_text(encoding="utf-8"))
        return config["tiers"][tier]["adapters"]["codex"]

    def transcript(self, name, agent_path=None, top_level=False, raw=None):
        path = self.root / f"{name}.jsonl"
        if raw is not None:
            path.write_bytes(raw)
            return path
        payload = {"session_id": name}
        if top_level:
            payload["agent_path"] = agent_path
        else:
            payload["source"] = {"subagent": {"thread_spawn": {"agent_path": agent_path}}}
        path.write_text(json.dumps({"type": "session_meta", "payload": payload}) + "\n", encoding="utf-8")
        return path

    def anchor(self, child, raw=b"parent transcript must not be parsed\n"):
        path = child.with_name(f"parent-{child.name}")
        path.write_bytes(raw)
        return path

    def transcript_fields(self, child, parent=None):
        parent = parent or self.anchor(child)
        return {"transcript_path": str(parent), "agent_transcript_path": str(child)}

    def assert_fallback(self, payload):
        output, changed = self.run_hook(payload)
        self.assertTrue(changed)
        self.assertNotIn("secret", json.dumps(output) + json.dumps(self.spawns()[-1]))
        self.assertEqual((self.spawns()[-1]["agent"], self.spawns()[-1]["model"],
                          self.spawns()[-1]["level"]),
                         (payload.get("agent_type") or "unknown", "Pending verification", "-"))
        return output

    def test_all_known_agents_use_config_and_ignore_parent(self):
        for agent, tier in AGENT_TO_TIER.items():
            output, changed = self.run_hook({"agent_type": agent, "model": "parent-secret", "cwd": str(self.root)})
            self.assertTrue(changed)
            row = self.spawns()[-1]
            cell = self.expected_cell(tier)
            self.assertEqual((row["agent"], row["adapter"]), (agent, "codex"))
            self.assertEqual((row["model"], row["level"]), (cell["model"], cell["level"]))
            self.assertNotIn("parent-secret", json.dumps(row))
            self.assertEqual(output["systemMessage"], f"spawn {agent} -> {cell['model']} / {cell['level']}")

    def test_unknown_agent_changes_ledger_with_pending_values(self):
        _, changed = self.run_hook({"agent_type": "mystery", "cwd": str(self.root)})
        self.assertTrue(changed)
        row = self.spawns()[-1]
        self.assertEqual((row["model"], row["level"]), ("Pending verification", "-"))

    def test_live_default_payload_derives_all_six_agents_from_nested_metadata(self):
        for agent, tier in AGENT_TO_TIER.items():
            transcript = self.transcript(f"nested-{agent}", f"/root/{agent}")
            output, changed = self.run_hook({
                "agent_type": "default",
                "model": "parent-model-must-be-ignored",
                **self.transcript_fields(transcript),
                "cwd": str(self.root),
            })
            self.assertTrue(changed)
            row = self.spawns()[-1]
            cell = self.expected_cell(tier)
            self.assertEqual((row["agent"], row["model"], row["level"]),
                             (agent, cell["model"], cell["level"]))
            self.assertNotIn("parent-model-must-be-ignored", json.dumps(row))
            self.assertIn("transcript session_meta", row["notes"])
            self.assertEqual(output["systemMessage"], f"spawn {agent} -> {cell['model']} / {cell['level']}")

    def test_top_level_agent_path_fallback(self):
        transcript = self.transcript("top-level", "/root/verifier", top_level=True)
        _, changed = self.run_hook({**self.transcript_fields(transcript), "cwd": str(self.root)})
        self.assertTrue(changed)
        self.assertEqual(self.spawns()[-1]["agent"], "verifier")

    def test_unsafe_or_unknown_agent_paths_fall_back_without_path_traversal(self):
        for i, agent_path in enumerate(("/root/../../utility", "/root/not-configured", "utility", "/tmp/engineer")):
            transcript = self.transcript(f"unsafe-{i}", agent_path)
            _, changed = self.run_hook({"agent_type": "default", **self.transcript_fields(transcript), "cwd": str(self.root)})
            self.assertTrue(changed)
            row = self.spawns()[-1]
            self.assertEqual((row["agent"], row["model"], row["level"]),
                             ("default", "Pending verification", "-"))

    def test_missing_malformed_oversized_and_unexpected_transcripts_fall_back(self):
        symlink_target = self.transcript("symlink-target", "/root/utility")
        symlink_path = self.root / "unreadable-symlink.jsonl"
        symlink_path.symlink_to(symlink_target)
        cases = [
            self.root / "missing.jsonl",
            symlink_path,
            self.transcript("malformed", raw=b"{bad json\n"),
            self.transcript("oversized", raw=b"{" + b"x" * (128 * 1024) + b"}\n"),
            self.transcript("unexpected", raw=json.dumps({"type": "turn_context", "payload": {"agent_path": "/root/utility"}}).encode() + b"\n"),
        ]
        for transcript in cases:
            output, changed = self.run_hook({"agent_type": "default", **self.transcript_fields(transcript), "cwd": str(self.root)})
            self.assertTrue(changed)
            self.assertNotIn(str(transcript), json.dumps(output))
            row = self.spawns()[-1]
            self.assertEqual((row["agent"], row["model"], row["level"]),
                             ("default", "Pending verification", "-"))

    def test_captured_cross_tree_payload_derives_utility(self):
        with tempfile.TemporaryDirectory(dir=self.root.parent) as session:
            session_dir = Path(session)
            parent = session_dir / "rollout-parent.jsonl"
            child = session_dir / "rollout-child.jsonl"
            parent.write_bytes(b"sensitive parent bytes are an identity anchor only\n")
            meta = {
                "type": "session_meta",
                "payload": {
                    "source": {"subagent": {"thread_spawn": {"agent_path": "/root/utility"}}},
                    "agent_path": "/root/utility",
                },
            }
            child.write_text(json.dumps(meta) + "\n", encoding="utf-8")
            self.assertNotIn(self.root, parent.parents)
            output, changed = self.run_hook({
                "agent_type": "default",
                "model": "parent-secret-model",
                "transcript_path": str(parent),
                "agent_transcript_path": str(child),
                "cwd": str(self.root),
            })
        self.assertTrue(changed)
        cell = self.expected_cell("utility")
        row = self.spawns()[-1]
        self.assertEqual((row["agent"], row["model"], row["level"]),
                         ("utility", cell["model"], cell["level"]))
        self.assertIn("agent derived from transcript session_meta", row["notes"])
        self.assertNotIn("parent-secret", json.dumps(row) + json.dumps(output))

    def test_fifo_in_authorized_transcript_directory_never_blocks(self):
        child = self.root / "no-writer.jsonl"
        os.mkfifo(child)
        parent = self.anchor(child)
        self.assert_fallback({"agent_type": "default", **self.transcript_fields(child, parent),
                              "cwd": str(self.root)})

    def test_outside_parent_directory_regular_jsonl_falls_back(self):
        child_dir = self.root / "other"
        child_dir.mkdir()
        child = child_dir / "valid.jsonl"
        child.write_text(json.dumps({"type": "session_meta", "payload": {"agent_path": "/root/utility"}}) + "\n")
        parent = self.root / "parent.jsonl"
        parent.write_text("anchor\n")
        self.assert_fallback({"agent_type": "default", **self.transcript_fields(child, parent),
                              "cwd": str(self.root)})

    def test_parent_anchor_is_regular_but_never_parsed(self):
        child = self.transcript("valid-child", "/root/utility")
        parent = self.anchor(child, b"{malformed secret-parent-content\n")
        output, _ = self.run_hook({"agent_type": "default", **self.transcript_fields(child, parent),
                                   "cwd": str(self.root)})
        self.assertEqual(self.spawns()[-1]["agent"], "utility")
        self.assertNotIn("secret-parent", json.dumps(output) + json.dumps(self.spawns()[-1]))

    def test_non_regular_parent_or_child_falls_back(self):
        makers = [("directory", lambda path: path.mkdir()),
                  ("fifo", lambda path: os.mkfifo(path))]
        if hasattr(socket, "AF_UNIX"):
            def make_socket(path):
                sock = socket.socket(socket.AF_UNIX)
                try:
                    sock.bind(str(path))
                    return sock
                except Exception:
                    sock.close()
                    raise
            probe_socket_path = self.root / "socket-probe.jsonl"
            try:
                probe_socket = make_socket(probe_socket_path)
                probe_socket.close()
                probe_socket_path.unlink()
                makers.append(("socket", make_socket))
            except OSError:
                pass
        if hasattr(os, "mknod"):
            def make_device(path):
                os.mknod(path, stat.S_IFCHR | 0o600, os.stat("/dev/null").st_rdev)
            try:
                probe = self.root / "device-probe.jsonl"
                make_device(probe)
                probe.unlink()
                makers.append(("device", make_device))
            except (OSError, PermissionError):
                pass

        for label, maker in makers:
            for bad_side in ("parent", "child"):
                with self.subTest(kind=label, side=bad_side):
                    case = self.root / f"{label}-{bad_side}"
                    case.mkdir()
                    parent = case / "parent.jsonl"
                    child = case / "child.jsonl"
                    resource = None
                    if bad_side == "parent":
                        resource = maker(parent)
                        child.write_text("{}\n")
                    else:
                        parent.write_text("anchor\n")
                        resource = maker(child)
                    try:
                        self.assert_fallback({"agent_type": "default",
                                              **self.transcript_fields(child, parent),
                                              "cwd": str(self.root)})
                    finally:
                        if resource is not None:
                            resource.close()

    def test_symlink_entry_and_parent_directory_fall_back(self):
        real_dir = self.root / "real"
        real_dir.mkdir()
        real_child = real_dir / "child.jsonl"
        real_child.write_text(json.dumps({"type": "session_meta", "payload": {"agent_path": "/root/utility"}}) + "\n")
        real_parent = real_dir / "parent.jsonl"
        real_parent.write_text("anchor\n")
        link_child = real_dir / "link-child.jsonl"
        link_child.symlink_to(real_child)
        self.assert_fallback({"agent_type": "default", **self.transcript_fields(link_child, real_parent),
                              "cwd": str(self.root)})
        link_dir = self.root / "linkdir"
        link_dir.symlink_to(real_dir, target_is_directory=True)
        self.assert_fallback({"agent_type": "default",
                              "transcript_path": str(link_dir / "parent.jsonl"),
                              "agent_transcript_path": str(link_dir / "child.jsonl"),
                              "cwd": str(self.root)})

    def test_malformed_and_bounded_child_metadata_falls_back(self):
        valid = json.dumps({"type": "session_meta", "payload": {"agent_path": "/root/utility"}}).encode()
        cases = {
            "empty": b"",
            "malformed": b"{bad json\n",
            "wrong-type": b'{"type":"turn_context","payload":{}}\n',
            "wrong-shape": b'{"type":"session_meta","payload":[]}\n',
            "no-newline": valid,
            "oversized": b'{' + b'x' * (128 * 1024) + b'}\n',
            "no-second-row": b"{bad json\n" + valid + b"\n",
        }
        for label, raw in cases.items():
            with self.subTest(case=label):
                child = self.transcript(f"bounded-{label}", raw=raw)
                self.assert_fallback({"agent_type": "default", **self.transcript_fields(child),
                                      "cwd": str(self.root)})

    def test_known_agent_precedence_skips_all_transcript_io(self):
        parent = self.root / "known-parent.jsonl"
        child = self.root / "known-child.jsonl"
        os.mkfifo(parent)
        os.mkfifo(child)
        _, changed = self.run_hook({"agent_type": "engineer", "transcript_path": str(parent),
                                    "agent_transcript_path": str(child), "cwd": str(self.root)})
        self.assertTrue(changed)
        cell = self.expected_cell("engineer")
        self.assertEqual((self.spawns()[-1]["agent"], self.spawns()[-1]["model"],
                          self.spawns()[-1]["level"]),
                         ("engineer", cell["model"], cell["level"]))

    def test_missing_anchor_or_capability_falls_back_one_json_exit_zero(self):
        child = self.transcript("capability", "/root/utility")
        parent = self.anchor(child)
        base = {"agent_type": "default", **self.transcript_fields(child, parent),
                "cwd": str(self.root)}
        for missing in ("transcript_path", "agent_transcript_path"):
            payload = dict(base)
            payload.pop(missing)
            self.assert_fallback(payload)

        spec = importlib.util.spec_from_file_location("resolve_spawn_capability", SCRIPT)
        module = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(module)
        with mock.patch.object(module.os, "supports_dir_fd", set()):
            self.assertIsNone(module.codex_agent_from_transcript(base))
        with mock.patch.object(module.os, "supports_follow_symlinks", set()):
            self.assertIsNone(module.codex_agent_from_transcript(base))
        original_nofollow = module.os.O_NOFOLLOW
        try:
            del module.os.O_NOFOLLOW
            self.assertIsNone(module.codex_agent_from_transcript(base))
        finally:
            module.os.O_NOFOLLOW = original_nofollow
        failing_open = mock.Mock(side_effect=NotImplementedError)
        with mock.patch.object(module.os, "open", failing_open), \
                mock.patch.object(module.os, "supports_dir_fd", {failing_open, module.os.stat}):
            self.assertIsNone(module.codex_agent_from_transcript(base))
        original_stat = module.os.stat
        failing_stat = mock.Mock(side_effect=NotImplementedError)
        with mock.patch.object(module.os, "stat", failing_stat), \
                mock.patch.object(module.os, "supports_dir_fd", {module.os.open, failing_stat}), \
                mock.patch.object(module.os, "supports_follow_symlinks", {failing_stat}):
            self.assertIsNone(module.codex_agent_from_transcript(base))

    def test_malicious_path_components_fall_back(self):
        child = self.transcript("malicious", "/root/utility")
        parent = self.anchor(child)
        cases = [
            (str(parent), str(child.parent) + "/./" + child.name),
            (str(parent), str(child.parent) + "/../" + child.parent.name + "/" + child.name),
            ("relative.jsonl", str(child)),
            (str(parent), str(parent)),
            (str(parent), str(child.with_suffix(".txt"))),
        ]
        for parent_path, child_path in cases:
            with self.subTest(child=child_path):
                self.assert_fallback({"agent_type": "default", "transcript_path": parent_path,
                                      "agent_transcript_path": child_path, "cwd": str(self.root)})

    def test_missing_and_invalid_config_change_ledger_without_leaking_errors(self):
        for invalid in (None, "{bad"):
            if invalid is None:
                (self.root / "flywheel" / "config.json").unlink(missing_ok=True)
            else:
                (self.root / "flywheel" / "config.json").write_text(invalid, encoding="utf-8")
            _, changed = self.run_hook({"agent_type": "engineer", "cwd": str(self.root)})
            self.assertTrue(changed)
            self.assertEqual(self.spawns()[-1]["model"], "Pending verification")

    def test_missing_ledger_is_created_and_invalid_ledger_is_unchanged(self):
        self.ledger.unlink()
        _, changed = self.run_hook({"agent_type": "utility", "cwd": str(self.root)})
        self.assertTrue(changed)
        self.assertEqual(len(self.spawns()), 1)
        self.ledger.write_text("{invalid-ledger\n", encoding="utf-8")
        output, changed = self.run_hook({"agent_type": "utility", "cwd": str(self.root)})
        self.assertFalse(changed)
        self.assertEqual(output["systemMessage"], "spawn log skipped")
        self.assertEqual(self.ledger.read_text(encoding="utf-8"), "{invalid-ledger\n")

    def test_malformed_payload_has_one_json_stdout_and_no_ledger_change(self):
        output, changed = self.run_hook("{not json")
        self.assertFalse(changed)
        self.assertEqual(output["systemMessage"], "spawn log skipped")

    def test_concurrent_writes_keep_valid_json(self):
        def once(i):
            return self.run_hook({"agent_type": "utility", "cwd": str(self.root), "turn_id": str(i)})
        with ThreadPoolExecutor(max_workers=8) as pool:
            results = list(pool.map(once, range(20)))
        self.assertTrue(all(changed for _, changed in results))
        rows = self.spawns()
        self.assertEqual(len(rows), 20)
        self.assertTrue(all(row["agent"] == "utility" for row in rows))


if __name__ == "__main__":
    unittest.main()

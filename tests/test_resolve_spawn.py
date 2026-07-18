import json
import hashlib
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
        self.script = self.root / "flywheel" / "resolve-spawn.py"
        shutil.copy(SCRIPT, self.script)
        self.ledger.write_text("[]\n", encoding="utf-8")

    def tearDown(self):
        self.tmp.cleanup()

    @property
    def ledger(self):
        return self.root / "flywheel" / "state" / "spawns.json"

    def run_hook(self, payload, adapter="codex", timeout=2, env=None):
        before = self.ledger.read_bytes() if self.ledger.exists() else None
        stdin = payload if isinstance(payload, str) else json.dumps(payload)
        proc = subprocess.run(
            ["python3", str(self.script), adapter], input=stdin, text=True,
            capture_output=True, cwd=REPO, check=False, timeout=timeout,
            env={**os.environ, **(env or {})},
        )
        self.assertEqual(proc.returncode, 0)
        self.assertEqual(proc.stderr, "")
        self.last_stdout = proc.stdout
        lines = [line for line in proc.stdout.splitlines() if line.strip()]
        self.assertEqual(len(lines), 1, proc.stdout)
        output = json.loads(lines[0])
        self.assertEqual(set(output), {"systemMessage"})
        after = self.ledger.read_bytes() if self.ledger.exists() else None
        return output, before != after

    def coordinator_rollout(self, thread_id, records=None, raw=None, name="rollout"):
        home = self.root / "home"
        sessions = home / ".codex" / "sessions" / "2026" / "07" / "18"
        sessions.mkdir(parents=True, exist_ok=True)
        path = sessions / f"{name}-{thread_id}.jsonl"
        if raw is not None:
            path.write_bytes(raw)
        else:
            path.write_text("".join(json.dumps(record) + "\n" for record in records),
                            encoding="utf-8")
        return home, path

    def coordinator_records(self, thread_id, contexts=None, **meta_overrides):
        meta = {
            "id": thread_id, "cwd": str(self.root), "source": "cli",
            "thread_source": "user",
        }
        meta.update(meta_overrides)
        records = [{"type": "session_meta", "payload": meta}]
        for context in contexts or []:
            payload = {"cwd": str(self.root), **context}
            records.append({"type": "turn_context", "payload": payload})
        return records

    def run_coordinator(self, thread_id, home, timeout=2):
        return self.run_hook("", adapter="codex-coordinator", timeout=timeout,
                             env={"HOME": str(home), "CODEX_THREAD_ID": thread_id})

    def spawns(self):
        return json.loads(self.ledger.read_text(encoding="utf-8"))

    def expected_cell(self, tier):
        config = json.loads((self.root / "flywheel" / "config.json").read_text(encoding="utf-8"))
        return config["tiers"][tier]["adapters"]["codex"]

    def adapter_cell(self, tier, adapter):
        config = json.loads((self.root / "flywheel" / "config.json").read_text(encoding="utf-8"))
        return config["tiers"][tier]["adapters"][adapter]

    def assert_terminal_row(self, actual, expected):
        self.assertEqual(set(actual), {"ts", "agent", "adapter", "model", "level",
                                       "task", "outcome", "notes"})
        self.assertRegex(actual["ts"], r"^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}$")
        self.assertEqual(actual, {"ts": actual["ts"], **expected})

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

    def test_codex_rows_ignore_agent_and_session_identifiers(self):
        self.run_hook({
            "agent_type": "utility", "agent_id": "must-not-persist",
            "session_id": "must-not-persist", "turn_id": "must-not-persist",
            "cwd": str(self.root),
        })
        cell = self.expected_cell("utility")
        self.assert_terminal_row(self.spawns()[-1], {
            "agent": "utility", "adapter": "codex", "model": cell["model"],
            "level": cell["level"], "task": "", "outcome": "ok",
            "notes": "auto-logged (codex; model from config, payload model is parent's)",
        })

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
        # A per-process before/after byte comparison races with other successful
        # writers; characterize the durable ledger and successful stdout instead.
        self.assertTrue(all(output["systemMessage"].startswith("spawn utility ->")
                            for output, _ in results))
        rows = self.spawns()
        self.assertEqual(len(rows), 20)
        self.assertTrue(all(row["agent"] == "utility" for row in rows))

    def test_codex_coordinator_uses_newest_runtime_context_and_short_hash(self):
        thread_id = "12345678-1234-1234-1234-123456789abc"
        records = self.coordinator_records(thread_id, [
            {"model": "old-runtime", "effort": "low"},
            {"model": "new-runtime", "effort": "high"},
        ])
        home, rollout = self.coordinator_rollout(thread_id, records)
        output, changed = self.run_coordinator(thread_id, home)
        self.assertTrue(changed)
        digest = hashlib.sha256(thread_id.encode("ascii")).hexdigest()[:12]
        self.assertEqual(output, {"systemMessage": "spawn coordinator -> new-runtime / high"})
        self.assert_terminal_row(self.spawns()[-1], {
            "agent": "coordinator", "adapter": "codex", "model": "new-runtime",
            "level": "high", "task": "", "outcome": "ok",
            "notes": f"auto-resolved from Codex turn_context; session-key:{digest}",
        })
        serialized = json.dumps(output) + json.dumps(self.spawns())
        self.assertNotIn(thread_id, serialized)
        self.assertNotIn(str(rollout), serialized)

    def test_codex_coordinator_is_idempotent_and_preserves_human_fields(self):
        thread_id = "22345678-1234-1234-1234-123456789abc"
        records = self.coordinator_records(thread_id, [
            {"model": "runtime-one", "effort": "medium"},
        ])
        home, rollout = self.coordinator_rollout(thread_id, records)
        self.run_coordinator(thread_id, home)
        rows = self.spawns()
        rows[0]["task"] = "human task"
        rows[0]["outcome"] = "retried"
        rows[0]["notes"] += "; human note"
        original_ts = rows[0]["ts"]
        self.ledger.write_text(json.dumps(rows, indent=2) + "\n", encoding="utf-8")
        records.append({"type": "turn_context", "payload": {
            "cwd": str(self.root), "model": "runtime-two", "effort": "high",
        }})
        rollout.write_text("".join(json.dumps(record) + "\n" for record in records),
                           encoding="utf-8")
        self.run_coordinator(thread_id, home)
        self.assertEqual(len(self.spawns()), 1)
        row = self.spawns()[0]
        self.assertEqual((row["model"], row["level"]),
                         ("runtime-two", "high"))
        self.assertEqual((row["task"], row["outcome"], row["notes"], row["ts"]),
                         ("human task", "retried",
                          f"auto-resolved from Codex turn_context; session-key:"
                          f"{hashlib.sha256(thread_id.encode('ascii')).hexdigest()[:12]}; human note",
                          original_ts))

    def test_codex_coordinator_pending_then_valid_upgrades_same_row(self):
        thread_id = "32345678-1234-1234-1234-123456789abc"
        records = self.coordinator_records(thread_id, [
            {"model": "must-not-fallback", "effort": "medium"},
            {"model": "", "effort": "high"},
        ])
        home, _ = self.coordinator_rollout(thread_id, records)
        output, changed = self.run_coordinator(thread_id, home)
        self.assertTrue(changed)
        self.assertEqual((self.spawns()[0]["model"], self.spawns()[0]["level"]),
                         ("Pending verification", "-"))
        self.assertIn("Pending verification / -", output["systemMessage"])
        self.assertNotIn("must-not-fallback", json.dumps(output))
        records[-1]["payload"]["model"] = "validated-runtime"
        path = next((home / ".codex" / "sessions").rglob(f"*-{thread_id}.jsonl"))
        path.write_text("".join(json.dumps(record) + "\n" for record in records),
                        encoding="utf-8")
        self.run_coordinator(thread_id, home)
        self.assertEqual(len(self.spawns()), 1)
        self.assertEqual((self.spawns()[0]["model"], self.spawns()[0]["level"]),
                         ("validated-runtime", "high"))

    def test_codex_coordinator_reconciles_one_manual_pending_but_not_ambiguous(self):
        thread_id = "33345678-1234-1234-1234-123456789abc"
        records = self.coordinator_records(
            thread_id, [{"model": "runtime", "effort": "medium"}]
        )
        home, _ = self.coordinator_rollout(thread_id, records)
        timestamp = __import__("datetime").datetime.now().strftime("%Y-%m-%dT%H:%M")
        manual = {
            "ts": timestamp, "agent": "coordinator", "adapter": "codex",
            "model": "Pending verification", "level": "-", "task": "curated task",
            "outcome": "retried", "notes": "curated manual note",
        }
        self.ledger.write_text(json.dumps([manual], indent=2) + "\n", encoding="utf-8")
        self.run_coordinator(thread_id, home)
        rows = self.spawns()
        self.assertEqual(len(rows), 1)
        self.assertEqual((rows[0]["model"], rows[0]["level"], rows[0]["task"],
                          rows[0]["outcome"]),
                         ("runtime", "medium", "curated task", "retried"))
        self.assertTrue(rows[0]["notes"].startswith("curated manual note; session-key:"))

        second_id = "34345678-1234-1234-1234-123456789abc"
        second_records = self.coordinator_records(
            second_id, [{"model": "second-runtime", "effort": "high"}]
        )
        second_home, _ = self.coordinator_rollout(second_id, second_records,
                                                   name="ambiguous")
        ambiguous = [dict(manual, notes="candidate one"),
                     dict(manual, notes="candidate two")]
        self.ledger.write_text(json.dumps(ambiguous, indent=2) + "\n", encoding="utf-8")
        self.run_coordinator(second_id, second_home)
        rows = self.spawns()
        self.assertEqual(len(rows), 3)
        self.assertEqual([row["notes"] for row in rows[:2]],
                         ["candidate one", "candidate two"])
        self.assertEqual(rows[-1]["model"], "second-runtime")

    def test_codex_coordinator_identity_failures_never_mutate(self):
        valid_id = "42345678-1234-1234-1234-123456789abc"
        cases = {
            "missing-id": ({}, None),
            "malformed-id": ({"CODEX_THREAD_ID": "../../secret"}, None),
            "wrong-meta-id": ({"CODEX_THREAD_ID": valid_id}, {"id": "52345678-1234-1234-1234-123456789abc"}),
            "wrong-source": ({"CODEX_THREAD_ID": valid_id}, {"source": "api"}),
            "wrong-thread-source": ({"CODEX_THREAD_ID": valid_id}, {"thread_source": "subagent"}),
            "agent-path": ({"CODEX_THREAD_ID": valid_id}, {"agent_path": "/root/engineer"}),
            "wrong-cwd": ({"CODEX_THREAD_ID": valid_id}, {"cwd": str(self.root.parent)}),
        }
        for label, (extra_env, overrides) in cases.items():
            with self.subTest(case=label):
                self.ledger.write_text("[]\n", encoding="utf-8")
                case_home = self.root / f"home-{label}"
                if overrides is not None:
                    records = self.coordinator_records(valid_id, [
                        {"model": "secret-model", "effort": "high"},
                    ], **overrides)
                    case_home, _ = self.coordinator_rollout(valid_id, records,
                                                             name=f"rollout-{label}")
                output, changed = self.run_hook(
                    "", adapter="codex-coordinator",
                    env={"HOME": str(case_home), "CODEX_THREAD_ID": "", **extra_env})
                self.assertFalse(changed)
                self.assertEqual(self.spawns(), [])
                self.assertNotIn(valid_id, json.dumps(output))

    def test_codex_coordinator_zero_duplicate_and_bad_file_types_fail_closed(self):
        thread_id = "62345678-1234-1234-1234-123456789abc"
        empty_home = self.root / "empty-home"
        empty_home.mkdir()
        _, changed = self.run_coordinator(thread_id, empty_home)
        self.assertFalse(changed)

        records = self.coordinator_records(thread_id, [{"model": "x", "effort": "high"}])
        home, first = self.coordinator_rollout(thread_id, records, name="first")
        self.coordinator_rollout(thread_id, records, name="second")
        _, changed = self.run_coordinator(thread_id, home)
        self.assertFalse(changed)

        for offset, kind in enumerate(("symlink", "fifo", "directory"), start=1):
            with self.subTest(kind=kind):
                case_id = f"{offset}2345678-2234-1234-1234-123456789abc"
                case_home = self.root / f"home-{kind}"
                sessions = case_home / ".codex" / "sessions"
                sessions.mkdir(parents=True)
                candidate = sessions / f"rollout-{case_id}.jsonl"
                if kind == "symlink":
                    target = sessions / "target.jsonl"
                    target.write_text("fixture-secret\n", encoding="utf-8")
                    candidate.symlink_to(target)
                elif kind == "fifo":
                    os.mkfifo(candidate)
                else:
                    candidate.mkdir()
                output, changed = self.run_coordinator(case_id, case_home)
                self.assertFalse(changed)
                self.assertNotIn("fixture-secret", json.dumps(output))

    def test_codex_coordinator_inode_and_size_changes_fail_closed(self):
        thread_id = "67345678-1234-1234-1234-123456789abc"
        records = self.coordinator_records(
            thread_id, [{"model": "runtime", "effort": "high"}]
        )
        home, rollout = self.coordinator_rollout(thread_id, records)
        spec = importlib.util.spec_from_file_location("resolve_spawn_coordinator", SCRIPT)
        module = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(module)

        replacement = rollout.with_name("replacement.jsonl")
        replacement.write_text(rollout.read_text(encoding="utf-8"), encoding="utf-8")
        original_open = module.os.open
        swapped = False

        def swapping_open(path, flags, *args, **kwargs):
            nonlocal swapped
            if os.fspath(path) == str(rollout) and not swapped:
                swapped = True
                os.replace(replacement, rollout)
            return original_open(path, flags, *args, **kwargs)

        with mock.patch.object(module.os, "open", side_effect=swapping_open):
            self.assertEqual(module.codex_coordinator_telemetry(
                str(self.root), {"CODEX_THREAD_ID": thread_id},
                sessions_root=home / ".codex" / "sessions"), (None, None, None))

        # A concurrent append changes the post-read size and invalidates the fixed
        # snapshot even though its original bytes parsed successfully.
        original_fstat = module.os.fstat
        fstat_calls = 0

        def growing_fstat(fd):
            nonlocal fstat_calls
            fstat_calls += 1
            if fstat_calls == 2:
                with rollout.open("ab") as stream:
                    stream.write(b"{}\n")
            return original_fstat(fd)

        with mock.patch.object(module.os, "fstat", side_effect=growing_fstat):
            self.assertEqual(module.codex_coordinator_telemetry(
                str(self.root), {"CODEX_THREAD_ID": thread_id},
                sessions_root=home / ".codex" / "sessions"), (None, None, None))

    def test_codex_coordinator_malformed_incomplete_oversized_and_wrong_context_fail_closed(self):
        thread_id = "72345678-1234-1234-1234-123456789abc"
        valid = self.coordinator_records(thread_id, [{"model": "runtime", "effort": "high"}])
        raw_cases = {
            "malformed": b"{bad json\n",
            "incomplete": json.dumps(valid[0]).encode() + b"\n" + json.dumps(valid[1]).encode(),
            "oversized-line": b"{" + b"x" * (128 * 1024) + b"}\n",
            "oversized-file": b"{}\n" * ((32 * 1024 * 1024 // 3) + 1),
        }
        for label, raw in raw_cases.items():
            with self.subTest(case=label):
                self.ledger.write_text("[]\n", encoding="utf-8")
                home, _ = self.coordinator_rollout(thread_id, raw=raw, name=label)
                _, changed = self.run_coordinator(thread_id, home)
                self.assertFalse(changed)
        for label, context in {
            "missing-model": {"effort": "high"},
            "missing-effort": {"model": "runtime"},
            "blank-model": {"model": " ", "effort": "high"},
            "wrong-cwd": {"cwd": str(self.root.parent), "model": "runtime", "effort": "high"},
        }.items():
            with self.subTest(case=label):
                self.ledger.write_text("[]\n", encoding="utf-8")
                records = self.coordinator_records(thread_id, [context])
                home, _ = self.coordinator_rollout(thread_id, records, name=f"context-{label}")
                _, changed = self.run_coordinator(thread_id, home)
                self.assertFalse(changed)

    def test_codex_coordinator_accepts_repo_descendant_cwds(self):
        thread_id = "82345678-1234-1234-1234-123456789abc"
        descendant = self.root / "nested"
        descendant.mkdir()
        records = self.coordinator_records(thread_id, [], cwd=str(descendant))
        records.append({"type": "turn_context", "payload": {
            "cwd": str(descendant), "model": "runtime", "effort": "medium",
        }})
        home, _ = self.coordinator_rollout(thread_id, records)
        _, changed = self.run_coordinator(thread_id, home)
        self.assertTrue(changed)

    def test_codex_coordinator_ignores_codex_home(self):
        thread_id = "92345678-1234-1234-1234-123456789abc"
        records = self.coordinator_records(thread_id, [{"model": "runtime", "effort": "medium"}])
        home, _ = self.coordinator_rollout(thread_id, records)
        fake_codex_home = self.root / "must-not-use"
        output, changed = self.run_hook(
            "", adapter="codex-coordinator",
            env={"HOME": str(home), "CODEX_HOME": str(fake_codex_home),
                 "CODEX_THREAD_ID": thread_id})
        self.assertTrue(changed)
        self.assertIn("runtime", output["systemMessage"])

    def test_codex_coordinator_drops_unrelated_secrets_and_writes_two_space_json(self):
        thread_id = "a2345678-1234-1234-1234-123456789abc"
        secret = "fixture-secret-must-not-survive"
        records = self.coordinator_records(
            thread_id, [{"model": "runtime", "effort": "medium", "prompt": secret}],
            unrelated=secret,
        )
        records.insert(1, {"type": "response_item", "payload": {"text": secret}})
        home, _ = self.coordinator_rollout(thread_id, records)
        output, changed = self.run_coordinator(thread_id, home)
        self.assertTrue(changed)
        serialized = json.dumps(output) + self.ledger.read_text(encoding="utf-8")
        self.assertNotIn(secret, serialized)
        self.assertTrue(self.ledger.read_text(encoding="utf-8").startswith(
            '[\n  {\n    "ts"'
        ))

    def test_claude_post_tool_use_override_is_a_complete_golden(self):
        description = "one two three four five six seven eight nine ten eleven twelve thirteen fourteen fifteen sixteen"
        output, changed = self.run_hook({
            "hook_event_name": "PostToolUse",
            "tool_name": "Agent",
            "tool_input": {
                "subagent_type": "researcher",
                "model": "requested-alias",
                "description": description,
            },
            "tool_response": {"resolvedModel": "resolved-model-id"},
            "cwd": str(self.root),
        }, adapter="claude-code")
        self.assertTrue(changed)
        self.assertEqual(output, {"systemMessage": "spawn researcher -> resolved-model-id / high"})
        self.assertEqual(self.last_stdout,
                         '{"systemMessage": "spawn researcher -> resolved-model-id / high"}\n')
        self.assert_terminal_row(self.spawns()[-1], {
            "agent": "researcher",
            "adapter": "claude-code",
            "model": "resolved-model-id",
            "level": self.adapter_cell("strategist", "claude-code")["level"],
            "task": "one two three four five six seven eight nine ten eleven twelve thirteen fourteen fifteen",
            "outcome": "ok",
            "notes": "auto-logged; override requested: requested-alias",
        })

    def test_claude_resolved_model_mismatch_and_config_fallback_goldens(self):
        configured = self.adapter_cell("engineer", "claude-code")
        cases = [
            ({"resolvedModel": "runtime-different"}, "runtime-different",
             f"auto-logged; resolved model differs from config ({configured['model']})"),
            ({}, configured["model"], "auto-logged"),
        ]
        for response, model, notes in cases:
            with self.subTest(response=response):
                output, changed = self.run_hook({
                    "tool_input": {"subagent_type": "engineer", "description": "build exact thing"},
                    "tool_response": response,
                    "cwd": str(self.root),
                }, adapter="claude-code")
                self.assertTrue(changed)
                self.assertEqual(self.last_stdout,
                                 json.dumps({"systemMessage": f"spawn engineer -> {model} / {configured['level']}"}) + "\n")
                self.assert_terminal_row(self.spawns()[-1], {
                    "agent": "engineer", "adapter": "claude-code", "model": model,
                    "level": configured["level"], "task": "build exact thing", "outcome": "ok",
                    "notes": notes,
                })

    def test_claude_unknown_agent_golden(self):
        self.run_hook({
            "tool_input": {"subagent_type": "future-agent", "description": "unknown still logs"},
            "tool_response": {}, "cwd": str(self.root),
        }, adapter="claude-code")
        self.assertEqual(self.last_stdout,
                         '{"systemMessage": "spawn future-agent -> Pending verification / -"}\n')
        self.assert_terminal_row(self.spawns()[-1], {
            "agent": "future-agent", "adapter": "claude-code",
            "model": "Pending verification", "level": "-", "task": "unknown still logs",
            "outcome": "ok", "notes": "auto-logged",
        })

    def test_antigravity_invoke_subagent_multi_row_order_and_truncation_golden(self):
        prompt = "one two three four five six seven eight nine ten eleven twelve thirteen fourteen fifteen sixteen"
        payload = {
            "hook_event_name": "PostToolUse", "tool_name": "invoke_subagent",
            "model": "parent-runtime-model",
            "tool_input": {"Subagents": [
                {"TypeName": "utility", "Prompt": prompt},
                {"TypeName": "future-agent", "Prompt": "unknown task"},
                {"TypeName": "plan-auditor", "Prompt": "audit plan"},
            ]},
            "tool_response": {"resolvedModel": "must-not-override-parent"},
            "cwd": str(self.root),
        }
        output, changed = self.run_hook(payload, adapter="antigravity")
        self.assertTrue(changed)
        self.assertEqual(output, {"systemMessage": "spawn log appended 3 rows"})
        self.assertEqual(self.last_stdout, '{"systemMessage": "spawn log appended 3 rows"}\n')
        expected = [
            ("utility", self.adapter_cell("utility", "antigravity")["level"],
             "one two three four five six seven eight nine ten eleven twelve thirteen fourteen fifteen"),
            ("future-agent", "-", "unknown task"),
            ("plan-auditor", self.adapter_cell("auditor", "antigravity")["level"], "audit plan"),
        ]
        for row, (agent, level, task) in zip(self.spawns()[-3:], expected):
            self.assert_terminal_row(row, {
                "agent": agent, "adapter": "antigravity", "model": "parent-runtime-model",
                "level": level, "task": task, "outcome": "ok",
                "notes": "auto-logged (antigravity; same model as parent)",
            })

    def test_antigravity_parent_resolution_precedence_and_config_fallback_goldens(self):
        fallback = self.adapter_cell("utility", "antigravity")["model"]
        cases = [
            ({"parent_model": "parent-field", "tool_response": {"resolvedModel": "response-field"}}, "parent-field"),
            ({"tool_response": {"resolvedModel": "response-field"}}, "response-field"),
            ({"tool_response": {}}, fallback),
        ]
        for extra, expected_model in cases:
            with self.subTest(extra=extra):
                payload = {
                    "tool_input": {"Subagents": [{"TypeName": "architect", "Prompt": "design"}]},
                    "cwd": str(self.root), **extra,
                }
                self.run_hook(payload, adapter="antigravity")
                level = self.adapter_cell("architect", "antigravity")["level"]
                self.assertEqual(self.last_stdout,
                                 json.dumps({"systemMessage": f"spawn architect -> {expected_model} / {level}"}) + "\n")
                self.assert_terminal_row(self.spawns()[-1], {
                    "agent": "architect", "adapter": "antigravity", "model": expected_model,
                    "level": level, "task": "design", "outcome": "ok",
                    "notes": "auto-logged (antigravity; same model as parent)",
                })


if __name__ == "__main__":
    unittest.main()

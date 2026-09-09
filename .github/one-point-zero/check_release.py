"""Offline release-contract checks; never contact GitHub or public game URLs."""
from __future__ import annotations

import copy
import hashlib
from pathlib import Path
import stat
import tempfile
import unittest
from unittest.mock import patch
import zipfile

import contracts as c
import publish


class ReleaseChecks(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory(prefix="ever-deeper-release-check-")
        self.root = Path(self.temporary.name)
        self.candidate = self.root / "candidate"
        (self.candidate / "dev").mkdir(parents=True)
        self.payloads = {side: {name: (side + ":" + name).encode() for name in c.WEB_FILES} for side in ("live", "dev")}
        self.base = {"files": {side: {name: {"size": len(data), "sha256": hashlib.sha256(data).hexdigest()} for name, data in files.items()} for side, files in self.payloads.items()}}
        for name in c.WEB_FILES:
            (self.candidate / "dev" / name).write_bytes(("candidate:" + name).encode())
        self.files = {name: c.identity(self.candidate / "dev" / name) for name in c.WEB_FILES}
        checks = {name: {"passed": True} for name in ("source", "dev", "dev-flavor", "production-flavor", "hero-audio", "hero-transitions")}
        for name in ("source", "dev"):
            checks[name]["cases"] = [{"case": case, "passed": True} for case in c.CASES]
        checks["dev-flavor"].update(version=c.DEV_VERSION, pack=self.files["index.pck"])
        checks["production-flavor"].update(version=c.PRODUCTION_VERSION, pack=self.base["files"]["live"]["index.pck"])
        c.write_json(self.candidate / "validation.json", {"passed": True, "checks": checks})
        manifest = {"schema": 1, "repository": c.REPOSITORY, "source_branch": c.BRANCH, "source_commit": "a" * 40, "build_run_id": 123, "dev_version": c.DEV_VERSION, "production_version": c.PRODUCTION_VERSION, "engine": "4.7.2.stable.test", "qa_cases": c.CASES, "dev_files": self.files, "validation": c.identity(self.candidate / "validation.json"), "production_flavor_files": self.base["files"]["live"]}
        c.write_json(self.candidate / "manifest.json", manifest)
        self.accepted = {"source_commit": "a" * 40, "qa_run_id": 123, "candidate_artifact_id": 456, "candidate_manifest_sha256": c.identity(self.candidate / "manifest.json")["sha256"], "files": self.files}

    def tearDown(self):
        self.temporary.cleanup()

    def fake_fetch(self, side, name, target, _expected):
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_bytes(self.payloads[side][name])

    def test_pinned_live_receipt_is_current(self):
        baseline = c.read_json(c.HERE / "baseline.json")
        receipt = c.ROOT / baseline["source_receipt"]
        self.assertEqual(c.identity(receipt)["sha256"], baseline["source_receipt_sha256"])
        self.assertEqual(c.read_json(receipt)["files"], baseline["files"])

    def test_incomplete_review_stops_before_network_or_staging(self):
        data = c.read_json(c.HERE / "review.json")
        data["visual_reviewed"] = False
        destination = self.root / "publisher"
        with patch.object(publish, "read_json", return_value=data), patch.object(publish, "api") as api:
            with self.assertRaisesRegex(RuntimeError, "review is incomplete"):
                publish.prepare(destination)
            api.assert_not_called()
        self.assertFalse(destination.exists())

    def test_dev_readiness_does_not_approve_final_one_point_zero(self):
        data = c.read_json(c.HERE / "review.json")
        data.update(self.accepted)
        data.update(candidate_zip_sha256="c" * 64, reviewed_at="2026-09-09T00:00:00Z", critic_score=8.5, critical_bug_count=0, dev_test_ready=True, physical_iphone_verified=False, final_one_point_zero_approved=False)
        for flag in ("package_checks_passed", "visual_reviewed", "mobile_touch_reviewed", "web_audio_reviewed", "full_progression_reviewed", "critic_reviewed"):
            data[flag] = True
        with patch.object(publish, "read_json", return_value=data):
            self.assertFalse(publish.reviewed()["physical_iphone_verified"])
            data["final_one_point_zero_approved"] = True
            with self.assertRaisesRegex(RuntimeError, "not final 1.0 acceptance"):
                publish.reviewed()

    def test_reviewed_dev_stages_with_live_identical(self):
        site, backup = self.root / "site", self.root / "rollback"
        with patch.object(publish, "BASE", self.base), patch.object(publish, "fetch_public", side_effect=self.fake_fetch):
            publish.stage(self.candidate, site, backup, self.accepted)
        for name in c.WEB_FILES:
            self.assertEqual((site / name).read_bytes(), self.payloads["live"][name])
            self.assertEqual((site / "dev" / name).read_bytes(), (self.candidate / "dev" / name).read_bytes())
            self.assertEqual((backup / "dev" / name).read_bytes(), self.payloads["dev"][name])
        self.assertEqual({item.name for item in site.iterdir()}, c.WEB_FILES | {"dev", ".nojekyll"})
        self.assertFalse((site / "production").exists())

    def test_changed_candidate_is_rejected_before_public_fetch(self):
        (self.candidate / "dev/index.html").write_bytes(b"changed")
        with patch.object(publish, "fetch_public") as fetch:
            with self.assertRaisesRegex(RuntimeError, "Changed web file"):
                publish.stage(self.candidate, self.root / "site", self.root / "rollback", self.accepted)
            fetch.assert_not_called()

    def test_changed_public_live_aborts_before_site_exists(self):
        self.payloads["live"]["index.pck"] = b"concurrent publication"
        site = self.root / "site"
        with patch.object(publish, "BASE", self.base), patch.object(publish, "fetch_public", side_effect=self.fake_fetch):
            with self.assertRaisesRegex(RuntimeError, "Changed web file"):
                publish.stage(self.candidate, site, self.root / "rollback", self.accepted)
        self.assertFalse(site.exists())

    def test_run_artifact_and_required_jobs_must_match(self):
        run = {"id": 123, "head_sha": "a" * 40, "head_branch": c.BRANCH, "path": c.WORKFLOW, "status": "completed", "conclusion": "success"}
        jobs = {"total_count": len(c.REQUIRED_JOBS), "jobs": [{"name": name, "conclusion": "success"} for name in c.REQUIRED_JOBS]}
        artifact = {"id": 456, "name": c.ARTIFACT_NAME, "expired": False, "workflow_run": {"id": 123, "head_sha": "a" * 40}}
        publish.check_run(self.accepted, run, jobs, artifact)
        for field, value in (("id", 999), ("expired", True), ("name", "different-artifact")):
            changed = copy.deepcopy(artifact)
            changed[field] = value
            with self.assertRaises(RuntimeError):
                publish.check_run(self.accepted, run, jobs, changed)
        changed = copy.deepcopy(run)
        changed["head_sha"] = "b" * 40
        with self.assertRaises(RuntimeError):
            publish.check_run(self.accepted, changed, jobs, artifact)
        jobs["jobs"][0]["conclusion"] = "failure"
        with self.assertRaises(RuntimeError):
            publish.check_run(self.accepted, run, jobs, artifact)

    def test_archive_extraction_rejects_extra_paths_and_symlinks(self):
        archive = self.root / "candidate.zip"
        with zipfile.ZipFile(archive, "w") as target:
            for item in self.candidate.rglob("*"):
                if item.is_file():
                    target.write(item, item.relative_to(self.candidate).as_posix())
        extracted = self.root / "extracted"
        publish.extract_candidate(archive, extracted)
        c.verify_candidate(extracted)
        with zipfile.ZipFile(archive, "a") as target:
            target.writestr("../unexpected", "unsafe")
        with self.assertRaises(RuntimeError):
            publish.extract_candidate(archive, self.root / "reject-path")
        with zipfile.ZipFile(archive, "w") as target:
            for item in self.candidate.rglob("*"):
                if item.is_file():
                    info = zipfile.ZipInfo(item.relative_to(self.candidate).as_posix())
                    if info.filename == "dev/index.html":
                        info.create_system = 3
                        info.external_attr = (stat.S_IFLNK | 0o777) << 16
                    target.writestr(info, item.read_bytes())
        with self.assertRaisesRegex(RuntimeError, "symlinks"):
            publish.extract_candidate(archive, self.root / "reject-link")


if __name__ == "__main__":
    unittest.main(verbosity=2)

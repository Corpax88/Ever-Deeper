"""Offline publisher checks, including the supplied real immutable artifacts."""
from __future__ import annotations

import argparse
import copy
from pathlib import Path
import stat
import tempfile
import unittest
from unittest.mock import patch
import zipfile

import contracts as c
import publish

EVIDENCE = None


class PublisherChecks(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="premium-dev-publisher-check-")
        self.root = Path(self.temp.name)
        self.pin = copy.deepcopy(c.pinned())
        self.candidate, self.complete = self.root / "candidate", self.root / "complete"
        self.candidate.mkdir()
        self.complete.mkdir()
        self.public = {side: {name: (side + ":" + name).encode() for name in c.WEB_FILES} for side in ("dev", "live")}
        self.base = {"files": {}}
        for side, files in self.public.items():
            directory = self.root / side
            directory.mkdir()
            for name, content in files.items():
                (directory / name).write_bytes(content)
            self.base["files"][side] = {name: c.identity(directory / name) for name in files}
        for name in c.WEB_FILES:
            (self.candidate / name).write_bytes(("new-dev:" + name).encode())
        files = {name: c.identity(self.candidate / name) for name in c.WEB_FILES}
        c.write_json(self.candidate / "manifest.json", files)
        c.write_json(self.candidate / "artifact-identity.json", {
            "schema": 1, "sourceSha": c.SOURCE, "runId": str(c.RUN), "runAttempt": str(c.ATTEMPT),
            "physicalIphone": False, "devFiles": files, "productionFiles": files, **self.pin["source_hashes"],
        })
        units = {"build": {"passed": True, "coreCases": 15, "devFlavorCases": 1, "productionFlavorCases": 1},
                 "visual-forge": {"passed": True, "visualCases": [1, 14], "pngCount": 14},
                 "visual-workshops": {"passed": True, "visualCases": [15, 19], "pngCount": 5},
                 "gameplay": {"passed": True, "checks": 1, "pngCount": 1, "touchSection": None},
                 "commerce-residency": {"passed": True, "checks": 1, "pngCount": 6, "feedbackChecks": 346, "feedbackPngCount": 8},
                 "mac-gameplay": {"passed": True, "checks": 1, "pngCount": 1, "touchSection": None},
                 "mac-touch-pause": {"passed": True, "checks": 1, "pngCount": 1, "touchSection": "pause"}}
        for section in c.SECTIONS:
            units["touch-" + section] = {"passed": True, "checks": 1, "pngCount": 1, "touchSection": section}
        c.write_json(self.complete / "complete-review.json", {
            "schema": 1, "sourceSha": c.SOURCE, "reviewOnly": True, "physicalIphone": False,
            "passed": True, "complete": True, "errors": [], "units": units,
            "pckSha256": files["index.pck"]["sha256"], "htmlSha256": files["index.html"]["sha256"],
        })
        for kind in ("candidate", "complete"):
            self.pin[kind]["members"] = {p.name: c.identity(p) for p in (self.root / kind).iterdir()}
        self.accepted = c.read_json(c.HERE / "review.json")
        self.accepted.update(dev_publication_authorized=True, authorization_record={"requested_by": "Fixture", "request": "Offline fixture only", "recorded_at": "2026-09-16T00:00:00Z"})
        self.accepted["visual_readiness"] = {"status": "approved_for_dev_playtest", "reviewer": "Fixture", "reviewed_at": "2026-09-16T00:00:00Z", "scope": "Offline fixture", "findings": "Fixture only", "evidence": ["fixture"], "blocking_defects": []}

    def tearDown(self):
        self.temp.cleanup()

    def fake_fetch(self, side, name, target, expected):
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_bytes(self.public[side][name])
        c.require(c.identity(target) == expected, "Changed public bytes")

    def metadata(self):
        run = {"id": c.RUN, "head_sha": c.SOURCE, "run_attempt": c.ATTEMPT, "head_branch": c.BRANCH, "path": c.WORKFLOW, "repository": {"full_name": c.REPOSITORY}, "status": "completed", "conclusion": "success"}
        jobs = {"total_count": 14, "jobs": [{"name": name, "status": "completed", "conclusion": "success", "run_id": c.RUN, "head_sha": c.SOURCE} for name in sorted(c.JOBS)]}
        artifacts = {kind: {"id": self.pin[kind]["id"], "name": self.pin[kind]["name"], "expired": False, "workflow_run": {"id": c.RUN, "head_sha": c.SOURCE}} for kind in ("candidate", "complete")}
        return run, jobs, artifacts

    def test_pinned_real_baseline_is_dev10_with_all_18_files(self):
        base = c.baseline()
        self.assertEqual(base["candidate_artifact_id"], 10479804355)
        self.assertEqual(base["source_commit"], "23076019b53819c6c7f213b7e55d24a2f6194f83")
        self.assertEqual(sum(len(rows) for rows in base["files"].values()), 18)

    def test_pending_visual_review_stops_before_network_or_workspace(self):
        data = copy.deepcopy(self.accepted)
        data["visual_readiness"]["status"] = "pending"
        read = c.read_json
        with patch.object(c, "read_json", side_effect=lambda path: data if Path(path).name == "review.json" else read(path)), patch.object(publish, "api") as api:
            with self.assertRaisesRegex(RuntimeError, "visual readiness is unapproved"):
                publish.prepare(self.root / "publish")
            api.assert_not_called()
        self.assertFalse((self.root / "publish").exists())

    def test_authorization_and_bounded_visual_record_are_required(self):
        with patch.object(c, "read_json", return_value=self.accepted):
            self.assertIs(c.reviewed(self.pin), self.accepted)
            for key in ("final_one_point_zero_approved", "live_publication_authorized", "physical_iphone_verified"):
                with self.subTest(key=key):
                    self.accepted[key] = True
                    with self.assertRaises(RuntimeError):
                        c.reviewed(self.pin)
                    self.accepted[key] = False
            self.accepted["dev_publication_authorized"] = False
            with self.assertRaises(RuntimeError):
                c.reviewed(self.pin)

    def test_exact_14_jobs_run_and_artifacts_are_required(self):
        run, jobs, artifacts = self.metadata()
        c.check_run(self.pin, run, jobs, artifacts)
        for field, bad in (("head_sha", "a" * 40), ("run_attempt", 2), ("conclusion", "cancelled"), ("head_branch", "main")):
            changed = copy.deepcopy(run)
            changed[field] = bad
            with self.subTest(field=field), self.assertRaises(RuntimeError):
                c.check_run(self.pin, changed, jobs, artifacts)
        for state in ("failure", "cancelled", "skipped"):
            changed = copy.deepcopy(jobs)
            changed["jobs"][0]["conclusion"] = state
            with self.subTest(state=state), self.assertRaises(RuntimeError):
                c.check_run(self.pin, run, changed, artifacts)
        changed = copy.deepcopy(jobs)
        changed["jobs"].pop()
        with self.assertRaises(RuntimeError):
            c.check_run(self.pin, run, changed, artifacts)
        for kind in ("candidate", "complete"):
            changed = copy.deepcopy(artifacts)
            changed[kind]["expired"] = True
            with self.subTest(kind=kind), self.assertRaises(RuntimeError):
                c.check_run(self.pin, run, jobs, changed)

    def test_stage_preserves_all_live_and_rollback_bytes(self):
        site, backup = self.root / "site", self.root / "rollback"
        with patch.object(publish, "fetch_public", side_effect=self.fake_fetch):
            publish.stage(self.candidate, self.complete, site, backup, self.pin, self.base)
        for name in c.WEB_FILES:
            self.assertEqual((site / name).read_bytes(), self.public["live"][name])
            self.assertEqual((site / "dev" / name).read_bytes(), (self.candidate / name).read_bytes())
            for side in ("live", "dev"):
                self.assertEqual((backup / side / name).read_bytes(), self.public[side][name])
        self.assertEqual({p.name for p in site.iterdir()}, c.WEB_FILES | {"dev", ".nojekyll"})
        self.assertEqual({p.name for p in (site / "dev").iterdir()}, c.WEB_FILES)

    def test_changed_candidate_stops_before_fetch_or_staging(self):
        (self.candidate / "index.html").write_bytes(b"changed")
        with patch.object(publish, "fetch_public") as fetch:
            with self.assertRaises(RuntimeError):
                publish.stage(self.candidate, self.complete, self.root / "site", self.root / "rollback", self.pin, self.base)
            fetch.assert_not_called()
        self.assertFalse((self.root / "site").exists())

    def test_changed_live_or_dev_baseline_stops_before_staging(self):
        for side in ("live", "dev"):
            original = self.public[side]["index.pck"]
            self.public[side]["index.pck"] = b"different published package"
            with self.subTest(side=side), patch.object(publish, "fetch_public", side_effect=self.fake_fetch), self.assertRaises(RuntimeError):
                publish.stage(self.candidate, self.complete, self.root / (side + "-site"), self.root / (side + "-rollback"), self.pin, self.base)
            self.assertFalse((self.root / (side + "-site")).exists())
            self.public[side]["index.pck"] = original

    def test_complete_report_cannot_be_partial_or_another_package(self):
        path = self.complete / "complete-review.json"
        original = c.read_json(path)
        for variant in ("missing-unit", "failed", "wrong-package", "wrong-section", "missing-mac", "incomplete-feedback"):
            data = copy.deepcopy(original)
            if variant == "missing-unit":
                del data["units"]["touch-light"]
            elif variant == "failed":
                data["passed"] = False
            elif variant == "wrong-package":
                data["pckSha256"] = "0" * 64
            elif variant == "missing-mac":
                del data["units"]["mac-gameplay"]
            elif variant == "incomplete-feedback":
                data["units"]["commerce-residency"]["feedbackPngCount"] = 7
            else:
                data["units"]["touch-light"]["touchSection"] = "wardrobe"
            c.write_json(path, data)
            self.pin["complete"]["members"][path.name] = c.identity(path)
            with self.subTest(variant=variant), self.assertRaises(RuntimeError):
                c.verify_bundle(self.candidate, self.complete, self.pin)

    def test_archive_exact_members_and_safe_regular_files(self):
        for variant in ("valid", "extra", "duplicate", "symlink", "changed-zip"):
            archive = self.root / (variant + ".zip")
            with zipfile.ZipFile(archive, "w") as output:
                for name in sorted(self.pin["candidate"]["members"]):
                    info = zipfile.ZipInfo(name)
                    if variant == "symlink" and name == "index.html":
                        info.create_system = 3
                        info.external_attr = (stat.S_IFLNK | 0o777) << 16
                    output.writestr(info, (self.candidate / name).read_bytes())
                if variant == "extra":
                    output.writestr("../outside", b"bad")
                if variant == "duplicate":
                    output.writestr("index.html", (self.candidate / "index.html").read_bytes())
            artifact = copy.deepcopy(self.pin["candidate"])
            artifact["zip"] = c.identity(archive)
            if variant == "changed-zip":
                artifact["zip"]["sha256"] = "0" * 64
            destination = self.root / (variant + "-extract")
            if variant == "valid":
                c.extract_exact(archive, destination, artifact)
                c.check_files(destination, artifact["members"])
            else:
                with self.subTest(variant=variant), self.assertRaises(RuntimeError):
                    c.extract_exact(archive, destination, artifact)
                self.assertFalse(destination.exists())

    def test_public_verification_requires_all_18_and_retains_failed_receipt(self):
        for name in c.WEB_FILES:
            self.public["dev"][name] = (self.candidate / name).read_bytes()
        with patch.object(c, "pinned", return_value=self.pin), patch.object(c, "reviewed", return_value=self.accepted), patch.object(c, "baseline", return_value=self.base), patch.object(publish, "fetch_public", side_effect=self.fake_fetch), patch.object(publish.time, "sleep"):
            publish.verify(self.root / "verified")
            good = c.read_json(self.root / "verified/publication-receipt.json")
            self.assertIs(good["passed"], True)
            self.assertEqual(good["verified_files"], 18)
            self.public["live"]["index.pck"] = b"corrupt"
            with self.assertRaises(RuntimeError):
                publish.verify(self.root / "failed")
            bad = c.read_json(self.root / "failed/publication-receipt.json")
            self.assertIs(bad["passed"], False)
            self.assertEqual(bad["verified_files"], 17)
            self.assertEqual(bad["verification_attempts"], 10)
            self.assertIn("live/index.pck", bad["errors"][0])

    def test_real_downloaded_artifacts_and_api_receipts(self):
        if EVIDENCE is None:
            self.skipTest("Pass --evidence to verify the real downloaded artifacts")
        pin = c.pinned()
        for kind in ("candidate", "complete"):
            c.extract_exact(EVIDENCE / (kind + ".zip"), self.root / ("real-" + kind), pin[kind])
        files = c.verify_bundle(self.root / "real-candidate", self.root / "real-complete", pin)
        self.assertEqual(files["index.pck"]["sha256"], "5b77b3a219011cb676895e41830c8dab32bec2346db93102c7894a3c084414e9")
        run_file, jobs_file = EVIDENCE / "qa-run-api.json", EVIDENCE / "qa-jobs-api.json"
        if run_file.exists() and jobs_file.exists():
            _, _, artifacts = self.metadata()
            c.check_run(pin, c.read_json(run_file), c.read_json(jobs_file), artifacts)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--evidence", type=Path)
    args, remaining = parser.parse_known_args()
    EVIDENCE = args.evidence
    unittest.main(argv=[__file__, *remaining], verbosity=2)

import contextlib
import copy
import gzip
import importlib.util
import io
import json
import os
from pathlib import Path
import subprocess
import tempfile
import unittest
from unittest.mock import patch
import xml.etree.ElementTree as ET


ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location("packages", ROOT / "build/packages.py")
packages = importlib.util.module_from_spec(spec)
spec.loader.exec_module(packages)
TAG = "v0.50.0"
COMMIT = "a" * 40


class PackageTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name)
        self.revisions = {"deb": 1, "rpm": 1}
        self.candidates = [
            {"format": "deb", "distro": distro, "arch": "amd64", "php": "8.4", "name": "php8.4-relay"}
            for distro in ("noble", "resolute")
        ] + [
            {"format": "rpm", "distro": "el9", "arch": "x86_64", "php": php, "name": "php-relay"}
            for php in ("8.3", "8.4")
        ]
        self.addCleanup(patch.stopall)
        patch.dict(os.environ, {"GITHUB_OUTPUT": ""}).start()

    def candidate(self, index, revision=1):
        package = dict(self.candidates[index])
        package["filename"] = packages.filename(package, TAG, revision)
        return package

    def index(self, candidates, revision=1, checksum="b" * 64, legacy=False):
        """Write actual index formats; no package bytes are needed by planning."""
        for package in candidates:
            fmt = package["format"]
            name = packages.filename(package, TAG, revision)
            if legacy:
                name = name.replace(f"-{TAG[1:]}-{revision}-", f"-{TAG[1:]}-")
            if fmt == "deb":
                path = self.root / f"deb/dists/{package['distro']}/main/binary-{package['arch']}/Packages"
                path.parent.mkdir(parents=True, exist_ok=True)
                with path.open("a") as stream:
                    stream.write(
                        f"Package: {package['name']}\nArchitecture: {package['arch']}\n"
                        f"Version: {TAG[1:]}-{revision}\nFilename: pools/{name}\nSHA256: {checksum}\n\n"
                    )
            else:
                directory = self.root / f"rpm/{package['distro']}/repodata"
                directory.mkdir(parents=True, exist_ok=True)
                primary = directory / "primary.xml.gz"
                ns = "http://linux.duke.edu/metadata/common"
                tree = ET.fromstring(gzip.decompress(primary.read_bytes())) if primary.exists() else ET.Element(f"{{{ns}}}metadata")
                pkg = ET.SubElement(tree, f"{{{ns}}}package")
                ET.SubElement(pkg, f"{{{ns}}}name").text = package["name"]
                ET.SubElement(pkg, f"{{{ns}}}arch").text = package["arch"]
                ET.SubElement(pkg, f"{{{ns}}}version", epoch="0", ver=TAG[1:], rel=str(revision))
                ET.SubElement(pkg, f"{{{ns}}}checksum", type="sha256").text = checksum
                ET.SubElement(pkg, f"{{{ns}}}location", href=f"{TAG}/{name}")
                primary.write_bytes(gzip.compress(ET.tostring(tree)))
                (directory / "repomd.xml").write_text(
                    '<repomd xmlns="http://linux.duke.edu/metadata/repo"><data type="primary">'
                    '<location href="repodata/primary.xml.gz"/></data></repomd>'
                )

    def plan(self, tag=TAG):
        for fmt, revision in self.revisions.items():
            packages.write_json(self.root / f"build/revisions/{fmt}.json", {TAG: revision})

        def command(args, **kwargs):
            if args[0] == "git":
                return COMMIT + "\n"
            return "".join("\t".join([
                *(p[k] for k in ("format", "distro", "arch", "php", "name")),
                packages.filename(p, TAG, self.revisions[p["format"]])
            ]) + "\n" for p in self.candidates)

        with patch.object(packages.subprocess, "check_output", side_effect=command):
            with contextlib.redirect_stdout(io.StringIO()):
                return packages.plan(self.root, tag)

    def artifact(self):
        manifest = self.plan()
        dist = self.root / "build/dist"
        dist.mkdir()
        for package in manifest["packages"]:
            (dist / package["filename"]).write_bytes(b"package bytes")
        packages.finish_manifest(self.root)
        return dist, packages.read_json(dist / "manifest.json")

    def test_legacy_rpm_release_one_is_skipped_for_each_php(self):
        self.index([self.candidates[2]], legacy=True)
        manifest = self.plan()
        self.assertEqual([p["php"] for p in manifest["packages"] if p["format"] == "rpm"], ["8.4"])

    def test_unchanged_revision_is_noop_and_manifest_is_still_produced(self):
        self.index(self.candidates)
        self.assertEqual(self.plan()["packages"], [])
        packages.finish_manifest(self.root)
        self.assertEqual(packages.read_json(self.root / "build/dist/manifest.json")["packages"], [])

    def test_only_bumped_format_is_built(self):
        self.index(self.candidates)
        self.revisions["rpm"] = 2
        manifest = self.plan()
        self.assertEqual({p["format"] for p in manifest["packages"]}, {"rpm"})
        self.assertTrue(all("-0.50.0-2-" in p["filename"] for p in manifest["packages"]))

    def test_new_distribution_does_not_rebuild_existing_packages(self):
        self.index([self.candidates[i] for i in (0, 2, 3)])
        manifest = self.plan()
        self.assertEqual([p["distro"] for p in manifest["packages"]], ["resolute"])

    def test_revision_cannot_go_backwards(self):
        self.index([self.candidates[0]], revision=2)
        with self.assertRaisesRegex(ValueError, "older than published"):
            self.plan()

    def test_unknown_tag_and_invalid_revisions_fail(self):
        with self.assertRaisesRegex(ValueError, "Add v0.51.0"):
            self.plan("v0.51.0")
        for value in (0, -1, True, "1", 1.5):
            self.revisions["deb"] = value
            with self.assertRaisesRegex(ValueError, "positive integers"):
                self.plan()

    def test_artifact_manifest_checks_every_planned_file(self):
        self.plan()
        (self.root / "build/dist").mkdir()
        with self.assertRaisesRegex(ValueError, "Build output differs"):
            packages.finish_manifest(self.root)

    def test_staging_rejects_tampering_and_wrong_commit(self):
        dist, manifest = self.artifact()
        with self.assertRaisesRegex(ValueError, "source commit"):
            packages.stage(self.root, dist, "deb", "c" * 40)
        (dist / manifest["packages"][0]["filename"]).write_bytes(b"modified")
        with self.assertRaisesRegex(ValueError, "Checksum mismatch"):
            packages.stage(self.root, dist, "deb", COMMIT)

    def test_stage_validates_whole_batch_before_writing(self):
        dist, manifest = self.artifact()
        self.index([self.candidates[1]])
        with self.assertRaisesRegex(ValueError, "Published identity has different bytes"):
            packages.stage(self.root, dist, "deb", COMMIT)
        self.assertFalse((self.root / packages.destination(manifest["packages"][0], TAG)).exists())

    def test_stage_is_repeatable_but_rejects_replacement(self):
        dist, manifest = self.artifact()
        with contextlib.redirect_stdout(io.StringIO()):
            packages.stage(self.root, dist, "deb", COMMIT)
            packages.stage(self.root, dist, "deb", COMMIT)
        dest = self.root / packages.destination(manifest["packages"][0], TAG)
        dest.write_bytes(b"older published bytes")
        with self.assertRaisesRegex(ValueError, "Refusing to overwrite"):
            packages.stage(self.root, dist, "deb", COMMIT)
        self.assertEqual(dest.read_bytes(), b"older published bytes")

    def test_manifest_cannot_escape_package_directories(self):
        _, manifest = self.artifact()
        for field in ("name", "distro", "arch", "php", "filename"):
            changed = copy.deepcopy(manifest)
            changed["packages"][0][field] = "../../escape"
            with self.assertRaises(ValueError):
                packages.validate_manifest(changed)

    def test_deb_upload_includes_pool_and_index_alias_only(self):
        dist, manifest = self.artifact()
        with patch.object(packages, "upload_object") as upload:
            packages.upload(dist, "deb", "bucket", "endpoint")
        keys = {call.args[1] for call in upload.call_args_list}
        self.assertEqual(len(keys), 4)
        self.assertIn("deb/pools/resolute/v0.50.0/php8.4-relay-0.50.0-1-php8.4-resolute_amd64.deb", keys)
        self.assertTrue(all(key.startswith("deb/") for key in keys))

    def test_remote_upload_uses_conditional_write_and_checks_retry_bytes(self):
        dist, manifest = self.artifact()
        package = manifest["packages"][0]
        remote_bytes = b"package bytes"

        def aws(args, **kwargs):
            if "put-object" in args:
                self.assertEqual(args[-2:], ["--if-none-match", "*"])
                return subprocess.CompletedProcess(args, 1, "", "PreconditionFailed")
            self.assertIn("get-object", args)
            Path(args[-1]).write_bytes(remote_bytes)
            return subprocess.CompletedProcess(args, 0)

        with patch.object(packages.subprocess, "run", side_effect=aws):
            with contextlib.redirect_stdout(io.StringIO()):
                packages.upload_object(dist / package["filename"], "key", package["sha256"], "bucket", "endpoint")
            remote_bytes = b"different bytes"
            with self.assertRaisesRegex(ValueError, "Published object has different bytes"):
                packages.upload_object(dist / package["filename"], "key", package["sha256"], "bucket", "endpoint")

    def test_remote_access_error_is_not_treated_as_missing_object(self):
        with patch.object(packages.subprocess, "run", return_value=subprocess.CompletedProcess([], 1, "", "AccessDenied")) as aws:
            with self.assertRaisesRegex(RuntimeError, "AccessDenied"):
                packages.upload_object(Path("unused"), "key", "checksum", "bucket", "endpoint")
            self.assertEqual(aws.call_count, 1)

    def test_real_shell_candidates_include_independent_revisions(self):
        result = subprocess.run(
            ["bash", str(ROOT / "build/fpm.sh"), TAG, "--list"],
            env=dict(os.environ, DEB_REVISION="3", RPM_REVISION="4"),
            check=True, capture_output=True, text=True,
        )
        rows = [line.split("\t") for line in result.stdout.splitlines()]
        self.assertEqual({row[0] for row in rows}, {"deb", "rpm"})
        for row in rows:
            self.assertEqual(len(row), 6)
            revision = "3" if row[0] == "deb" else "4"
            self.assertIn(f"-0.50.0-{revision}-php", row[-1])


if __name__ == "__main__":
    unittest.main()

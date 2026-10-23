"""Packaging contract tests; no SDK, signing secrets, or real builds needed."""

import argparse
import hashlib
import importlib.util
import json
import os
from pathlib import Path
import subprocess
import tarfile
import tempfile
import unittest
from unittest.mock import patch
import zipfile


SPEC = importlib.util.spec_from_file_location("artifacts", Path(__file__).with_name("artifacts.py"))
artifacts = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(artifacts)


class ArtifactTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.repo = Path(self.temporary.name)
        self.environment = patch.dict(os.environ, {}, clear=True)
        self.environment.start()
        self.addCleanup(self.environment.stop)
        self.write("mise.toml", '[tools]\nflutter = "3.44.4"\n')
        self.write("app/pubspec.yaml", "name: avalon\nversion: 2.0.0+1\n")
        for name in ("LICENSE", "COPYRIGHT", "THIRD_PARTY_NOTICES.md"):
            self.write(name, name)
        self.write("docs/licenses/sing-box.txt", "upstream license")
        self.write("app/assets/licenses/zxing.txt", "runtime license")

    def write(self, name, content="fixture"):
        path = self.repo / name
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(content)
        return path

    def args(self, platform="linux", **values):
        result = argparse.Namespace(
            repo_root=self.repo,
            dist=None,
            platform=platform,
            arch="amd64",
            build_number="20007",
            commit="a" * 40,
            android_signing="unsigned",
            apksigner="apksigner",
        )
        for name, value in values.items():
            setattr(result, name, value)
        return result

    def linux_bundle(self):
        self.write("app/build/linux/x64/release/bundle/avalon", "ELF app")
        self.write("app/build/linux/x64/release/bundle/lib/libflutter_linux_gtk.so")
        self.write("core/out/avalon-helper-linux-amd64", "ELF helper")
        self.write("core/install_linux_helper.sh", "#!/bin/sh\n")

    def apks(self):
        paths = []
        for abi in artifacts.ABI_NAMES:
            path = self.repo / f"app/build/app/outputs/flutter-apk/app-{abi}-release.apk"
            path.parent.mkdir(parents=True, exist_ok=True)
            with zipfile.ZipFile(path, "w") as archive:
                archive.writestr("AndroidManifest.xml", "manifest fixture")
                archive.writestr("classes.dex", "dex fixture")
            paths.append(path)
        return paths

    @staticmethod
    def verification(code=1, stdout="", stderr="DOES NOT VERIFY\nERROR: Missing META-INF/MANIFEST.MF"):
        return subprocess.CompletedProcess([], code, stdout, stderr)

    def test_metadata_rejects_mismatched_or_legacy_tags(self):
        for tag in ("avalon-v2.0.0", "v2.0.1", "v1.0.18", "v2.0.0-extra", "v2.0.0+1"):
            with self.subTest(tag=tag), self.assertRaises(artifacts.ArtifactError):
                artifacts.read_metadata(self.repo, {"GITHUB_REF": f"refs/tags/{tag}"})
        result = artifacts.read_metadata(self.repo, {"GITHUB_REF_TYPE": "tag", "GITHUB_REF_NAME": "v2.0.0"})
        self.assertEqual(result["version"], "2.0.0")

    def test_metadata_rejects_invalid_run_number(self):
        for value in ("0", "-1", "x", "3\nx=y", "2100000000"):
            with self.subTest(value=value), self.assertRaises(artifacts.ArtifactError):
                artifacts.read_metadata(self.repo, {"GITHUB_RUN_NUMBER": value})

    def test_linux_contains_helper_installer_licenses_and_source(self):
        self.linux_bundle()
        info = artifacts.package(self.args())
        self.assertEqual(info["status"], "build-validation")
        target = next((self.repo / "dist").glob("*.tar.gz"))
        with tarfile.open(target) as archive:
            names = archive.getnames()
            prefix = target.name.removesuffix(".tar.gz")
            self.assertIn(f"{prefix}/app/lib/avalon-helper", names)
            self.assertIn(f"{prefix}/install_linux_helper.sh", names)
            self.assertIn(f"{prefix}/licenses/upstream/sing-box.txt", names)
            source = json.load(archive.extractfile(f"{prefix}/BUILD_INFO.json"))
            self.assertEqual(source["source_commit"], "a" * 40)
            self.assertEqual(source["homepage"], artifacts.HOMEPAGE)
            self.assertEqual(archive.getmember(f"{prefix}/app/lib/avalon-helper").mode & 0o777, 0o755)
        self.assert_checksums()

    def assert_checksums(self):
        dist = self.repo / "dist"
        records = (dist / "SHA256SUMS").read_text().splitlines()
        actual_files = {p.relative_to(dist).as_posix() for p in dist.rglob("*") if p.is_file() and p.name != "SHA256SUMS"}
        self.assertEqual({line.split("  ", 1)[1] for line in records}, actual_files)
        for line in records:
            digest, name = line.split("  ", 1)
            self.assertEqual(hashlib.sha256((dist / name).read_bytes()).hexdigest(), digest)

    def test_linux_missing_helper_fails_without_partial_output(self):
        self.linux_bundle()
        (self.repo / "core/out/avalon-helper-linux-amd64").unlink()
        with self.assertRaises(artifacts.ArtifactError):
            artifacts.package(self.args())
        self.assertFalse((self.repo / "dist").exists())

    def test_missing_license_fails_without_partial_output(self):
        self.linux_bundle()
        (self.repo / "COPYRIGHT").unlink()
        with self.assertRaises(artifacts.ArtifactError):
            artifacts.package(self.args())
        self.assertFalse((self.repo / "dist").exists())

    def test_rejects_stale_output(self):
        self.linux_bundle()
        self.write("dist/stale.apk")
        with self.assertRaises(artifacts.ArtifactError):
            artifacts.package(self.args())
        self.assertEqual((self.repo / "dist/stale.apk").read_text(), "fixture")

    def test_rejects_output_outside_dist(self):
        for name in ("../elsewhere", "app", "core", ".", "dist/../../elsewhere"):
            with self.subTest(name=name), self.assertRaises(artifacts.ArtifactError):
                artifacts.package(self.args(dist=Path(name)))

    def test_rejects_bundle_symlink_escaping_to_repo(self):
        self.linux_bundle()
        bundle = self.repo / "app/build/linux/x64/release/bundle"
        (bundle / "leaked-source").symlink_to(self.repo / "COPYRIGHT")
        with self.assertRaises(artifacts.ArtifactError):
            artifacts.package(self.args())

    def test_linux_preserves_safe_relative_library_symlinks(self):
        self.linux_bundle()
        library = self.repo / "app/build/linux/x64/release/bundle/lib"
        (library / "libflutter.so").symlink_to("libflutter_linux_gtk.so")
        artifacts.package(self.args())
        with tarfile.open(next((self.repo / "dist").glob("*.tar.gz"))) as archive:
            links = [entry for entry in archive.getmembers() if entry.issym()]
            self.assertEqual(len(links), 1)
            self.assertEqual(links[0].linkname, "libflutter_linux_gtk.so")

    def test_android_unsigned_apks_and_checksum_inventory(self):
        self.apks()
        with patch.object(artifacts.subprocess, "run", return_value=self.verification()):
            info = artifacts.package(self.args("android"))
        self.assertEqual(info["status"], "unsigned-validation")
        self.assertEqual(len(info["artifacts"]), 3)
        self.assertTrue(all("unsigned-validation" in item["name"] for item in info["artifacts"]))
        self.assert_checksums()

    def test_android_missing_abi_does_not_leave_partial_apks(self):
        paths = self.apks()
        paths[-1].unlink()
        with patch.object(artifacts.subprocess, "run", return_value=self.verification()), self.assertRaises(artifacts.ArtifactError):
            artifacts.package(self.args("android"))
        self.assertFalse((self.repo / "dist").exists())

    def test_android_release_requires_verified_non_debug_certificate(self):
        path = self.apks()[0]
        reports = (
            self.verification(),
            self.verification(0, "Signer #1 certificate DN: CN=Android Debug\nSigner #1 certificate SHA-256 digest: " + "a" * 64, ""),
            self.verification(0, "unexpected output", ""),
        )
        for report in reports:
            with self.subTest(report=report), patch.object(artifacts.subprocess, "run", return_value=report), self.assertRaises(artifacts.ArtifactError):
                artifacts.verify_android(path, "release", "apksigner")
        valid = self.verification(0, "Signer #1 certificate DN: CN=Avalon\nSigner #1 certificate SHA-256 digest: " + "a" * 64, "")
        with patch.object(artifacts.subprocess, "run", return_value=valid):
            artifacts.verify_android(path, "release", "apksigner")

    def test_android_unsigned_rejects_signed_or_corrupt_signature_reports(self):
        path = self.apks()[0]
        for report in (self.verification(0), self.verification(1, stderr="ERROR: digest mismatch"), self.verification(2)):
            with self.subTest(report=report), patch.object(artifacts.subprocess, "run", return_value=report), self.assertRaises(artifacts.ArtifactError):
                artifacts.verify_android(path, "unsigned", "apksigner")

    def test_android_rejects_non_apk_zip(self):
        path = self.write("invalid.apk", "not an archive")
        with self.assertRaises(artifacts.ArtifactError):
            artifacts.verify_android(path, "unsigned", "apksigner")

    def test_android_unsigned_rejects_leftover_jar_signer(self):
        path = self.apks()[0]
        with zipfile.ZipFile(path, "a") as archive:
            archive.writestr("META-INF/CERT.RSA", "damaged certificate")
        with patch.object(artifacts.subprocess, "run", return_value=self.verification()), self.assertRaises(artifacts.ArtifactError):
            artifacts.verify_android(path, "unsigned", "apksigner")

if __name__ == "__main__":
    unittest.main()

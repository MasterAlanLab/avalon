"""Release eligibility and manifest tests using unsigned fixtures, never real keys."""

import argparse
import hashlib
import json
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch
import zipfile

sys.path.insert(0, str(Path(__file__).parent))
import artifacts
import prepare_release as release


class PrepareReleaseTests(unittest.TestCase):
    def setUp(self):
        temporary = tempfile.TemporaryDirectory()
        self.addCleanup(temporary.cleanup)
        self.repo = Path(temporary.name)
        self.source = self.repo / "dist/input/android"
        self.source.mkdir(parents=True)
        self.output = self.repo / "dist/release"
        self.write("mise.toml", '[tools]\nflutter = "3.44.4"\n')
        self.write("app/pubspec.yaml", "version: 2.0.0+1\n")
        for name in ("LICENSE", "COPYRIGHT", "THIRD_PARTY_NOTICES.md", "docs/licenses/core.txt", "app/assets/licenses/app.txt"):
            self.write(name, "license fixture")
        self.info = {
            "schema_version": 1, "platform": "android", "arch": "all",
            "status": "release-signed-validation", "version": "2.0.0",
            "build_number": 20001, "source_commit": "a" * 40,
        }
        self.environment = {
            "GITHUB_EVENT_NAME": "push", "GITHUB_REF": "refs/tags/v2.0.0",
            "GITHUB_SHA": "a" * 40, "GITHUB_RUN_NUMBER": "1",
        }
        self.args = argparse.Namespace(
            repo_root=self.repo, input=Path("dist/input/android"), output=Path("dist/release"),
            apksigner="apksigner", aapt="aapt",
        )
        for abi in release.ABI_OFFSETS:
            with zipfile.ZipFile(self.apk(abi), "w") as archive:
                archive.writestr("AndroidManifest.xml", "manifest fixture")
        self.refresh_checksums()
        signer = patch.object(artifacts, "verify_android", return_value="b" * 64)
        self.signer = signer.start()
        self.addCleanup(signer.stop)
        aapt = patch.object(release.subprocess, "run", side_effect=self.aapt_result)
        self.aapt = aapt.start()
        self.addCleanup(aapt.stop)
        notes = patch.object(release.release_notes, "render", return_value="V1 template notes fixture\n")
        self.notes = notes.start()
        self.addCleanup(notes.stop)

    def write(self, name, value):
        path = self.repo / name
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(value)

    def apk(self, abi):
        return self.source / f"Avalon-2.0.0-android-{abi}-release-signed-validation.apk"

    def refresh_checksums(self):
        (self.source / "ARTIFACTS.json").write_text(json.dumps(self.info))
        (self.source / "SHA256SUMS").write_text("".join(
            f"{hashlib.sha256(path.read_bytes()).hexdigest()}  {path.name}\n"
            for path in sorted(self.source.iterdir()) if path.name != "SHA256SUMS"
        ))

    def aapt_result(self, command, **kwargs):
        abi = next(abi for abi in release.ABI_OFFSETS if abi in command[-1])
        report = (
            f"package: name='app.getavalon.avalon' versionCode='{20001 + release.ABI_OFFSETS[abi]}' versionName='2.0.0'\n"
            f"native-code: '{abi}'\n"
        )
        return subprocess.CompletedProcess(command, 0, report, "")

    def test_matching_tag_emits_only_installable_android_assets_and_compatible_manifest(self):
        # Unrelated platform artifacts must never enter the public release.
        (self.source / "unsigned-macos.zip").write_text("unpublishable fixture")
        self.refresh_checksums()
        manifest = release.assemble(self.args, self.environment)
        self.assertEqual(manifest, {
            "schema": 1, "application": "app.getavalon.avalon", "engine": "sing-box",
            "hostProtocol": 1, "version": "2.0.0", "platforms": ["android"],
        })
        self.assertEqual({p.name for p in self.output.iterdir()}, {
            "Avalon-2.0.0-android-armeabi-v7a.apk", "Avalon-2.0.0-android-arm64-v8a.apk",
            "Avalon-2.0.0-android-x86_64.apk", "Avalon-2.0.0-licenses.zip",
            "SOURCE.json", "avalon-client-release.json", "SHA256SUMS",
        })
        self.assertEqual(self.signer.call_count, 3)
        self.assertEqual(self.aapt.call_count, 3)
        self.notes.assert_called_once()
        note_repo, note_version, note_assets, note_commit = self.notes.call_args.args
        self.assertEqual((note_repo, note_version, note_commit), (self.repo.resolve(), "2.0.0", "a" * 40))
        self.assertEqual(set(note_assets), {path.name for path in self.output.iterdir()})
        self.assertEqual((self.output.parent / "release-notes.md").read_text(), "V1 template notes fixture\n")
        release.check_inventory(self.output)
        source = json.loads((self.output / "SOURCE.json").read_text())
        self.assertEqual(source["source_commit"], "a" * 40)
        self.assertEqual(source["android_certificate_sha256"], "b" * 64)
        with zipfile.ZipFile(self.output / "Avalon-2.0.0-licenses.zip") as archive:
            self.assertIn("Avalon-2.0.0-licenses/licenses/upstream/core.txt", archive.namelist())

    def test_main_pr_manual_and_mismatched_tag_cannot_assemble_a_release(self):
        cases = (
            {"GITHUB_REF": "refs/heads/main"},
            {"GITHUB_EVENT_NAME": "pull_request"},
            {"GITHUB_EVENT_NAME": "workflow_dispatch"},
            {"GITHUB_REF": "refs/tags/v2.0.1"},
            {"GITHUB_REF": "refs/tags/avalon-v2.0.0"},
            {"GITHUB_REF": "refs/tags/v1.0.18"},
        )
        for changes in cases:
            with self.subTest(changes=changes), self.assertRaises(artifacts.ArtifactError):
                release.assemble(self.args, {**self.environment, **changes})
            self.assertFalse(self.output.exists())
        self.signer.assert_not_called()

    def test_unsigned_wrong_commit_version_or_build_cannot_be_promoted(self):
        for key, value in (
            ("status", "unsigned-validation"), ("status", "build-validation"),
            ("source_commit", "c" * 40), ("version", "2.0.1"), ("build_number", 20002),
        ):
            with self.subTest(key=key, value=value):
                old = self.info[key]
                self.info[key] = value
                self.refresh_checksums()
                with self.assertRaises(artifacts.ArtifactError):
                    release.assemble(self.args, self.environment)
                self.info[key] = old
                self.assertFalse(self.output.exists())
        self.signer.assert_not_called()

    def test_corrupt_incomplete_or_extra_abi_rejected(self):
        path = self.apk("x86_64")
        original = path.read_bytes()
        path.write_bytes(b"corrupted fixture")
        with self.assertRaisesRegex(artifacts.ArtifactError, "checksum mismatch"):
            release.assemble(self.args, self.environment)
        path.unlink()
        self.refresh_checksums()
        with self.assertRaisesRegex(artifacts.ArtifactError, "three signed"):
            release.assemble(self.args, self.environment)
        path.write_bytes(original)
        (self.source / "debug.apk").write_bytes(original)
        self.refresh_checksums()
        with self.assertRaisesRegex(artifacts.ArtifactError, "three signed"):
            release.assemble(self.args, self.environment)
        self.assertFalse(self.output.exists())

    def test_signature_failure_or_mixed_certificates_rejected(self):
        self.signer.side_effect = artifacts.ArtifactError("invalid signature")
        with self.assertRaises(artifacts.ArtifactError):
            release.assemble(self.args, self.environment)
        self.signer.side_effect = ["b" * 64, "c" * 64, "b" * 64]
        with self.assertRaisesRegex(artifacts.ArtifactError, "same release signing"):
            release.assemble(self.args, self.environment)
        self.assertFalse(self.output.exists())

    def test_actual_apk_identity_version_build_and_abi_must_match(self):
        valid = self.aapt_result(["aapt", "dump", "badging", str(self.apk("arm64-v8a"))]).stdout
        for before, after in (
            ("app.getavalon.avalon", "dev.avalon.avalon"), ("2.0.0", "1.0.18"),
            ("22001", "22002"), ("native-code: 'arm64-v8a'", "native-code: 'x86_64'"),
        ):
            with self.subTest(before=before), self.assertRaises(artifacts.ArtifactError):
                self.aapt.side_effect = None
                self.aapt.return_value = subprocess.CompletedProcess([], 0, valid.replace(before, after), "")
                release.check_apk_identity(self.apk("arm64-v8a"), "aapt", "2.0.0", 20001, "arm64-v8a")

    def test_existing_output_is_never_overwritten(self):
        self.output.mkdir()
        marker = self.output / "preserve.txt"
        marker.write_text("preserve")
        with self.assertRaises(artifacts.ArtifactError):
            release.assemble(self.args, self.environment)
        self.assertEqual(marker.read_text(), "preserve")


if __name__ == "__main__":
    unittest.main()

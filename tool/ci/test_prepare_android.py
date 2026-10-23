"""Offline stdlib checks: never install an SDK or use a real signing key."""

import base64
from contextlib import redirect_stderr, redirect_stdout
import importlib.util
import io
import os
from pathlib import Path
import stat
import tempfile
import unittest
from unittest import mock


spec = importlib.util.spec_from_file_location(
    "prepare_android", Path(__file__).with_name("prepare_android.py")
)
prepare = importlib.util.module_from_spec(spec)
spec.loader.exec_module(prepare)


class PrepareAndroidTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name)
        self.environment = {
            "RUNNER_TEMP": str(self.root),
            "GITHUB_ENV": str(self.root / "github-env"),
            "GITHUB_OUTPUT": str(self.root / "github-output"),
        }

    def signing_environment(self):
        return {
            **self.environment,
            "KEYSTORE": base64.b64encode(b"not-a-real-keystore").decode(),
            "KEY_ALIAS": "fixture-alias",
            "STORE_PASSWORD": "fixture-store-password",
            "KEY_PASSWORD": "fixture-key-password",
        }

    def test_no_secrets_produces_only_unsigned_output(self):
        self.assertEqual(prepare.prepare_signing(self.environment), "unsigned")
        self.assertEqual((self.root / "github-output").read_text(), "signing_kind=unsigned\n")
        self.assertFalse((self.root / "github-env").exists())
        self.assertFalse((self.root / "avalon-release.keystore").exists())

    def test_tagged_release_rejects_missing_signing_without_unsigned_output(self):
        with self.assertRaisesRegex(prepare.PreparationError, "Tagged releases require"):
            prepare.prepare_signing(self.environment, require_release=True)
        self.assertFalse((self.root / "github-output").exists())
        self.assertFalse((self.root / "github-env").exists())
        self.assertFalse((self.root / "avalon-release.keystore").exists())

    def test_each_missing_secret_fails_without_persisting_anything(self):
        for name in ("KEYSTORE", "KEY_ALIAS", "STORE_PASSWORD", "KEY_PASSWORD"):
            with self.subTest(name=name):
                environment = self.signing_environment()
                del environment[name]
                with self.assertRaisesRegex(prepare.PreparationError, "all four"):
                    prepare.prepare_signing(environment)
                self.assertFalse((self.root / "avalon-release.keystore").exists())
                self.assertFalse((self.root / "github-env").exists())
                self.assertFalse((self.root / "github-output").exists())

    def test_invalid_or_empty_base64_does_not_write_a_keystore(self):
        for value in ("not-base64!", "eA=", "\n \t", "非base64"):
            with self.subTest(value=value):
                environment = {**self.signing_environment(), "KEYSTORE": value}
                with self.assertRaises(prepare.PreparationError):
                    prepare.prepare_signing(environment)
                self.assertFalse((self.root / "avalon-release.keystore").exists())

    def test_signing_file_is_private_and_only_its_path_is_exported(self):
        environment = self.signing_environment()
        environment["KEYSTORE"] = "\n" + environment["KEYSTORE"] + "\n"
        self.assertEqual(prepare.prepare_signing(environment), "release")
        keystore = self.root / "avalon-release.keystore"
        self.assertEqual(keystore.read_bytes(), b"not-a-real-keystore")
        self.assertEqual(stat.S_IMODE(keystore.stat().st_mode), 0o600)
        self.assertEqual((self.root / "github-env").read_text(), f"AVALON_KEYSTORE_PATH={keystore}\n")
        self.assertEqual((self.root / "github-output").read_text(), "signing_kind=release\n")
        for name in ("KEY_ALIAS", "STORE_PASSWORD", "KEY_PASSWORD", "KEYSTORE"):
            self.assertNotIn(environment[name], (self.root / "github-env").read_text())

    def test_existing_path_or_symlink_is_never_overwritten(self):
        target = self.root / "existing-keystore"
        target.write_bytes(b"preserve")
        destination = self.root / "avalon-release.keystore"
        for symlink in (False, True):
            with self.subTest(symlink=symlink):
                if symlink:
                    destination.symlink_to(target)
                else:
                    destination.write_bytes(b"preserve")
                with self.assertRaises(prepare.PreparationError):
                    prepare.prepare_signing(self.signing_environment())
                self.assertEqual(destination.read_bytes(), b"preserve")
                self.assertEqual(target.read_bytes(), b"preserve")
                destination.unlink()

    def test_cli_errors_do_not_echo_secrets_or_a_traceback(self):
        environment = {**self.signing_environment(), "KEYSTORE": "private-fixture-invalid!"}
        stdout, stderr = io.StringIO(), io.StringIO()
        with mock.patch.dict(os.environ, environment, clear=True), \
                mock.patch("sys.argv", ["prepare_android.py", "signing"]), \
                redirect_stdout(stdout), redirect_stderr(stderr):
            self.assertEqual(prepare.main(), 1)
        logs = stdout.getvalue() + stderr.getvalue()
        self.assertIn("not valid base64", logs)
        self.assertNotIn("Traceback", logs)
        for name in ("KEYSTORE", "KEY_ALIAS", "STORE_PASSWORD", "KEY_PASSWORD"):
            self.assertNotIn(environment[name], logs)

if __name__ == "__main__":
    unittest.main()

"""Release template and reachable V2 changelog regression tests."""

from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import unittest

sys.path.insert(0, str(Path(__file__).parent))
import release_notes


class ReleaseNotesTests(unittest.TestCase):
    def setUp(self):
        temporary = tempfile.TemporaryDirectory()
        self.addCleanup(temporary.cleanup)
        self.repo = Path(temporary.name)
        (self.repo / ".github").mkdir()
        shutil.copyfile(
            Path(__file__).resolve().parents[2] / ".github/release_template.md",
            self.repo / ".github/release_template.md",
        )
        self.git("init", "-b", "main")
        self.git("config", "user.name", "Release notes fixture")
        self.git("config", "user.email", "release@example.invalid")

    def git(self, *arguments):
        return subprocess.run(
            ["git", "-C", str(self.repo), *arguments],
            capture_output=True, text=True, check=True,
        ).stdout.strip()

    def commit(self, body):
        self.git("commit", "--allow-empty", "-m", body)
        return self.git("rev-parse", "HEAD")

    def test_v1_template_keeps_badge_and_android_table_without_unpublished_platforms(self):
        assets = [
            f"Avalon-2.0.0-android-{abi}.apk"
            for abi in ("arm64-v8a", "armeabi-v7a", "x86_64")
        ] + ["SOURCE.json", "Avalon-2.0.0-licenses.zip"]
        result = release_notes.render(
            self.repo, "2.0.0", assets, "a" * 40,
            changelog="Improve TUN response\n\nKeep animation quality\nUpdate changelog\n   \n",
        )
        self.assertTrue(result.startswith("- Improve TUN response\n\n- Keep animation quality\n\n"))
        self.assertIn("[![Release Downloads]", result)
        self.assertIn("/v2.0.0/total?style=flat-square&logo=github", result)
        self.assertIn("<table>", result)
        self.assertIn("<td>Android</td>", result)
        for asset in assets[:3]:
            self.assertIn(f"releases/download/v2.0.0/{asset}", result)
        for unpublished in ("Windows", "macOS", "Linux", "VERSION", "Update changelog"):
            self.assertNotIn(unpublished, result)

    def test_partial_platform_inventory_never_emits_missing_asset_links(self):
        result = release_notes.render(
            self.repo, "2.0.1", ["Avalon-2.0.1-android-arm64-v8a.apk"], "a" * 40, changelog="",
        )
        self.assertIn("<td>Android</td>", result)
        self.assertIn("APK-ARMv8", result)
        self.assertNotIn("armeabi-v7a", result)
        self.assertNotIn("x86_64", result)
        self.assertNotIn("<td>Linux</td>", result)
        empty = release_notes.render(self.repo, "2.0.1", [], "a" * 40, changelog="")
        self.assertNotIn("releases/download/", empty)
        self.assertNotIn("<td>Android</td>", empty)

    def test_incremental_notes_use_only_reachable_previous_stable_v2_tag(self):
        initial = self.commit("Already released V2")
        self.git("tag", "v2.0.0")
        self.git("checkout", "-b", "other")
        self.commit("Unrelated future branch")
        self.git("tag", "v2.9.0")
        self.git("checkout", "main")
        self.commit("New release change")
        current = self.commit("Another detail")
        self.git("tag", "v2.10.0")
        result = release_notes.render(self.repo, "2.10.0", [], current)
        self.assertIn("- New release change", result)
        self.assertIn("- Another detail", result)
        self.assertNotIn("Already released V2", result)
        self.assertNotIn("Unrelated future branch", result)
        self.assertEqual(self.git("rev-parse", "v2.0.0"), initial)

    def test_v1_tags_never_bound_current_generation_notes(self):
        self.commit("Start V2 clean-room implementation")
        self.git("checkout", "--orphan", "legacy")
        self.commit("Unrelated V1 history")
        self.git("tag", "v1.0.18")
        self.git("checkout", "main")
        current = self.commit("V2 change")
        body = release_notes.collect_changelog(self.repo, "2.0.0", current)
        self.assertIn("Start V2 clean-room implementation", body)
        self.assertIn("V2 change", body)
        self.assertNotIn("Unrelated V1 history", body)

    def test_shallow_history_cannot_silently_emit_incomplete_notes(self):
        self.commit("First V2 change")
        current = self.commit("Newest V2 change")
        with tempfile.TemporaryDirectory() as temporary:
            clone = Path(temporary) / "shallow"
            subprocess.run(
                ["git", "clone", "--depth=1", self.repo.as_uri(), str(clone)],
                capture_output=True, text=True, check=True,
            )
            with self.assertRaisesRegex(ValueError, "complete current-generation"):
                release_notes.collect_changelog(clone, "2.0.0", current)


if __name__ == "__main__":
    unittest.main()

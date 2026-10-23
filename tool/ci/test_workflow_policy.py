"""Keep branch checks separate from signed, tag-only release builds."""

from __future__ import annotations

import json
from pathlib import Path
import re
import unittest

import yaml


REPO = Path(__file__).resolve().parents[2]
WORKFLOWS = REPO / ".github/workflows"
NATIVE_JOBS = {"android", "linux", "windows", "macos", "ios"}
BUILD_OR_PUBLISH = re.compile(
    r"\bflutter\s+build\b|\bxcodebuild\b|\bgh\s+release\b|"
    r"(?:^|[\s/])build\.sh\s+(?:android|apple|helper|tools)\b|"
    r"(?:softprops/action-gh-release|ncipollo/release-action)@",
    re.MULTILINE,
)


def load_yaml(path: Path) -> dict:
    # BaseLoader keeps GitHub's `on` key and all boolean-like values as strings.
    document = yaml.load(path.read_text(encoding="utf-8"), Loader=yaml.BaseLoader)
    if not isinstance(document, dict):
        raise AssertionError(f"Expected a YAML mapping: {path}")
    return document


def needs(job: dict) -> set[str]:
    value = job.get("needs", [])
    if isinstance(value, str):
        return {value}
    if not isinstance(value, list):
        raise AssertionError("Job dependencies must be a name or a list of names.")
    return set(value)


def permissions(document: dict, job: dict | None = None) -> dict:
    value = (job or {}).get("permissions", document.get("permissions", {}))
    if not isinstance(value, dict):
        raise AssertionError("Workflow permissions must explicitly name their scopes.")
    return value


class WorkflowPolicyTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.ci = load_yaml(WORKFLOWS / "ci.yml")
        cls.release = load_yaml(WORKFLOWS / "release.yml")

    def test_main_pull_requests_and_manual_runs_only_reach_checks(self):
        triggers = self.ci["on"]
        self.assertEqual(
            set(triggers), {"push", "pull_request", "workflow_dispatch", "workflow_call"}
        )
        for event in ("push", "pull_request"):
            self.assertEqual(triggers[event], {"branches": ["main"]})
        self.assertEqual(set(self.ci["jobs"]), {"checks"})
        self.assertNotRegex(json.dumps(self.ci), BUILD_OR_PUBLISH)
        self.assertNotIn("secrets.", json.dumps(self.ci))

        # A composite setup action is executable on PRs too; its steps must not
        # quietly introduce an app build or release outside the workflow graph.
        for step in self.ci["jobs"]["checks"].get("steps", []):
            action = step.get("uses", "")
            if action.startswith("./"):
                setup = load_yaml(REPO / action / "action.yml")
                self.assertNotRegex(json.dumps(setup), BUILD_OR_PUBLISH)
                self.assertNotIn("secrets.", json.dumps(setup))

    def test_release_builds_can_only_start_from_a_pushed_v_tag(self):
        self.assertEqual(
            self.release["on"], {"push": {"tags": ["v*"]}}
        )
        checks = self.release["jobs"]["checks"]
        self.assertEqual(checks["uses"], "./.github/workflows/ci.yml")
        self.assertNotIn("secrets", checks)
        self.assertNotIn("runs-on", checks)

    def test_publish_requires_successful_checks_and_every_native_build(self):
        jobs = self.release["jobs"]
        self.assertTrue(NATIVE_JOBS | {"checks", "publish"} <= set(jobs))
        self.assertTrue(
            NATIVE_JOBS | {"checks"} <= needs(jobs["publish"]),
            "Publishing must wait for every platform, including validation-only builds.",
        )
        for name in NATIVE_JOBS:
            self.assertIn("checks", needs(jobs[name]))
        for name in NATIVE_JOBS | {"checks", "publish"}:
            with self.subTest(job=name):
                job = jobs[name]
                self.assertNotEqual(job.get("continue-on-error"), "true")
                self.assertNotRegex(
                    job.get("if", ""), r"\b(?:always|failure|cancelled)\s*\("
                )
                for step in job.get("steps", []):
                    self.assertNotEqual(step.get("continue-on-error"), "true")

    def test_only_publish_can_write_repository_contents(self):
        for filename, workflow in (("ci.yml", self.ci), ("release.yml", self.release)):
            self.assertEqual(permissions(workflow), {"contents": "read"})
            for name, job in workflow["jobs"].items():
                with self.subTest(workflow=filename, job=name):
                    effective = permissions(workflow, job)
                    if filename == "release.yml" and name == "publish":
                        self.assertEqual(effective, {"contents": "write"})
                    else:
                        self.assertEqual(effective, {"contents": "read"})

    def test_signing_secrets_are_confined_to_android_and_never_optional(self):
        self.assertNotIn("secrets.", json.dumps(self.release.get("env", {})))
        for name, job in self.release["jobs"].items():
            if name not in {"android", "publish"}:
                with self.subTest(job=name):
                    self.assertNotIn("secrets.", json.dumps(job))
                    self.assertNotIn("secrets", job)
        android = self.release["jobs"]["android"]
        signing = [
            step
            for step in android.get("steps", [])
            if re.search(r"prepare_android\.py\s+signing\b", step.get("run", ""))
        ]
        self.assertEqual(len(signing), 1)
        self.assertRegex(signing[0]["run"], r"(?:^|\s)--require-release(?:\s|$)")
        self.assertNotIn("if", signing[0], "Tag builds must always require release signing.")
        self.assertNotRegex(
            json.dumps(android), r"\|\|\s*['\"]unsigned['\"]",
            "A missing release signature must fail rather than produce an unsigned release.",
        )

if __name__ == "__main__":
    unittest.main()

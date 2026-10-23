#!/usr/bin/env python3
"""Render the V1 release template using current-generation history and assets."""

from __future__ import annotations

from collections.abc import Iterable
from pathlib import Path
import re
import subprocess


VERSION = re.compile(r"([0-9]+)\.([0-9]+)\.([0-9]+)")
DOWNLOAD = re.compile(
    r'<a href="https://github\.com/MasterAlanLab/avalon/releases/download/'
    r'vVERSION/([^"/]+)">.*?</a>(?:<br>)?',
    re.DOTALL,
)
ROW = re.compile(r"[ \t]*<tr>.*?</tr>\n?", re.DOTALL)


def _version(value: str) -> tuple[int, int, int]:
    match = VERSION.fullmatch(value)
    if not match or int(match[1]) < 2:
        raise ValueError("Release notes require a stable V2 or later version.")
    return tuple(int(part) for part in match.groups())


def _git(repo: Path, *arguments: str) -> str:
    result = subprocess.run(
        ["git", "-C", str(repo), *arguments],
        capture_output=True, text=True, check=True,
    )
    return result.stdout


def collect_changelog(repo: Path, version: str, commit: str) -> str:
    """Read only the tagged V2 history since its last reachable stable major tag."""
    current = _version(version)
    if not re.fullmatch(r"[0-9a-f]{40}|[0-9a-f]{64}", commit):
        raise ValueError("Release notes require the tagged commit SHA.")
    if _git(repo, "rev-parse", "--is-shallow-repository").strip() != "false":
        raise ValueError("Release notes require the complete current-generation commit history.")
    resolved = _git(repo, "rev-parse", "--verify", f"{commit}^{{commit}}").strip()
    previous: tuple[tuple[int, int, int], str] | None = None
    for tag in _git(repo, "for-each-ref", "--format=%(refname:short)", "refs/tags").splitlines():
        match = re.fullmatch(r"v([0-9]+\.[0-9]+\.[0-9]+)", tag)
        if not match:
            continue
        parts = tuple(int(part) for part in match[1].split("."))
        if parts[0] != current[0] or parts >= current:
            continue
        reachable = subprocess.run(
            ["git", "-C", str(repo), "merge-base", "--is-ancestor", tag, resolved],
            capture_output=True, text=True,
        )
        if reachable.returncode not in (0, 1):
            raise subprocess.CalledProcessError(
                reachable.returncode, reachable.args, reachable.stdout, reachable.stderr,
            )
        if reachable.returncode == 0 and (previous is None or parts > previous[0]):
            previous = (parts, tag)
    revision = f"{previous[1]}..{resolved}" if previous else resolved
    return _git(repo, "log", "--no-merges", "--pretty=format:%B", revision, "--")


def format_changelog(body: str) -> str:
    """Match V1: one bullet per nonempty commit-body line, excluding changelog noise."""
    return "".join(
        f"- {line}\n\n" for line in body.splitlines()
        if line.strip() and "Update changelog" not in line
    )


def render(
    repo: Path,
    version: str,
    assets: Iterable[str | Path],
    commit: str,
    *,
    changelog: str | None = None,
) -> str:
    """Render notes; assets are verified public asset names, changelog is raw log text."""
    _version(version)
    names = {Path(asset).name for asset in assets}
    template = (repo / ".github/release_template.md").read_text()

    def filter_row(match: re.Match[str]) -> str:
        row = match[0]
        if not DOWNLOAD.search(row):
            return row
        kept = False

        def filter_download(download: re.Match[str]) -> str:
            nonlocal kept
            if download[1].replace("VERSION", version) in names:
                kept = True
                return download[0]
            return ""

        row = DOWNLOAD.sub(filter_download, row)
        return row if kept else ""

    template = ROW.sub(filter_row, template).replace("VERSION", version)
    if changelog is None:
        changelog = collect_changelog(repo, version, commit)
    return format_changelog(changelog) + template

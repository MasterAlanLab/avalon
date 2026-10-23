#!/usr/bin/env python3
"""Verify tagged Android artifacts and assemble assets; never publish from here."""

from __future__ import annotations

import argparse
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys
import tempfile

import artifacts
import release_notes


APPLICATION = "app.getavalon.avalon"
ABI_OFFSETS = {"armeabi-v7a": 1000, "arm64-v8a": 2000, "x86_64": 4000}


def check_inventory(directory: Path) -> None:
    artifacts.checked_tree(directory)
    files = {p.relative_to(directory).as_posix(): p for p in directory.rglob("*") if p.is_file()}
    if any(p.is_symlink() for p in directory.rglob("*")):
        raise artifacts.ArtifactError("Release input must contain only regular files and directories.")
    sums = artifacts.require_file(directory / "SHA256SUMS").read_text().splitlines()
    expected = {}
    for line in sums:
        match = re.fullmatch(r"([0-9a-f]{64})  (.+)", line)
        if not match or match[2] in expected or match[2] not in files:
            raise artifacts.ArtifactError("Invalid or duplicate artifact checksum entry.")
        expected[match[2]] = match[1]
    if set(expected) != set(files) - {"SHA256SUMS"}:
        raise artifacts.ArtifactError("Artifact checksum inventory is incomplete.")
    for name, digest in expected.items():
        if artifacts.sha256(files[name]) != digest:
            raise artifacts.ArtifactError(f"Artifact checksum mismatch: {name}")


def check_apk_identity(path: Path, aapt: str, version: str, build: int, abi: str) -> None:
    result = subprocess.run([aapt, "dump", "badging", str(path)], capture_output=True, text=True, check=True)
    package = re.search(
        r"^package: name='([^']+)' versionCode='([0-9]+)' versionName='([^']+)'",
        result.stdout, re.MULTILINE,
    )
    native = re.search(r"^native-code: (.+)$", result.stdout, re.MULTILINE)
    if (
        not package or package[1] != APPLICATION or package[3] != version
        or int(package[2]) != build + ABI_OFFSETS[abi]
        or not native or native[1].strip() != f"'{abi}'"
    ):
        raise artifacts.ArtifactError(f"APK application, version, build or ABI mismatch: {path.name}")


def assemble(args: argparse.Namespace, env: dict[str, str] | None = None) -> dict:
    env = os.environ if env is None else env
    repo = args.repo_root.resolve()
    metadata = artifacts.read_metadata(repo, env)
    version = metadata["version"]
    if env.get("GITHUB_EVENT_NAME") != "push" or env.get("GITHUB_REF") != f"refs/tags/v{version}":
        raise artifacts.ArtifactError("Release assembly requires a push of the matching version tag.")
    commit = env.get("GITHUB_SHA", "")
    if not re.fullmatch(r"[0-9a-f]{40}|[0-9a-f]{64}", commit):
        raise artifacts.ArtifactError("Release assembly requires the tagged commit SHA.")
    source = (repo / args.input).resolve()
    output = (repo / args.output).resolve()
    if not output.is_relative_to(repo / "dist") or output == source or output.is_relative_to(source):
        raise artifacts.ArtifactError("Release output must be a separate directory inside dist/.")
    if output.exists():
        raise artifacts.ArtifactError("Release output must not already exist.")
    check_inventory(source)
    info = json.loads(artifacts.require_file(source / "ARTIFACTS.json").read_text())
    required = {
        "schema_version": 1, "platform": "android", "arch": "all",
        "status": "release-signed-validation", "version": version,
        "build_number": int(metadata["build_number"]), "source_commit": commit,
    }
    if not isinstance(info, dict) or any(info.get(key) != value for key, value in required.items()):
        raise artifacts.ArtifactError("Only signed Android artifacts from this tagged build can be released.")
    prefix = metadata["artifact_prefix"]
    expected = {f"{prefix}-android-{abi}-release-signed-validation.apk": abi for abi in ABI_OFFSETS}
    if {p.name for p in source.rglob("*.apk")} != set(expected):
        raise artifacts.ArtifactError("Release requires exactly the three signed Android ABI packages.")
    certificates = set()
    for name, abi in expected.items():
        path = artifacts.require_file(source / name)
        certificates.add(artifacts.verify_android(path, "release", args.apksigner))
        check_apk_identity(path, args.aapt, version, required["build_number"], abi)
    if len(certificates) != 1:
        raise artifacts.ArtifactError("All APKs must use the same release signing certificate.")
    manifest = {
        "schema": 1, "application": APPLICATION, "engine": "sing-box", "hostProtocol": 1,
        "version": version, "platforms": ["android"],
    }
    output.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(prefix=".avalon-release-", dir=output.parent) as temporary:
        work = Path(temporary)
        staged = work / "output"
        staged.mkdir()
        for name, abi in expected.items():
            shutil.copy2(source / name, staged / f"{prefix}-android-{abi}.apk")
        licenses = work / f"{prefix}-licenses"
        artifacts.copy_licenses(repo, licenses)
        artifacts.make_zip(licenses, staged / f"{prefix}-licenses.zip")
        artifacts.write_json(staged / "avalon-client-release.json", manifest)
        artifacts.write_json(staged / "SOURCE.json", {
            "version": version, "build_number": required["build_number"],
            "source_commit": commit, "source_url": f"{artifacts.SOURCE}/tree/{commit}",
            "homepage": artifacts.HOMEPAGE, "android_certificate_sha256": next(iter(certificates)),
        })
        (staged / "SHA256SUMS").write_text("".join(
            f"{artifacts.sha256(path)}  {path.name}\n" for path in sorted(staged.iterdir())
        ))
        notes = release_notes.render(repo, version, [path.name for path in staged.iterdir()], commit)
        shutil.move(str(staged), str(output))
    (output.parent / "release-notes.md").write_text(notes)
    return manifest


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--repo-root", type=Path, default=Path(__file__).resolve().parents[2])
    parser.add_argument("--input", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--apksigner", required=True)
    parser.add_argument("--aapt", required=True)
    try:
        print(json.dumps(assemble(parser.parse_args()), indent=2))
        return 0
    except (artifacts.ArtifactError, OSError, ValueError, subprocess.SubprocessError) as error:
        print(f"Release validation failed: {error}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    sys.exit(main())

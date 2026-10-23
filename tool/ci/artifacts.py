#!/usr/bin/env python3
"""Collect CI validation artifacts. This tool never publishes a release."""

from __future__ import annotations

import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys
import tarfile
import tempfile
import zipfile


SOURCE = "https://github.com/MasterAlanLab/avalon"
HOMEPAGE = "https://getavalon.app"
ABI_NAMES = ("arm64-v8a", "armeabi-v7a", "x86_64")


class ArtifactError(ValueError):
    pass


def read_metadata(repo: Path, env: dict[str, str] | None = None) -> dict:
    env = os.environ if env is None else env
    pin = re.search(
        r'^flutter\s*=\s*"([0-9]+\.[0-9]+\.[0-9]+)"\s*$',
        (repo / "mise.toml").read_text(),
        re.MULTILINE,
    )
    version = re.search(
        r"^version:\s*([0-9]+\.[0-9]+\.[0-9]+)\+([0-9]+)\s*$",
        (repo / "app/pubspec.yaml").read_text(),
        re.MULTILINE,
    )
    if not pin or not version:
        raise ArtifactError("Expected a Flutter pin and a three-part pubspec version.")
    name = version[1]
    if int(name.split(".")[0]) < 2:
        raise ArtifactError("V2 CI requires pubspec major version 2 or later.")
    run = env.get("GITHUB_RUN_NUMBER", "1")
    if not re.fullmatch(r"[1-9][0-9]*", run):
        raise ArtifactError("GITHUB_RUN_NUMBER must be a positive integer.")
    number = 20000 + int(run)
    # Flutter's split APK versionCode adds an ABI offset of up to 4000.
    if number > 2_099_995_999:
        raise ArtifactError("Build number exceeds the Android versionCode range.")
    ref = env.get("GITHUB_REF", "")
    is_tag = env.get("GITHUB_REF_TYPE") == "tag" or ref.startswith("refs/tags/")
    tag = env.get("GITHUB_REF_NAME") or ref.removeprefix("refs/tags/")
    if is_tag and tag != f"v{name}":
        raise ArtifactError(f"Tag must be v{name}, matching app/pubspec.yaml.")
    return {
        "flutter_version": pin[1],
        "version": name,
        "build_number": str(number),
        "artifact_prefix": f"Avalon-{name}",
    }


def require_file(path: Path) -> Path:
    if not path.is_file() or path.is_symlink():
        raise ArtifactError(f"Missing regular file: {path}")
    return path


def checked_tree(path: Path) -> Path:
    if not path.is_dir() or path.is_symlink():
        raise ArtifactError(f"Missing directory: {path}")
    base = path.resolve()
    for child in path.rglob("*"):
        if child.is_symlink() and (
            Path(os.readlink(child)).is_absolute()
            or not child.resolve().is_relative_to(base)
        ):
            raise ArtifactError(f"Bundle symlink escapes its directory: {child}")
        if not child.is_symlink() and not child.is_file() and not child.is_dir():
            raise ArtifactError(f"Unsupported bundle entry: {child}")
    return path


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for block in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def write_json(path: Path, value: object) -> None:
    path.write_text(json.dumps(value, indent=2, ensure_ascii=False) + "\n")


def copy_licenses(repo: Path, destination: Path) -> None:
    destination.mkdir(parents=True, exist_ok=True)
    for name in ("LICENSE", "COPYRIGHT", "THIRD_PARTY_NOTICES.md"):
        shutil.copy2(require_file(repo / name), destination / name)
    for source, name in (
        (repo / "docs/licenses", "upstream"),
        (repo / "app/assets/licenses", "app"),
    ):
        checked_tree(source)
        if not any(p.is_file() for p in source.rglob("*")):
            raise ArtifactError(f"License directory is empty: {source}")
        shutil.copytree(source, destination / "licenses" / name, symlinks=True)


def verify_android(path: Path, signing: str, apksigner: str) -> str | None:
    try:
        with zipfile.ZipFile(path) as apk:
            names = apk.namelist()
            if "AndroidManifest.xml" not in names or apk.testzip():
                raise ArtifactError(f"Invalid APK: {path.name}")
            jar_signer = any(
                re.fullmatch(r"META-INF/[^/]+\.(?:RSA|DSA|EC|SF)", name, re.I)
                for name in names
            )
            # V2/V3 signer data lives immediately before the ZIP central
            # directory rather than in META-INF. Reject even a damaged signer
            # block when the output is supposed to be unsigned.
            with path.open("rb") as stream:
                stream.seek(max(0, apk.start_dir - 16))
                apk_signer = stream.read(16) == b"APK Sig Block 42"
    except zipfile.BadZipFile as error:
        raise ArtifactError(f"Invalid APK: {path.name}") from error
    result = subprocess.run(
        [apksigner, "verify", "--print-certs", str(path)],
        capture_output=True,
        text=True,
        check=False,
    )
    report = result.stdout + "\n" + result.stderr
    if signing == "release":
        if result.returncode != 0:
            raise ArtifactError(f"APK signature verification failed: {path.name}")
        if re.search(r"(?:CN\s*=\s*Android Debug|Android Debug)", report, re.I):
            raise ArtifactError(f"Release APK uses a debug certificate: {path.name}")
        certificate = re.search(r"certificate SHA-256 digest:\s*([0-9a-f]{64})", report, re.I)
        if not certificate:
            raise ArtifactError(f"Cannot identify APK signing certificate: {path.name}")
        return certificate[1].lower()
    elif result.returncode == 0 or jar_signer or apk_signer:
        raise ArtifactError(f"Expected an unsigned APK, but found a signature: {path.name}")
    elif result.returncode != 1 or not re.search(
        r"Missing META-INF/MANIFEST.MF|No (?:JAR )?signatures", report, re.I
    ):
        raise ArtifactError(f"APK failed verification for a reason other than no signature: {path.name}")


def make_zip(source: Path, target: Path) -> None:
    # Native Apple bundles need ditto to preserve their framework symlinks.
    with zipfile.ZipFile(target, "w", zipfile.ZIP_DEFLATED) as archive:
        for path in sorted(source.rglob("*")):
            if path.is_symlink():
                raise ArtifactError(f"ZIP input contains a symlink: {path}")
            if path.is_file():
                archive.write(path, path.relative_to(source.parent))


def package(args: argparse.Namespace) -> dict:
    repo = args.repo_root.resolve()
    metadata = read_metadata(repo)
    number = args.build_number or metadata["build_number"]
    if not re.fullmatch(r"[1-9][0-9]*", str(number)):
        raise ArtifactError("Build number must be a positive integer.")
    commit = args.commit or os.environ.get("GITHUB_SHA")
    if not commit:
        commit = subprocess.check_output(
            ["git", "rev-parse", "HEAD"], cwd=repo, text=True
        ).strip()
    if not re.fullmatch(r"[0-9a-fA-F]{40}|[0-9a-fA-F]{64}", commit):
        raise ArtifactError("Commit must be a full hexadecimal git object ID.")
    requested_dist = args.dist or Path("dist")
    dist = (repo / requested_dist).resolve()
    if not dist.is_relative_to(repo / "dist") or dist == repo:
        raise ArtifactError("Artifact output must be inside the repository's dist/ directory.")
    if dist.exists() and any(dist.iterdir()):
        raise ArtifactError("Artifact output directory must be empty (prevents stale artifacts).")
    platform = args.platform
    if platform == "android":
        arch = "all"
        status = "release-signed-validation" if args.android_signing == "release" else "unsigned-validation"
    else:
        arch = args.arch
        if arch not in ("amd64", "arm64"):
            raise ArtifactError("Desktop and iOS artifacts require --arch amd64 or arm64.")
        if platform == "ios" and arch != "arm64":
            raise ArtifactError("The unsigned iOS device build requires arm64.")
        status = "unsigned-validation" if platform in ("macos", "ios") else "build-validation"
    info = {
        "schema_version": 1,
        "project": "Avalon",
        "version": metadata["version"],
        "build_number": int(number),
        "platform": platform,
        "arch": arch,
        "status": status,
        "homepage": HOMEPAGE,
        "source_repository": SOURCE,
        "source_commit": commit.lower(),
        "source_url": f"{SOURCE}/tree/{commit.lower()}",
        "publication": "CI validation artifact; not a published release",
        "limitations": {
            "android": "Installation requires a valid signature; unsigned artifacts cannot be installed.",
            "linux": "TUN requires the separately installed fixed-path helper and CAP_NET_ADMIN.",
            "windows": "Native runtime, UAC/service lifecycle, and release signing require Windows acceptance; this is build validation only.",
            "macos": "Unsigned and not notarized; System Extension authorization is not validated.",
            "ios": "Unsigned device app, not an IPA; installation and Packet Tunnel require team signing.",
        }[platform],
        "artifacts": [],
    }
    prefix = metadata["artifact_prefix"]
    # Assemble in a private sibling first; failures leave no partial distributable.
    dist.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(prefix=".avalon-ci-", dir=dist.parent) as temporary:
        work = Path(temporary)
        output = work / "output"
        output.mkdir()
        if platform == "android":
            for abi in ABI_NAMES:
                candidates = [
                    repo / f"app/build/app/outputs/flutter-apk/app-{abi}-release.apk",
                    repo / f"app/build/app/outputs/flutter-apk/app-{abi}-release-unsigned.apk",
                ]
                present = [p for p in candidates if p.exists()]
                if len(present) != 1:
                    raise ArtifactError(f"Expected exactly one release APK for {abi}.")
                source = require_file(present[0])
                verify_android(source, args.android_signing, args.apksigner)
                target = output / f"{prefix}-android-{abi}-{status}.apk"
                shutil.copy2(source, target)
            copy_licenses(repo, output)
            write_json(output / "BUILD_INFO.json", info)
        else:
            package_name = f"{prefix}-{platform}-{arch}-{status}"
            staging = work / package_name
            staging.mkdir()
            if platform in ("linux", "windows"):
                flutter_arch = "x64" if arch == "amd64" else "arm64"
                if platform == "linux":
                    bundle = repo / f"app/build/linux/{flutter_arch}/release/bundle"
                    executable = bundle / "avalon"
                else:
                    bundle = repo / f"app/build/windows/{flutter_arch}/runner/Release"
                    executable = bundle / "avalon.exe"
                checked_tree(bundle)
                require_file(executable)
                shutil.copytree(bundle, staging / "app", symlinks=True)
                suffix = ".exe" if platform == "windows" else ""
                helper = require_file(repo / f"core/out/avalon-helper-{platform}-{arch}{suffix}")
                helper_target = staging / "app" / ("lib/avalon-helper" if platform == "linux" else "avalon-helper.exe")
                helper_target.parent.mkdir(parents=True, exist_ok=True)
                shutil.copy2(helper, helper_target)
                if platform == "linux":
                    helper_target.chmod(0o755)
                    shutil.copy2(require_file(repo / "core/install_linux_helper.sh"), staging / "install_linux_helper.sh")
            else:
                bundle = repo / (
                    "app/build/macos/Build/Products/Release/Avalon.app"
                    if platform == "macos"
                    else "app/build/ios/iphoneos/Runner.app"
                )
                checked_tree(bundle)
                binary = bundle / ("Contents/MacOS/Avalon" if platform == "macos" else "Runner")
                require_file(bundle / ("Contents/Info.plist" if platform == "macos" else "Info.plist"))
                require_file(binary)
                shutil.copytree(bundle, staging / bundle.name, symlinks=True)
            copy_licenses(repo, staging)
            write_json(staging / "BUILD_INFO.json", info)
            if platform == "linux":
                target = output / f"{package_name}.tar.gz"
                with tarfile.open(target, "w:gz") as archive:
                    archive.add(staging, arcname=package_name)
            elif platform in ("macos", "ios"):
                target = output / f"{package_name}.zip"
                subprocess.run(
                    ["ditto", "-c", "-k", "--sequesterRsrc", "--keepParent", str(staging), str(target)],
                    check=True,
                )
            else:
                target = output / f"{package_name}.zip"
                make_zip(staging, target)
        info["artifacts"] = [
            {"name": p.name, "size": p.stat().st_size, "sha256": sha256(p)}
            for p in sorted(output.iterdir())
            if p.suffix in (".apk", ".zip", ".gz")
        ]
        write_json(output / "ARTIFACTS.json", info)
        files = sorted(p for p in output.rglob("*") if p.is_file())
        (output / "SHA256SUMS").write_text(
            "".join(f"{sha256(p)}  {p.relative_to(output).as_posix()}\n" for p in files)
        )
        if dist.exists():
            dist.rmdir()
        shutil.move(str(output), str(dist))
    return info


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    commands = parser.add_subparsers(dest="command", required=True)
    meta = commands.add_parser("metadata")
    meta.add_argument("--repo-root", type=Path, default=Path(__file__).resolve().parents[2])
    meta.add_argument("--github-output", type=Path)
    pack = commands.add_parser("package")
    pack.add_argument("--repo-root", type=Path, default=Path(__file__).resolve().parents[2])
    pack.add_argument("--platform", choices=("android", "linux", "windows", "macos", "ios"), required=True)
    pack.add_argument("--arch", choices=("amd64", "arm64"))
    pack.add_argument("--dist", type=Path)
    pack.add_argument("--build-number")
    pack.add_argument("--commit")
    pack.add_argument("--android-signing", choices=("unsigned", "release"), default="unsigned")
    pack.add_argument("--apksigner", default="apksigner")
    args = parser.parse_args()
    try:
        if args.command == "metadata":
            result = read_metadata(args.repo_root.resolve())
            output = args.github_output or os.environ.get("GITHUB_OUTPUT")
            if output:
                with Path(output).open("a") as stream:
                    for key, value in result.items():
                        stream.write(f"{key}={value}\n")
        else:
            result = package(args)
        print(json.dumps(result, indent=2))
        return 0
    except (ArtifactError, OSError, subprocess.SubprocessError) as error:
        print(f"Artifact validation failed: {error}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    sys.exit(main())

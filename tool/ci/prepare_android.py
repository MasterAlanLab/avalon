#!/usr/bin/env python3
"""Prepare the pinned Flutter NDK or optional Android release signing for CI."""

import argparse
import base64
import binascii
import os
from pathlib import Path
import re
import subprocess
import sys
from collections.abc import Mapping


class PreparationError(Exception):
    """A deliberately non-secret error suitable for a CI log."""


def flutter_ndk_version(source: str) -> str:
    """Read the exact SDK default used by Gradle's flutter.ndkVersion."""
    source = re.sub(r"/\*.*?\*/|//[^\n]*", "", source, flags=re.DOTALL)
    versions = re.findall(
        r'^\s*val\s+ndkVersion\s*:\s*String\s*=\s*"([0-9]+\.[0-9]+\.[0-9]+)"\s*;?\s*$',
        source,
        flags=re.MULTILINE,
    )
    if len(versions) != 1:
        raise PreparationError("Flutter's exact ndkVersion could not be determined.")
    return versions[0]


def _required(environment: Mapping[str, str], name: str) -> str:
    value = environment.get(name, "")
    if not value or "\n" in value or "\r" in value or "\0" in value:
        raise PreparationError(f"A valid {name} is required.")
    return value


def _append_values(path: str, values: Mapping[str, str]) -> None:
    if any("\n" in value or "\r" in value or "\0" in value for value in values.values()):
        raise PreparationError("A CI output value is not a single line.")
    try:
        with open(path, "a", encoding="utf-8") as destination:
            for name, value in values.items():
                destination.write(f"{name}={value}\n")
    except OSError:
        raise PreparationError("Could not write the GitHub Actions environment or output.") from None


def prepare_ndk(environment: Mapping[str, str]) -> str:
    flutter_root = Path(_required(environment, "FLUTTER_ROOT"))
    android_home = Path(_required(environment, "ANDROID_HOME"))
    github_env = _required(environment, "GITHUB_ENV")
    github_output = _required(environment, "GITHUB_OUTPUT")
    extension = flutter_root / "packages/flutter_tools/gradle/src/main/kotlin/FlutterExtension.kt"
    try:
        version = flutter_ndk_version(extension.read_text(encoding="utf-8"))
    except OSError:
        raise PreparationError("The installed Flutter Gradle extension could not be read.") from None
    sdkmanager = android_home / "cmdline-tools/latest/bin/sdkmanager"
    if not sdkmanager.is_file():
        raise PreparationError("Android's command-line sdkmanager is not installed.")
    try:
        subprocess.run(
            [str(sdkmanager), f"--sdk_root={android_home}", f"ndk;{version}"],
            check=True,
        )
    except (OSError, subprocess.CalledProcessError):
        raise PreparationError("Installing Flutter's pinned Android NDK failed.") from None
    ndk_home = android_home / "ndk" / version
    if not (ndk_home / "source.properties").is_file():
        raise PreparationError("The pinned Android NDK installation is incomplete.")
    _append_values(github_env, {"ANDROID_NDK_HOME": str(ndk_home), "ANDROID_NDK_ROOT": str(ndk_home)})
    _append_values(github_output, {"ndk_version": version})
    return version


def prepare_signing(environment: Mapping[str, str], *, require_release: bool = False) -> str:
    """Only the keystore path is persisted; passwords stay in step environments."""
    github_output = _required(environment, "GITHUB_OUTPUT")
    names = ("KEYSTORE", "KEY_ALIAS", "STORE_PASSWORD", "KEY_PASSWORD")
    values = [environment.get(name, "") for name in names]
    if not any(values):
        if require_release:
            raise PreparationError("Tagged releases require all four Android signing secrets.")
        _append_values(github_output, {"signing_kind": "unsigned"})
        return "unsigned"
    if not all(values):
        raise PreparationError("Android release signing requires all four signing secrets.")
    try:
        keystore = base64.b64decode("".join(values[0].split()), validate=True)
    except (binascii.Error, ValueError):
        raise PreparationError("The Android release keystore is not valid base64.") from None
    if not keystore:
        raise PreparationError("The Android release keystore is empty.")
    runner_temp = Path(_required(environment, "RUNNER_TEMP"))
    github_env = _required(environment, "GITHUB_ENV")
    if not runner_temp.is_absolute() or not runner_temp.is_dir():
        raise PreparationError("The runner temporary directory does not exist.")
    path = runner_temp / "avalon-release.keystore"
    created = False
    try:
        descriptor = os.open(path, os.O_WRONLY | os.O_CREAT | os.O_EXCL, 0o600)
        created = True
        with os.fdopen(descriptor, "wb") as destination:
            os.fchmod(destination.fileno(), 0o600)
            destination.write(keystore)
        _append_values(github_env, {"AVALON_KEYSTORE_PATH": str(path)})
        _append_values(github_output, {"signing_kind": "release"})
    except (OSError, PreparationError) as error:
        if created:
            try:
                path.unlink(missing_ok=True)
            except OSError:
                pass
        if isinstance(error, PreparationError):
            raise
        raise PreparationError("The Android release keystore could not be prepared securely.") from None
    return "release"


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("command", choices=("ndk", "signing"))
    parser.add_argument("--require-release", action="store_true")
    arguments = parser.parse_args()
    try:
        if arguments.command == "ndk":
            version = prepare_ndk(os.environ)
            print(f"Prepared Flutter's pinned Android NDK {version}.")
        else:
            kind = prepare_signing(os.environ, require_release=arguments.require_release)
            print(f"Prepared Android signing: {kind}.")
    except PreparationError as error:
        print(f"::error::{error}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

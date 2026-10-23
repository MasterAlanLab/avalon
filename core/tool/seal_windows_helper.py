#!/usr/bin/env python3
"""Bind the existing Windows helper artifact to its own loaded image digest.

This is an installation integrity check, not code signing or a publisher trust
claim. It creates no second artifact. Any later binary modification (including
Authenticode signing) requires a reviewed integration with this integrity seal.
"""

import argparse
import hashlib
import pathlib
import re

SLOT = re.compile(rb"AVALON_HELPER_IMAGE_SHA256\[([0-9a-f]{64})\]")


def image_digest(body: bytes) -> tuple[re.Match[bytes], bytes]:
    matches = list(SLOT.finditer(body))
    if len(matches) != 1:
        raise ValueError("the helper must contain exactly one image digest slot")
    slot = matches[0]
    canonical = body[: slot.start(1)] + b"0" * 64 + body[slot.end(1) :]
    return slot, hashlib.sha256(canonical).hexdigest().encode("ascii")


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("image", type=pathlib.Path)
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()
    body = args.image.read_bytes()
    slot, digest = image_digest(body)
    if args.check:
        if slot.group(1) != digest:
            raise SystemExit("the helper image digest is invalid")
        return
    args.image.write_bytes(body[: slot.start(1)] + digest + body[slot.end(1) :])


if __name__ == "__main__":
    main()

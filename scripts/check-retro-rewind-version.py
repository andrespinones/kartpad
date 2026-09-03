#!/usr/bin/env python3
"""Fail when the official Retro Rewind feed is newer than KartPad's pin."""

from __future__ import annotations

import json
import urllib.request
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
PROFILE = ROOT / "builder/profiles/mkwii-rmcp01-rev0.json"


def version_key(version: str) -> tuple[int, ...]:
    parts = version.split(".")
    if not 2 <= len(parts) <= 4 or any(not part.isdigit() for part in parts):
        raise ValueError(f"invalid Retro Rewind version: {version!r}")
    return tuple(int(part) for part in parts)


def latest_version(text: str) -> str:
    versions = [line.split()[0] for line in text.splitlines() if line.strip()]
    if not versions:
        raise ValueError("official Retro Rewind feed is empty")
    for version in versions:
        version_key(version)
    return max(versions, key=version_key)


def main() -> int:
    profile = json.loads(PROFILE.read_text())
    config = profile["retroRewind"]
    request = urllib.request.Request(
        config["versionManifestUrl"],
        headers={"User-Agent": "KartPad-Retro-Rewind-Version-Watch/1"},
    )
    with urllib.request.urlopen(request, timeout=30) as response:
        current = latest_version(response.read().decode("utf-8"))
    pinned = config["version"]
    print(f"KartPad pins Retro Rewind {pinned}; official feed reports {current}")
    if version_key(current) > version_key(pinned):
        raise SystemExit(
            f"Retro Rewind {current} requires a KartPad profile and native graph update"
        )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

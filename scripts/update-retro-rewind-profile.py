#!/usr/bin/env python3
"""Update KartPad's Retro Rewind pins from an official full archive."""

from __future__ import annotations

import argparse
import hashlib
import json
import re
import urllib.parse
import zipfile
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
DEFAULT_PROFILE = ROOT / "builder/profiles/mkwii-rmcp01-rev0.json"
VERSION_PATTERN = re.compile(r"^[0-9]+(?:\.[0-9]+){1,3}$")


def member_digest(bundle: zipfile.ZipFile, name: str) -> tuple[int, str]:
    info = bundle.getinfo(name)
    digest = hashlib.sha256()
    with bundle.open(info) as source:
        while chunk := source.read(1024 * 1024):
            digest.update(chunk)
    return info.file_size, digest.hexdigest()


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Pin an official Retro Rewind full ZIP without weakening checks."
    )
    parser.add_argument("archive", type=Path)
    parser.add_argument("archive_url")
    parser.add_argument("--profile", type=Path, default=DEFAULT_PROFILE)
    args = parser.parse_args()

    archive = args.archive.resolve()
    parsed = urllib.parse.urlparse(args.archive_url)
    if parsed.scheme != "https" or parsed.netloc != "cdn.update.rwfc.net":
        parser.error("archive URL must use the official HTTPS Retro Rewind CDN")
    if not archive.is_file() or not zipfile.is_zipfile(archive):
        parser.error("archive must be a readable ZIP")

    profile = json.loads(args.profile.read_text())
    config = profile["retroRewind"]
    root = config["root"]
    version_path = f"{root}/version.txt"
    code_path = f"{root}/{config['codePul']['path']}"
    xml_path = f"{root}/{config['riivolutionXml']['path']}"
    with zipfile.ZipFile(archive) as bundle:
        version = bundle.read(version_path).decode("utf-8").strip()
        if not VERSION_PATTERN.fullmatch(version):
            parser.error("archive contains an invalid Retro Rewind version")
        code_bytes, code_hash = member_digest(bundle, code_path)
        xml_bytes, xml_hash = member_digest(bundle, xml_path)

    archive_hash = hashlib.sha256()
    with archive.open("rb") as source:
        while chunk := source.read(1024 * 1024):
            archive_hash.update(chunk)

    config["version"] = version
    config["archive"].update(
        url=args.archive_url,
        bytes=archive.stat().st_size,
        sha256=archive_hash.hexdigest(),
    )
    config["codePul"].update(bytes=code_bytes, sha256=code_hash)
    config["riivolutionXml"].update(bytes=xml_bytes, sha256=xml_hash)
    args.profile.write_text(json.dumps(profile, indent=2) + "\n")
    print(f"Pinned Retro Rewind {version}")
    print(f"archive {archive.stat().st_size} {archive_hash.hexdigest()}")
    print(f"Code.pul {code_bytes} {code_hash}")
    print(f"XML {xml_bytes} {xml_hash}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

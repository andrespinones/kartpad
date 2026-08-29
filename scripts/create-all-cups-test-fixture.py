#!/usr/bin/env python3
"""Create a private all-cups test fixture from an owned Mario Kart Wii save.

This tool deliberately refuses in-place edits.  It changes only the selected
license's GP completion flags and the RKSYS core CRC, leaving progression
acceptance to a separate, honest retail playtest.
"""

from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path
import sys
import zlib


RKSYS_SIZE = 0x2BC000
CORE_CRC_OFFSET = 0x27FFC
LICENSES_OFFSET = 0x8
RKPD_SIZE = 0x8CC0
RKPD_COMPLETION_OFFSET = 0x30
GP_COMPLETION_MASK = 0xFFFFC000


def crc32(data: bytes | bytearray) -> int:
    return zlib.crc32(data[:CORE_CRC_OFFSET]) & 0xFFFFFFFF


def validate(data: bytes | bytearray, license_index: int) -> int:
    if len(data) != RKSYS_SIZE:
        raise ValueError(f"expected 0x{RKSYS_SIZE:x} bytes, got 0x{len(data):x}")
    if data[:4] != b"RKSD":
        raise ValueError("missing RKSD magic")
    if data[4:8] != b"0006":
        raise ValueError(f"unsupported RKSYS version {data[4:8]!r}")
    stored_crc = int.from_bytes(data[CORE_CRC_OFFSET : CORE_CRC_OFFSET + 4], "big")
    calculated_crc = crc32(data)
    if stored_crc != calculated_crc:
        raise ValueError(
            f"invalid core CRC: stored 0x{stored_crc:08x}, calculated 0x{calculated_crc:08x}"
        )
    rkpd_offset = LICENSES_OFFSET + license_index * RKPD_SIZE
    if data[rkpd_offset : rkpd_offset + 4] != b"RKPD":
        raise ValueError(f"license {license_index} is not initialized")
    return rkpd_offset


def create_fixture(source: bytes, license_index: int) -> tuple[bytes, int, int]:
    rkpd_offset = validate(source, license_index)
    completion_offset = rkpd_offset + RKPD_COMPLETION_OFFSET
    before = int.from_bytes(source[completion_offset : completion_offset + 4], "big")
    after = before | GP_COMPLETION_MASK

    fixture = bytearray(source)
    fixture[completion_offset : completion_offset + 4] = after.to_bytes(4, "big")
    fixture[CORE_CRC_OFFSET : CORE_CRC_OFFSET + 4] = crc32(fixture).to_bytes(4, "big")
    validate(fixture, license_index)
    return bytes(fixture), before, after


def self_test() -> None:
    source = bytearray(RKSYS_SIZE)
    source[:8] = b"RKSD0006"
    source[LICENSES_OFFSET : LICENSES_OFFSET + 4] = b"RKPD"
    completion_offset = LICENSES_OFFSET + RKPD_COMPLETION_OFFSET
    source[completion_offset : completion_offset + 4] = (0x80000015).to_bytes(4, "big")
    source[CORE_CRC_OFFSET : CORE_CRC_OFFSET + 4] = crc32(source).to_bytes(4, "big")

    fixture, before, after = create_fixture(bytes(source), 0)
    assert before == 0x80000015
    assert after == 0xFFFFC015
    assert fixture[:completion_offset] == source[:completion_offset]
    assert fixture[completion_offset + 4 : CORE_CRC_OFFSET] == source[completion_offset + 4 : CORE_CRC_OFFSET]
    assert fixture[CORE_CRC_OFFSET + 4 :] == source[CORE_CRC_OFFSET + 4 :]

    damaged = bytearray(source)
    damaged[0x100] ^= 1
    try:
        create_fixture(bytes(damaged), 0)
    except ValueError as error:
        assert "invalid core CRC" in str(error)
    else:
        raise AssertionError("damaged input was accepted")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("source", nargs="?", type=Path)
    parser.add_argument("output", nargs="?", type=Path)
    parser.add_argument("--license", type=int, default=0, choices=range(4))
    parser.add_argument("--self-test", action="store_true")
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    if args.self_test:
        self_test()
        print("all-cups fixture self-test passed")
        return 0
    if args.source is None or args.output is None:
        raise ValueError("source and output are required unless --self-test is used")

    source = args.source.resolve()
    output = args.output.resolve()
    if source == output:
        raise ValueError("refusing to modify a save in place")
    if output.exists():
        raise FileExistsError(f"refusing to overwrite existing output: {output}")

    source_data = source.read_bytes()
    fixture, before, after = create_fixture(source_data, args.license)
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_bytes(fixture)

    report = {
        "source_sha256": hashlib.sha256(source_data).hexdigest(),
        "fixture_sha256": hashlib.sha256(fixture).hexdigest(),
        "license": args.license,
        "completion_before": f"0x{before:08x}",
        "completion_after": f"0x{after:08x}",
        "changed_fields": ["selected RKPD GP completion flags", "RKSYS core CRC32"],
    }
    print(json.dumps(report, indent=2))
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (FileNotFoundError, FileExistsError, ValueError) as error:
        print(f"error: {error}", file=sys.stderr)
        raise SystemExit(2)

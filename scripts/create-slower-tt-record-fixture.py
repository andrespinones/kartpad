#!/usr/bin/env python3
"""Create a private RKSYS fixture with one deliberately slower TT record.

The fixture is for exercising Mario Kart Wii's authentic personal-ghost
replacement path.  It refuses in-place edits, requires an existing personal
ghost for the selected save-course slot, changes only the first leaderboard
timer and the core CRC, and leaves the stored ghost payload untouched.
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
PB_GHOST_BITFIELD_OFFSET = 0x4
LEADERBOARD_OFFSET = 0xDC0
LEADERBOARD_ENTRY_SIZE = 0x60
# RFL::StoreData occupies 0x4c bytes in this on-disc structure; the older
# reverse-engineering comment that calls it 0x4a omits its trailing checksum.
LEADERBOARD_TIME_OFFSET = 0x4C


def crc32(data: bytes | bytearray) -> int:
    return zlib.crc32(data[:CORE_CRC_OFFSET]) & 0xFFFFFFFF


def encode_time(milliseconds: int) -> int:
    if milliseconds < 0 or milliseconds > (127 * 60 + 127) * 1000 + 1023:
        raise ValueError("time is outside the retail bit-field range")
    minutes, remainder = divmod(milliseconds, 60_000)
    seconds, millis = divmod(remainder, 1_000)
    if seconds > 127 or millis > 1023:
        raise ValueError("time cannot be represented by the retail bit fields")
    return (minutes << 25) | (seconds << 18) | (millis << 8)


def decode_time(word: int) -> int:
    return ((word >> 25) & 0x7F) * 60_000 + ((word >> 18) & 0x7F) * 1_000 + ((word >> 8) & 0x3FF)


def validate(data: bytes | bytearray, license_index: int) -> int:
    if len(data) != RKSYS_SIZE:
        raise ValueError(f"expected 0x{RKSYS_SIZE:x} bytes, got 0x{len(data):x}")
    if data[:8] != b"RKSD0006":
        raise ValueError("unsupported RKSYS magic or version")
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


def create_fixture(
    source: bytes, license_index: int, save_course_id: int, slower_time_ms: int
) -> tuple[bytes, int, int, int]:
    if save_course_id not in range(32):
        raise ValueError("save course ID must be in 0..31")
    rkpd_offset = validate(source, license_index)
    pb_bits = int.from_bytes(
        source[rkpd_offset + PB_GHOST_BITFIELD_OFFSET : rkpd_offset + PB_GHOST_BITFIELD_OFFSET + 4],
        "big",
    )
    if not pb_bits & (1 << save_course_id):
        raise ValueError(f"save course {save_course_id} has no personal ghost")

    timer_offset = (
        rkpd_offset
        + LEADERBOARD_OFFSET
        + save_course_id * LEADERBOARD_ENTRY_SIZE
        + LEADERBOARD_TIME_OFFSET
    )
    before_word = int.from_bytes(source[timer_offset : timer_offset + 4], "big")
    before_ms = decode_time(before_word)
    if slower_time_ms <= before_ms:
        raise ValueError(
            f"fixture time {slower_time_ms} ms must be slower than current {before_ms} ms"
        )

    after_word = encode_time(slower_time_ms) | (before_word & 0xFF)
    fixture = bytearray(source)
    fixture[timer_offset : timer_offset + 4] = after_word.to_bytes(4, "big")
    fixture[CORE_CRC_OFFSET : CORE_CRC_OFFSET + 4] = crc32(fixture).to_bytes(4, "big")
    validate(fixture, license_index)
    return bytes(fixture), timer_offset, before_ms, slower_time_ms


def self_test() -> None:
    source = bytearray(RKSYS_SIZE)
    source[:8] = b"RKSD0006"
    source[LICENSES_OFFSET : LICENSES_OFFSET + 4] = b"RKPD"
    source[LICENSES_OFFSET + PB_GHOST_BITFIELD_OFFSET : LICENSES_OFFSET + 8] = (1 << 18).to_bytes(4, "big")
    timer_offset = LICENSES_OFFSET + LEADERBOARD_OFFSET + 18 * LEADERBOARD_ENTRY_SIZE + LEADERBOARD_TIME_OFFSET
    source[timer_offset : timer_offset + 4] = (encode_time(98_880) | 0x15).to_bytes(4, "big")
    source[CORE_CRC_OFFSET : CORE_CRC_OFFSET + 4] = crc32(source).to_bytes(4, "big")

    fixture, changed_offset, before, after = create_fixture(bytes(source), 0, 18, 99_500)
    assert changed_offset == timer_offset
    assert before == 98_880 and after == 99_500
    assert fixture[timer_offset : timer_offset + 4] == (encode_time(99_500) | 0x15).to_bytes(4, "big")
    assert fixture[:timer_offset] == source[:timer_offset]
    assert fixture[timer_offset + 4 : CORE_CRC_OFFSET] == source[timer_offset + 4 : CORE_CRC_OFFSET]
    assert fixture[CORE_CRC_OFFSET + 4 :] == source[CORE_CRC_OFFSET + 4 :]

    try:
        create_fixture(bytes(source), 0, 17, 99_500)
    except ValueError as error:
        assert "no personal ghost" in str(error)
    else:
        raise AssertionError("missing personal ghost was accepted")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("source", nargs="?", type=Path)
    parser.add_argument("output", nargs="?", type=Path)
    parser.add_argument("--license", type=int, default=0, choices=range(4))
    parser.add_argument("--save-course-id", type=int, choices=range(32))
    parser.add_argument("--time-ms", type=int)
    parser.add_argument("--self-test", action="store_true")
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    if args.self_test:
        self_test()
        print("slower Time Trial record fixture self-test passed")
        return 0
    if args.source is None or args.output is None or args.save_course_id is None or args.time_ms is None:
        raise ValueError("source, output, --save-course-id, and --time-ms are required")
    source = args.source.resolve()
    output = args.output.resolve()
    if source == output:
        raise ValueError("refusing to modify a save in place")
    if output.exists():
        raise FileExistsError(f"refusing to overwrite existing output: {output}")

    source_data = source.read_bytes()
    fixture, offset, before, after = create_fixture(
        source_data, args.license, args.save_course_id, args.time_ms
    )
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_bytes(fixture)
    print(json.dumps({
        "source_sha256": hashlib.sha256(source_data).hexdigest(),
        "fixture_sha256": hashlib.sha256(fixture).hexdigest(),
        "license": args.license,
        "save_course_id": args.save_course_id,
        "timer_offset": f"0x{offset:x}",
        "time_before_ms": before,
        "time_after_ms": after,
        "changed_fields": ["selected RKPD primary leaderboard timer", "RKSYS core CRC32"],
    }, indent=2))
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (FileNotFoundError, FileExistsError, ValueError) as error:
        print(f"error: {error}", file=sys.stderr)
        raise SystemExit(2)

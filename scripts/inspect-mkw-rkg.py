#!/usr/bin/env python3
"""Inspect Mario Kart Wii RKG metadata and input streams without exporting them.

The parser follows the original game's RawGhostFile and KPadGhostController
layouts.  It accepts one RKG file or a directory and emits only structural
metadata; no Nintendo input payload is written to disk.
"""

from __future__ import annotations

import argparse
import json
import struct
import sys
from dataclasses import asdict, dataclass
from pathlib import Path


RKG_HEADER_SIZE = 0x88
RKG_COMPRESSED_DATA_OFFSET = 0x8C
RKG_UNCOMPRESSED_DATA_OFFSET = 0x88


class RkgError(ValueError):
    """An invalid or unsupported RKG structure."""


@dataclass(frozen=True)
class StreamSummary:
    sequences: int
    frames: int


@dataclass(frozen=True)
class RkgSummary:
    file: str
    compressed: bool
    race_time_ms: int
    course_id: int
    vehicle_id: int
    character_id: int
    controller_id: int
    year: int
    month: int
    day: int
    ghost_type: int
    drift_is_auto: bool
    inputs_size: int
    face: StreamSummary
    direction: StreamSummary
    trick: StreamSummary


def _u16be(data: bytes, offset: int) -> int:
    return struct.unpack_from(">H", data, offset)[0]


def _u32be(data: bytes, offset: int) -> int:
    return struct.unpack_from(">I", data, offset)[0]


def decode_yaz(data: bytes) -> bytes:
    """Decode the Yaz0/Yaz1 variant used by RKG files."""
    if len(data) < 16 or data[:3] != b"Yaz":
        raise RkgError("missing Yaz0/Yaz1 header")

    expanded_size = _u32be(data, 4)
    source_index = 16
    flags = 0
    mask = 0
    output = bytearray()

    while len(output) < expanded_size:
        if mask == 0:
            if source_index >= len(data):
                raise RkgError("truncated Yaz flag byte")
            flags = data[source_index]
            source_index += 1
            mask = 0x80

        if flags & mask:
            if source_index >= len(data):
                raise RkgError("truncated Yaz literal")
            output.append(data[source_index])
            source_index += 1
        else:
            if source_index + 2 > len(data):
                raise RkgError("truncated Yaz back-reference")
            repeat = _u16be(data, source_index)
            source_index += 2
            distance = (repeat & 0x0FFF) + 1
            if distance > len(output):
                raise RkgError("Yaz back-reference precedes output")

            count = repeat >> 12
            if count:
                count += 2
            else:
                if source_index >= len(data):
                    raise RkgError("truncated Yaz extended run")
                count = data[source_index] + 18
                source_index += 1

            if len(output) + count > expanded_size:
                raise RkgError("Yaz run exceeds declared output size")
            for _ in range(count):
                output.append(output[-distance])

        mask >>= 1

    return bytes(output)


def _summarize_stream(records: bytes, trick: bool = False) -> StreamSummary:
    if len(records) % 2:
        raise RkgError("input stream has a partial sequence")
    frames = 0
    for offset in range(0, len(records), 2):
        if trick:
            frames += max(1, _u16be(records, offset) & 0x0FFF)
        else:
            frames += max(1, records[offset + 1])
    return StreamSummary(sequences=len(records) // 2, frames=frames)


def inspect_rkg(path: Path) -> RkgSummary:
    data = path.read_bytes()
    if len(data) < RKG_UNCOMPRESSED_DATA_OFFSET or data[:4] != b"RKGD":
        raise RkgError("missing RKGD header")

    race = _u32be(data, 4)
    identity = _u32be(data, 8)
    flags = _u16be(data, 0x0C)
    inputs_size = _u16be(data, 0x0E)
    compressed = data[RKG_COMPRESSED_DATA_OFFSET:RKG_COMPRESSED_DATA_OFFSET + 3] == b"Yaz"

    if compressed:
        compressed_size = _u32be(data, RKG_HEADER_SIZE)
        end = RKG_COMPRESSED_DATA_OFFSET + compressed_size
        if end > len(data):
            raise RkgError("compressed input size exceeds file")
        inputs = decode_yaz(data[RKG_COMPRESSED_DATA_OFFSET:end])
    else:
        end = RKG_UNCOMPRESSED_DATA_OFFSET + inputs_size
        if end > len(data):
            raise RkgError("uncompressed input size exceeds file")
        inputs = data[RKG_UNCOMPRESSED_DATA_OFFSET:end]

    if len(inputs) != inputs_size:
        raise RkgError(
            f"expanded input size {len(inputs)} does not match header {inputs_size}"
        )
    if len(inputs) < 8:
        raise RkgError("input payload is shorter than its stream table")

    counts = (_u16be(inputs, 0), _u16be(inputs, 2), _u16be(inputs, 4))
    expected_size = 8 + 2 * sum(counts)
    if expected_size != len(inputs):
        raise RkgError(
            f"stream table consumes {expected_size} bytes, payload has {len(inputs)}"
        )

    face_start = 8
    direction_start = face_start + 2 * counts[0]
    trick_start = direction_start + 2 * counts[1]

    minutes = race >> 25
    seconds = (race >> 18) & 0x7F
    milliseconds = (race >> 8) & 0x3FF

    return RkgSummary(
        file=path.name,
        compressed=compressed,
        race_time_ms=(minutes * 60 + seconds) * 1000 + milliseconds,
        course_id=(race >> 2) & 0x3F,
        vehicle_id=identity >> 26,
        character_id=(identity >> 20) & 0x3F,
        year=(identity >> 13) & 0x7F,
        month=(identity >> 9) & 0x0F,
        day=(identity >> 4) & 0x1F,
        controller_id=identity & 0x0F,
        ghost_type=(flags >> 2) & 0x7F,
        drift_is_auto=bool(flags & 0x0002),
        inputs_size=inputs_size,
        face=_summarize_stream(inputs[face_start:direction_start]),
        direction=_summarize_stream(inputs[direction_start:trick_start]),
        trick=_summarize_stream(inputs[trick_start:], trick=True),
    )


def _self_test() -> None:
    # Eight literals: "ABCABCAB". This exercises header parsing and literal flow.
    literal = b"Yaz1" + struct.pack(">I", 8) + bytes(8) + b"\xffABCABCAB"
    assert decode_yaz(literal) == b"ABCABCAB"

    # Three literals followed by a five-byte back-reference at distance three.
    copied = b"Yaz1" + struct.pack(">I", 8) + bytes(8) + b"\xe0ABC\x30\x02"
    assert decode_yaz(copied) == b"ABCABCAB"

    assert _summarize_stream(b"\x01\x00\x01\xff").frames == 256
    assert _summarize_stream(b"\x20\x00", trick=True).frames == 1
    assert _summarize_stream(b"\x2f\xff", trick=True).frames == 4095


def _paths(source: Path) -> list[Path]:
    if source.is_file():
        return [source]
    if source.is_dir():
        return sorted(source.rglob("*.rkg"))
    raise RkgError(f"path does not exist: {source}")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("source", type=Path, nargs="?", help="RKG file or directory")
    parser.add_argument("--json", action="store_true", help="emit JSON")
    parser.add_argument("--self-test", action="store_true", help="run data-free parser tests")
    args = parser.parse_args()

    try:
        if args.self_test:
            _self_test()
            print("RKG parser self-test passed.")
            if args.source is None:
                return 0
        if args.source is None:
            parser.error("source is required unless --self-test is used")

        summaries = [inspect_rkg(path) for path in _paths(args.source)]
        if not summaries:
            raise RkgError("no RKG files found")

        if args.json:
            print(json.dumps([asdict(summary) for summary in summaries], indent=2))
        else:
            for summary in summaries:
                print(
                    f"{summary.file}: course={summary.course_id} "
                    f"time={summary.race_time_ms / 1000:.3f}s "
                    f"inputs={summary.inputs_size} "
                    f"sequences={summary.face.sequences}/"
                    f"{summary.direction.sequences}/{summary.trick.sequences} "
                    f"frames={summary.face.frames}/"
                    f"{summary.direction.frames}/{summary.trick.frames}"
                )
        return 0
    except (OSError, RkgError, AssertionError) as error:
        print(f"ERROR: {error}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())

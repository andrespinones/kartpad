#!/usr/bin/env python3
"""Summarize KartPad audio queue telemetry without copying PCM or game data."""

from __future__ import annotations

import argparse
import json
import re
from dataclasses import asdict, dataclass
from pathlib import Path
from typing import Iterable, List, Sequence


PATTERN = re.compile(
    r"^\[audio\] (?P<final>final )?queue telemetry: "
    r"checks=(?P<checks>\d+), "
    r"empty-before-push=(?P<empty>\d+), "
    r"dropped-blocks=(?P<blocks>\d+), "
    r"dropped-bytes=(?P<bytes>\d+), "
    r"submitted-bytes=(?P<submitted>\d+), "
    r"queued=(?P<queued>-?\d+), "
    r"observed-range=\[(?P<minimum>-?\d+),(?P<maximum>-?\d+)\] bytes, "
    r"limit=(?P<limit>\d+) bytes$"
)


@dataclass(frozen=True)
class Sample:
    checks: int
    empty_before_push: int
    dropped_blocks: int
    dropped_bytes: int
    submitted_bytes: int
    queued_bytes: int
    minimum_queued_bytes: int
    maximum_queued_bytes: int
    limit_bytes: int
    final: bool


def parse_lines(lines: Iterable[str], source: str) -> List[Sample]:
    samples: List[Sample] = []
    for line_number, raw in enumerate(lines, 1):
        line = raw.rstrip("\n")
        if "queue telemetry:" not in line:
            continue
        match = PATTERN.fullmatch(line)
        if not match:
            raise ValueError(f"malformed queue telemetry in {source}:{line_number}")
        values = match.groupdict()
        sample = Sample(
            checks=int(values["checks"]),
            empty_before_push=int(values["empty"]),
            dropped_blocks=int(values["blocks"]),
            dropped_bytes=int(values["bytes"]),
            submitted_bytes=int(values["submitted"]),
            queued_bytes=int(values["queued"]),
            minimum_queued_bytes=int(values["minimum"]),
            maximum_queued_bytes=int(values["maximum"]),
            limit_bytes=int(values["limit"]),
            final=values["final"] is not None,
        )
        if samples:
            previous = samples[-1]
            for field in (
                "checks",
                "empty_before_push",
                "dropped_blocks",
                "dropped_bytes",
                "submitted_bytes",
            ):
                if getattr(sample, field) < getattr(previous, field):
                    raise ValueError(
                        f"non-monotonic {field} in {source}:{line_number}"
                    )
        if (
            sample.limit_bytes <= 0
            or sample.minimum_queued_bytes < 0
            or sample.minimum_queued_bytes > sample.maximum_queued_bytes
            or sample.maximum_queued_bytes > sample.limit_bytes
        ):
            raise ValueError(f"invalid queue range in {source}:{line_number}")
        samples.append(sample)
    return samples


def summarize(paths: Sequence[Path]) -> dict:
    sessions = []
    total_empty = 0
    total_blocks = 0
    total_dropped_bytes = 0
    total_submitted_bytes = 0
    for path in paths:
        with path.open(encoding="utf-8", errors="replace") as handle:
            samples = parse_lines(handle, str(path))
        if not samples:
            raise ValueError(f"no queue telemetry in {path}")
        last = samples[-1]
        total_empty += last.empty_before_push
        total_blocks += last.dropped_blocks
        total_dropped_bytes += last.dropped_bytes
        total_submitted_bytes += last.submitted_bytes
        sessions.append(
            {
                "path": str(path),
                "sample_count": len(samples),
                "last": asdict(last),
            }
        )
    return {
        "session_count": len(sessions),
        "sessions": sessions,
        "totals": {
            "empty_before_push": total_empty,
            "dropped_blocks": total_blocks,
            "dropped_bytes": total_dropped_bytes,
            "submitted_bytes": total_submitted_bytes,
        },
        "clean": total_empty == 0 and total_blocks == 0 and total_dropped_bytes == 0,
    }


def self_test() -> None:
    clean = [
        "noise\n",
        "[audio] queue telemetry: checks=8192, empty-before-push=0, "
        "dropped-blocks=0, dropped-bytes=0, submitted-bytes=3145344, "
        "queued=5384, observed-range=[0,9404] bytes, limit=15360 bytes\n",
        "[audio] final queue telemetry: checks=9000, empty-before-push=0, "
        "dropped-blocks=0, dropped-bytes=0, submitted-bytes=3456000, "
        "queued=5000, observed-range=[0,9404] bytes, limit=15360 bytes\n",
    ]
    samples = parse_lines(clean, "self-test")
    assert len(samples) == 2 and samples[-1].final
    assert samples[-1].submitted_bytes == 3456000

    malformed = clean + ["[audio] queue telemetry: incomplete\n"]
    try:
        parse_lines(malformed, "self-test-malformed")
    except ValueError:
        pass
    else:
        raise AssertionError("malformed telemetry was accepted")

    non_monotonic = [clean[1], clean[1].replace("checks=8192", "checks=8191")]
    try:
        parse_lines(non_monotonic, "self-test-monotonic")
    except ValueError:
        pass
    else:
        raise AssertionError("non-monotonic telemetry was accepted")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("logs", nargs="*", type=Path)
    parser.add_argument("--require-clean", action="store_true")
    parser.add_argument("--self-test", action="store_true")
    args = parser.parse_args()

    if args.self_test:
        self_test()
        print("audio queue telemetry self-test passed")
        return 0
    if not args.logs:
        parser.error("provide at least one log or use --self-test")

    try:
        result = summarize(args.logs)
    except (OSError, ValueError) as error:
        parser.error(str(error))
    print(json.dumps(result, indent=2, sort_keys=True))
    return 1 if args.require_clean and not result["clean"] else 0


if __name__ == "__main__":
    raise SystemExit(main())

#!/usr/bin/env python3
"""Summarize content-free Mario Kart Wii native state-trace completion evidence."""

from __future__ import annotations

import argparse
import csv
import json
import sys
from dataclasses import asdict, dataclass
from pathlib import Path


REQUIRED_COLUMNS = {
    "sample",
    "retrace",
    "stage",
    "race_time",
    "pos_x",
    "pos_y",
    "pos_z",
    "external_x",
    "external_y",
    "external_z",
    "rot_x",
    "rot_y",
    "rot_z",
    "rot_w",
    "internal_x",
    "internal_y",
    "internal_z",
    "internal_speed",
    "move_dir_x",
    "move_dir_y",
    "move_dir_z",
}


class TraceError(ValueError):
    """A malformed trace or unmet completion requirement."""


@dataclass(frozen=True)
class RaceSegment:
    first_row: int
    last_row: int
    first_race_time: int
    last_race_time: int
    frames: int
    reached_finish: bool


def read_trace(path: Path) -> list[dict[str, int]]:
    rows: list[dict[str, int]] = []
    with path.open(newline="", encoding="utf-8") as source:
        reader = csv.DictReader(source)
        columns = set(reader.fieldnames or [])
        missing = sorted(REQUIRED_COLUMNS - columns)
        if missing:
            raise TraceError(f"missing trace columns: {missing}")

        for line_number, raw in enumerate(reader, start=2):
            try:
                row = {
                    "sample": int(raw["sample"]),
                    "retrace": int(raw["retrace"]),
                    "stage": int(raw["stage"]),
                    "race_time": int(raw["race_time"]),
                }
                for field in REQUIRED_COLUMNS - row.keys():
                    int(raw[field], 16)
            except (KeyError, TypeError, ValueError) as error:
                raise TraceError(f"line {line_number}: malformed value") from error
            rows.append(row)

    if not rows:
        raise TraceError("trace has no samples")
    for index, row in enumerate(rows):
        if row["sample"] != index:
            raise TraceError(
                f"row {index}: sample {row['sample']} is not the expected {index}"
            )
        if index and row["retrace"] <= rows[index - 1]["retrace"]:
            raise TraceError(f"row {index}: retrace is not strictly increasing")
    return rows


def race_segments(rows: list[dict[str, int]]) -> list[RaceSegment]:
    spans: list[tuple[int, int]] = []
    start: int | None = None
    for index, row in enumerate(rows):
        consecutive = (
            start is not None
            and row["stage"] == 2
            and rows[index - 1]["stage"] == 2
            and row["race_time"] == rows[index - 1]["race_time"] + 1
        )
        if row["stage"] == 2 and start is None:
            start = index
        elif row["stage"] == 2 and not consecutive:
            spans.append((start, index - 1))
            start = index
        elif row["stage"] != 2 and start is not None:
            spans.append((start, index - 1))
            start = None
    if start is not None:
        spans.append((start, len(rows) - 1))

    segments: list[RaceSegment] = []
    for span_index, (first, last) in enumerate(spans):
        next_first = spans[span_index + 1][0] if span_index + 1 < len(spans) else len(rows)
        reached_finish = any(row["stage"] == 4 for row in rows[last + 1:next_first])
        segments.append(
            RaceSegment(
                first_row=first,
                last_row=last,
                first_race_time=rows[first]["race_time"],
                last_race_time=rows[last]["race_time"],
                frames=last - first + 1,
                reached_finish=reached_finish,
            )
        )
    return segments


def require_completion(
    segments: list[RaceSegment], expected_input_frames: int | None
) -> RaceSegment:
    completed = [segment for segment in segments if segment.reached_finish]
    if not completed:
        raise TraceError("no consecutive race-stage segment reached finish stage 4")
    if expected_input_frames is None:
        return completed[0]
    if expected_input_frames <= 240:
        raise TraceError("expected input frame count must exceed the 240-frame countdown")

    expected_first = 240
    expected_last = expected_input_frames - 1
    expected_frames = expected_input_frames - expected_first
    exact = [
        segment
        for segment in completed
        if segment.first_race_time == expected_first
        and segment.last_race_time == expected_last
        and segment.frames == expected_frames
    ]
    if not exact:
        observed = [
            f"{segment.first_race_time}..{segment.last_race_time}/{segment.frames}"
            for segment in completed
        ]
        raise TraceError(
            "no completed segment matches expected input frame count "
            f"{expected_input_frames}; observed {observed}"
        )
    return exact[0]


def _self_test() -> None:
    rows = [
        {"sample": index, "retrace": 100 + index, "stage": stage, "race_time": time}
        for index, (stage, time) in enumerate(
            [(1, 238), (1, 239), (2, 240), (2, 241), (2, 242), (4, 243), (0, 0)]
        )
    ]
    segments = race_segments(rows)
    assert len(segments) == 1
    assert require_completion(segments, 243).frames == 3
    for expected in (242, 244):
        try:
            require_completion(segments, expected)
        except TraceError:
            pass
        else:
            raise AssertionError("incorrect expected frame count was accepted")
    try:
        require_completion(race_segments(rows[:-2]), None)
    except TraceError:
        pass
    else:
        raise AssertionError("unfinished race segment was accepted")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("trace", type=Path, nargs="?", help="native state-trace CSV")
    parser.add_argument("--require-complete", action="store_true")
    parser.add_argument("--expected-input-frames", type=int)
    parser.add_argument("--self-test", action="store_true")
    args = parser.parse_args()

    try:
        if args.self_test:
            _self_test()
            print("State-trace summarizer self-test passed.")
            if args.trace is None:
                return 0
        if args.trace is None:
            parser.error("trace is required unless --self-test is used")
        if args.expected_input_frames is not None and not args.require_complete:
            parser.error("--expected-input-frames requires --require-complete")

        rows = read_trace(args.trace)
        segments = race_segments(rows)
        accepted = (
            require_completion(segments, args.expected_input_frames)
            if args.require_complete
            else None
        )
        print(
            json.dumps(
                {
                    "path": str(args.trace),
                    "samples": len(rows),
                    "segments": [asdict(segment) for segment in segments],
                    "accepted_segment": asdict(accepted) if accepted else None,
                },
                indent=2,
            )
        )
        return 0
    except (OSError, TraceError, AssertionError) as error:
        print(f"ERROR: {error}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())

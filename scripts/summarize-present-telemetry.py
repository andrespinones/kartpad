#!/usr/bin/env python3
"""Validate and summarize bounded KartPad presentation telemetry."""

from __future__ import annotations

import argparse
import json
import re
from dataclasses import asdict, dataclass
from pathlib import Path
from typing import Iterable, List, Sequence


PATTERN = re.compile(
    r"^\[gx\] present telemetry: "
    r"total=(?P<total>\d+) samples=(?P<samples>\d+) "
    r"avg-ms=(?P<average>\d+(?:\.\d+)?) "
    r"p50-ms=(?P<p50>\d+(?:\.\d+)?) "
    r"p95-ms=(?P<p95>\d+(?:\.\d+)?) "
    r"p99-ms=(?P<p99>\d+(?:\.\d+)?) "
    r"worst-ms=(?P<worst>\d+(?:\.\d+)?) "
    r"jitter-ms=(?P<jitter>\d+(?:\.\d+)?) "
    r"fps=(?P<fps>\d+(?:\.\d+)?) "
    r"effective-fps=(?P<effective>\d+(?:\.\d+)?) "
    r"pipelines-queued=(?P<queued>\d+) "
    r"pipelines-created=(?P<created>\d+)$"
)


@dataclass(frozen=True)
class Sample:
    total_presents: int
    sample_count: int
    average_ms: float
    p50_ms: float
    p95_ms: float
    p99_ms: float
    worst_ms: float
    jitter_ms: float
    fps: float
    effective_fps: float
    pipelines_queued: int
    pipelines_created: int


def parse_lines(lines: Iterable[str], source: str) -> List[Sample]:
    samples: List[Sample] = []
    for line_number, raw in enumerate(lines, 1):
        line = raw.rstrip("\n")
        if "present telemetry:" not in line:
            continue
        match = PATTERN.fullmatch(line)
        if not match:
            raise ValueError(f"malformed present telemetry in {source}:{line_number}")
        values = match.groupdict()
        sample = Sample(
            total_presents=int(values["total"]),
            sample_count=int(values["samples"]),
            average_ms=float(values["average"]),
            p50_ms=float(values["p50"]),
            p95_ms=float(values["p95"]),
            p99_ms=float(values["p99"]),
            worst_ms=float(values["worst"]),
            jitter_ms=float(values["jitter"]),
            fps=float(values["fps"]),
            effective_fps=float(values["effective"]),
            pipelines_queued=int(values["queued"]),
            pipelines_created=int(values["created"]),
        )
        if not 1 <= sample.sample_count <= 512:
            raise ValueError(f"invalid sample count in {source}:{line_number}")
        if not (
            0.0 < sample.p50_ms <= sample.p95_ms <= sample.p99_ms
            <= sample.worst_ms
        ):
            raise ValueError(f"invalid percentile order in {source}:{line_number}")
        if (
            sample.average_ms <= 0.0
            or sample.jitter_ms < 0.0
            or sample.fps <= 0.0
            or sample.effective_fps < 0.0
            or sample.effective_fps > sample.fps + 0.001
        ):
            raise ValueError(f"invalid timing values in {source}:{line_number}")
        if samples:
            previous = samples[-1]
            if sample.total_presents <= previous.total_presents:
                raise ValueError(
                    f"non-monotonic total presents in {source}:{line_number}"
                )
            if sample.pipelines_created < previous.pipelines_created:
                raise ValueError(
                    f"non-monotonic created pipelines in {source}:{line_number}"
                )
        samples.append(sample)
    return samples


def summarize(paths: Sequence[Path]) -> dict:
    sessions = []
    for path in paths:
        with path.open(encoding="utf-8", errors="replace") as handle:
            samples = parse_lines(handle, str(path))
        if not samples:
            raise ValueError(f"no present telemetry in {path}")
        sessions.append(
            {
                "path": str(path),
                "sample_count": len(samples),
                "minimum_fps": min(sample.fps for sample in samples),
                "minimum_effective_fps": min(
                    sample.effective_fps for sample in samples
                ),
                "maximum_p99_ms": max(sample.p99_ms for sample in samples),
                "maximum_worst_ms": max(sample.worst_ms for sample in samples),
                "first": asdict(samples[0]),
                "last": asdict(samples[-1]),
            }
        )
    return {"session_count": len(sessions), "sessions": sessions}


def self_test() -> None:
    valid = [
        "noise\n",
        "[gx] present telemetry: total=300 samples=60 avg-ms=16.667 "
        "p50-ms=16.600 p95-ms=17.000 p99-ms=18.000 worst-ms=20.000 "
        "jitter-ms=0.500 fps=59.999 effective-fps=59.999 "
        "pipelines-queued=20 pipelines-created=100\n",
        "[gx] present telemetry: total=600 samples=60 avg-ms=16.666 "
        "p50-ms=16.600 p95-ms=16.900 p99-ms=17.500 worst-ms=19.000 "
        "jitter-ms=0.300 fps=60.001 effective-fps=60.001 "
        "pipelines-queued=0 pipelines-created=120\n",
    ]
    samples = parse_lines(valid, "self-test")
    assert len(samples) == 2 and samples[-1].pipelines_created == 120

    for name, bad in (
        ("malformed", valid + ["[gx] present telemetry: incomplete\n"]),
        ("percentile", [valid[1].replace("p99-ms=18.000", "p99-ms=15.000")]),
        ("monotonic", [valid[2], valid[1]]),
    ):
        try:
            parse_lines(bad, f"self-test-{name}")
        except ValueError:
            pass
        else:
            raise AssertionError(f"{name} telemetry was accepted")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("logs", nargs="*", type=Path)
    parser.add_argument("--self-test", action="store_true")
    args = parser.parse_args()

    if args.self_test:
        self_test()
        print("present telemetry self-test passed")
        return 0
    if not args.logs:
        parser.error("provide at least one log or use --self-test")

    try:
        result = summarize(args.logs)
    except (OSError, ValueError) as error:
        parser.error(str(error))
    print(json.dumps(result, indent=2, sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

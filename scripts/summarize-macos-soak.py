#!/usr/bin/env python3
"""Strictly summarize the private output from monitor-macos-soak.sh."""

from __future__ import annotations

import argparse
import csv
import json
import math
import statistics
import tempfile
from pathlib import Path


EXPECTED_COLUMNS = (
    "utc",
    "elapsed_seconds",
    "rss_kib",
    "cpu_percent",
    "thread_count",
)


def percentile(values: list[float], fraction: float) -> float:
    ordered = sorted(values)
    index = max(0, math.ceil(fraction * len(ordered)) - 1)
    return ordered[index]


def read_metadata(path: Path) -> dict[str, str]:
    result: dict[str, str] = {}
    for number, raw in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
        if not raw:
            continue
        if "=" not in raw:
            raise ValueError(f"malformed metadata at {path}:{number}")
        key, value = raw.split("=", 1)
        if not key or key in result:
            raise ValueError(f"invalid or duplicate metadata key at {path}:{number}")
        result[key] = value
    return result


def read_samples(path: Path) -> list[dict[str, float | str]]:
    rows: list[dict[str, float | str]] = []
    with path.open(newline="", encoding="utf-8") as stream:
        reader = csv.DictReader(stream)
        if tuple(reader.fieldnames or ()) != EXPECTED_COLUMNS:
            raise ValueError(f"unexpected columns in {path}: {reader.fieldnames}")
        previous_elapsed = -1.0
        for number, raw in enumerate(reader, 2):
            try:
                elapsed = float(raw["elapsed_seconds"])
                rss = float(raw["rss_kib"])
                cpu = float(raw["cpu_percent"])
                threads = float(raw["thread_count"])
            except (TypeError, ValueError) as error:
                raise ValueError(f"non-numeric sample at {path}:{number}") from error
            values = (elapsed, rss, cpu, threads)
            if not all(math.isfinite(value) and value >= 0 for value in values):
                raise ValueError(f"invalid sample at {path}:{number}")
            if elapsed <= previous_elapsed:
                raise ValueError(f"non-monotonic elapsed time at {path}:{number}")
            if not raw["utc"]:
                raise ValueError(f"missing UTC timestamp at {path}:{number}")
            rows.append({
                "utc": raw["utc"],
                "elapsed": elapsed,
                "rss": rss,
                "cpu": cpu,
                "threads": threads,
            })
            previous_elapsed = elapsed
    if len(rows) < 2:
        raise ValueError(f"at least two samples are required in {path}")
    return rows


def slope_per_hour(x_values: list[float], y_values: list[float]) -> float:
    mean_x = statistics.fmean(x_values)
    mean_y = statistics.fmean(y_values)
    denominator = sum((value - mean_x) ** 2 for value in x_values)
    if denominator == 0:
        return 0.0
    slope_per_second = sum(
        (x_value - mean_x) * (y_value - mean_y)
        for x_value, y_value in zip(x_values, y_values)
    ) / denominator
    return slope_per_second * 3600.0


def summarize(directory: Path) -> dict[str, object]:
    metadata = read_metadata(directory / "metadata.txt")
    rows = read_samples(directory / "samples.csv")
    elapsed = [float(row["elapsed"]) for row in rows]
    rss = [float(row["rss"]) for row in rows]
    cpu = [float(row["cpu"]) for row in rows]
    threads = [float(row["threads"]) for row in rows]
    gaps = [right - left for left, right in zip(elapsed, elapsed[1:])]
    requested = int(metadata.get("duration_seconds", "0"))
    return {
        "directory": str(directory),
        "sample_count": len(rows),
        "requested_duration_seconds": requested,
        "covered_duration_seconds": elapsed[-1] - elapsed[0],
        "maximum_sample_gap_seconds": max(gaps),
        "completed_duration": metadata.get("completed_duration") == "true",
        "process_exited_early_at_seconds": metadata.get("process_exited_early_at_seconds"),
        "process_alive_at_end": metadata.get("process_alive_at_end"),
        "leaks_exit_status": metadata.get("leaks_exit_status"),
        "rss_kib": {
            "first": rss[0],
            "last": rss[-1],
            "minimum": min(rss),
            "maximum": max(rss),
            "delta": rss[-1] - rss[0],
            "least_squares_slope_per_hour": slope_per_hour(elapsed, rss),
        },
        "cpu_percent": {
            "median": statistics.median(cpu),
            "p95": percentile(cpu, 0.95),
            "maximum": max(cpu),
        },
        "thread_count": {
            "minimum": min(threads),
            "maximum": max(threads),
            "first": threads[0],
            "last": threads[-1],
        },
        "identity": {
            key: metadata.get(key)
            for key in (
                "start_utc",
                "end_utc",
                "pid",
                "executable_sha256",
                "git_commit",
                "hardware",
                "os_version",
                "os_build",
                "power_source",
                "save_file",
                "save_size_start",
                "save_size_end",
                "save_sha256_start",
                "save_sha256_end",
            )
        },
    }


def self_test() -> None:
    with tempfile.TemporaryDirectory() as temporary:
        directory = Path(temporary)
        (directory / "metadata.txt").write_text(
            "duration_seconds=120\ncompleted_duration=true\n"
            "process_alive_at_end=true\nleaks_exit_status=0\n",
            encoding="utf-8",
        )
        (directory / "samples.csv").write_text(
            ",".join(EXPECTED_COLUMNS) + "\n"
            "2026-08-30T00:00:00Z,0,1000,20,10\n"
            "2026-08-30T00:01:00Z,60,1100,40,11\n"
            "2026-08-30T00:02:00Z,120,1200,30,10\n",
            encoding="utf-8",
        )
        result = summarize(directory)
        assert result["sample_count"] == 3
        assert result["covered_duration_seconds"] == 120
        assert result["rss_kib"]["delta"] == 200
        assert round(result["rss_kib"]["least_squares_slope_per_hour"]) == 6000
        assert result["thread_count"]["maximum"] == 11
    print("macOS soak summary self-test passed")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("directory", nargs="?", type=Path)
    parser.add_argument("--self-test", action="store_true")
    args = parser.parse_args()
    if args.self_test:
        self_test()
        return
    if args.directory is None:
        parser.error("directory is required unless --self-test is used")
    print(json.dumps(summarize(args.directory.resolve()), indent=2, sort_keys=True))


if __name__ == "__main__":
    main()

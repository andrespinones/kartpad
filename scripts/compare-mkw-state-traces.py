#!/usr/bin/env python3
"""Compare KartPad CSV state traces with Dolphin MemoryWatcher datagrams."""

from __future__ import annotations

import argparse
import csv
from pathlib import Path


ADDRESSES = {
    "pos_x": "809c18f8 20 0 0 8 90 4 68",
    "pos_y": "809c18f8 20 0 0 8 90 4 6c",
    "pos_z": "809c18f8 20 0 0 8 90 4 70",
    "external_x": "809c18f8 20 0 0 8 90 4 74",
    "external_y": "809c18f8 20 0 0 8 90 4 78",
    "external_z": "809c18f8 20 0 0 8 90 4 7c",
    "rot_x": "809c18f8 20 0 0 8 90 4 f0",
    "rot_y": "809c18f8 20 0 0 8 90 4 f4",
    "rot_z": "809c18f8 20 0 0 8 90 4 f8",
    "rot_w": "809c18f8 20 0 0 8 90 4 fc",
    "internal_x": "809c18f8 20 0 0 8 90 4 14c",
    "internal_y": "809c18f8 20 0 0 8 90 4 150",
    "internal_z": "809c18f8 20 0 0 8 90 4 154",
    "internal_speed": "809c18f8 20 0 0 28 20",
    "move_dir_x": "809c18f8 20 0 0 28 74",
    "move_dir_y": "809c18f8 20 0 0 28 78",
    "move_dir_z": "809c18f8 20 0 0 28 7c",
}
TIME_ADDRESS = "809bd730 20"
STAGE_ADDRESS = "809bd730 28"


def longest_race_segment(rows: list[dict[str, int]]) -> list[dict[str, int]]:
    best: list[dict[str, int]] = []
    current: list[dict[str, int]] = []
    for row in rows:
        if row["stage"] != 2:
            current = []
            continue
        if current and row["race_time"] != current[-1]["race_time"] + 1:
            current = []
        current.append(row)
        if len(current) > len(best):
            best = list(current)
    return best


def read_native(path: Path) -> list[dict[str, int]]:
    with path.open(newline="", encoding="utf-8") as source:
        return [
            {
                "stage": int(row["stage"]),
                "race_time": int(row["race_time"]),
                **{name: int(row[name], 16) for name in ADDRESSES},
            }
            for row in csv.DictReader(source)
        ]


def read_oracle(path: Path) -> list[dict[str, int]]:
    rows: list[dict[str, int]] = []
    state: dict[str, int] = {}
    with path.open(encoding="utf-8") as source:
        for line_number, raw_line in enumerate(source, start=1):
            fields = raw_line.rstrip("\n").split("\t")[2:]
            if fields == [""]:
                continue
            if len(fields) % 2:
                raise ValueError(f"line {line_number}: odd MemoryWatcher pair count")
            changed_time = False
            for index in range(0, len(fields), 2):
                address = fields[index]
                value = int(fields[index + 1].replace(",", ""), 16)
                state[address] = value
                changed_time |= address == TIME_ADDRESS
            if changed_time and STAGE_ADDRESS in state and all(
                address in state for address in ADDRESSES.values()
            ):
                rows.append(
                    {
                        "stage": state[STAGE_ADDRESS] & 0xFF,
                        "race_time": state[TIME_ADDRESS],
                        **{name: state[address] for name, address in ADDRESSES.items()},
                    }
                )
    return rows


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("native", type=Path)
    parser.add_argument("oracle", type=Path)
    args = parser.parse_args()

    native = longest_race_segment(read_native(args.native))
    oracle = longest_race_segment(read_oracle(args.oracle))
    if not native or not oracle:
        raise SystemExit("missing a consecutive race-stage segment")

    print(
        f"native_segment={native[0]['race_time']}..{native[-1]['race_time']} "
        f"frames={len(native)}"
    )
    print(
        f"oracle_segment={oracle[0]['race_time']}..{oracle[-1]['race_time']} "
        f"frames={len(oracle)}"
    )

    native_by_time = {row["race_time"]: row for row in native}
    oracle_by_time = {row["race_time"]: row for row in oracle}
    common = sorted(native_by_time.keys() & oracle_by_time.keys())
    mismatches: list[tuple[int, str, int, int]] = []
    for race_time in common:
        for name in ADDRESSES:
            native_value = native_by_time[race_time][name]
            oracle_value = oracle_by_time[race_time][name]
            if native_value != oracle_value:
                mismatches.append((race_time, name, native_value, oracle_value))
                if len(mismatches) <= 20:
                    print(
                        f"mismatch time={race_time} field={name} "
                        f"native={native_value:08x} oracle={oracle_value:08x}"
                    )

    print(
        f"common_frames={len(common)} words_per_frame={len(ADDRESSES)} "
        f"compared_words={len(common) * len(ADDRESSES)}"
    )
    print(f"mismatches={len(mismatches)}")
    return 1 if mismatches else 0


if __name__ == "__main__":
    raise SystemExit(main())

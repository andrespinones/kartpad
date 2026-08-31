#!/usr/bin/env python3
"""Reject unified-diff hunks whose declared and actual line counts differ."""

from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path


HUNK_HEADER = re.compile(
    r"^@@ -(?:\d+)(?:,(\d+))? \+(?:\d+)(?:,(\d+))? @@"
)


def verify_patch(path: Path) -> int:
    lines = path.read_text(encoding="utf-8", errors="surrogateescape").splitlines()
    hunk_count = 0
    index = 0

    while index < len(lines):
        header = HUNK_HEADER.match(lines[index])
        if header is None:
            line = lines[index]
            if ((line.startswith(("+", "-")) and
                 not line.startswith(("+++ ", "--- "))) or
                    line.startswith(" ")):
                raise ValueError(
                    f"{path}:{index + 1}: stray line outside a declared hunk"
                )
            index += 1
            continue

        hunk_count += 1
        expected_old = int(header.group(1) or "1")
        expected_new = int(header.group(2) or "1")
        actual_old = 0
        actual_new = 0
        index += 1

        while index < len(lines):
            if (actual_old, actual_new) == (expected_old, expected_new):
                break
            line = lines[index]
            if line.startswith("\\ No newline at end of file"):
                index += 1
                continue
            if line == "" or line.startswith(" "):
                actual_old += 1
                actual_new += 1
            elif line.startswith("-"):
                actual_old += 1
            elif line.startswith("+"):
                actual_new += 1
            else:
                break

            if actual_old > expected_old or actual_new > expected_new:
                raise ValueError(
                    f"{path}:{index + 1}: hunk exceeds declared counts "
                    f"old={expected_old}, new={expected_new}"
                )
            index += 1

        if (actual_old, actual_new) != (expected_old, expected_new):
            raise ValueError(
                f"{path}:{index + 1}: hunk count mismatch: declared "
                f"old={expected_old}, new={expected_new}; actual "
                f"old={actual_old}, new={actual_new}"
            )

    return hunk_count


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("patches", nargs="+", type=Path)
    args = parser.parse_args()

    total = 0
    failures = []
    for path in args.patches:
        try:
            total += verify_patch(path)
        except ValueError as error:
            failures.append(str(error))
    if failures:
        for failure in failures:
            print(f"ERROR: {failure}", file=sys.stderr)
        return 1
    print(f"Verified {total} unified-diff hunks across {len(args.patches)} patches.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

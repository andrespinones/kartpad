# G10 retail-course oracle inventory

Date: 2026-08-29

## Purpose

PRD row 22 requires every one of the 32 retail tracks to complete. Before running
that matrix, KartPad needs a complete, structurally valid, content-private oracle
input set. This check does not claim that any additional track has booted or
completed.

## Validation

`scripts/inspect-mkw-rkg.py --require-course-matrix` now requires:

- exactly 32 files;
- one unique course ID for every value from 0 through 31;
- equal face, direction, and trick stream frame counts within each file; and
- a positive recorded time and non-empty input payload.

The data-free self-test covers a valid matrix, missing course, duplicate course,
and mismatched-frame cases. A one-file negative test exits with status 1.

Both private disc-derived staff sets passed:

| Set | Files | Course IDs | Recorded-time range | Input-frame range |
|---|---:|---:|---:|---:|
| regular staff | 32 | 0..31 | 66.595–199.323 s | 4,232–12,188 |
| expert staff | 32 | 0..31 | 58.907–175.933 s | 3,771–10,786 |

The directory labels `ghost1` and `ghost2` are intentionally not interpreted as
difficulty in the verifier; the table classifies the sets from their observed
recorded-time ranges. No RKG payload, game asset, save content, or translated
game code is copied into this repository or evidence file.

## Classification

**Preparation pass, not PRD row 22 acceptance.** KartPad now has a strict,
content-free preflight proving that both candidate oracle sets cover all 32
retail course IDs. Native per-track execution and completion evidence remains
required.

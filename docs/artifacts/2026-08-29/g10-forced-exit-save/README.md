# G10 forced-exit save safety

Status: **Pass for PRD row 20 at a stable Main Menu boundary.**

## Procedure and result

- Target: final signed native arm64 KartPad product path, normal launch, one game process, no diagnostic environment.
- The app was idle at Main Menu after the completed Battle rows.
- Before termination, the 2,867,200-byte `rksys.dat` and an ignored recovery copy both had SHA-256 `c5a5108cd3184d4b6e8ca55c4fdd768afd08638c99fcb98695757a5f3a58d1d6`.
- The only resolved KartPad process (PID 23422) was terminated with `SIGKILL`; no second game process existed.
- The live save remained byte-identical to the recovery copy immediately after termination.
- KartPad relaunched normally as a single new process (PID 26767), reached Select License, and displayed the existing `Player` license and progress grid without a recovery warning or damaged slot.
- After relaunch, the live save remained byte-identical with the same SHA-256.
- No Simulator device was booted.

## Evidence

- `relaunch-player-license.jpeg` — existing `Player` license and progress grid after the forced exit and relaunch.

The recovery copy remains ignored under `private/g10-forced-exit/` and is not published.

# G10 native N64 Mario Raceway staff-ghost comparison

Status: **Fail — P1 native replay determinism defect.**

This evidence compares the final native arm64 KartPad product path with the exact pinned Dolphin 5.0-17995 oracle. Both runs use the same read-only PAL `RMCP01` WBFS and the original regular staff ghost for N64 Mario Raceway: `Nin★Ichiro`, `02:14.799`.

## Result

- KartPad was launched without `KARTPAD_RKG_INPUT`, without the opt-in fixture armed, and without player injection. The game selected its own official ghost through Time Trials → Shell Cup → N64 Mario Raceway → Watch Replay.
- The native replay began plausibly at 59.7–59.9 FPS, then left the racing line and remained in progress well after the ghost's `02:14.799` reference duration. `replay-overdue-diverged.jpeg` records the overdue kart off course in the infield.
- The isolated pinned Dolphin oracle selected the same ghost from the same WBFS, held 60 FPS/VPS at 100%, stayed on the racing line at the corresponding checkpoints, completed, and automatically began the next replay loop. `oracle-loop-restarted.jpeg` records the restarted countdown.
- First-run reproducibility is 1/1 for the native failure and 1/1 for the oracle pass. A changed, instrumented native run is required before another repetition.

## Failure signature

| Field | Value |
|---|---|
| Goal | G10 — macOS offline compatibility |
| Target | Final native arm64 KartPad runtime, Metal renderer |
| Build checkpoint | Repository `3ebe6a6`; ignored signed app regenerated from the tracked runtime patch |
| Interaction | Official in-game `Watch Replay`; no fixture or injected player controls |
| Expected | `Nin★Ichiro 02:14.799` finishes and the replay loops, matching Dolphin |
| Actual | Kart leaves the racing line and replay continues well beyond the recorded duration |
| First failing subsystem | Native translated runtime physics/determinism boundary; narrower cause not yet attributed |
| Renderer cadence | 59.7–59.9 FPS during the native observation |
| Known-good comparison | Dolphin 5.0-17995, identical WBFS/ghost, completes and loops |
| Evidence | This directory |

The only intended test variable between the two product-path observations is the execution runtime. Course and ghost are identical. This evidence does not by itself reopen G6 or identify a faulty instruction; it establishes a genuine G10 blocker that must be narrowed to the first divergent guest state.

## Files

- `ghost-menu.jpeg` — native selection of `Nin★Ichiro 02:14.799`.
- `replay-start.jpeg`, `replay-mid.jpeg`, `replay-late.jpeg` — native replay checkpoints.
- `replay-overdue-diverged.jpeg` — native replay still running and visibly off course after the reference duration.
- `oracle-ghost-menu.jpeg` — matching selection in pinned Dolphin.
- `oracle-replay-start.jpeg`, `oracle-replay-mid.jpeg`, `oracle-replay-late.jpeg` — oracle checkpoints on the racing line.
- `oracle-loop-restarted.jpeg` — oracle completed and automatically restarted the replay.

The screenshots contain game UI only and no private data. The Dolphin comparison used an isolated user directory; its temporary `Always Connected` controller option was restored to off before Dolphin was closed. No Simulator was booted, and only one game instance ran at a time.

## Next bounded step

Instrument the native replay with a deterministic per-frame kart/physics state trace and identify the earliest state transition that disagrees with a known-good run. Do not repeat the unchanged visual test or broaden the compatibility matrix until that first divergence is attributable.

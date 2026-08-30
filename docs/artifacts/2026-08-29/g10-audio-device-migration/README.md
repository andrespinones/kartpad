# G10 audio output-device migration

Status: **Pass for the output-device-change subcase of PRD row 33.** PRD row 33 remains in progress because subjective listening and the required long representative session are separate open checks.

## Candidate and procedure

- Target: Apple M2, native arm64, macOS 26.5, sole ad-hoc-signed KartPad process; no Dolphin and no booted Simulator.
- Runtime SHA-256: `23b1e51843faeb764d4ae685dc4a85004f8e21fd0ce3c342d791081409b78026`.
- Mode: Time Trials → SNES Mario Circuit 3 → durable `Player 05:01.445` personal ghost → Watch Replay.
- Began on the system's original `Jump Desktop Audio` default output, changed the default to `MacBook Air Speakers` during active replay, observed the app for 12 seconds, restored `Jump Desktop Audio`, and observed another 30 seconds before a normal window close.

## Result

- Before migration, telemetry reached 57,344 queue checks and 22,019,712 submitted bytes with zero post-start empty observations and zero dropped blocks.
- The switch to speakers produced a bounded transition burst: at 65,536 checks the cumulative counter was 54 stale blocks (20,736 bytes), with zero empty observations. The replay remained visibly active at the 60 FPS overlay target.
- Restoring the original output produced a second bounded burst, reaching 101 cumulative stale blocks (38,784 bytes) by 73,728 checks. The count then remained exactly 101 through 98,304 checks and 37,709,568 submitted bytes. Empty observations remained zero throughout.
- The final queue held 6,468 of its 15,360-byte limit. There was no sustained underrun, unbounded queue growth, drop cascade after settling, crash, gameplay stall, or save mutation.
- The original system default was restored and verified as `Jump Desktop Audio`. The live RKSYS remained byte-identical at SHA-256 `ad79c24bc5eb0ba6bc8cd2836a55680621892b578a04ea49d8884a71a42c563a`.

The transition drops are the backend's deliberate bounded-latency policy: stale blocks are discarded rather than accumulated. This instrumentation-backed result establishes continuity and recovery, but it does not claim that a listener heard no transient click or level change.

## Evidence

- `after-switch-to-speakers.png` — personal replay visibly active after the first route change; SHA-256 `9c7597f94eb163de8d9b59af8b2c7f1a09042e8621cd06d4ad74cdb6c3bb1b29`.
- `stable-after-restore.png` — personal replay visibly active after restoration and settling; SHA-256 `ce230dfc07b1f2945092381d4f19b191f6a9b842130a570a426fe27da61206bc`.
- Ignored private state trace SHA-256: `bd284f478d60a74555bc215cce3d88caee47fc655fa447642de0cfd249765ea5`.
- Ignored private console log SHA-256: `f57741874c7205f027f8a24417ae6ad716e1e54e0b7cc3108119eadbf0fa5b98`.


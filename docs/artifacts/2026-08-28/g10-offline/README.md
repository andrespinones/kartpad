# G10 offline compatibility — RKG fixture investigation

Status: **Inconclusive diagnostic; not a G10 pass.**

This evidence set records the first deterministic RKG input-fixture work for the native macOS runtime. The public artifacts contain screenshots, bounded counters, and structural metadata only. They do not contain a ghost input payload, save, disc data, or a personal path.

## Proven

- The checked parser accepts every 64 on-disc staff RKG files and reports equal face/direction/trick frame totals for each file.
- The original game's translated `KPadGhostController` starts consuming at race stage 1. Its stage-1 countdown lasts exactly 240 input frames.
- The opt-in player fixture also consumes exactly 240 frames before stage 2 (`kartpad-rkg-fixture-sync.log`).
- Native guest output for the first Luigi Circuit direction records matches the parser's expansion: four frames of `0x8e`, then the next record.
- The generated guard is opt-in and leaves the original `KPadWiiController::calcInner` translation untouched when no fixture is armed.
- The native product path still replays the original Luigi Circuit staff ghost at 60 FPS, as recorded by G9.

## Not proven

The diagnostic fixture can follow the expected racing line for substantial intervals, but it later diverges when injected through a live player controller. Phase offsets were falsified, and presenting the player slot as control source `GHOST` correctly raised the game's controller-disconnected dialog. The fixture therefore is not accepted as a full deterministic player-lap oracle and is not used to claim any G10 matrix row.

## Files

- `kartpad-g10-hook-boot.jpeg` — guarded runtime booted normally.
- `kartpad-g10-stage2b-10s.jpeg` — zero-phase run following the expected early racing line.
- `kartpad-g10-stage2b-22s.jpeg` — later divergence from that diagnostic run.
- `kartpad-g10-phase5-18s.jpeg` — rejected five-frame phase experiment.
- `kartpad-rkg-fixture-sync.log` — bounded stage/frame counter (`stage 1: frame 0`, `stage 2: frame 240`).

The next accepted G10 evidence must come from native mode/track/controller/save execution, including the game's own ghost-controller path, not from this incomplete player-injection harness.

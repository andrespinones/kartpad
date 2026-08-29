# G10 native N64 Mario Raceway staff-ghost comparison

Status: **Pass — initial visual failure classification disproven by full-frame state comparison.**

This evidence compares the final native arm64 KartPad product path with exact pinned Dolphin 5.0-17995. Both runs use the same read-only PAL `RMCP01` WBFS and original regular N64 Mario Raceway staff ghost: `Nin★Ichiro`, `02:14.799`.

## Corrected result

- KartPad was launched without `KARTPAD_RKG_INPUT`, without the opt-in fixture armed, and without player injection. The official ghost was selected through Time Trials → Shell Cup → N64 Mario Raceway → Watch Replay.
- The first screenshot-only observation was incorrectly classified as an overdue, off-course replay. The missing fact was that Watch Replay automatically starts another loop after completion; the supposedly overdue observation was from a later loop.
- A changed native run added an opt-in, read-only frame-end trace. Race stage 2 covered timer values `240..8319` (8,080 frames) and transitioned to finish stage 4 at `8320`, then returned to stage 0 and began another countdown/replay loop.
- Dolphin's built-in frame-end MemoryWatcher captured the identical guest addresses. Its longest race segment was also `240..8319` (8,080 frames).
- The comparison checked 17 raw 32-bit position, velocity, rotation, internal-speed, and movement-direction words for every one of those 8,080 frames: **137,360 comparisons, zero mismatches**.
- The native product path therefore completes and loops the official ghost with bit-exact watched physics state. There is no native replay determinism defect in this row, and G6 remains closed.

## Reproduction

```text
./scripts/compare-mkw-state-traces.py \
  private/g10-native-state-trace.csv \
  private/g10-oracle-memorywatch.tsv

native_segment=240..8319 frames=8080
oracle_segment=240..8319 frames=8080
common_frames=8080 words_per_frame=17 compared_words=137360
mismatches=0
```

The private raw traces are not published. Their SHA-256 hashes are recorded in `state-trace-comparison.txt`; the bounded comparison result contains no disc, save, or ghost payload.

## Files

- `ghost-menu.jpeg` — native selection of `Nin★Ichiro 02:14.799`.
- `replay-start.jpeg`, `replay-mid.jpeg`, `replay-late.jpeg`, `replay-overdue-diverged.jpeg` — screenshots from the initial visual observation. The last filename preserves the original classification for auditability; that interpretation is superseded by the full trace.
- `oracle-ghost-menu.jpeg` — matching selection in pinned Dolphin.
- `oracle-replay-start.jpeg`, `oracle-replay-mid.jpeg`, `oracle-replay-late.jpeg` — oracle replay checkpoints.
- `oracle-loop-restarted.jpeg` — direct visual evidence that Watch Replay automatically starts a new loop.
- `state-trace-comparison.txt` — bounded command output, raw trace hashes, and provenance.

The screenshots contain game UI only and no private data. Dolphin used an isolated user directory; its temporary `Always Connected` option was restored to off before exit. One game emulation ran at a time, and no Simulator was booted.

## Classification lesson

Wall-clock screenshot intervals cannot establish ghost overrun when the product automatically loops replays and does not overlay the current timer. Future ghost acceptance uses race-stage/timer transitions or frame-end state comparison, not visual elapsed-time inference.

# G10 retail-track completion matrix

Date: 2026-08-29

This directory indexes PRD row 22. Raw state traces and staff inputs remain
private and ignored. A track is marked Pass only when native execution reaches a
real finish transition; boot screenshots do not qualify.

| Cup | Track | Course ID | Status | Evidence |
|---|---|---:|---|---|
| Mushroom | Luigi Circuit | 8 | Pass | Complete live three-lap race/results in G9 and complete two-player race/results in G10 |
| Mushroom | Moo Moo Meadows | 1 | Pass | Native regular-staff replay exactly matches 6,106 input frames: stage 2 `240..6105`, 5,866 samples, then stage 4 |
| Mushroom | Mushroom Gorge | 2 | Pass | Native regular-staff replay exactly matches 8,399 input frames: stage 2 `240..8398`, 8,159 samples, then stage 4 |
| Mushroom | Toad's Factory | 4 | Pass | Native regular-staff replay exactly matches 8,781 input frames: stage 2 `240..8780`, 8,541 samples, then stage 4 |
| Flower | Mario Circuit | 0 | Open | — |
| Flower | Coconut Mall | 5 | Open | — |
| Flower | DK Summit | 6 | Open | — |
| Flower | Wario's Gold Mine | 7 | Open | — |
| Star | Daisy Circuit | 9 | Open | — |
| Star | Koopa Cape | 15 | Open | — |
| Star | Maple Treeway | 11 | Open | — |
| Star | Grumble Volcano | 3 | Open | — |
| Special | Dry Dry Ruins | 14 | Open | — |
| Special | Moonview Highway | 10 | Open | — |
| Special | Bowser's Castle | 12 | Open | — |
| Special | Rainbow Road | 13 | Open | — |
| Shell | GCN Peach Beach | 16 | Open | — |
| Shell | DS Yoshi Falls | 20 | Open | — |
| Shell | SNES Ghost Valley 2 | 25 | Open | — |
| Shell | N64 Mario Raceway | 26 | Pass | Native regular-staff replay exactly matches 8,320 input frames; 8,080 stage-2 samples and zero state-word mismatches against Dolphin |
| Banana | N64 Sherbet Land | 27 | Open | — |
| Banana | GBA Shy Guy Beach | 31 | Open | — |
| Banana | DS Delfino Square | 23 | Open | — |
| Banana | GCN Waluigi Stadium | 18 | Open | — |
| Leaf | DS Desert Hills | 21 | Open | — |
| Leaf | GBA Bowser Castle 3 | 30 | Open | — |
| Leaf | N64 DK's Jungle Parkway | 29 | Open | — |
| Leaf | GCN Mario Circuit | 17 | Open | — |
| Lightning | SNES Mario Circuit 3 | 24 | Open | — |
| Lightning | DS Peach Gardens | 22 | Open | — |
| Lightning | GCN DK Mountain | 19 | Open | — |
| Lightning | N64 Bowser's Castle | 28 | Open | — |

## Moo Moo Meadows exact run

- Product: sole native arm64 KartPad process; no Dolphin and no Simulator.
- Retail UI path: Time Trials → Mushroom Cup → Moo Moo Meadows → regular
  Nintendo staff data `Nin★YuNya 01:37.856` → Watch Replay.
- Private trace SHA-256:
  `b61dc910a085a09c0e62c252a9cd516223cde46d6fb175ce201b8154f719b572`.
- Strict assertion:
  `scripts/summarize-mkw-state-trace.py --require-complete --expected-input-frames 6106`.
- Result: first completed segment begins at race time 240, ends at 6105,
  contains 5,866 consecutive stage-2 samples, and is followed by stage 4.

The first attempt visually finished but produced no trace because its absolute
output directory did not exist. Runtime output explicitly said `unable to open`;
that run is rejected. The directory was created and the changed run above passed.

Eight unrelated `dolrecomp` workers were active during both runs. Their load
affected the FPS overlay and audio queue, so neither performance nor audio is
accepted from this evidence. Guest stage progression and exact input-frame
completion are independent of that wall-clock contention.

## Mushroom Gorge exact run

- Product: sole native arm64 KartPad process; no Dolphin and no Simulator.
- Executable SHA-256: `f6b40a3902ac5ba559d359c5b1cb5488176ebf14bc8eab3da1371c1fd146f9fc`.
- Retail UI path: Time Trials → Mushroom Cup → Mushroom Gorge → regular Nintendo staff data `Nin★Murak 02:16.110` → Watch Replay.
- Original accepted private trace SHA-256: `e20883a2ca6cdfda1bb1f3da75535b852006a44ac87b833c46787ceea88277e4`. After the GUI-helper filename incident described below, a process-local rerun restored the convenience trace with SHA-256 `5aa1026555f10dc683c68fb80476ad077a641e4ab30669f50bebdbb43d3419b5` and the same exact accepted stage/frame boundary.
- Strict assertion: `scripts/summarize-mkw-state-trace.py --require-complete --expected-input-frames 8399`.
- Result: the accepted segment begins at race time 240, ends at 8398, contains 8,159 consecutive stage-2 samples, and is followed by stage 4. The later incomplete segment is the retail automatic replay loop and is not accepted as a second run.
- The focused UI observations remained at 60.0 FPS, but this trace run is accepted only for guest-stage completion; it is not a G11 frame-pacing sample. The known writable-cache bundle-seal issue recurred after the run and remains separately tracked for G13.

## Toad's Factory exact run

- Product: sole native arm64 KartPad process; no Dolphin and no Simulator.
- Executable SHA-256: `3927307a33dd9cac30237906489b4423fd7a11ba4ccc3d81f54efbd15281b5d6`.
- Retail UI path: Time Trials → Mushroom Cup → Toad's Factory → regular Nintendo staff data `Nin★Misa 02:22.480` → Watch Replay.
- Private trace SHA-256: `259abe8ae52bf1a54b069ded79fbd41cf816fd82dde2fea45a546254d6a58495`.
- Strict assertion: `scripts/summarize-mkw-state-trace.py --require-complete --expected-input-frames 8781`.
- Result: the accepted segment begins at race time 240, ends at 8780, contains 8,541 consecutive stage-2 samples, and is followed by stage 4. A later incomplete segment is the retail automatic replay loop.
- Harness note: the persistent GUI launch helper retained the preceding Mushroom Gorge trace path, so this run initially overwrote that ignored filename. The completed contents were validated and moved to `toads-factory-native.csv` after the process closed. `scripts/launch-g10-traced-runtime.sh` now binds the path in the runtime's own process, refuses relative/existing outputs and a second KartPad process, and restored the Mushroom Gorge convenience trace in an exact rerun.

Current row 22 status: **5/32 Pass; 27 Open.**

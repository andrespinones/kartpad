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
| Flower | Mario Circuit | 0 | Pass | Native regular-staff replay exactly matches 6,521 input frames: stage 2 `240..6520`, 6,281 samples, then stage 4 |
| Flower | Coconut Mall | 5 | Pass | Native regular-staff replay exactly matches 9,277 input frames: stage 2 `240..9276`, 9,037 samples, then stage 4 |
| Flower | DK Summit | 6 | Pass | Native regular-staff replay exactly matches 9,513 input frames: stage 2 `240..9512`, 9,273 samples, then stage 4 |
| Flower | Wario's Gold Mine | 7 | Pass | Native regular-staff replay exactly matches 8,607 input frames: stage 2 `240..8606`, 8,367 samples, then stage 4 |
| Star | Daisy Circuit | 9 | Pass | Native regular-staff replay exactly matches 7,243 input frames: stage 2 `240..7242`, 7,003 samples, then stage 4 |
| Star | Koopa Cape | 15 | Open | — |
| Star | Maple Treeway | 11 | Pass | Native regular-staff replay exactly matches 10,948 input frames: stage 2 `240..10947`, 10,708 samples, then stage 4 |
| Star | Grumble Volcano | 3 | Pass | Native regular-staff replay exactly matches 9,126 input frames: stage 2 `240..9125`, 8,886 samples, then stage 4 |
| Special | Dry Dry Ruins | 14 | Pass | Native regular-staff replay exactly matches 9,288 input frames: stage 2 `240..9287`, 9,048 samples, then stage 4 |
| Special | Moonview Highway | 10 | Pass | Native regular-staff replay exactly matches 8,440 input frames: stage 2 `240..8439`, 8,200 samples, then stage 4 |
| Special | Bowser's Castle | 12 | Open | — |
| Special | Rainbow Road | 13 | Open | — |
| Shell | GCN Peach Beach | 16 | Pass | Native regular-staff replay exactly matches 5,889 input frames: stage 2 `240..5888`, 5,649 samples, then stage 4 |
| Shell | DS Yoshi Falls | 20 | Pass | Native regular-staff replay exactly matches 4,824 input frames: stage 2 `240..4823`, 4,584 samples, then stage 4 |
| Shell | SNES Ghost Valley 2 | 25 | Pass | Native regular-staff replay exactly matches 4,232 input frames: stage 2 `240..4231`, 3,992 samples, then stage 4 |
| Shell | N64 Mario Raceway | 26 | Pass | Native regular-staff replay exactly matches 8,320 input frames; 8,080 stage-2 samples and zero state-word mismatches against Dolphin |
| Banana | N64 Sherbet Land | 27 | Pass | Native regular-staff replay exactly matches 10,349 input frames: stage 2 `240..10348`, 10,109 samples, then stage 4 |
| Banana | GBA Shy Guy Beach | 31 | Pass | Native regular-staff replay exactly matches 6,568 input frames: stage 2 `240..6567`, 6,328 samples, then stage 4 |
| Banana | DS Delfino Square | 23 | Pass | Native regular-staff replay exactly matches 9,939 input frames: stage 2 `240..9938`, 9,699 samples, then stage 4 |
| Banana | GCN Waluigi Stadium | 18 | Pass | Native regular-staff replay exactly matches 9,404 input frames: stage 2 `240..9403`, 9,164 samples, then stage 4 |
| Leaf | DS Desert Hills | 21 | Pass | Native regular-staff replay exactly matches 8,047 input frames: stage 2 `240..8046`, 7,807 samples, then stage 4 |
| Leaf | GBA Bowser Castle 3 | 30 | Pass | Native regular-staff replay exactly matches 10,928 input frames: stage 2 `240..10927`, 10,688 samples, then stage 4 |
| Leaf | N64 DK's Jungle Parkway | 29 | Pass | Native regular-staff replay exactly matches 10,926 input frames twice: stage 2 `240..10925`, 10,686 samples, then stage 4 |
| Leaf | GCN Mario Circuit | 17 | Pass | Native regular-staff replay exactly matches 7,420 input frames: stage 2 `240..7419`, 7,180 samples, then stage 4 |
| Lightning | SNES Mario Circuit 3 | 24 | Pass | Native regular-staff replay exactly matches 6,167 input frames: stage 2 `240..6166`, 5,927 samples, then stage 4 |
| Lightning | DS Peach Gardens | 22 | Pass | Native regular-staff replay exactly matches 9,525 input frames: stage 2 `240..9524`, 9,285 samples, then stage 4 |
| Lightning | GCN DK Mountain | 19 | Pass | Native regular-staff replay exactly matches 10,894 input frames: stage 2 `240..10893`, 10,654 samples, then stage 4 |
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

## Mario Circuit exact run

- Product: sole native arm64 KartPad process launched with the process-local trace helper; no Dolphin and no Simulator.
- Executable SHA-256: `bc953f9e6642190a3bfe226558f69f1abfaed4416aeb1c9b7645caccc215ec82`.
- Retail UI path: Time Trials → Flower Cup → Mario Circuit → regular Nintendo staff data `Nin★==Kony 01:44.777` → Watch Replay.
- Private trace SHA-256: `621ffc9cb573aba276b1c51daa6a2a532970811331f38e999c14fe3f99ec6307`.
- Strict assertion: `scripts/summarize-mkw-state-trace.py --require-complete --expected-input-frames 6521`.
- Result: the accepted segment begins at race time 240, ends at 6520, contains 6,281 consecutive stage-2 samples, and is followed by stage 4. A later incomplete segment is the retail automatic replay loop.
- Capture-time FPS and audio drops under current host load are rejected; only exact guest-stage completion is accepted.

## Coconut Mall exact run

- Product: sole native arm64 KartPad process launched with the process-local trace helper; no Dolphin and no Simulator.
- Executable SHA-256: `1c2f73f9105d6f41a5ed617f1d22334cd0220bb011ccb010348a8da90635e069`.
- Retail UI path: Time Trials → Flower Cup → Coconut Mall → regular Nintendo staff data `Nin★♪SiM0 02:30.764` → Watch Replay.
- Private trace SHA-256: `64de24b8985da1e190aa8835fd47890253a265612c6c0795a880244af2664272`.
- Strict assertion: `scripts/summarize-mkw-state-trace.py --require-complete --expected-input-frames 9277`.
- Result: the accepted segment begins at race time 240, ends at 9276, contains 9,037 consecutive stage-2 samples, and is followed by stage 4. A later incomplete segment is the retail automatic replay loop.
- Focused observations reached 60 FPS across indoor/outdoor transitions, escalators, traffic, shadows, and reflective surfaces, but capture-time variance and audio drops under current host load are rejected from performance/audio acceptance.

## DK Summit exact run

- Product: sole native arm64 KartPad process launched with the process-local trace helper; no Dolphin and no Simulator.
- Executable SHA-256: `bfa5378f45b3a4eba30804d37cdcfb957f065ab34948d2ada17929d1d25e9e28`.
- Retail UI path: Time Trials → Flower Cup → DK's Snowboard Cross (PAL DK Summit) → regular Nintendo staff data `Nin★mokke 02:34.693` → Watch Replay.
- Private trace SHA-256: `7da9713d157958270635a4e27dd8e34eabe9b6095cdc0df46df018ce9f8dafee`.
- Strict assertion: `scripts/summarize-mkw-state-trace.py --require-complete --expected-input-frames 9513`.
- Result: the accepted segment begins at race time 240, ends at 9512, contains 9,273 consecutive stage-2 samples, and is followed by stage 4. A later incomplete segment is the retail automatic replay loop.
- Focused observations displayed 60 FPS across half-pipe, snow, ski-lift, jump, and trick sections; audio drops under host load keep this run out of performance/audio acceptance.

## Wario's Gold Mine exact run

- Product: sole native arm64 KartPad process launched with the process-local trace helper; no Dolphin and no Simulator.
- Executable SHA-256: `86d074650e352e266c50d3fc12489fd35854b3ac35d2968062e6ee316d8ddec6`.
- Retail UI path: Time Trials → Flower Cup → Wario's Gold Mine → regular Nintendo staff data `Nin★morimo 02:19.585` → Watch Replay.
- Private trace SHA-256: `25c25abdc17a5bcbcb09d016bb2b3b6e9a6f5df2e482649cba6d0c809a08f8ba`.
- Strict assertion: `scripts/summarize-mkw-state-trace.py --require-complete --expected-input-frames 8607`.
- Result: the accepted segment begins at race time 240, ends at 8606, contains 8,367 consecutive stage-2 samples, and is followed by stage 4. A later incomplete segment is the retail automatic replay loop.
- Focused observations displayed 60 FPS across ravines, mine interiors, moving carts, steam, branching rails, and dense wood geometry; audio drops keep this out of performance/audio acceptance.

## GCN Peach Beach exact run

- Product: sole native arm64 KartPad process launched with the process-local trace helper; no Dolphin and no Simulator.
- Executable SHA-256: `334e99a89cb1b061efb7f69bf7ab912e98f5661a361869152e76588912a70403`.
- Retail UI path: Time Trials → Shell Cup → GCN Peach Beach → regular Nintendo staff data `Nin★HIRO 01:34.233` → Watch Replay.
- Private trace SHA-256: `0cf22954bcaa8b59edea83c181abbff5bea735263759df13fa4f637bb9e60b85`.
- Strict assertion: `scripts/summarize-mkw-state-trace.py --require-complete --expected-input-frames 5889`.
- Result: the accepted segment begins at race time 240, ends at 5888, contains 5,649 consecutive stage-2 samples, and is followed by stage 4. A later incomplete segment is the retail automatic replay loop.
- Focused observations displayed 60 FPS across beach, surf, forest, item-obstacle, and translucent effect scenes; four audio drops under host load are rejected from audio acceptance.

## DS Yoshi Falls exact run

- Product: sole native arm64 KartPad process launched with the process-local trace helper; no Dolphin and no Simulator.
- Executable SHA-256: `ee4260df39e341dd1baecf8d74115e8f28ca770152d980a6aa635c74e59731b5`.
- Retail UI path: Time Trials → Shell Cup → DS Yoshi Falls → regular Nintendo staff data `Nin★DoTak 01:16.461` → Watch Replay.
- Private trace SHA-256: `9d52cf29f84851e183c9f4e4afe72531c8229f63ee0eb3431747ba0fea2fbe71`.
- Strict assertion: `scripts/summarize-mkw-state-trace.py --require-complete --expected-input-frames 4824`.
- Result: the accepted segment begins at race time 240, ends at 4823, contains 4,584 consecutive stage-2 samples, and is followed by stage 4. A later incomplete segment is the retail automatic replay loop.
- The private console log SHA-256 is `112ed94e5af89eea89f56db6bed7e31d3c951d09f3df0d085f89d146d78ead4c`. Its bounded audio summary is clean through 81,920 checks and 31,456,896 submitted bytes, with zero empty observations or drops and an 8,684-byte maximum below the 15,360-byte limit. This supports gameplay continuity but does not by itself complete row 33's pause/device-change/long-session scope.

## SNES Ghost Valley 2 exact run

- Product: sole native arm64 KartPad process launched with the process-local trace helper; no Dolphin and no Simulator.
- Executable SHA-256: `d3ec1cfd25df859e19ad3332bfa7a539183c2d8f54371971c8a355a09cc2b046`.
- Retail UI path: Time Trials → Shell Cup → SNES Ghost Valley 2 → regular Nintendo staff data `Nin★YOKO. 01:06.595` → Watch Replay.
- Private trace SHA-256: `9b308f3ed729cfb8cc805e04eb2000c1ed593b9e359f5ae2fd3ed223bcf10f68`.
- Strict assertion: `scripts/summarize-mkw-state-trace.py --require-complete --expected-input-frames 4232`.
- Result: the accepted segment begins at race time 240, ends at 4231, contains 3,992 consecutive stage-2 samples, and is followed by stage 4. A later incomplete segment is the retail automatic replay loop.
- Focused observations displayed 60 FPS across dark/fogged geometry, animated ghosts, breakaway edges, transparent driver rendering, and boost effects. Seven audio drops under host load are rejected from audio acceptance.

## GBA Shy Guy Beach exact run

- Product: sole native arm64 KartPad process launched with the process-local trace helper; no Dolphin and no Simulator.
- Executable SHA-256: `8dc81191800692bf03a5eb6d3d0e04348e3a73e9f7d8efeb333e06cf144eb71c`.
- Retail UI path: Time Trials → Banana Cup → GBA Shy Guy Beach → regular Nintendo staff data `Nin★Kato 01:45.568` → Watch Replay.
- Private trace SHA-256: `eecd70c0084708ffe4c06766c147a55a4f448721557d246e378d32f3b5770889`.
- Strict assertion: `scripts/summarize-mkw-state-trace.py --require-complete --expected-input-frames 6568`.
- Result: the accepted segment begins at race time 240, ends at 6567, contains 6,328 consecutive stage-2 samples, and is followed by stage 4. A later incomplete segment is the retail automatic replay loop.
- A rejected partial launch accidentally entered the first local Nintendo WFC privacy-notice screen. No agreement or network action occurred; the process was closed and its partial trace moved recoverably to Trash before this fresh offline run.
- The private accepted log SHA-256 is `596da9664cf1288d30f3d4b950b05066d22ae6167c0ab4d64c02556a15b17e89`. Bounded audio telemetry is clean through 106,496 checks and 40,894,080 submitted bytes, with zero empty observations/drops and a 14,296-byte maximum below the 15,360-byte limit. Broader row 33 scope remains open.

## GCN Waluigi Stadium exact run

- Product: sole native arm64 KartPad process launched with the process-local trace helper; no Dolphin and no Simulator.
- Executable SHA-256: `fa86a907ca2bebbc72eec1baf02cd83f3ceb816e584e33ed3dd23926ab945545`.
- Retail UI path: Time Trials → Banana Cup → GCN Waluigi Stadium → regular Nintendo staff data `Nin★NARI★ 02:32.882` → Watch Replay.
- Private trace SHA-256: `6b2a4644bbff65de2d12ea9a3cc18b7b6845ec3bca7b8546e026cfdbb6d9caeb`.
- Strict assertion: `scripts/summarize-mkw-state-trace.py --require-complete --expected-input-frames 9404`.
- Result: the accepted segment begins at race time 240, ends at 9403, contains 9,164 consecutive stage-2 samples, and is followed by stage 4. A later incomplete segment is the retail automatic replay loop.
- Focused observations displayed 60 FPS across the stadium crowd, dirt, ramp, lighting, boost, and water sections. The private log SHA-256 is `0b4c18b56b690eda9a5d07e9a8d9ba5e65169290171468aad45429fe539dae8d`; nine audio-queue drops are rejected from audio-row acceptance.

## DS Delfino Square exact run

- Product: sole native arm64 KartPad process launched with the process-local trace helper; no Dolphin and no Simulator.
- Executable SHA-256: `fa86a907ca2bebbc72eec1baf02cd83f3ceb816e584e33ed3dd23926ab945545`.
- Retail UI path: Time Trials → Banana Cup → DS Delfino Square → regular Nintendo staff data `Nin★iwaco 02:41.807` → Watch Replay.
- Private trace SHA-256: `9438f871a2f1490c2b989b86f938a9c12aa9cb8f727b5ba7212006f0dde1010f`.
- Strict assertion: `scripts/summarize-mkw-state-trace.py --require-complete --expected-input-frames 9939`.
- Result: the accepted segment begins at race time 240, ends at 9938, contains 9,699 consecutive stage-2 samples, and is followed by stage 4. A later incomplete segment is the retail automatic replay loop.
- Dense town geometry, shadows, bridges, water, and transparent ghost rendering remained intact. Computer-Use sampling observed temporary mid-run readings around 46–53 FPS before recovery to 60 FPS; this remains a performance observation rather than a determinism failure.
- Private log SHA-256 `3633b262262416c59f2f915ecd463d4d6ed78e97e8adfe0d464f8b7170f141fc` recorded 25 audio-queue drops, so this run is rejected from audio-row acceptance.

## N64 Sherbet Land exact run

- Product: sole native arm64 KartPad process launched with the process-local trace helper; no Dolphin and no Simulator.
- Executable SHA-256: `fa86a907ca2bebbc72eec1baf02cd83f3ceb816e584e33ed3dd23926ab945545`.
- Retail UI path: Time Trials → Banana Cup → N64 Sherbet Land → regular Nintendo staff data `Nin★Sakat 02:48.651` → Watch Replay.
- Private trace SHA-256: `877c38399ac6eaacecb0242a6183a2f6c267d711bc54f584e1ce7770d375ddf4`.
- Strict assertion: `scripts/summarize-mkw-state-trace.py --require-complete --expected-input-frames 10349`.
- Result: the accepted segment begins at race time 240, ends at 10348, contains 10,109 consecutive stage-2 samples, and is followed by stage 4. A later incomplete segment is the retail automatic replay loop.
- Ice, snow, water reflections, penguins, and transparent ghost rendering remained intact. GUI sampling observed temporary readings around 45–54 FPS under host load; this is retained as a performance observation.
- Private log SHA-256 `e08a09425dcf787670131e761000c25b23c3bb1afa90f5a2e74ef1fd9812d0af` recorded 14 audio-queue drops, so this run is rejected from audio-row acceptance.

## SNES Mario Circuit 3 exact run

- Product: sole native arm64 KartPad process launched with the process-local trace helper; no Dolphin and no Simulator.
- Test precondition: the user's own private all-cups fixture documented in `docs/artifacts/2026-08-29/g10-all-cups-fixture.md`. This enables track access only and is not progression evidence.
- Executable SHA-256: `fa86a907ca2bebbc72eec1baf02cd83f3ceb816e584e33ed3dd23926ab945545`.
- Retail UI path: Time Trials → Lightning Cup → SNES Mario Circuit 3 → regular Nintendo staff data `Nin★iwaco 01:38.880` → Watch Replay.
- Private trace SHA-256: `1cdad62c99dd8e1bcede3c14f9ceb3033a9a319902e175eda3c7c2740195fa17`.
- Strict assertion: `scripts/summarize-mkw-state-trace.py --require-complete --expected-input-frames 6167`.
- Result: the accepted segment begins at race time 240, ends at 6166, contains 5,927 consecutive stage-2 samples, and is followed by stage 4. A separate 74-frame unfinished segment is ignored; the later incomplete segment is the retail automatic replay loop.
- Focused observations displayed 60 FPS through flat-color geometry, barriers, transparency, and boost effects. Private log SHA-256 `bcbc782c220fad8fb0850d9540d37f2eaf7f46ffcf0ff045ef069c958f55aec7` recorded 17 audio-queue drops, rejected from audio-row acceptance.

## Daisy Circuit exact run

- Product: sole native arm64 KartPad process launched with the process-local trace helper; no Dolphin and no Simulator.
- Test precondition: the user's own private all-cups fixture documented in `docs/artifacts/2026-08-29/g10-all-cups-fixture.md`; progression acceptance remains separate.
- Executable SHA-256: `fa86a907ca2bebbc72eec1baf02cd83f3ceb816e584e33ed3dd23926ab945545`.
- Retail UI path: Time Trials → Star Cup → Daisy Circuit → regular Nintendo staff data `Nin★Toki 01:56.822` → Watch Replay.
- Private trace SHA-256: `290104ee301b0f8c45da71960186ffdb052a8b3c25d3ac97e0154f57c1444532`.
- Strict assertion: `scripts/summarize-mkw-state-trace.py --require-complete --expected-input-frames 7243`.
- Result: the accepted segment begins at race time 240, ends at 7242, contains 7,003 consecutive stage-2 samples, and is followed by stage 4. An earlier unfinished segment is ignored; the later incomplete segment is the retail automatic replay loop.
- Harbor, tunnel, lighthouse, animated scenery, sun/glare effects, and transparent ghost rendering remained intact. Focused presentation sampled near 58 FPS. Private log SHA-256 `7e9daa7f5d8e3ee47999d7f5374d2bd45a5d19049123e7fd82f0bcdb8f6f6db3` recorded 147 audio-queue drops and is rejected from audio-row acceptance.

## DS Desert Hills exact run

- Product: sole native arm64 KartPad process launched with the process-local trace helper; no Dolphin and no Simulator.
- Test precondition: the user's own private all-cups fixture documented in `docs/artifacts/2026-08-29/g10-all-cups-fixture.md`; progression acceptance remains separate.
- Executable SHA-256: `fa86a907ca2bebbc72eec1baf02cd83f3ceb816e584e33ed3dd23926ab945545`.
- Retail UI path: Time Trials → Leaf Cup → DS Desert Hills → regular Nintendo staff data `Nin★CHIA 02:10.233` → Watch Replay.
- Private trace SHA-256: `bd9a6068adbc64633df6df1f2aac92bee2cf48b5f279918bdb1e71e3e14f436e`.
- Strict assertion: `scripts/summarize-mkw-state-trace.py --require-complete --expected-input-frames 8047`.
- Result: the accepted segment begins at race time 240, ends at 8046, contains 7,807 consecutive stage-2 samples, and is followed by stage 4. An earlier unfinished segment is ignored; the later incomplete segment is the retail automatic replay loop.
- A bounded first-use shader compile sampled at 23 FPS, then presentation recovered to 60 FPS through sand, ruins, lighting, obstacles, and ghost transparency. This remains a G11/G36 performance observation.
- Private log SHA-256 `4ba00de7368798886bf0eafdd2ab99afe844871822c9ed2632b6392653e16e88` recorded 39 audio-queue drops and is rejected from audio-row acceptance.

## GCN Mario Circuit exact run

- Product: sole native arm64 KartPad process launched with the process-local trace helper; no Dolphin and no Simulator.
- Test precondition: the user's own private all-cups fixture documented in `docs/artifacts/2026-08-29/g10-all-cups-fixture.md`; progression acceptance remains separate.
- Executable SHA-256: `fa86a907ca2bebbc72eec1baf02cd83f3ceb816e584e33ed3dd23926ab945545`.
- Retail UI path: Time Trials → Leaf Cup → GCN Mario Circuit → regular Nintendo staff data `Nin★♪Miz 01:59.771` → Watch Replay.
- Private trace SHA-256: `14a6c68d222b2a59e9714cb762cee36a6aa1eae206df4b6c18ad30bcfe67cca3`.
- Strict assertion: `scripts/summarize-mkw-state-trace.py --require-complete --expected-input-frames 7420`.
- Result: the accepted segment begins at race time 240, ends at 7419, contains 7,180 consecutive stage-2 samples, and is followed by stage 4.
- An initial presentation sample read 19.9 FPS, then recovered to 60 FPS through animated trees, chain chomp, trackside geometry, boost effects, and ghost transparency. This remains a G11/G36 performance observation.
- Private log SHA-256 `dc90b846ac856a1f31ce5830e60501e03023c3a5a84308e03652e29ca6f6881d` recorded four audio-queue drops and is rejected from audio-row acceptance.

## Moonview Highway exact run

- Product: sole native arm64 KartPad process launched with the process-local trace helper; no Dolphin and no Simulator.
- Test precondition: the user's own private all-cups fixture documented in `docs/artifacts/2026-08-29/g10-all-cups-fixture.md`; progression acceptance remains separate.
- Executable SHA-256: `fa86a907ca2bebbc72eec1baf02cd83f3ceb816e584e33ed3dd23926ab945545`.
- Retail UI path: Time Trials → Special Cup → Moonview Highway → regular Nintendo staff data `Nin★KOZ★ 02:16.802` → Watch Replay.
- Private trace SHA-256: `264a3fcfec4143cbfc243585f08b0244a3a12002324aabd05dcee2c5b2b796bc`.
- Strict assertion: `scripts/summarize-mkw-state-trace.py --require-complete --expected-input-frames 8440`.
- Result: the accepted segment begins at race time 240, ends at 8439, contains 8,200 consecutive stage-2 samples, and is followed by stage 4. An earlier unfinished segment is ignored; the later incomplete segment is the retail automatic replay loop.
- First use sampled at 1.3 FPS, recovered to roughly 46 FPS within 20 seconds, and later sampled at 46–54 FPS through traffic, city/rural geometry, lighting, boosts, and ghost transparency. This is retained as a G11/G36 performance risk and needs a warm-cache comparison.
- Private log SHA-256 `f74ae46452cee47ce12eeec215a055282c7a7a88524e82877fa458628fe0f305` recorded 33 audio-queue drops and is rejected from audio-row acceptance.

## Grumble Volcano exact run

- Product: sole native arm64 KartPad process launched with the process-local trace helper; no Dolphin and no Simulator.
- Test precondition: the user's own private all-cups fixture documented in `docs/artifacts/2026-08-29/g10-all-cups-fixture.md`; progression acceptance remains separate.
- Executable SHA-256: `de6e157784b6256695c54d41d193da5e90363d480835db3826501fdeecbabe2b`.
- Retail UI path: Time Trials → Star Cup → Grumble Volcano → regular Nintendo staff data `Nin★Gorin 02:28.237` → Watch Replay.
- Private trace SHA-256: `308e333e3ea5290a89051039df21b99ede54048c1e3f48517dfd67da3c047180`.
- Strict assertion: `scripts/summarize-mkw-state-trace.py --require-complete --expected-input-frames 9126`.
- Result: the accepted segment begins at race time 240, ends at 9125, contains 8,886 consecutive stage-2 samples, and is followed by stage 4. Earlier non-finishing menu/preview segments are ignored; the later incomplete segment is the retail automatic replay loop.
- Bounded presentation checks during the completed replay ranged from 39.6 to 58 FPS through lava, collapsing terrain, tunnels, particles, and ghost transparency. This remains a G11/G36 performance observation, not deterministic cadence acceptance.
- Private log SHA-256 `0d936c9e0bdd409db94dfdae7d1892ab521ca1f0e567bdea9f61d55523970c89` recorded 60 audio-queue drops and is rejected from audio-row acceptance.

## Dry Dry Ruins exact run

- Product: sole native arm64 KartPad process launched with the process-local trace helper; no Dolphin and no Simulator.
- Test precondition: the user's own private all-cups fixture documented in `docs/artifacts/2026-08-29/g10-all-cups-fixture.md`; progression acceptance remains separate.
- Executable SHA-256: `80bcfee80ecd9615efef7ad2826407cf0562858c4c8dec5936a40e4e16f2532d`.
- Retail UI path: Time Trials → Special Cup → Dry Dry Ruins → regular Nintendo staff data `Nin★Kei 02:30.949` → Watch Replay.
- Private trace SHA-256: `477275d7e1cee0f61174421e81a46403f52fde057106e4f0ee97e2b325e42cd4`.
- Strict assertion: `scripts/summarize-mkw-state-trace.py --require-complete --expected-input-frames 9288`.
- Result: the accepted segment begins at race time 240, ends at 9287, contains 9,048 consecutive stage-2 samples, and is followed by stage 4. The later incomplete segment is the retail automatic replay loop.
- Bounded presentation checks remained at the overlay's 60 FPS target through sand, falling columns, bats, water, boost panels, interior/exterior geometry, and ghost transparency. Deterministic cadence remains a G11 gate.
- Private log SHA-256 `9e8727372b9da8b2979c4b2242977244bcb910876461d7e135febfa80b9ac8e7` recorded three audio-queue drops and is rejected from audio-row acceptance.

## DS Peach Gardens exact run

- Product: sole native arm64 KartPad process launched with the process-local trace helper; no Dolphin and no Simulator.
- Test precondition: the user's own private all-cups fixture documented in `docs/artifacts/2026-08-29/g10-all-cups-fixture.md`; progression acceptance remains separate.
- Executable SHA-256: `f50f860f3a3546590dc91c2f36eff9db001108c767667188e2721ba24401e26f`.
- Retail UI path: Time Trials → Lightning Cup → DS Peach Gardens → regular Nintendo staff data `Nin★Ito.y 02:34.894` → Watch Replay.
- Private trace SHA-256: `ce59ada4bc1dfe100e8e02708b34821f5fc053e131503f8e45989f79b4239f3d`.
- Strict assertion: `scripts/summarize-mkw-state-trace.py --require-complete --expected-input-frames 9525`.
- Result: the accepted segment begins at race time 240, ends at 9524, contains 9,285 consecutive stage-2 samples, and is followed by stage 4. The later incomplete segment is the retail automatic replay loop.
- Bounded presentation checks began at the 60 FPS target and later sampled at 51.7–55 FPS through hedges, Chain Chomps, flowers, statuary, garden/castle geometry, and ghost transparency. This remains G11/G36 performance evidence only.
- Private log SHA-256 `3cdc89dbad0860ca86a5bb97303c75ab528c7a43321154ba0f1410ea5096d3f3` ended at 139,264 audio-queue checks with zero drops, zero post-start empty observations, and 53,476,992 submitted bytes. It is retained as a clean telemetry candidate, but counters alone do not satisfy the subjective G10 audio row.

## N64 DK's Jungle Parkway exact run

- Product: sole native arm64 KartPad process launched with the process-local trace helper; no Dolphin and no Simulator.
- Test precondition: the user's own private all-cups fixture documented in `docs/artifacts/2026-08-29/g10-all-cups-fixture.md`; progression acceptance remains separate.
- Executable SHA-256: `bb5e63cd56751f8a9e5daea4e8bdecce92275278a0e7ac10b5a52507cf03c79c`.
- Retail UI path: Time Trials → Leaf Cup → N64 DK's Jungle Parkway → regular Nintendo staff data `Nin★Matt 02:58.264` → Watch Replay.
- Private trace SHA-256: `b2cc03b7651ba45a090a03f838c299c15faaa5193ddbfea3ca037affe54a2ac5`.
- Strict assertion: `scripts/summarize-mkw-state-trace.py --require-complete --expected-input-frames 10926`.
- Result: two independent accepted segments each begin at race time 240, end at 10925, contain 10,686 consecutive stage-2 samples, and are followed by stage 4. A later third segment is the incomplete automatic replay loop.
- Bounded presentation checks ranged from 38 to 58.5 FPS through the jungle, riverboat, bridge, water, vegetation, mud, particles, and ghost transparency. This remains G11/G36 performance evidence only; guest-state completion was exact in both complete loops.
- Private log SHA-256 `5e08e0d93913085faf2782b654c98853ce06897aa6288cfbe694a8692e5fb95a` recorded 30 audio-queue drops and is rejected from audio-row acceptance.

## GBA Bowser Castle 3 exact run

- Product: sole native arm64 KartPad process launched with the process-local trace helper; no Dolphin and no Simulator.
- Test precondition: the user's own private all-cups fixture documented in `docs/artifacts/2026-08-29/g10-all-cups-fixture.md`; progression acceptance remains separate.
- Executable SHA-256: `7f4d9d9a138f4b780d8fc092ac25517615bbf3df687a3eaf8183910ca319bdfb`.
- Retail UI path: Time Trials → Leaf Cup → GBA Bowser Castle 3 → regular Nintendo staff data `Nin★Fukuda 02:58.304` → Watch Replay.
- Private trace SHA-256: `e4b51fb794ae3cfddf4dae4161ddfa26fb630d7c084c0906f076c4334d430e8c`.
- Strict assertion: `scripts/summarize-mkw-state-trace.py --require-complete --expected-input-frames 10928`.
- Result: the accepted segment begins at race time 240, ends at 10927, contains 10,688 consecutive stage-2 samples, and is followed by stage 4. The later incomplete segment is the retail automatic replay loop.
- Bounded presentation checks remained at the overlay's 60 FPS target through lava, moving platforms, Thwomps, ramps, particles, storm effects, and ghost transparency. Deterministic cadence remains a G11 gate.
- Private log SHA-256 `12f996acb5c88a1c9cbe195e1c3c5c047c8a8fbdae2aa08bb100ffe4877c4bf4` recorded 11 audio-queue drops and is rejected from audio-row acceptance.

## Maple Treeway exact run

- Product: sole native arm64 KartPad process launched with the process-local trace helper; no Dolphin and no Simulator.
- Test precondition: the user's own private all-cups fixture documented in `docs/artifacts/2026-08-29/g10-all-cups-fixture.md`; progression acceptance remains separate.
- Executable SHA-256: `cdfd788a365edadecac4c2134ecd600606bbab4e55a85217e63a12df11366296`.
- Retail UI path: Time Trials → Star Cup → Maple Treeway → regular Nintendo staff data `Nin★pico 02:58.633` → Watch Replay.
- Private trace SHA-256: `b36a526eef9571fa16473b9f50c5f719e0ac1b91e40e248620658d76fbdca3b4`.
- Strict assertion: `scripts/summarize-mkw-state-trace.py --require-complete --expected-input-frames 10948`.
- Result: the accepted segment begins at race time 240, ends at 10947, contains 10,708 consecutive stage-2 samples, and is followed by stage 4. The later incomplete segment is the retail automatic replay loop.
- Bounded presentation checks remained at the overlay's 60 FPS target through foliage, leaf particles, tree interiors, branches, net bridge, Wigglers, moving hazards, and ghost transparency. Deterministic cadence remains a G11 gate.
- Private log SHA-256 `f946d86b72862b051495a17ef5ac08c6288fb1bd474e0384261e99b8d6408801` recorded eight audio-queue drops and is rejected from audio-row acceptance.

## GCN DK Mountain exact run

- Product: sole native arm64 KartPad process launched with the process-local trace helper; no Dolphin and no Simulator.
- Test precondition: the user's own private all-cups fixture documented in `docs/artifacts/2026-08-29/g10-all-cups-fixture.md`; progression acceptance remains separate.
- Executable SHA-256: `6989b5c35f54902641be367f9f426995c12c8c8d1eb1fa4722ef9d5a91f82ace`.
- Retail UI path: Time Trials → Lightning Cup → GCN DK Mountain → regular Nintendo staff data `Nin★♫msk 02:57.744` → Watch Replay.
- Private trace SHA-256: `6cfad5811fd108b5d24cfad977a58edbdc679107c9d8117a36b4dcf70eb76d88`.
- Strict assertion: `scripts/summarize-mkw-state-trace.py --require-complete --expected-input-frames 10894`.
- Result: the accepted segment begins at race time 240, ends at 10893, contains 10,654 consecutive stage-2 samples, and is followed by stage 4. Earlier non-finishing segments include a rejected menu-only Grand Prix prelude; the later incomplete segment is the automatic replay loop.
- Focused race presentation checks sampled at 49–51 FPS through the cannon flight, mountain switchbacks, bridge, vegetation, dust, jumps, moving hazards, and ghost transparency. This remains G11/G36 performance evidence only.
- Private log SHA-256 `1e1ba66b908f6e1830d8ad368c83d0b3ab9e310ad86a47bc3635422c8dbb1e84` recorded 85 audio-queue drops and is rejected from audio-row acceptance.

Current row 22 status: **28/32 Pass; 4 Open.** Mushroom, Flower, Shell, Banana, and Leaf Cups each have complete four-track evidence; Star and Lightning Cups are 3/4, and Special Cup is 2/4.

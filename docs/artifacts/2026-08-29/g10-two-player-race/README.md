# G10 two-player split-screen race

Status: **Pass for PRD row 29.** A normal native two-player race completed through the retail finish and standings flow with independent local-controller ownership.

## Candidate and setup

- Target: Apple M2 macOS arm64, ad-hoc-signed `KartPadRuntime.app` using the public WiiCompiled Apple-runtime patch and the user's read-only PAL `RMCP01` input.
- Closed post-run executable SHA-256: `75bd40a98db4c262448439230bb3fcb113914a2a477710c40a674e3767fd3c02`; public patch SHA-256: `d14299ac6f3faf02b6c2c86d6afc9d1a7f64844b7c428140c9fa8d1eadd6317c`.
- Mode: Multiplayer (2P) → VS Race → Solo Race → 100cc Luigi Circuit.
- P1: Mario, Standard Kart M, Automatic; keyboard-backed Classic channel 0.
- P2: Luigi, Standard Kart M, Automatic; independently registered keyboard-backed Classic channel 1.
- Instance discipline: exactly one KartPad process, no Dolphin, and no booted Simulator.

## Changed run

- P1 completed all three laps through live `U` acceleration, `M` reverse, and `A`/`D` analog steering input. The input path used no RKG playback: the active process contained only obsolete pre-rename diagnostic environment names, the candidate reads the `_V2` names, and the complete console log contained zero `[input-fixture]` entries.
- P2 remained independently connected and visible in the lower pane. Earlier changed-variable evidence in `active-both-inputs.jpeg` proves P2 can accelerate and steer separately; parking P2 here isolates P1's full human-driven completion without merging controller ownership.
- Both panes reached the retail `FINISH!` transition. The standings table then showed Mario 11th with 1 point and Luigi 12th with 0 points, following the ten CPU racers.
- Focused live captures during the race and results repeatedly showed the native overlay at 59.5–60.1 FPS, including 60.0 on both retained completion images. G11 still owns p99/worst-case frame-pacing qualification; this row does not substitute screenshot labels for that broader performance gate.
- The same native audio path already has non-silent 32 kHz stereo host-stream and independent system-output evidence under `docs/artifacts/2026-08-28/g8-title-menu/`. No audio interruption or underrun was observed during this complete split-screen run.

## Evidence

- `active-both-inputs.jpeg` — earlier changed-variable proof that both local channels independently accelerate and steer.
- `live-keyboard-finish.jpeg` — both split-screen panes display the retail finish transition after P1's third lap. SHA-256 `c8222e5fa08532f7fafdab7330389b941e094cb4601c964d8dfe26a1c8aec99a`.
- `live-keyboard-standings.jpeg` — the complete 12-racer standings table with distinct Mario/P1 and Luigi/P2 rows. SHA-256 `314f0f5d73734580ad6aaca4556ea4470c58826ed02079fd992f9c376ebd0141`.

## Diagnostic history

- A parked-player investigation showed that the retail race does not time out merely because local players remain stationary.
- A countdown-synchronized staff RKG diverged from the rear/outside VS grid origin and remains diagnostic only.
- A retail-CPU reclassification experiment crashed during scene construction and was removed completely.
- A later clean-run failure was traced to stale launcher environment inherited by the GUI helper. Diagnostic variables were renamed to `_V2`, leaving the stale names inert. The successful run above is the changed verification.

The next local-multiplayer gate is PRD row 30: complete three-player and four-player split-screen races while preserving the verified original mode cadence.

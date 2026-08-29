# G10 keyboard steering range correction

Status: **implementation correction passes its narrow build/runtime check; PRD row 30 remains open.**

The four-channel Classic-controller bridge claimed to expose the full normalized keyboard-stick range, but `ReadClassicLeftStick` multiplied every digital direction by `0.08f`. A live three-player Luigi Circuit attempt falsified that value: P1 could accelerate but could not reliably steer away from or recover from a barrier. The two-player evidence predates this focused check and required prolonged manual correction; it did not establish the documented range.

The reproducible Apple-runtime patch now emits `-1.0`, `0.0`, or `1.0` per digital axis. The already generated private runtime source received the same one-line change for the immediate build. The arm64 `WiiCompiled` target rebuilt successfully, the public patch dry-ran cleanly against the pinned runtime, the app passed strict ad-hoc signature verification before launch, and the changed native runtime was observed turning and reverse-turning P1 decisively in the retail three-player race.

- Public patch SHA-256: `9cda1217ab0f9d16549e19f288bd8c61d9ee38f6729eeb43f0a48700198b8fe5`.
- Closed, re-sealed playtest executable SHA-256: `dee991ea9596cf24b05c3329215722a52238d7c3faf5d4e236fcd157f07eee0f`.
- Instance discipline: one native KartPad process; no Dolphin and no booted Simulator.

Three private traces were rejected from row-30 acceptance and retained only under ignored `private/g10-multiplayer/`: the original 8%-range failure, an over-steered retry using the obsolete tap cadence, and a calibrated live-tap attempt that entered runoff and struck scenery. None reached a complete standings cycle. The runtime itself remained stable with all three player panes plus the fourth retail overview pane; the failure was the GUI automation driving line, not another camera lifecycle crash.

Next acceptance remains a normal three-player and four-player race reaching finish and standings. This artifact does not substitute steering movement or a partial race for that result.

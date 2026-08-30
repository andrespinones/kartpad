# G10 keyboard steering range correction

Status: **implementation correction passes its narrow build/runtime check; PRD row 30 remains open.**

The four-channel Classic-controller bridge claimed to expose the full normalized keyboard-stick range, but `ReadClassicLeftStick` multiplied every digital direction by `0.08f`. A live three-player Luigi Circuit attempt falsified that value: P1 could accelerate but could not reliably steer away from or recover from a barrier. The two-player evidence predates this focused check and required prolonged manual correction; it did not establish the documented range.

The reproducible Apple-runtime patch now preserves `-1.0`, `0.0`, or `1.0` for a physically held digital axis. A later Grand Prix playtest exposed a separate accessibility-input problem: GUI-generated key taps were only live for 50 ms, while consecutive Computer Use calls left substantial neutral gaps. Extending those taps at full strength made individual corrections too coarse. The bridge now distinguishes physical state from its synthetic fallback: synthesized axis taps use a bounded `0.35` level for 250 ms, while real holds retain the full endpoint. Controllers and future touch input do not use this fallback.

The already generated private runtime source received the same change for the immediate build. The arm64 `WiiCompiled` target rebuilt successfully, the app passed strict ad-hoc signature verification before launch, and the changed native runtime took the opening Luigi Circuit bend with bounded single-tap corrections. The incomplete cup traces remain rejected; this is a control smoke check, not Grand Prix acceptance.

- Public patch SHA-256: `c7aa6bdcdba3dd49bcfb325bbb0074d2a92ee9a6a4c208dbbc1edbb1aabc78be`.
- Closed, re-sealed playtest executable SHA-256: `454a9eebbeb0d680c77a52480970b512842a3a46c89ef37483f82d3187a2a0fe`.
- Instance discipline: one native KartPad process; no Dolphin and no booted Simulator.

Three private multiplayer traces and three Grand Prix steering-calibration traces are rejected from acceptance and retained only under ignored `private/`. None reached a complete standings or cup cycle. The runtime remained stable; these failures classify the GUI automation driving line and do not establish another gameplay or camera lifecycle fault.

Next acceptance remains a normal three-player and four-player race reaching finish and standings. This artifact does not substitute steering movement or a partial race for that result.

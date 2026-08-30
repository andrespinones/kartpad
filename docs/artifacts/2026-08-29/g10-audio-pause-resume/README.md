# G10 audio pause/resume continuity

Status: **Pass for the pause/resume subcase of PRD row 33.** PRD row 33 remains in progress because default-output-device migration, subjective listening, and the required long session are separate open checks.

## Candidate and procedure

- Target: Apple M2, native arm64, macOS 26.5, sole ad-hoc-signed KartPad process; no Dolphin and no booted Simulator.
- Runtime SHA-256: `23b1e51843faeb764d4ae685dc4a85004f8e21fd0ce3c342d791081409b78026`.
- Public Apple-runtime patch SHA-256: `c7aa6bdcdba3dd49bcfb325bbb0074d2a92ee9a6a4c208dbbc1edbb1aabc78be`.
- Mode: Time Trials → SNES Mario Circuit 3 → durable `Player 05:01.445` personal ghost → Watch Replay.
- The replay ran with non-silent 32 kHz stereo host playback, was paused through the retail `Continue Replay` menu for 15 seconds, resumed, and then ran for two additional telemetry intervals before a normal window close.

## Result

- Before pause: telemetry reached 40,960 checks and 15,728,256 submitted bytes with zero post-start empty observations and zero dropped blocks.
- During the 15-second pause, the bounded output queue reached 15,004 of 15,360 bytes and deliberately discarded eight stale blocks (3,072 bytes) rather than allowing unbounded latency growth. No empty observation or underrun occurred.
- After `Continue Replay`, the ghost visibly resumed. Cumulative telemetry advanced through 81,920 checks and 31,453,824 submitted bytes while the drop count remained exactly eight and empty observations remained zero. Therefore the transition introduced no continuing starvation, drop cascade, or queue-growth failure.
- The live RKSYS remained byte-identical at SHA-256 `ad79c24bc5eb0ba6bc8cd2836a55680621892b578a04ea49d8884a71a42c563a`.

This is an instrumentation-backed continuity result. It does not claim subjective absence of a click, device-route migration, or long-session stability.

## Evidence

- `pause-menu.png` — retail replay pause menu; SHA-256 `f572542c4a07904165efeb59c642f58d522012835546d27849e6cc25424195b6`.
- `resumed-replay.png` — personal ghost visibly running after resume; SHA-256 `411d54e38439bebf66d680e7f9d9789e7707dcc1238634257eb24be83660a390`.
- Ignored private state trace SHA-256: `8ef29d7b86b2e909c25eb204ece1a0de87305063d191c63b1633bf7de712edc3`.
- Ignored private console log SHA-256: `a3d52c4c8334d2e3ce11d21136de88e7b4829694e1fb6e3c87c29ae43d89e1e5`.

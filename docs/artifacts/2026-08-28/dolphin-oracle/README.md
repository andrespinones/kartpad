# Dolphin baseline oracle

Date: 2026-08-28

## Build and isolation

- Application: Dolphin 5.0-17995, universal arm64/x86_64 macOS build
- Runtime title: `JITARM64 DC | Vulkan | HLE`
- Executable SHA-256: `818bc7f1d344f4cf0a0ac78ee6c72dbf7800f3ad3ceebdc0c91f72aff7de4fe8`
- Disc identity: clean read-only PAL `RMCP01`, revision 0 (hashes are locked in `dependencies.lock.json`)
- User directory: repository-private ignored `private/oracle/dolphin-5.0-17995`
- Input: Dolphin's built-in `Pipe/0/KartPadOracle` controller backend; no physical controller required
- Instance rule: one Dolphin game process; no KartPad process was running

The installed application is an exact, hashed preliminary oracle binary. The source oracle remains pinned separately in `dependencies.lock.json`; no claim is made that this installed binary was built from that newer source pin.

## Observed results

- Booted the supplied WBFS through wrist-strap and title screens.
- Created a new license in the isolated NAND/user directory and reached the main menu.
- Entered Single Player → Time Trials → Luigi Circuit.
- Located the built-in Nin★sato Nintendo staff ghost (`01:29.670`).
- Launched a live staff-ghost challenge and observed real race rendering/gameplay.
- Launched the deterministic staff replay and observed sustained course traversal, lap transition, steering, boost effects, and recovery to `60 FPS / 60 VPS / 100%` after shader warmup.
- First-time course shader compilation caused transient frame-rate dips; this is baseline behavior, not a KartPad result.
- Live pipe-driven menu actions are deterministic. Race acceleration/brake semantics need a narrower control fixture before being used as a KartPad acceptance oracle.
- Audio quality was not judged; hands-on audio acceptance remains unclaimed.

## Screenshot index

- `boot-wrist-strap.png`, `title.png`: clean boot flow
- `license-select.png`, `license-create-confirmation.png`, `license-created.png`: isolated save creation
- `main-menu.png`: stable main menu
- `time-trial-luigi-circuit-select.png`: course selection
- `staff-ghost-luigi-circuit.png`: official staff ghost identity and reference time
- `staff-replay-running.png`, `staff-replay-lap-1.png`, `staff-replay-lap-2.png`, `staff-replay-final-lap.png`: deterministic reference gameplay at successive replay phases

## Cleanup verification

Dolphin was stopped through its confirmation/save flow. The pre-session and post-session SHA-256 hashes of the user's global `WiimoteNew.ini`, `GCPadNew.ini`, and `Dolphin.ini` matched byte-for-byte. All oracle save/controller state remains ignored under `private/`.

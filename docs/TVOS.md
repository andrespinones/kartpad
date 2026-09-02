# KartPad native tvOS implementation

## Current status

Native tvOS support is under active implementation on the maintainer-owned
`codex/tvos-retro-rewind` branch. There is no public tvOS build and no accepted
Apple TV gameplay result yet. Until the physical acceptance matrix below
passes, the correct claim is **buildable experimental tvOS candidate**, not
supported Apple TV release.

This implementation starts from KartPad `main`, the project's pinned upstream
sources, and Apple/SDL platform contracts. It does not incorporate code from
pull request #7. That pull request remains useful feasibility evidence, but its
patch is not the implementation source for this branch.

## First candidate scope

- Apple TV hardware running tvOS 17 or later.
- Original Mario Kart Wii and Retro Rewind 6.12.4 through the existing
  `KartPadDual` ahead-of-time translated product.
- Offline play first. Retro WFC remains a separate network-acceptance gate.
- One to four Extended Gamepad controllers. The Siri Remote can operate native
  setup UI but is not a supported racing controller.
- User-provided, validated PAL `RMCP01` revision-0 extracted game data.
- The official pinned Retro Rewind full pack, downloaded and hash-verified by
  KartPad. Neither game data nor the Retro Rewind pack is bundled.

## Architecture

The tvOS target shares KartPad's translated base/Retro Rewind graph, Aurora,
Dawn/Metal renderer, Classic Controller adapter, four-player GameController
assignment, release profile, and Retro Rewind archive verifier. It has a small
tvOS-specific UIKit host for focus-driven setup and deliberately excludes the
iPhone/iPad document picker, touch overlay, motion steering, and Files app
workflow.

The host refuses to begin gameplay until all of these are true:

1. A complete RMCP01 extracted tree is present and its disc header and
   `sys/main.dol` match the pinned profile.
2. The selected Original or Retro Rewind product exists in the linked dual
   graph.
3. Retro Rewind content matches the pinned version, sizes, and SHA-256 hashes
   when that mode is selected.
4. At least one Extended Gamepad is connected.

## Storage and recovery contract

tvOS may purge large local data. KartPad therefore separates state by whether
it can be reconstructed:

| Data | Location | Recovery |
| --- | --- | --- |
| Extracted RMCP01 data | `Library/Caches/KartPad/GameData` | Restage from the user's Mac |
| Retro Rewind pack | `Library/Caches/KartPad/RetroRewind` | Download and verify again |
| Config, NAND, saves, diagnostics | `Library/Application Support/KartPad` | Back up to the user's Mac before testing |

Application Support is not treated as a permanent guarantee on Apple TV. The
developer preview includes a Mac-side backup command, and testers must back up
before replacing or deleting the app. A later broadly supported release needs
a tested durable sync/restore design, such as an appropriately entitled
CloudKit container, before it can promise durable saves.

## Building the first candidate

Requirements:

- ARM64 Mac with an installed stable Xcode that includes the tvOS SDK.
- KartPad's pinned reference checkouts and private dual-profile translation.
- User-owned extracted RMCP01 data. Keep it outside Git and the app bundle.

Build the pinned Dawn package once:

```sh
./scripts/build-dawn-tvos.sh appletvos
```

Prepare a fresh patched runtime and build the unsigned dual-mode app:

```sh
./scripts/prepare-tvos-game-runtime.sh
./scripts/build-tvos-game-app.sh
```

The expected output is
`build/tvos-game-app-xcode/Release-appletvos/KartPad.app`. The build script runs
the tvOS audit automatically. Signing and installation remain local developer
actions; the unsigned app contains translated code but no disc image, extracted
assets, Retro Rewind pack, saves, provisioning profile, or signing identity.

After installing the signed app, stage the user's extracted DATA directory:

```sh
./scripts/stage-tvos-game-data.sh /absolute/path/to/DATA "Living Room"
```

Launch KartPad, choose Retro Rewind, and allow KartPad to download and verify
the pinned official pack. Never stage Nintendo or Retro Rewind data into the
repository or distributable app bundle.

Back up saves and configuration before replacing or deleting the app:

```sh
./scripts/backup-tvos-state.sh "Living Room" /absolute/path/to/new-backup
```

## Physical acceptance matrix

Record the Apple TV model, tvOS version, Xcode/SDK, controller models, source
commit, binary SHA-256, and whether the run used Original or Retro Rewind.

- [x] Clean unsigned `KartPadDual` build passes `audit-tvos-app.sh`.
- [ ] Locally signed candidate installs and opens on a physical Apple TV.
- [ ] Missing data shows setup instructions rather than crashing or exiting.
- [ ] Valid RMCP01 data stages from a Mac and survives ordinary relaunch.
- [ ] Original mode reaches a complete race with correct video and audio.
- [ ] Retro Rewind downloads, verifies, installs, and reaches a complete race.
- [ ] Original/Retro mode switching works across clean relaunches.
- [ ] Controller-required UI works with no controller, pairing, disconnect, and
  reconnect; Siri Remote input never leaks into racing controls.
- [ ] Two-, three-, and four-controller slot assignment is stable.
- [ ] A save survives normal exit, relaunch, sleep/wake, and forced termination.
- [ ] `backup-tvos-state.sh` captures the save and a restore rehearsal recovers
  it before any tester is asked to risk meaningful progress.
- [ ] Purging reconstructible content produces a recovery screen; restaging
  game data and redownloading Retro Rewind do not overwrite saves.
- [ ] A full cup and at least a 30-minute soak record frame pacing, audio,
  memory pressure, temperature, and controller behavior.
- [ ] A native layered tvOS app icon is compiled and visually checked on the
  Apple TV Home Screen before an external build is distributed.
- [ ] The exact tester artifact contains no private data, derived branding,
  signing material, local paths, or unsupported public claims.

## External testing gate

Do not recruit testers merely because the source compiles. The first external
test build requires one maintainer-run physical Apple TV pass covering install,
game-data staging, controller input, Original gameplay, Retro Rewind download
and gameplay, save/relaunch, and backup. After that pass, publish a narrowly
scoped tester checklist and collect exact device/build evidence. Keep issues
open until the reported hardware path has been retested.

The first unsigned device build passed on 2026-09-03 with Xcode 26.6 and the
tvOS 26.5 SDK at a tvOS 17.0 deployment target. See
[`docs/artifacts/2026-09-03/tvos-first-native-build.md`](artifacts/2026-09-03/tvos-first-native-build.md).

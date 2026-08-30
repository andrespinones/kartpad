# KartPad

<p align="center">
  <strong>Mario Kart Wii on Apple Silicon Mac, iPhone, and iPad through static recompilation and Metal.</strong><br>
  Native macOS gameplay plus touch-first iPhone and iPad development builds using private user-supplied game data.
</p>

<p align="center">
  <img src="branding/exports/KartPadIcon-1024.png" width="180" alt="KartPad app icon">
</p>

<p align="center">
  <img alt="Apple Silicon" src="https://img.shields.io/badge/Apple%20Silicon-arm64-0A84FF?logo=apple">
  <img alt="Metal renderer" src="https://img.shields.io/badge/renderer-Metal-5E5CE6">
  <img alt="Ahead-of-time static recompilation" src="https://img.shields.io/badge/PowerPC-static%20recompilation-FF9F0A">
  <img alt="macOS development target" src="https://img.shields.io/badge/macOS%20target-14%2B-0A84FF">
  <img alt="Game data not included" src="https://img.shields.io/badge/game%20data-not%20included-FF453A">
</p>

![KartPad running a saved Mario Circuit 3 replay natively on macOS](docs/artifacts/2026-08-29/g10-audio-device-migration/stable-after-restore.png)

KartPad packages a native Apple ARM64 app around a
[WiiCompiled](https://github.com/sonicdcer/WiiCompiled)-generated Mario Kart Wii
module and its Aurora/Dawn compatibility runtime. PowerPC game code runs as
ahead-of-time translated arm64 code, Dawn presents through Metal, and a narrow
Apple host layer supplies audio, input, storage, timing, and lifecycle behavior.

This repository contains KartPad's Apple integration, reproducible patches,
tests, documentation, and original artwork. It does **not** contain Mario Kart
Wii, a disc image, extracted Nintendo assets, generated game code, saves, or
signing material.

## Current status

| Area | Current result |
|---|---|
| macOS runtime | Native arm64 title, menus, races, saves, ghosts, Battle, and split-screen gameplay through Metal |
| Track coverage | All 32 retail tracks have exact native completion evidence |
| Correctness | Darwin memory, scheduler, ABI, integer, scalar-FP, and paired-single gates pass against their defined oracles |
| Input | Keyboard plus four independent Classic-controller slots; two-player full-race evidence passes |
| Audio | Non-silent host playback, pause/resume, live output-device migration, and a two-hour representative continuity run pass their instrumented subcases; subjective listening and the eight-hour soak remain open |
| Packaging | The original icon and exact branded 80 MiB package pass audit, installed-storage, configured gameplay, save-preservation, and normal-close checks; the native first-run/settings/data-management shell remains open |
| iPhone/iPad | The full 29,065-function arm64 retail app boots, reaches live races, imports private extracted data, preserves saves, and resumes on iPhone and iPad Simulator with the exact SunPad touch/menu source; complete touch races and physical-device acceptance remain open |
| Distribution | Development source only; no game data and no release candidate |

The evidence ledger, exact open rows, and known risks live in
[`docs/STATUS.md`](docs/STATUS.md). The 67-row release matrix is in
[`docs/PRD.md`](docs/PRD.md); a successful compile or screenshot is never
treated as gameplay acceptance by itself.

## Game data

KartPad never downloads or bundles Nintendo data. Development uses a locally
owned PAL `RMCP01` revision 0 image that is verified, kept read-only, and
ignored by Git. Extracted files, translations, caches, saves, logs, and private
captures stay in ignored local directories.

On iPhone and iPad, first launch stops before emulation and asks for an
extracted `RMCP01` `DATA` folder. KartPad validates the disc identity and
runtime-critical files, copies the 2.5 GiB tree into private Application
Support with iOS data protection, excludes it from backup, and atomically
activates it. Interrupted imports recover or roll back; replacement never
silently discards the last valid copy. Removal is explicit, undoable until
relaunch, and occurs before emulation while preserving saves.

The translated ARM64 graph is compiled and signed on the Mac. The mobile app
imports non-executable game data only; it contains no PowerPC JIT, runtime
compiler, or executable-code download.

## Developer workflow

You need an Apple Silicon Mac, Xcode and its command-line tools, CMake, Ninja,
Git, ripgrep, Python 3, and your own legally obtained supported Mario Kart Wii
disc image.

Verify the pinned public sources and private input boundary:

```sh
./scripts/verify-sources.sh
./scripts/check-repo-safety.sh
```

Run the portable correctness gates:

```sh
./scripts/test-host-portability.sh
./scripts/test-guest-memory.sh
./scripts/test-guest-scheduler.sh
./scripts/test-ppc-semantics.sh
```

Build from the pinned supported image in one fail-closed local workflow:

```sh
./scripts/self-build-macos.sh /path/to/your/Mario-Kart-Wii.wbfs
```

The workflow verifies the complete supported image hash, extracts it read-only
with pinned `nodtool`, validates `RMCP01` revision 0 plus the DOL/REL hashes,
translates the full private title graph with bounded parallelism, builds the
patched Apple runtime, and audits the signed local app. All extracted and
translated outputs stay under ignored `private/`; the app stays under ignored
`build/`. Existing valid extraction/translation work can be resumed.

To build from an already produced ignored translation graph, run the lower
level steps directly:

```sh
./scripts/prepare-g7-game-runtime.sh
./scripts/package-macos-runtime.sh \
  "$PWD/build/g7-game-runtime-build" \
  "$PWD/build/KartPad.app"
./scripts/audit-macos-package.sh "$PWD/build/KartPad.app"
```

Prepare and build the complete iOS Simulator runtime from the same private
translation graph:

```sh
./scripts/prepare-ios-game-runtime.sh \
  private/g8-full-translation \
  build/ios-game-runtime-source \
  build/ios-game-runtime-build
./scripts/build-ios-game-app.sh \
  build/ios-game-runtime-source \
  build/ios-game-app-xcode \
  private/g8-full-translation
```

The build scripts verify the exact SunPad source snapshot and dependency pins,
compile only ARM64 code, and fail if private game data, saves, signing material,
or non-system dynamic dependencies enter the app bundle. Installation and
signing remain local development steps; this repository does not publish a
playable app artifact.

See [`docs/GOAL-LOOP.md`](docs/GOAL-LOOP.md) for the execution rules and
[`docs/JOURNAL.md`](docs/JOURNAL.md) for reproducible commands and dated
results.

## Controls and mobile direction

The development macOS keyboard bridge maps directional keys to menu movement,
`U` to A/accelerate, `M` to B/reverse, and dedicated steering keys to the
Classic Controller stick. Native controller discovery and four stable local
slots are implemented separately from the keyboard fallback.

The iPhone/iPad app compiles a byte-identical pinned snapshot of SunPad's GPLv3
touch-control component and persistent **•••** menu directly. It preserves the
component's independently editable phone/tablet layouts, safe-area treatment,
multitouch, accessibility labels, settings, diagnostics, and controller-handoff
behavior. A separate tested adapter supplies Mario Kart Wii's Classic Controller
ABI without changing the copied baseline.

KartPad's owning layer adds two actions ahead of SunPad's unchanged menu:

- **Multiplayer…** reports connected controllers, stable Player 1–4 assignment,
  and opens controller setup guidance. Players 2–4 publish independent retail
  KPAD channels while touch remains Player 1.
- **Motion Steering…** is default-off and provides recenter, inversion, and
  0.5×/1×/2× sensitivity. Touch can override it, physical controllers take
  priority, and backgrounding clears the live motion state.

The full retail graph boots on iPhone 17 Pro and iPad Pro 13-inch Simulator,
reaches title/menu/live Luigi Circuit, survives background/foreground, and
preserves exact save hashes across relaunch. The original icon catalog, privacy
manifest, opaque fitted-output bands, package boundary, and unsigned physical
device compilation pass. Simulator motion sensors are unavailable by design;
physical motion feel, complete touch/motion races, physical controller handoff,
and physical-device performance/audio remain hands-on gates.

## First launch on iPhone or iPad

KartPad does not include Mario Kart Wii and cannot compile game code on-device.
For a locally built development app:

1. Prepare the supported private translation and extracted `RMCP01` data on the
   Mac from your own disc image.
2. Put the extracted `DATA` folder in Files, or choose it from another Files
   provider when KartPad asks for game data.
3. Launch KartPad and choose **Choose Extracted DATA Folder…**.
4. Leave the app open while it validates, protects, stages, and activates the
   copy. A successful first import continues into the game in the same session.
5. Later, use **••• → Game Data & Saves** to reimport or schedule removal.

Saves live separately from the extracted game-data tree. Reimport and removal
retain them; uninstalling the app still removes its whole Apple container.

## Mobile screenshots

<table>
  <tr>
    <td width="50%"><img src="docs/artifacts/2026-08-30/g14-full-game-simulator/iphone-live-race-touch.jpeg" alt="KartPad live Luigi Circuit gameplay with the touch overlay on iPhone Simulator"></td>
    <td width="50%"><img src="docs/artifacts/2026-08-30/g14-full-game-simulator/ipad-live-race-touch.jpeg" alt="KartPad live Luigi Circuit gameplay with the touch overlay on iPad Simulator"></td>
  </tr>
  <tr>
    <td align="center"><strong>iPhone retail runtime</strong><br>Metal gameplay with the exact SunPad touch surface.</td>
    <td align="center"><strong>iPad retail runtime</strong><br>The independent tablet layout scales across the larger safe area.</td>
  </tr>
</table>

These are Simulator development-build captures using game data supplied
privately by the device owner. No game image, extracted data, save, or playable
binary is part of this repository.

## Evidence-first development

KartPad keeps publishable, content-safe evidence under `docs/artifacts/` and
private traces under ignored paths. Every accepted step records the candidate,
procedure, observed result, hashes, limitations, and next gate. The project
does not infer timing, audio quality, touch feel, or stability from source
inspection alone.

Useful starting points:

- [`docs/STATUS.md`](docs/STATUS.md) — current accepted state and open risks.
- [`docs/PRD.md`](docs/PRD.md) — product requirements and release matrix.
- [`docs/PORTABILITY.md`](docs/PORTABILITY.md) — Windows-to-Apple host boundary.
- [`docs/SEMANTICS.md`](docs/SEMANTICS.md) — PPC/AArch64 correctness evidence.
- [`docs/RELEASE-CHECKLIST.md`](docs/RELEASE-CHECKLIST.md) — release gates.

## Legal and provenance

Mario Kart, Wii, Nintendo, and game imagery are owned by their respective
rights holders and are used here only to identify compatibility and document
runtime behavior. KartPad is not affiliated with or endorsed by Nintendo.

WiiCompiled is GPLv3 at the pinned revision. Aurora, Dawn, SDL, Dolphin-derived
code, Crypto++, Abseil, FreeType, libpng, and other dependencies retain their
own licenses and notice obligations. The imported SunPad mobile UI snapshot
retains its GPLv3 license, exact upstream revision, hashes, and attribution.
KartPad's original icon provenance is recorded in
[`branding/PROVENANCE.md`](branding/PROVENANCE.md).

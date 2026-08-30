# KartPad

<p align="center">
  <strong>Mario Kart Wii on Apple Silicon Mac, iPhone, and iPad through static recompilation and Metal.</strong><br>
  Native macOS gameplay today; a touch-first iPhone and iPad shell is the next product stage.
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
| iPhone/iPad | The native arm64 shell now runs on both iPhone and iPad Simulator with the exact SunPad overlay/menu, original icons, linked core self-check, rotation policy, and foreground lifecycle; retail gameplay and mobile acceptance remain open |
| Distribution | Development source only; no game data and no release candidate |

The evidence ledger, exact open rows, and known risks live in
[`docs/STATUS.md`](docs/STATUS.md). The 67-row release matrix is in
[`docs/PRD.md`](docs/PRD.md); a successful compile or screenshot is never
treated as gameplay acceptance by itself.

## Game data

KartPad never downloads or bundles Nintendo data. Development currently uses a
locally owned PAL `RMCP01` revision 0 disc image that is verified, kept
read-only, and ignored by Git. Extracted files, translations, caches, saves,
logs, and captures stay in ignored local directories.

A finished app will provide a local import flow for a user-supplied supported
image. Until that shell is complete, the repository is intended for developers
who can reproduce the pinned translation workflow.

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

After producing the ignored translated title graph, build the patched Apple
runtime and package it as a self-contained app:

```sh
./scripts/prepare-g7-game-runtime.sh
./scripts/package-macos-runtime.sh \
  "$PWD/build/g7-game-runtime-build" \
  "$PWD/build/KartPad.app"
./scripts/audit-macos-package.sh "$PWD/build/KartPad.app"
```

The game-runtime workflow is still being consolidated into a clean-clone
single command. See [`docs/GOAL-LOOP.md`](docs/GOAL-LOOP.md) for the execution
rules and [`docs/JOURNAL.md`](docs/JOURNAL.md) for reproducible commands and
dated results.

## Controls and mobile direction

The development macOS keyboard bridge maps directional keys to menu movement,
`U` to A/accelerate, `M` to B/reverse, and dedicated steering keys to the
Classic Controller stick. Native controller discovery and four stable local
slots are implemented separately from the keyboard fallback.

The iPhone/iPad shell compiles a byte-identical pinned snapshot of SunPad's
GPLv3 touch-control component and persistent **•••** menu directly. It preserves
the component's layout editing, controller handoff, accessibility behavior, and
safe-area treatment; a separate tested adapter supplies Mario Kart Wii's Classic
Controller mapping without changing the copied baseline. The native arm64
Simulator shell now launches on both an iPhone 17 Pro and an iPad Pro 13-inch
class, and its original icon catalog, privacy manifest, scene lifecycle, linked
core self-check, and package audit pass. The same source graph also builds and
audits as an unsigned physical-device artifact. The full retail graph and real
KartPad menu services remain under integration, and the mobile surface is not
accepted until complete iPhone and iPad Simulator races pass with one Simulator
booted at a time.

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

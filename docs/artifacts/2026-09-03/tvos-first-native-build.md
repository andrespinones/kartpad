# First native tvOS full-game build

Date: 2026-09-03

## Scope

This is the first independent KartPad tvOS build proof. It starts from KartPad
`main` at `ad8ef33810aedbf94f8738d246aa3a0619f3b3ea` plus the tracked changes on
`codex/tvos-retro-rewind`. No code from pull request #7 was incorporated.

The target links the private, maintainer-generated dual translation graph for
Original Mario Kart Wii and Retro Rewind. The audited `.app` contains no disc
image, extracted game data, Retro Rewind pack, save, provisioning profile, or
signing identity.

## Toolchain and dependency evidence

- Host: arm64 macOS.
- Xcode: 26.6 (`17F113`).
- tvOS SDK: 26.5.
- Deployment target: tvOS 17.0.
- Dawn source: pinned commit `13abc3bc8ea2d3c2050f9e77a12d012108ceee24`.
- Deterministic tvOS Dawn package SHA-256:
  `e992f36281f153147cb25dd9c77d6bddfd5f7bfa421a3f999139a1dbadadbb57`.

The tvOS Dawn package built from the pinned source and Aurora resolved it from
the local hash-verified package. The complete `KartPadDual` target then compiled
and linked for arm64 `TVOS`; the resulting bundle was 91 MiB.

## Audit result

`scripts/audit-tvos-app.sh` passed for the unsigned app. The audit confirmed:

- bundle identifier `dev.kartpad.tv` and tvOS 17.0 minimum version;
- `TVOS` Mach-O platform metadata with SDK 26.5;
- SDL's UIKit scene delegate;
- declared Extended Gamepad support;
- system-only dynamic dependencies;
- linked Original/Retro Rewind profile-selection and four-player controller
  input contracts;
- presence of the focus-driven Apple TV setup and recovery strings;
- privacy manifest presence; and
- absence of game images, saves, provisioning profiles, and other forbidden
  private material.

Executable SHA-256:
`c0f759e6e27cc3c31abeba124f798b0f1f30bb80bd1b58b303d1467cafff4c0e`.

Privacy manifest SHA-256:
`343dbc92a22d95a896d5bb894f439d655ac8e15d0fcc7fe72500bd5fcaba1740`.

The bundle is intentionally unsigned. `codesign` reported that the code object
was not signed at all. The final build also passed the wrapper's absolute
repository-path rejection after rebuilding Dawn with deterministic file and
macro prefix maps.

## Remaining acceptance gates

No Apple TV was paired with the build Mac; only an iPad and iPhone were visible
to CoreDevice. This evidence closes compilation, linking, and static artifact
inspection only. It does not establish signing, installation, launch, focus
behavior, controller input, video/audio correctness, Original or Retro Rewind
gameplay, performance, sleep/wake, save durability, or recovery.

The first proof bundle also has no compiled tvOS brand asset. A layered KartPad
icon and its Home Screen visual check remain required before external testing;
this does not invalidate the executable/link proof.

The next gate is one maintainer-run physical Apple TV pass following
`docs/TVOS.md`. External testing begins only after that pass, using an exact
signed build and recorded executable hash.

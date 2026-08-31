# Full translated physical-iOS application

The accepted integrated mobile source now produces a complete unsigned
physical-iPhone/iPad app, not only a portability shell or isolated UIKit
object.

## Exact graph

- Base translated functions: `29,065/29,065`.
- Target: arm64 `IOS`, minimum iOS 16.0, SDK 26.5.
- Renderer: Aurora GX through pinned Dawn/Metal.
- App/lifecycle: SDL UIKit scene delegate plus KartPad's exact SunPad-derived
  overlay host.
- Input: touch, physical controllers, four retail KPAD channels, optional
  CoreMotion steering, compact digital R, and held-acceleration feedback.
- Physical-iOS Dawn package SHA-256:
  `a361fcca75929fa5c766cfcde979c010a6da7d805e5db8e15c75e73fd8260e78`.

## Result

- `scripts/build-ios-device-game-app.sh` — pass.
- Xcode compile/link — pass.
- Built app size — 75 MiB.
- Full-game `IOS` audit — pass.
- Executable SHA-256:
  `54458302a273c2f93955f3ee9c8558e54456c8578439d50fd3651cb52cf17711`.
- `Assets.car` SHA-256:
  `d25540efa70a7c9f6ef8d12849a6469ea8e7ff2c5cbe9477c9e7513c640b2434`.
- `PrivacyInfo.xcprivacy` SHA-256:
  `343dbc92a22d95a896d5bb894f439d655ac8e15d0fcc7fe72500bd5fcaba1740`.
- Dynamic dependency audit: Apple system frameworks/libraries only.
- Private-data/package-boundary audit: pass.
- Simulator-only import/touch probes absent: pass.
- Immediate incremental reproduction: same executable hash.

## Fresh-directory reproduction

A later clean source preparation found that the serialized full-file KPAD hunk
declared 765 output lines while actually containing 767. Traditional `patch`
accepted the hunk but omitted the final `return true;` and closing brace. The
tracked header now declares all 767 lines; applying it to a new copy of the
pinned runtime preserves the complete function.

- Fresh Simulator source/build directories: pass after correcting the tracked
  hunk and resuming the rejected build.
- Original failure boundary: runtime unity compilation, step 757/853.
- Corrected standalone Simulator link: pass; executable SHA-256
  `db5be50d55916fd9bd9ed8be7dbee7fb7885edc21380687d8dc4cf9bef563cf1`.
- The standalone Ninja output deliberately retains generator placeholders in
  `Info.plist` and has no Xcode-compiled `Assets.car`; it is a full-code link
  boundary, not an installable or package-audited Simulator app.
- Independent fresh physical-device Xcode directory: configure, compile, link,
  and strict `IOS` audit pass.
- Fresh physical executable SHA-256:
  `3e201daca7591a2bcadc3e28a4ad45565ac0813b2138ff57abad7690aaef8c4f`.
- Immediate incremental rerun: pass with the same physical executable hash.
- `Assets.car` SHA-256 remains
  `d25540efa70a7c9f6ef8d12849a6469ea8e7ff2c5cbe9477c9e7513c640b2434`.
- `PrivacyInfo.xcprivacy` SHA-256 remains
  `343dbc92a22d95a896d5bb894f439d655ac8e15d0fcc7fe72500bd5fcaba1740`.
- Exact twelve-file SunPad snapshot remains byte-identical at
  `e43f0ea6b797e5110787171957c9dc3c6213269c`.
- Simulator-only touch/import test hooks remain absent from the device app.
- No Simulator device or game runtime was launched.

## Patch-stack guard

`scripts/verify-patch-hunks.py` now validates the declared old/new line counts
for every unified-diff hunk before source pins and disc identity are accepted.
The initial run detected the KPAD truncation plus count defects in six older
patches; all tracked headers were corrected without changing patch
content. The guard now passes 174 hunks across 13 patches. A new disposable
runtime copy accepted the complete mobile patch sequence, and its KPAD and
Aurora presentation sources are byte-identical to the sources used by the
successful clean builds. The FPSCR translator patch also reapplied and its
Release CLI rebuilt with zero warnings or errors.

No Simulator or game instance ran during this work. This is evidence for full
physical-iOS source compilation, linking, bundle construction, and package
audit. It does not establish signing, installation, launch, Metal execution,
performance, thermals, audio, touch feel, or lifecycle behavior on hardware.

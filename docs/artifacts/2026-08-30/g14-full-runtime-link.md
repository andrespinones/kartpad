# G14 full retail runtime Simulator link checkpoint

Date: 2026-08-30

## Classification

Pass for reproducibly compiling and linking the complete base-game translated
runtime as an arm64 iOS Simulator Mach-O. This is an integration prerequisite,
not a runnable-app or gameplay claim. The generated standalone CMake bundle has
placeholder identity/lifecycle metadata and is not the KartPad UIKit shell.
No Simulator was booted for this checkpoint.

## First blocker and correction

The first complete iOS link used encounter/dawn-build's official
`dawn-ios-arm64.tar.gz`. Compilation succeeded through the complete translated
graph and Aurora GX, but the linker correctly rejected `libwebgpu_dawn.a`
because its objects declared platform `IOS`, not `IOSSIMULATOR`.

KartPad now builds the same Dawn release commit directly for the Simulator:

- Dawn release: `v20260603.191052`.
- Dawn commit: `13abc3bc8ea2d3c2050f9e77a12d012108ceee24`.
- Pinned source-archive SHA-256:
  `713bea5b92d4f6c5175752fd7cbf1c3c5ce36598ff5dd98685d8a1216614ebba`.
- Deterministic Simulator-package SHA-256:
  `c9272faca14a307e4545ea83cb66ab2f65e87fa33a0a687bf5c702666271bc03`.

`scripts/build-dawn-ios-simulator.sh` builds a native host `protoc`, then the
arm64 `iphonesimulator` monolithic static library. It normalizes the archive
symbol table, install-tree timestamps, ownership, member order, and gzip header.
Two complete package passes produced the exact same final digest. Representative
`webgpu_dawn_native_proc.cpp.o` and `MetalBackend.mm.o` members both report:

```text
platform IOSSIMULATOR
minos 16.0
sdk 26.5
```

The runtime patch now selects independent pinned hashes for macOS, physical iOS,
and iOS Simulator artifacts. It does not relax Apple's platform check.

## Reproducible runtime build

`scripts/prepare-ios-game-runtime.sh` copies the untouched pinned upstream
runtime, applies `patches/wiicompiled-apple-runtime.patch`, verifies the Dawn and
sse2neon inputs, configures the iOS 16 Simulator graph, builds the complete
base-game target, and rejects a final binary with a host-library dependency or
the wrong Mach-O platform.

The fresh build exposed a latent patch-serialization defect: the KPAD hunk
declared 756 output lines while containing 765, so `patch` had silently omitted
the final nine lines. The hunk count was corrected. A second untouched upstream
copy patched with the final patch is byte-identical to the resumed clean build
source; the corrected KPAD SHA-256 in both trees is
`2406c7caae6d8387591eff2f803d223a4f78c9acb178384b0285a7930b15fa42`.
The complete patch dry-run passes, including the platform-aware NAND path fix.

The clean configure reported:

```text
Translator graph: 29065/29065 base functions shared
Platform: iOS
Video drivers: dummy offscreen uikit
GPU drivers: metal vulkan
Audio drivers: coreaudio disk dummy
Joystick drivers: hidapi mfi virtual
```

The fresh build compiled all content-addressed translation shards, 16
registration shards, indirect dispatch, runtime/HLE, Crypto++, pugixml, SDL
UIKit/CoreAudio, and Aurora GX/Metal, then linked successfully.

## Final artifact audit

- Binary: ignored
  `build/g14-ios-runtime-repro-build/WiiCompiled.app/WiiCompiled`.
- Size: 78,548,760 bytes.
- SHA-256:
  `1d970f1ae75b5b0c8f3287df89d02d9b1b38524960808aa867868d30c855315c`.
- Architecture: Mach-O 64-bit executable, arm64.
- Build platform: `IOSSIMULATOR`.
- Deployment floor: iOS 16.0.
- Dynamic dependencies: Apple iOS system libraries/frameworks only; no
  `/opt/homebrew` or `/usr/local` dependency.

The linked frameworks include UIKit, Metal, QuartzCore, CoreAudio,
AudioToolbox, AVFoundation/AVFAudio, GameController, CoreMotion, CoreHaptics,
CoreMedia/CoreVideo, Foundation/CoreFoundation, and Apple system libraries.

## Honest boundary and next gate

The generated `WiiCompiled.app` still has empty bundle identity/version/icon
fields and no KartPad scene ownership. Its linker-generated ad-hoc signature
does not seal bundle resources. It was therefore audited as a static
compile/link product and not installed or launched.

The next gate is to expose an embedded runtime entry/lifecycle boundary and
link these exact retail objects into KartPad's existing UIKit scene while
retaining the byte-identical SunPad overlay, real icon catalog, privacy
manifest, storage services, and one-Simulator-at-a-time launch guard. Only then
can title/menu/audio/save and complete touch-driven races be tested honestly.

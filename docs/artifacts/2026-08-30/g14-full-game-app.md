# G14 full retail Simulator app integration

Date: 2026-08-30

## Scope

This checkpoint promotes the previously linked 29,065-function retail runtime into a real Xcode-produced iPhone/iPad Simulator application. It does not claim a successful launch, gameplay, audio, save, or touch feel; no Simulator was booted while collecting this build evidence.

## Integration boundary

- SDL 3.4.4 owns the UIKit application and scene lifecycle through `SDL_RunApp` and `SDLUIKitSceneDelegate`.
- After Aurora creates the real SDL/UIKit Metal window, `KartPadMobileRuntimeHostInstall` resolves its `UIWindow` and attaches the byte-identical SunPad overlay above the renderer view.
- `KartPadMobileReadClassicInput` consumes the exact SunPad mixer, passes it through KartPad's separate Classic Controller adapter, and merges channel-zero touch state into both retail KPAD status paths.
- The copied SunPad snapshot remains byte-identical to pinned reference commit `e43f0ea6b797e5110787171957c9dc3c6213269c`.
- The original KartPad light/dark/tinted icon catalog and privacy manifest are compiled by Xcode; no private disc image or save is packaged.

## Reproducible source

The integration is serialized in four ordered patches: the Apple runtime, iOS app integration, mobile core-button bridge, and mobile settings/aspect bridge. A fresh copy of `ref/upstream/Wiicompiled/runtime` accepted all four patches, and the generated source matched the compiled source byte-for-byte.

| File | SHA-256 |
|---|---|
| `cmake/PublicProducts.cmake` | `3ddb3a165b382d825c4005e9df028f0374038124345419586d8fa5a2dcdb519b` |
| `src/main.cpp` | `3ddc6aaa5e6fb03e283910d0176c8b526dabab42c4c0bb98fce93fef650035cc` |
| `src/hle/input/kpad.cpp` | `b943fc1887ed17d4f0c94f10858cb1986cc0b7f8d88ca420a8c1de24aee5adaa` |
| `src/dynamic_aspect.cpp` | `6b9928c9c0e2d633f2fa573a8c1624ff9deb1d4cb394d7c994a06bc8dcafadf1` |

The first compile correctly rejected Objective-C++ sources that inherited the runtime's C++ precompiled header. The tracked fix marks only the six mobile `.mm` files `SKIP_PRECOMPILE_HEADERS`; the translated C++ graph retains its existing PCH and release options.

`scripts/build-ios-game-app.sh` configured and rebuilt the existing clean Xcode tree successfully. `scripts/audit-ios-game-app.sh` is the fail-closed full-game bundle auditor. `scripts/run-ios-game-simulator.sh` preserves the one-Simulator and no-concurrent-macOS-game invariants and signs only a temporary install copy.

## Built artifact

App: `build/g14-ios-game-app-xcode/Release-iphonesimulator/KartPad.app`

- Xcode Release build: pass (`** BUILD SUCCEEDED **`)
- Graph: 29,065/29,065 base functions
- Mach-O: arm64, `IOSSIMULATOR`, minimum iOS 16.0, SDK 26.5
- Identity: `dev.kartpad.app`, version `0.1.0` (1), iPhone and iPad families
- Lifecycle: `SDLUIKitSceneDelegate`
- Resources: compiled `Assets.car`, iPhone/iPad icon PNGs, privacy manifest, DSP coefficients, pipeline cache, bootstrap
- Dynamic dependencies: Apple system libraries/frameworks only
- Required symbols: SDL run wrapper and UIKit scene delegate, KartPad host/read APIs, SunPad overlay and mixer
- Forbidden content: no WBFS, ISO, RVZ, WIA, GCZ, `rksys.dat`, or provisioning profile
- Full-game bundle audit: pass

| Artifact | SHA-256 |
|---|---|
| `KartPad` executable | `e31a0d0a8f5583b497141c93aeb63aa40b5ab2e0c2b6f79b3e27cb47322497b7` |
| `Assets.car` | `18de0779809a419002a50074b1d9e45e83aa89dfaa4e4355e8ed26c45c7fb346` |
| `PrivacyInfo.xcprivacy` | `343dbc92a22d95a896d5bb894f439d655ac8e15d0fcc7fe72500bd5fcaba1740` |

## Classification

Pass for full retail runtime-to-native-app compile, link, resources, lifecycle ownership, exact-overlay embedding, touch-to-Classic/core ABI wiring, settings/aspect bridging, and package audit. The iPhone retail-launch follow-up is recorded in `g14-full-game-simulator/README.md`; G14 remains open for complete race/save/relaunch and the sequential iPad pass.

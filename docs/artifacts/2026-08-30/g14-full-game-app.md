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

The integration is serialized in `patches/wiicompiled-ios-app-integration.patch`, applied after `patches/wiicompiled-apple-runtime.patch`. A fresh copy of `ref/upstream/Wiicompiled/runtime` accepted both patches, and these integrated files matched the compiled source byte-for-byte:

| File | SHA-256 |
|---|---|
| `cmake/PublicProducts.cmake` | `3ddb3a165b382d825c4005e9df028f0374038124345419586d8fa5a2dcdb519b` |
| `src/main.cpp` | `c5515140a8494188dd3c2b3e2f57a007c41be27c11f64ba87bad85a3c65f698f` |
| `src/hle/input/kpad.cpp` | `6d87a22e83e99d18278ffb2694c9b1344a553fc3bfb0e019b363bf7ee0af6c92` |

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
| `KartPad` executable | `9a5d69076299324e7f33ae10366a97cdccc512dc4af87c0d77fcdb4af35d4ca0` |
| `Assets.car` | `18de0779809a419002a50074b1d9e45e83aa89dfaa4e4355e8ed26c45c7fb346` |
| `PrivacyInfo.xcprivacy` | `343dbc92a22d95a896d5bb894f439d655ac8e15d0fcc7fe72500bd5fcaba1740` |

## Classification

Pass for full retail runtime-to-native-app compile, link, resources, lifecycle ownership, exact-overlay embedding, touch-to-Classic ABI wiring, and package audit. G14 remains open. The next gate is a single iPhone Simulator launch, runtime-log diagnosis, title/menu/Metal/audio/touch playtest, save/relaunch, and a complete race; the iPhone must be terminated and shut down before repeating on iPad.

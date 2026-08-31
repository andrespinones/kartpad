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

No Simulator or game instance ran during this work. This is evidence for full
physical-iOS source compilation, linking, bundle construction, and package
audit. It does not establish signing, installation, launch, Metal execution,
performance, thermals, audio, touch feel, or lifecycle behavior on hardware.

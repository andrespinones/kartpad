# G14/G15 iPhone and iPad Simulator shell checkpoint

Date: 2026-08-30

## Classification

Pass for the native shell-level portions exercised here on both Simulator
classes: app launch, linked mobile-core self-check, exact SunPad touch overlay,
persistent three-dot menu, settings/layout-editor reachability, landscape scene
policy, and background/foreground return. This is not a G14 or G15 completion
claim. The full 29,637-function retail graph, title/menu/race, Metal gameplay,
audio, save/relaunch, real game-data import, controller handoff, gyro, and touch
feel remain open on mobile.

## Candidate

- Host: Apple Silicon macOS, Xcode 26.6, iOS 26.5 Simulator runtime.
- iPhone class: iPhone 17 Pro.
- iPad class: iPad Pro 13-inch (M5).
- Deployment floor: iOS/iPadOS 16.0.
- Simulator executable SHA-256:
  `91a202f0ee62212b3c23d1616bda9a9595a6c498ca9ff4aa21de10b8723d11cd`.
- Unsigned physical-device executable SHA-256:
  `c380a319a972971b74e0b2684824e7dde520788804bf8e1a1e712ecc556a632b`.
- Exact SunPad source pin:
  `e43f0ea6b797e5110787171957c9dc3c6213269c`.

The nine copied SunPad source/license files remain byte-identical to that pin.
KartPad's separate Classic-controller adapter contract passes without modifying
the copied component.

## Procedure and observed result

1. Regenerated the Xcode project after adding the modern scene manifest. This
   removed a stale configure-time `Info.plist` copy that had silently omitted
   `UIApplicationSceneManifest` from the built app.
2. Built and audited the arm64 Simulator app. The linked startup bridge displayed
   `KartPad mobile core checks passed`, proving checked memory, scheduler, host
   clock, and translated-fixture checks executed successfully in each class.
3. Booted only the iPad, installed and cold-launched KartPad, inspected the exact
   overlay, opened every visible three-dot menu section, opened touch settings
   and layout editing, exercised a game-data delegate, backgrounded/foregrounded
   the app, terminated it, and shut the iPad down.
4. Booted only the iPhone after the iPad was fully shut down. Repeated launch,
   overlay/menu inspection, scrolled the compact menu to expose controller
   mapping, touch settings, game data, and report actions, then backgrounded and
   foregrounded from the KartPad icon. The core status and overlay returned.
5. Terminated KartPad and shut the iPhone down. `simctl list devices booted`
   was empty before the regression run.
6. Regenerated and built the same source graph for the unsigned `iphoneos`
   target. Its app audit and embedded scene manifest pass; signing/installing on
   physical hardware are not claimed.

The game-data action currently reaches a KartPad integration alert only. That
proves menu/delegate wiring, not import behavior.

## Rotation result

The root view now takes its size from its `UIWindowScene`, not
`UIScreen.mainScreen.bounds`, and the app requests a landscape scene through
`UIWindowSceneGeometryPreferencesIOS`. Both classes render correctly when the
simulated hardware is landscape and follow scene lifecycle transitions. The
iPhone was rotated through both landscape sides; both remained upright. A
rejected intermediate implementation permanently locked the first orientation
and made the opposite side upside down, so that lock is not in the candidate.

On iPadOS 26, Apple intentionally decouples the scene orientation from the
physical chassis and no longer guarantees the deprecated
`UIRequiresFullScreen` compatibility behavior. A landscape-only scene launched
while the simulated iPad hardware is portrait is therefore letterboxed until
the hardware rotates; after rotation it fills the display with the exact iPad
layout. This is platform behavior, not accepted as proof of a touch-driven race.

## Regression evidence

- Simulator package auditor: 50 consecutive passes.
- Physical-device package auditor: 50 consecutive passes.
- Exact SunPad snapshot verifier: pass at the pinned commit.
- `kartpad.mobile.classic-input`: pass.
- Repository safety audit: pass.
- No booted Simulator and no KartPad process after the run.

The auditor itself was corrected before acceptance. Its former
`producer | rg -q` checks could report intermittent failure under
`set -o pipefail` when the producer received `SIGPIPE`. It now captures
`find`, `strings`, and `nm` output before testing it. The 50-pass loops prove
the corrected oracle is stable for these artifacts.

## Screenshots

- `iphone-shell.png` — 2622x1206, SHA-256
  `91006fe8da84d31fcceb2f8455efa24fbe1b6603dbd29210bcc50824da5702e2`.
- `iphone-three-dot-menu.png` — 2622x1206, SHA-256
  `ae6fc03522a8fa6a4d90f179d871256e41a3e0d68c401d382a9b6e2989d0ac2a`.
- `ipad-shell.png` — 2752x2064, SHA-256
  `c7fb915c7f942f3fd159512022ff41713649f1ed6713d4f326a707ed9638df9c`.
- `ipad-three-dot-menu.png` — 2752x2064, SHA-256
  `bdff3d458a52b790a811749fde603a7402700b686148deb38a03aef7d759cedc`.

The PNGs contain only KartPad's black integration surface, original shell text,
and the copied SunPad UI. No Nintendo imagery or private game data is present.

## Next gate

Link the full retail translated graph and mobile host services, replace the
placeholder data actions with the real private import/storage flow, then repeat
the one-Simulator-at-a-time procedure through title, audible gameplay, a
complete touch-driven race, save/relaunch, lifecycle/surface recreation, and
controller handoff on both classes.

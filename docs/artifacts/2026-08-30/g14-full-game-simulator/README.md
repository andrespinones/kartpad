# G14 full retail iPhone Simulator checkpoint

Date: 2026-08-30

## Scope and result

The exact 29,065-function retail UIKit app now launches on the sole booted iPhone 17 Pro / iOS 26.5 Simulator, loads the staged extracted Mario Kart Wii data, renders through Metal, reaches the title and retail menus, accepts touch input, enters the retail two-player controller-registration flow, and reaches a live 50cc Luigi Circuit race.

This checkpoint does not claim a completed mobile race, sustained touch acceleration/steering feel, save acceptance, iPad retail execution, physical-device behavior, or subjective audio quality. Those gates remain open.

## Exact candidate

- App: `build/g14-ios-game-app-xcode/Release-iphonesimulator/KartPad.app`
- Executable SHA-256: `e31a0d0a8f5583b497141c93aeb63aa40b5ab2e0c2b6f79b3e27cb47322497b7`
- `Assets.car` SHA-256: `18de0779809a419002a50074b1d9e45e83aa89dfaa4e4355e8ed26c45c7fb346`
- Privacy manifest SHA-256: `343dbc92a22d95a896d5bb894f439d655ac8e15d0fcc7fe72500bd5fcaba1740`
- Simulator: iPhone 17 Pro, iOS 26.5, UDID `7E8E357A-30DD-4EB3-B8C7-83BB555E67B7`
- One-Simulator invariant: pass; every other Simulator remained shut down.
- Full-game bundle audit: pass before install.
- Exact pinned nine-file SunPad snapshot verifier: pass.

## Storage migration

Installing a rebuilt app migrates the Simulator data container to a new UUID. The initial absolute `dvd_root` therefore became stale even though the 2.5 GiB extracted game data migrated correctly. The tested configuration now uses `dvd_root = "GameData"`, resolved relative to KartPad's Application Support directory. A reinstall changed the container UUID while preserving both the relative path and the staged `sys/main.dol` SHA-256 `80d18895b39c63bd80f457398bfcbb91b7d16ac116a41a88967e954080155b05`; the title booted again.

## Edge-artifact diagnosis and aspect policy

The reported striped/checker pixels were reproduced only when the experimental fill-screen path stretched the native 2622x1206 surface and exposed Mario Kart Wii's overscan/scratch area. They are not Simulator chrome or a Metal surface failure.

- `Original 4:3`: stable default, fit policy, clean uniform pillarboxes.
- `16:9 (Experimental)`: bounded fit policy, clean output matching the macOS title composition without exposing the scratch area.
- `Fill Screen (Experimental)`: remains explicitly experimental because it exposes invalid edge content in the current title build.

The exact SunPad aspect, render-scale, and FPS preferences are now read before Aurora creates its surface. The generated retail runtime applies the corresponding 4:3, bounded 16:9, or dynamic-fill policy. The stable default was restored after the A/B test.

Visual QA used combined same-state inputs, not isolated screenshots:

- `title-mac-vs-iphone-16x9.png`: macOS reference and bounded iPhone 16:9 title at the same 663x372 viewport.
- `title-oracle-vs-iphone-4x3.png`: Dolphin and iPhone 4:3 title at the same 496x372 viewport; retained as a diagnostic comparison, not an exact-match claim.

## Touch and Multiplayer results

The original mobile adapter emitted Classic buttons, but retail menu paths also consumed core Wii button fields. A reproducible patch now mirrors Classic A/B/Plus/Minus/D-pad into the corresponding core bits in both KPAD paths while keeping the Classic extension active. Runtime sampling previously proved A as core `00000800` plus Classic `00000010`, and D-pad Right as core `00000002` plus Classic `00008000`.

Observed end-to-end behavior on this candidate:

- A advances the retail title screen.
- D-pad Left/Right navigates the retail main menu.
- A opens Single Player and each Grand Prix selection screen.
- A plus D-pad navigation opens Multiplayer → 2 Players → Register Controllers.
- The full flow reaches 50cc Mushroom Cup → Luigi Circuit and live race state.
- Background/Home and foreground resume preserve the running game and clear touch state.

The pinned SunPad files remain byte-identical. A KartPad-owned subclass adds a top-level `Multiplayer…` action around the unchanged source menu. The action opens a native setup sheet explaining Player 1 touch and routes to the existing controller-mapping UI. The native entry and the retail two-player controller-registration screen were both exercised.

## Evidence files

- `iphone-stable-original-4x3.jpeg`
- `iphone-bounded-16x9.jpeg`
- `iphone-kartpad-menu.jpeg`
- `iphone-multiplayer-menu.jpeg`
- `iphone-multiplayer-pair-screen.jpeg`
- `iphone-live-race-touch.jpeg`
- `title-mac-vs-iphone-16x9.png`
- `title-oracle-vs-iphone-4x3.png`

## Classification

Pass for iPhone retail boot, Metal presentation, container migration, stable aspect default, bounded 16:9 option, title/menu touch navigation, Multiplayer access, controller-registration entry, live-race entry, and background/foreground recovery. G14/G15 remain open pending a complete touch-driven iPhone race/save/relaunch, sequential iPad retail pass after shutting down iPhone, controller handoff, and hands-on touch/audio acceptance.

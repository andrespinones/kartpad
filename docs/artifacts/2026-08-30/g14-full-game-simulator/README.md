# G14 full retail iPhone and iPad Simulator checkpoint

Date: 2026-08-30

## Scope and result

The exact 29,065-function retail UIKit app now launches sequentially on iPhone 17 Pro and iPad Pro 13-inch (M5) / iOS 26.5 Simulators, loads the staged extracted Mario Kart Wii data, renders through Metal, reaches the title and retail menus, accepts touch input, and reaches live 50cc Luigi Circuit on both device classes. The iPhone also enters the retail two-player controller-registration flow.

This checkpoint does not claim a completed mobile race, sustained touch acceleration/steering feel, physical-device behavior, or subjective audio quality. Those gates remain open.

## Exact candidate

- App: `build/g14-ios-game-app-xcode/Release-iphonesimulator/KartPad.app`
- Executable SHA-256: `e31a0d0a8f5583b497141c93aeb63aa40b5ab2e0c2b6f79b3e27cb47322497b7`
- `Assets.car` SHA-256: `18de0779809a419002a50074b1d9e45e83aa89dfaa4e4355e8ed26c45c7fb346`
- Privacy manifest SHA-256: `343dbc92a22d95a896d5bb894f439d655ac8e15d0fcc7fe72500bd5fcaba1740`
- Simulator: iPhone 17 Pro, iOS 26.5, UDID `7E8E357A-30DD-4EB3-B8C7-83BB555E67B7`
- Simulator: iPad Pro 13-inch (M5), iOS 26.5, UDID `D80E9862-C29A-4D69-B8E5-D81D396C17D5`
- One-Simulator invariant: pass; the iPhone was terminated and shut down before booting the iPad, and the iPad was shut down after its pass.
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
- Reinstall migrated the iPhone container again while preserving relative `GameData`, the staged title, and the existing `Player` save. The iPhone `rksys.dat` SHA-256 `87473fa67e0ec2345d471584979217f6dbd7316ed47db054ce565269ef316d58` remained byte-identical across terminate/relaunch, and touch returned through the preserved license to Single Player.

The pinned SunPad files remain byte-identical. A KartPad-owned subclass adds a top-level `Multiplayer…` action around the unchanged source menu. The action opens a native setup sheet explaining Player 1 touch and routes to the existing controller-mapping UI. The native entry and the retail two-player controller-registration screen were both exercised.

## iPad results

- The guarded runner booted the iPad only after the iPhone was shut down.
- Landscape rotation fills the iPad display cleanly in the native 4:3 mode; the portrait-hardware state correctly presents the landscape scene letterboxed until rotation.
- The exact touch overlay scales cleanly and the complete SunPad menu is visible without compact-menu scrolling.
- The KartPad-owned `Multiplayer…` entry appears above the unchanged SunPad menu children.
- Touch created a new local `Player` license, reached Main Menu, selected the default 50cc Grand Prix flow, and reached live Luigi Circuit.
- The new `rksys.dat` had SHA-256 `5291cecd0ae1749a7996dfd8f3bc53978a9af08fe9aaf639a831214d6bb24f42` before and after terminate/relaunch, and the `Player` license remained selectable.
- Home/background and foreground resume returned to the active game/menu state.

## Evidence files

- `iphone-stable-original-4x3.jpeg`
- `iphone-bounded-16x9.jpeg`
- `iphone-kartpad-menu.jpeg`
- `iphone-multiplayer-menu.jpeg`
- `iphone-multiplayer-pair-screen.jpeg`
- `iphone-live-race-touch.jpeg`
- `iphone-save-relaunch-main-menu.jpeg`
- `title-mac-vs-iphone-16x9.png`
- `title-oracle-vs-iphone-4x3.png`
- `ipad-stable-original-4x3.jpeg`
- `ipad-main-menu-touch.jpeg`
- `ipad-kartpad-menu.jpeg`
- `ipad-live-race-touch.jpeg`

## Classification

Pass for sequential iPhone/iPad retail boot, Metal presentation, container migration, stable aspect default, bounded iPhone 16:9 option, title/menu touch navigation, Multiplayer access, controller-registration entry, live-race entry on both device classes, save/relaunch preservation on both device classes, and background/foreground recovery. G14/G15 remain open pending complete touch-driven races, controller handoff, and hands-on touch/audio acceptance.

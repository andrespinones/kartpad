# G9 macOS race, save, and staff-ghost evidence

Date: 2026-08-28  
Runtime: native Apple arm64 WiiCompiled graph, Aurora/Dawn Metal  
Disc fixture: private user-owned PAL `RMCP01` (not retained here)

## Result

- Created the isolated `Player` license and backed up its 17-file portable NAND before and after creation.
- Completed a 100cc Luigi Circuit VS session through standings, the `Next Race / Quit` result menu, and Main Menu. The GUI-driven player timed out in 12th with 0 points; this limitation is retained rather than presented as a winning/three-lap player run.
- Exercised the exact 2008 Classic Controller path: A/accelerate, scaled analog steering, D-pad menu navigation, and B/reverse all produced guest-visible behavior.
- The 2,867,200-byte `rksys.dat` changed from post-license SHA-256 `5291cecd0ae1749a7996dfd8f3bc53978a9af08fe9aaf639a831214d6bb24f42` to post-race SHA-256 `1e7b6a9482d01436bf5fb650528191f8b725d1a74c178bad30ccae2d10cdc529`.
- After clean quit and relaunch, `Player` remained available and `rksys.dat` retained the same post-race SHA-256.
- Reopened the original Luigi Circuit staff ghost `Nin★sato` (`01:29.670`) and ran its replay at 60 FPS.
- No Simulator was booted; exactly one game instance was used.

## Captures

- `relaunch-boot.jpeg` — signed portable app begins a fresh native boot.
- `relaunch-title.jpeg` — fresh title/attract prompt after quit.
- `relaunch-main-saved-player.jpeg` — persisted `Player` license on Main Menu; Classic `B` glyph also proves controller detection.
- `staff-ghost-selection.jpeg` — original `Nin★sato 01:29.670` fixture.
- `staff-ghost-replay.jpeg` — fixture actively replaying Luigi Circuit at 60 FPS.

## Capture hashes

```text
81a7136c64434d1c9e5ffd9209eb07cf0a4a95d8e72c3b313000616bb51eb7b8  relaunch-boot.jpeg
6bd94c4ca8a10a6a2cf6198a87b48f1aacc711845ed04f24057144e24b22b5c8  relaunch-main-saved-player.jpeg
dbe0c4a20ea7632d1978e96ed31da8da8cd131c38287ff31839d9d84bc37fc89  relaunch-title.jpeg
a54af7a885fa45f2548278cc07006603e6e91b37fc9087ba6f4d6db4870eea24  staff-ghost-replay.jpeg
0b37ec5857c4c3e4a9296e0eb089ca1ced4d3f8f5feb404d162b33b9c14b1167  staff-ghost-selection.jpeg
```

# KartPad status

Updated: 2026-08-28

## Current goal

**G2 — Baseline oracle captured** is the lowest unmet goal. G0 and G1 pass. The pinned no-game-data translator suite passes, while the Dolphin gameplay oracle remains to be captured.

## Goal ledger

| Goal | Status | Evidence / next gate |
|---|---|---|
| G0 Workspace/evidence | Pass | Safety audit passed; checkpoint `2f3bf40` pushed |
| G1 Inputs/pins | Pass | Full source/disc verifier passed; locked checkpoint pending push |
| G2 Baseline oracle | In progress | Translator tests 570/570 pass; Dolphin boot/race/save/ghost oracle remains |
| G3–G18 | Not started | Blocked by the preceding evidence gates |

## Known-good state

- Repository source: `7875e82` (`origin/main`), documentation only.
- Simulator state: none booted at the 2026-08-28 session start.
- Buildable KartPad targets: none yet.
- Input profile: WBFS containing clean PAL `RMCP01`, revision 0; original is read-only.
- WiiCompiled baseline: required commit/tree verified in a detached, push-disabled partial clone.
- Translator baseline: 570 passed, 0 failed, 0 skipped on native arm64 with .NET SDK 8.0.130.
- Original icon: editable default/dark/tinted SVG masters and opaque exports exist; 1024 px and 16 px visual QA passed. Asset-catalog validation awaits application targets.

## Active risks and blockers

- Only about 21 GiB of host storage was free at session start. WiiCompiled's source/dependency graph and translated/build products may exceed that; capacity must be managed before large builds.
- No human-only prerequisite currently blocks G0 or the independent parts of G1.
- Physical-device, public-service, account, and hands-on acceptance rows remain future external prerequisites and are not claimed.
- WiiCompiled's bundled `MAP.txt` may be used as an ignored local reference, but independent provenance for republishing it is not established; do not copy it into public KartPad sources/artifacts.

## UI reference commitment

The local `ref/sunpad` checkout is the direct implementation reference for the future mobile touch interface and persistent three-dot menu. KartPad will copy those components exactly at G15, adapting only the game-specific input mapping required by Mario Kart Wii. Mobile implementation cannot be accepted before the PRD's macOS correctness prerequisites pass.

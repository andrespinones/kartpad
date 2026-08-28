# KartPad status

Updated: 2026-08-28

## Current goal

**G0 — Workspace and evidence system ready** is ready for its checkpoint gate. The PRD and goal loop have been read completely, the initial repository/host inventory is recorded, no Simulator is booted, and the safety/evidence system exists.

## Goal ledger

| Goal | Status | Evidence / next gate |
|---|---|---|
| G0 Workspace/evidence | In progress | Repository safety check and pushed checkpoint remain |
| G1 Inputs/pins | In progress | Disc and WiiCompiled pin verified; remaining required references/licenses must be pinned |
| G2–G18 | Not started | Blocked by the preceding evidence gates |

## Known-good state

- Repository source: `7875e82` (`origin/main`), documentation only.
- Simulator state: none booted at the 2026-08-28 session start.
- Buildable KartPad targets: none yet.
- Input profile: WBFS containing clean PAL `RMCP01`, revision 0; original is read-only.
- WiiCompiled baseline: required commit/tree verified in a detached, push-disabled partial clone.

## Active risks and blockers

- Only about 21 GiB of host storage was free at session start. WiiCompiled's source/dependency graph and translated/build products may exceed that; capacity must be managed before large builds.
- No human-only prerequisite currently blocks G0 or the independent parts of G1.
- Physical-device, public-service, account, and hands-on acceptance rows remain future external prerequisites and are not claimed.

## UI reference commitment

The local `ref/sunpad` checkout is the direct implementation reference for the future mobile touch interface and persistent three-dot menu. KartPad will copy those components exactly at G15, adapting only the game-specific input mapping required by Mario Kart Wii. Mobile implementation cannot be accepted before the PRD's macOS correctness prerequisites pass.

# KartPad status

Updated: 2026-08-28

## Current goal

**G6 — PPC/AArch64 semantics are exact** is the lowest unmet goal. G0–G5 pass. A first portable differential subset and translated scalar microfixture are green, but the complete translator-emitted helper surface is not yet ported or proven.

## Goal ledger

| Goal | Status | Evidence / next gate |
|---|---|---|
| G0 Workspace/evidence | Pass | Safety audit passed; checkpoint `2f3bf40` pushed |
| G1 Inputs/pins | Pass | Full source/disc verifier passed; checkpoint `94f6e79` is on GitHub |
| G2 Baseline oracle | Pass | Translator 570/570; isolated Dolphin boot/license/menu/race/staff-ghost oracle in `docs/artifacts/2026-08-28/dolphin-oracle/` |
| G3 Host portability | Pass | Native arm64 host library/contracts pass; Darwin graph contains no Win32/x86-only link token; manifest recorded |
| G4 Guest memory | Pass | Checked Darwin path passes conformance, lifecycle, randomized stress, microprogram, ASan/UBSan; safe Mach VM feasibility probe passes |
| G5 Guest scheduler | Pass | Explicit state machine passes lifecycle/priority/VI/register tests and two deterministic million-operation runs under Release and ASan/UBSan |
| G6 PPC/AArch64 semantics | In progress | 250,155-check arm64/x86 differential hashes match; Dolphin estimates, sanitizers, translator 570/570, and translated scalar/paired/GQR/FPSCR fixture pass; remaining stateful helper surface is open |
| G7–G18 | Gated | Provisional direct-Metal translated command frame exists, but it is not Dawn/Aurora, GX, or a game frame |

## Known-good state

- Repository checkpoint: `3fc612b` (`origin/main`), native subsystem smoke baseline.
- Simulator state: the user's existing Simulator application is running; KartPad has not booted an additional simulator or app instance.
- Buildable KartPad targets: host, memory, scheduler, semantic contracts, native subsystem smoke, translated semantic fixture, and provisional translated-frame app.
- Input profile: WBFS containing clean PAL `RMCP01`, revision 0; original is read-only.
- WiiCompiled baseline: required commit/tree verified in a detached, push-disabled partial clone.
- Translator baseline: 570 passed, 0 failed, 0 skipped on native arm64 with .NET SDK 8.0.130.
- Gameplay baseline: hashed Dolphin 5.0-17995 arm64/Vulkan/HLE binary boots `RMCP01`, creates an isolated license/save, reaches Luigi Circuit and its official staff ghost, and recovers to 60 FPS/VPS after shader warmup.
- Portability baseline: `kartpad_host` and its contract suite compile/link/run natively for arm64 macOS; manifest is under `docs/artifacts/2026-08-28/`.
- Memory baseline: checked/table guest memory is the accepted correctness path; evidence is `docs/artifacts/2026-08-28/g4-guest-memory.md`.
- Scheduler baseline: explicit cooperative state machine, deterministic hash `0x7287563387fb1677`; evidence is `docs/artifacts/2026-08-28/g5-guest-scheduler.md`.
- Native subsystem preparation: validated Metal/CoreAudio/GameController/storage/network smoke; useful for later gates but not a substitute for G6 semantics.
- Semantic subset: arm64/x86_64 state hash `0xb332d343c4e3dc81`; evidence is `docs/artifacts/2026-08-28/g6-ppc-semantics.md` and `docs/SEMANTICS.md`.
- Original icon: editable default/dark/tinted SVG masters and opaque exports exist; 1024 px and 16 px visual QA passed. Asset-catalog validation awaits application targets.

## Active risks and blockers

- Only about 18 GiB of host storage remains. WiiCompiled's source/dependency graph and translated/build products may exceed that; capacity must be managed before large builds.
- No human-only prerequisite currently blocks G0 or the independent parts of G1.
- Physical-device, public-service, account, and hands-on acceptance rows remain future external prerequisites and are not claimed.
- WiiCompiled's bundled `MAP.txt` may be used as an ignored local reference, but independent provenance for republishing it is not established; do not copy it into public KartPad sources/artifacts.
- Dolphin pipe input is accepted for deterministic menus. Live race acceleration/brake semantics remain deliberately unclaimed until a narrow controller fixture distinguishes the observed behavior.
- G2 audio evidence is limited to emulator execution; subjective audio quality is a future hands-on row and is not claimed.
- Upstream PPC helpers are x86/SSE/MXCSR-shaped. KartPad's portable layer currently proves only the inventoried subset, so G6 remains open.

## UI reference commitment

The local `ref/sunpad` checkout is the direct implementation reference for the future mobile touch interface and persistent three-dot menu. KartPad will copy those components exactly at G15, adapting only the game-specific input mapping required by Mario Kart Wii. Mobile implementation cannot be accepted before the PRD's macOS correctness prerequisites pass.

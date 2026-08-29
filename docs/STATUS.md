# KartPad status

Updated: 2026-08-28

## Current goal

**G8 — macOS boots and accepts input** is the lowest unmet goal. G0–G7 pass. The native arm64 runtime renders Mario Kart Wii's real wrist-strap frame at 60 FPS through Aurora, pinned Dawn, and Metal; menu input and audible audio remain to be proven.

## Goal ledger

| Goal | Status | Evidence / next gate |
|---|---|---|
| G0 Workspace/evidence | Pass | Safety audit passed; checkpoint `2f3bf40` pushed |
| G1 Inputs/pins | Pass | Full source/disc verifier passed; checkpoint `94f6e79` is on GitHub |
| G2 Baseline oracle | Pass | Translator 570/570; isolated Dolphin boot/license/menu/race/staff-ghost oracle in `docs/artifacts/2026-08-28/dolphin-oracle/` |
| G3 Host portability | Pass | Native arm64 host library/contracts pass; Darwin graph contains no Win32/x86-only link token; manifest recorded |
| G4 Guest memory | Pass | Checked Darwin path passes conformance, lifecycle, randomized stress, microprogram, ASan/UBSan; safe Mach VM feasibility probe passes |
| G5 Guest scheduler | Pass | Explicit state machine passes lifecycle/priority/VI/register tests and two deterministic million-operation runs under Release and ASan/UBSan |
| G6 PPC/AArch64 semantics | Pass | 250,227-check arm64/x86 hashes match; Dolphin oracle, sanitizers, translator 579/579, translated scalar/paired state, scheduler/callback persistence, and all 10,836 title units pass |
| G7 Native Metal frame | Pass | Real PAL wrist-strap frame visible at 60 FPS; reproducible Apple runtime patch and capture evidence recorded |
| G8 macOS boots/input | In progress | Advance through intro/title/menu; verify audible audio and keyboard/controller navigation |
| G9–G18 | Gated | Await G8 |

## Known-good state

- Repository checkpoint: pending this G7 game-frame commit; prior checkpoint `ce2fbb5` is on `origin/main`.
- Simulator state: no Simulator device is booted. KartPad will boot exactly one when a mobile gate requires it.
- Buildable KartPad targets: host, memory, scheduler, semantic contracts, native subsystem smoke, translated semantic fixture, and provisional translated-frame app.
- Input profile: WBFS containing clean PAL `RMCP01`, revision 0; original is read-only.
- WiiCompiled baseline: required commit/tree verified in a detached, push-disabled partial clone.
- Translator baseline: immutable upstream remains 570/570; KartPad's reproducible FPSCR lowering patch passes 579/579 on native arm64 with .NET SDK 8.0.130.
- Gameplay baseline: hashed Dolphin 5.0-17995 arm64/Vulkan/HLE binary boots `RMCP01`, creates an isolated license/save, reaches Luigi Circuit and its official staff ghost, and recovers to 60 FPS/VPS after shader warmup.
- Portability baseline: `kartpad_host` and its contract suite compile/link/run natively for arm64 macOS; manifest is under `docs/artifacts/2026-08-28/`.
- Memory baseline: checked/table guest memory is the accepted correctness path; evidence is `docs/artifacts/2026-08-28/g4-guest-memory.md`.
- Scheduler baseline: explicit cooperative state machine, deterministic hash `0x7287563387fb1677`, plus translated CPU-context/NI/FPSCR persistence across yields and host callbacks; evidence is `docs/artifacts/2026-08-28/g5-guest-scheduler.md`.
- Native subsystem preparation: validated Metal/CoreAudio/GameController/storage/network smoke; useful for G7 and later gates.
- Semantic subset: arm64/x86_64 complete 250,227 checks with state hash `0xccd5757c4c0643d4`; the translated fixture additionally proves VE-enabled paired invalid arithmetic still writes both lanes while aggregating causes. Evidence is `docs/artifacts/2026-08-28/g6-ppc-semantics.md` and `docs/SEMANTICS.md`.
- Real DOL surface: user-owned `main.dol` matches the pinned PAL hash, translates into 10,836 functions with unsupported instructions disabled, and every emitted unit compiles against the portable shim.
- Original icon: editable default/dark/tinted SVG masters and opaque exports exist; 1024 px and 16 px visual QA passed. Asset-catalog validation awaits application targets.

## Active risks and blockers

- About 14 GiB of host storage remains after private disc extraction and the full translated runtime build. Large generated products remain ignored; capacity must be checked before additional build graphs.
- No human-only prerequisite currently blocks G0 or the independent parts of G1.
- Physical-device, public-service, account, and hands-on acceptance rows remain future external prerequisites and are not claimed.
- WiiCompiled's bundled `MAP.txt` may be used as an ignored local reference, but independent provenance for republishing it is not established; do not copy it into public KartPad sources/artifacts.
- Dolphin pipe input is accepted for deterministic menus. Live race acceleration/brake semantics remain deliberately unclaimed until a narrow controller fixture distinguishes the observed behavior.
- G2 audio evidence is limited to emulator execution; subjective audio quality is a future hands-on row and is not claimed.
- The complete PAL game translation now reaches a real Mario Kart Wii frame through GX/Aurora/Dawn/Metal. G8 still requires advancing through the intro/title/menu with working input and audible audio.

## UI reference commitment

The local `ref/sunpad` checkout is the direct implementation reference for the future mobile touch interface and persistent three-dot menu. KartPad will copy those components exactly at G15, adapting only the game-specific input mapping required by Mario Kart Wii. Mobile implementation cannot be accepted before the PRD's macOS correctness prerequisites pass.

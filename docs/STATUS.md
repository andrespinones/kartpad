# KartPad status

Updated: 2026-08-29

## Current goal

**G10 — macOS offline compatibility complete** is the lowest unmet goal. G0–G9 pass. Staff-ghost determinism is bit-exact on N64 Mario Raceway. Both Battle rows pass: every retail arena boots in Balloon Battle and Coin Runners, with representative Block Plaza matches completing through results and Main Menu.

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
| G8 macOS boots/input | Pass | Full DOL+StaticR intro/title/menu, audible output, A/directional/1 navigation; evidence under `docs/artifacts/2026-08-28/g8-title-menu/` |
| G9 first race/save | Pass | 100cc VS standings/result/menu cycle, changed save hash, clean quit/relaunch with `Player` intact, and `Nin★sato 01:29.670` replay; evidence under `docs/artifacts/2026-08-28/g9-race-save/` |
| G10 macOS offline compatibility | In progress | N64 Mario ghost passes 137,360/137,360 state words; Battle rows 27–28 pass; forced-exit save safety passes at Main Menu. Continue tracks/cups/modes/local multiplayer/controller/audio/save rows |
| G11–G18 | Gated | Await G10 |

## Known-good state

- Repository checkpoint: all-arena Coin Runners checkpoint `1379a9f` is on `origin/main`; forced-exit save-safety evidence is the next backup.
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
- Full title surface: user-owned PAL DOL and StaticR translate into 29,637 functions; the native runtime executes both constructor graphs through the title and license menu.
- Original icon: editable default/dark/tinted SVG masters and opaque exports exist; 1024 px and 16 px visual QA passed. Asset-catalog validation awaits application targets.

## Active risks and blockers

- About 20 GiB of host storage remains after private disc extraction and the full translated runtime build. Large generated products remain ignored; capacity must be checked before additional build graphs.
- No human-only prerequisite currently blocks G0 or the independent parts of G1.
- Physical-device, public-service, account, and hands-on acceptance rows remain future external prerequisites and are not claimed.
- WiiCompiled's bundled `MAP.txt` may be used as an ignored local reference, but independent provenance for republishing it is not established; do not copy it into public KartPad sources/artifacts.
- The exact 2008 Classic ABI is live and the game recognizes it. A/accelerate, analog steering, D-pad, and B/reverse are proven; GUI-driven full-lap precision remains a G10 playtest-quality row.
- The opt-in RKG player fixture matches native stream expansion and the exact 240-frame countdown cadence but later diverges through the live-player path. It remains a diagnostic harness, not evidence for staff-ghost synchronization or a completed track.
- The initial visual interpretation of an N64 Mario staff-ghost overrun was false: the observation crossed into an automatic replay loop. A changed frame-end trace proved identical `240..8319` race segments and zero mismatches across 137,360 watched words. Ghost timing must be accepted from guest state, not wall-clock screenshots.
- Balloon Battle PRD row 27 passes: all ten retail arenas boot, and a complete 6-v-6 Block Plaza match reaches results and Main Menu. Instantaneous capture-time labels ranged from 43.2–60.0 FPS; deterministic cadence measurement remains a G11 gate and is not inferred from screenshots.
- Coin Runners PRD row 28 passes: all ten retail arenas boot, and complete 6-v-6 Block Plaza matches reach per-player results, team outcome, and Main Menu.
- Forced-exit save safety PRD row 20 passes at the stable Main Menu boundary: pre-exit, post-`SIGKILL`, and post-relaunch saves are byte-identical, and the existing `Player` license remains selectable.
- G2 audio evidence is limited to emulator execution; subjective audio quality is a future hands-on row and is not claimed.
- G8 playback is proven by both the runtime's non-silent host-stream telemetry and an independent system-output loopback level capture. Subjective audio quality and latency remain hands-on G10/G11 rows.

## UI reference commitment

The local `ref/sunpad` checkout is the direct implementation reference for the future mobile touch interface and persistent three-dot menu. KartPad will copy those components exactly at G15, adapting only the game-specific input mapping required by Mario Kart Wii. Mobile implementation cannot be accepted before the PRD's macOS correctness prerequisites pass.

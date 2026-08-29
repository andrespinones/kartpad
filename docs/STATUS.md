# KartPad status

Updated: 2026-08-29

## Current goal

**G10 — macOS offline compatibility complete** is the lowest unmet goal. G0–G9 pass. Staff-ghost determinism is bit-exact on N64 Mario Raceway. Both Battle rows pass, and the normal two-player split-screen race now completes through finish and standings from live keyboard input.

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
| G10 macOS offline compatibility | In progress | Ghost sync, save safety, vehicles/drift, items/AI/collisions, Battle rows 27–28, two-player row 29, four controller slots, and explicit GameCube-adapter limitation pass. Continue tracks/cups/modes, three/four-player races, and audio/save rows |
| G11–G18 | Gated | Await G10 |

## Known-good state

- Repository checkpoint: repeated-race camera lifecycle repair `923a846` is on `origin/main`; the accepted two-player completion remains `7ffdd27`.
- Simulator state: no Simulator device is booted. KartPad will boot exactly one when a mobile gate requires it.
- Buildable KartPad targets: host, memory, scheduler, semantic contracts, native subsystem smoke, translated semantic fixture, and provisional translated-frame app.
- Input profile: WBFS containing clean PAL `RMCP01`, revision 0; original is read-only. GUI keyboard steering uses the measured 0.08 Classic-stick magnitude with a 50 ms synthetic pulse; acceleration/reverse retain their 500 ms gameplay holds. Physical controllers and future touch input are unaffected.
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
- The exact 2008 Classic ABI is live and the game recognizes it. A/accelerate, analog steering, D-pad, and B/reverse are proven. Three-player gameplay switches to the retail 30 FPS cadence documented by the Dolphin oracle; a complete live-input three-player race remains open.
- A deterministic second-race crash after returning from a three-player race was traced to a reclaimed camera node retained by the global race-camera list. The reproducible generated-source guard removes the stale node with retail intrusive-list semantics; the exact formerly failing sequence now reaches live second-race gameplay without a process relaunch. An uncontended cadence resample and full three-/four-player standings cycles remain open.
- The opt-in RKG player fixture matches native stream expansion and the exact 240-frame countdown cadence but later diverges through the live-player path. It remains a diagnostic harness, not evidence for staff-ghost synchronization or a completed track.
- Two-player split-screen PRD row 29 passes: P1 completed three live-keyboard laps, both panes reached the retail finish transition, and the full standings table retained distinct Mario/P1 and Luigi/P2 rows. The successful log contains zero fixture entries; evidence is under `docs/artifacts/2026-08-29/g10-two-player-race/`. Three/four-player full races remain open.
- The initial visual interpretation of an N64 Mario staff-ghost overrun was false: the observation crossed into an automatic replay loop. A changed frame-end trace proved identical `240..8319` race segments and zero mismatches across 137,360 watched words. Ghost timing must be accepted from guest state, not wall-clock screenshots.
- Balloon Battle PRD row 27 passes: all ten retail arenas boot, and a complete 6-v-6 Block Plaza match reaches results and Main Menu. Instantaneous capture-time labels ranged from 43.2–60.0 FPS; deterministic cadence measurement remains a G11 gate and is not inferred from screenshots.
- Coin Runners PRD row 28 passes: all ten retail arenas boot, and complete 6-v-6 Block Plaza matches reach per-player results, team outcome, and Main Menu.
- Forced-exit save safety PRD row 20 passes at the stable Main Menu boundary: pre-exit, post-`SIGKILL`, and post-relaunch saves are byte-identical, and the existing `Player` license remains selectable.
- Vehicles/characters/drift PRD row 24 passes representative native coverage: Baby Mario light bike Manual completes via the bit-exact staff replay, Mario medium kart Manual completes both Battle modes, and Bowser heavy bike Automatic completes a full Balloon Battle.
- Items/AI/collisions PRD row 25 passes across complete 12-racer VS, Balloon Battle, and Coin Runners fixtures with item effects, collisions, AI, scoring/standings, results, and clean exits.
- GameCube adapter PRD row 32 passes by explicit limitation: the Darwin product deliberately uses a no-device WUP-028 stub and does not advertise raw USB adapter support; ordinary controllers remain mandatory separately.
- Four controller slots PRD row 31 passes: P1–P4 independently register as Classic controllers, channel-specific disconnect raises the correct interruption state, reconnect restores assignment, and pending/previous held input is cleared.
- G2 audio evidence is limited to emulator execution; subjective audio quality is a future hands-on row and is not claimed.
- G8 playback is proven by both the runtime's non-silent host-stream telemetry and an independent system-output loopback level capture. Subjective audio quality and latency remain hands-on G10/G11 rows.
- Audio continuity instrumentation is now bounded and cumulative. Its first uncontended diagnostic sample recorded 104,960 queue checks and 40,304,256 submitted bytes with zero post-start empty observations or drops; the final 8,192-check reporting cadence, gameplay/pause, default-device migration, and long-session rows remain open.

## UI reference commitment

The local `ref/sunpad` checkout is the direct implementation reference for the future mobile touch interface and persistent three-dot menu. KartPad will copy those components exactly at G15, adapting only the game-specific input mapping required by Mario Kart Wii. Mobile implementation cannot be accepted before the PRD's macOS correctness prerequisites pass.

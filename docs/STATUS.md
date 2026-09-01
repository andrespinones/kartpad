# KartPad status

Updated: 2026-09-01

## Current goal

**Local Apple-to-Apple online flow passes.** Native macOS and the exact iPad
Simulator completed login, matchmaking, room formation, Luigi Circuit race
traffic, the retail online finish/results path, rating updates, and return to
the shared lobby. The accepted run exchanged more than 3,500 UDP packets in
each direction per client and consumed the complete 5,001-frame fixture. The
test-only finish trigger is documented in `docs/ONLINE.md`; public-service,
physical-device online, impairment, and external-client rows remain open.

The exact dual-mode Simulator candidate also reaches production Retro WFC NAS
authentication. It then receives `61070` because the public GameSpy
gameplay-login endpoint times out. Retro Rewind's official documentation lists
the service as in testing/maintenance mode, and its status page has no live
room data. Production online acceptance is waiting on Retro WFC recovery; this
external outage does not invalidate the accepted isolated-server flow.

The same source produced a fresh signed KartPad `0.3.0` physical-iOS
candidate. It was installed over the existing app on the attached iPad without
an uninstall, launched successfully, and visibly reached the Original / Retro
Rewind chooser. That is physical build, install, launch, and chooser evidence;
it is not production Retro WFC matchmaking or gameplay evidence. The latter
remains queued behind service recovery.

Two physical-iPad attempts to download the official 6.12.4 full pack then
failed identically after transfer: both device crash reports show `Thread stack
size exceeded` in `KartPadSHA256ForLargeFile`. The verifier had placed a 1 MiB
streaming buffer on a dispatch worker's smaller stack. Current source moves that
buffer to heap storage, makes download and install percentages separate, checks
Retro Rewind's official version feed before launch, and fails closed when a
newer pack requires a new ahead-of-time KartPad build. Physical build 7 is now
installed in place and its full-width dual-mode chooser is visually accepted on
the iPad. A fresh hands-on retest downloaded the official 6.12.4 pack, completed
verification and installation without a crash, launched Retro Rewind, and
reached a playable single-player match. This closes physical pack installation,
Retro Rewind launch, and initial offline-gameplay acceptance. Production Retro
WFC matchmaking and online gameplay remain unaccepted while the service is in
maintenance and reports no room data.

## Goal ledger

| Goal | Status | Evidence / next gate |
|---|---|---|
| G0 Workspace/evidence | Pass | Safety audit passed; checkpoint `2f3bf40` pushed |
| G1 Inputs/pins | Pass | Full source/disc verifier passed; checkpoint `94f6e79` is on GitHub |
| G2 Baseline oracle | Pass | Translator 570/570; isolated Dolphin boot/license/menu/race/staff-ghost oracle in `docs/artifacts/2026-08-28/dolphin-oracle/` |
| G3 Host portability | Pass | Native arm64 host library/contracts pass; Darwin graph contains no Win32/x86-only link token; manifest recorded |
| G4 Guest memory | Pass | Checked Darwin path passes conformance, lifecycle, randomized stress, microprogram, ASan/UBSan; safe Mach VM feasibility probe passes |
| G5 Guest scheduler | Pass | Explicit state machine passes lifecycle/priority/VI/register tests and two deterministic million-operation runs under Release and ASan/UBSan |
| G6 PPC/AArch64 semantics | Pass | 250,227-check arm64/x86 hashes match; Dolphin oracle, sanitizers, translator 582/582, translated scalar/paired state, scheduler/callback persistence, and all 10,836 title units pass |
| G7 Native Metal frame | Pass | Real PAL wrist-strap frame visible at 60 FPS; reproducible Apple runtime patch and capture evidence recorded |
| G8 macOS boots/input | Pass | Full DOL+StaticR intro/title/menu, audible output, A/directional/1 navigation; evidence under `docs/artifacts/2026-08-28/g8-title-menu/` |
| G9 first race/save | Pass | 100cc VS standings/result/menu cycle, changed save hash, clean quit/relaunch with `Player` intact, and `Nin★sato 01:29.670` replay; evidence under `docs/artifacts/2026-08-28/g9-race-save/` |
| G10 macOS offline compatibility | In progress | Row 22 passes all 32/32 retail tracks with every cup subset complete; ghost sync, save safety, vehicles/drift, items/AI/collisions, Time Trial row 26, Battle rows 27–28, two-player row 29, four full-range keyboard/controller slots, explicit GameCube-adapter limitation, privacy-safe obsolete-service fallback, and a two-hour representative audio-continuity run also pass their stated subcases. Continue honest Grand Prix progression, three/four-player standings cycles, and subjective/final audio acceptance |
| G11–G18 | Gated | Await G10 |

## Finish-line order

The project is no longer blocked on proving that the game can run. The shortest
credible path to a release is to close the remaining evidence and product gaps
in dependency order:

1. **Close G10 honestly:** finish representative Grand Prix progression,
   complete three- and four-player race/standings cycles, and perform the
   remaining subjective audio acceptance. Do not spend more time re-proving
   already accepted tracks or modes.
2. **Make G11 measurable before optimizing:** add bounded frame/pipeline
   telemetry, establish reversible cold/warm fixtures, then attack the ranked
   bottleneck. Shader-cache guesses without p99/worst evidence are not a plan.
3. **Separate automation from hands-on gates:** run long stress, save, package,
   cache, diagnostics, and Simulator work autonomously; keep only touch feel,
   motion feel, subjective audio, physical thermals, and public-service access
   on the human prerequisite list.
4. **Finish the application boundary:** automate clean-clone source
   provisioning, bring WBFS validation/extraction into the native first-run
   experience with resumable progress, and complete license/notarization/update
   infrastructure without ever bundling private data.
5. **Promote to hardware now:** Simulator proves integration, not physical
   touch, audio, thermal, memory, sustained performance, or controller feel.
   Run the documented iPad pass first, close it, then run modern iPhone using
   the same content-safe telemetry contract.
6. **Finish online through the local harness first:** complete protocol state,
   impairment, reconnect, and full local race/results evidence before any
   normal authorized external-service session.
7. **Cut one exact candidate:** rerun the full 67-row matrix, package/privacy/
   license audits, source self-build, and zero-P0/P1 review against the same
   immutable commit and artifact hashes.

The practical change in approach is to stop treating broad successful gameplay
as the scarce resource. The scarce resource is now controlled evidence:
repeatable multiplayer completion, frame-time instrumentation, reversible cache
experiments, physical-device interaction, and a reproducible legal build path.

## Known-good state

- Repository checkpoint: exact branded macOS gameplay-package source `325d5f3` is on `origin/main`. Its ignored 80 MiB arm64 package passes installed-storage, configured title/menu/live-race input, save-preservation, and normal-close checks with bundle-content hash `12e827fdaf206df3689ab0fe0b73fa7ebe20fe3827b538d8fe7c21e8ac25e3db`. Source `5781b99` adds the native data/cache/diagnostics menu without changing the gameplay core. Source `bed127f` adds the native display/audio Settings panel. Source `a5ee9fe` adds the native first-run extracted-data gate, reconfiguration action, complete fallback application menu, and safe menu-Quit route. Source `ac89225` exposes the existing in-game controller-mapping UI from that native menu. Source `c6f94b7` adds bounded technical context to the privacy-safe diagnostics report. Source `df98779` adds persistent clean/unclean session classification and capped/redacted current/previous tails; its exact package passes export, privacy scan, clean relaunch, and audit with bundle-content hash `893095ac96d66d036c61cbfa8af79b58eac3bdbf9d24b5da4fa44066111afcb6`. Source `d6e3202` adds the one-command WBFS-to-macOS self-build; its fresh extraction, 29,637-function translation, 857-step build, exact package audit/title/audio/clean-quit exercise, and byte-identical function/shard comparisons pass with bundle-content hash `bc53f9e82e2e7656d86170e59426b9ab79b4553366946b684824739fd9f0fc92`.
- Performance checkpoint: source `2cfb7e1` adds bounded p50/p95/p99/worst presentation telemetry, effective-motion FPS, pipeline queue counts, and strict summary parsing. Its exact package reaches the title, emits valid records, audits, and quits cleanly with bundle-content hash `dc6ecdca64df7a031fde00ab63472f0130674e8705bd27196483d6a0005615de`. A reversible empty-cache/warm-cache title pair quantified the cold failure at minimum 51.958 effective FPS, 83.783 ms maximum p99, 85.094 ms worst, and 20 audio drops versus warm minimum 59.963 effective FPS, 17.264 ms maximum p99, 25.966 ms worst, and zero drops. A counterbalanced one-vs-six priority-worker sweep proved that application-cache emptiness does not control all machine-level Metal/Dawn state: both policies ranged from poor to essentially perfect as that state changed. Warm Moonview profiling now rules out steady GPU saturation (12.15% union occupancy, no drawable waits) and ranks exact scalar-FP exception bookkeeping on the main thread. Direct arm64 FPSR access passed correctness and a microbenchmark but failed a paired production CPU comparison, so it was reverted. Source `2282e2c` corrects hidden FPSCR effects in ABI/liveness analysis and passes the complete semantic surface; its exact package held 60 FPS with zero audio drops, but a paired attract-race profile was CPU-neutral (candidate/control total 10.432/10.813 seconds, main thread 7.527/7.402 seconds). Correctness is retained; no speedup is claimed, and safe FPSCR-state elimination remains the ranked CPU direction.
- The first exact `2282e2c` automated macOS soak was operator-stopped after
  4:10:10 and is not row-38 acceptance. Its partial trace strongly rejects
  monotonic memory/thread growth (257,120--1,125,792 KiB RSS, negative
  post-warmup slope, 23--28 threads) and preserved the exact save, but 480
  audio blocks / 184,320 bytes were dropped in scene-transition bursts. The
  fixed 120 ms queue ceiling is now the ranked pre-soak fix. The Simulator
  application shell had also remained visibly open despite zero booted
  devices; future launches require both zero booted devices and zero competing
  visible runtime applications. Evidence:
  `docs/artifacts/2026-08-30/g11-interrupted-macos-soak.md`.
- Simulator state: no Simulator is booted. The disposable iPhone 17 Pro devices used for clean-import/rollback and scheduled-removal testing were terminated, shut down, and deleted; the preserved iPhone container was not modified.
- Buildable KartPad targets: host, memory, scheduler, semantic contracts, native subsystem smoke, translated semantic fixture, and provisional translated-frame app.
- Input profile: WBFS containing clean PAL `RMCP01`, revision 0; original is read-only. Physical keyboard holds retain the full normalized Classic-stick range. Accessibility-generated GUI taps use a bounded 0.35 level for 250 ms; acceleration/reverse retain their 500 ms gameplay holds. Physical controllers and future touch input are unaffected.
- WiiCompiled baseline: required commit/tree verified in a detached, push-disabled partial clone.
- Translator baseline: immutable upstream remains 570/570; KartPad's reproducible FPSCR lowering patch passes 582/582 on native arm64 with .NET SDK 8.0.130. Stateful scalar/paired FP, comparison, FPSCR move, and exception-control helpers now expose their hidden FPSCR reads/writes to ABI and interprocedural liveness analysis instead of masquerading as pure calls.
- Gameplay baseline: hashed Dolphin 5.0-17995 arm64/Vulkan/HLE binary boots `RMCP01`, creates an isolated license/save, reaches Luigi Circuit and its official staff ghost, and recovers to 60 FPS/VPS after shader warmup.
- Portability baseline: `kartpad_host` and its contract suite compile/link/run natively for arm64 macOS; manifest is under `docs/artifacts/2026-08-28/`.
- Memory baseline: checked/table guest memory is the accepted correctness path; evidence is `docs/artifacts/2026-08-28/g4-guest-memory.md`.
- Scheduler baseline: explicit cooperative state machine, deterministic hash `0x7287563387fb1677`, plus translated CPU-context/NI/FPSCR persistence across yields and host callbacks; evidence is `docs/artifacts/2026-08-28/g5-guest-scheduler.md`.
- Native subsystem preparation: validated Metal/CoreAudio/GameController/storage/network smoke; useful for G7 and later gates.
- Semantic subset: arm64/x86_64 complete 250,227 checks with state hash `0xccd5757c4c0643d4`; the translated fixture additionally proves VE-enabled paired invalid arithmetic still writes both lanes while aggregating causes. Evidence is `docs/artifacts/2026-08-28/g6-ppc-semantics.md` and `docs/SEMANTICS.md`.
- Full title surface: user-owned PAL DOL and StaticR translate into 29,637 functions; the native runtime executes both constructor graphs through the title and license menu.
- Original icon: editable default/dark/tinted SVG masters and opaque exports exist; 1024 px and 16 px visual QA passed. The iPhone/iPad appearance variants now pass Simulator and physical-device asset-catalog builds.
- Full mobile game app: the freshly serialized controller integration compiles all 29,065 base translated functions into an Xcode-produced arm64 `IOSSIMULATOR` app. SDL owns the UIKit scene lifecycle; the real SDL/Metal window receives the byte-identical SunPad overlay. The first physical controller takes Player 1, clearing/hiding touch by default on hardware; Players 2–4 publish independent states into their matching retail KPAD channels and disconnect clears stale input. The resolved iPhone/iPad bundle, original compiled icon catalog, privacy/runtime resources, system-only linkage, twelve-file exact snapshot, and forbidden-private-data audit pass. The latest full FPSCR-effect-model Simulator candidate has executable SHA-256 `bdb805b933e9cbce3e921dba11063af18fd6b18eaebdb36c447bbae24f71f2d8`; its exact FPS, aspect-ratio, and render-resolution menu actions all update the runtime immediately without relaunch. A normal twelve-racer iPad Simulator Luigi Circuit scene held 57.003–60.082 effective FPS across 35 retained race records and advanced 10.615 guest seconds across a roughly ten-second wall-clock bracket, ruling out a repeated-frame-only 60 Hz result for that stationary scene. Sequential iPhone/iPad launches preserve exact saves; the iPhone regression reaches live gameplay, discovers the Simulator extended controller, exposes its assignment/setup through Multiplayer, contains fitted output with opaque-black bands, opens the real system folder picker, completes a validated 2.5 GiB private import/swap, restores the old copy byte-for-byte under an injected swap failure, and recovers a stranded rollback on its next launch. With no installed game data, a native gate now runs before emulator initialization and can import the supported WBFS or extracted fixture and continue directly into gameplay in the same process. Destructive removal is explicitly scheduled, undoable until relaunch, and applied before emulator startup; its full-size regression removed only game data while preserving the exact save. A fresh post-motion source preparation completed the full 853-step serialized graph from immutable pins; its standalone Simulator link is `06238bd24c37235524375b7a12fbb0ca522b156b51936bf5be97049f5da5e500`. A Simulator-only one-worker pipeline policy corrects the observed Metal compiler scheduler crash without changing device/macOS policy. KartPad-owned configurable CoreMotion steering now compiles for Simulator and device, passes its deterministic input contract, presents an accurate Simulator-unavailable fallback, and survives the final candidate's background/foreground cycle; physical motion play remains open. Evidence: `docs/artifacts/2026-08-30/g14-full-game-app.md`, `docs/artifacts/2026-08-30/g14-full-game-simulator/`, `docs/artifacts/2026-08-30/g14-controller-multiplayer/`, `docs/artifacts/2026-08-30/g14-opaque-letterbox/`, `docs/artifacts/2026-08-30/g14-game-data-import/`, `docs/artifacts/2026-08-30/g15-native-wbfs-import/`, and `docs/artifacts/2026-08-30/g15-motion-steering/`.
- Physical mobile build: the same integrated source and all 29,065 base
  translated functions now compile and link against the pinned physical-iOS
  Dawn archive as a complete unsigned arm64 `IOS` 16.0 app. The 75 MiB bundle
  passes the strict full-game package/private-data/system-dependency audit at
  executable SHA-256
  `b02c1c94dee58526169a08e73bbbe671e6f6ee31c1870517ef244e2651e9de92`.
  A new source and build directory exposed and corrected an undercounted
  serialized KPAD patch hunk, then rebuilt both the complete Simulator graph
  and the complete physical-device graph from the corrected patch stack. The
  source verifier rejects any declared/actual line-count mismatch across the
  complete tracked unified-diff stack before a costly build begins. The final
  audit additionally requires the native WBFS-import contract and rejects
  Dolphin JIT/cached-interpreter execution-core symbols.
  The reproducible `scripts/build-ios-device-game-app.sh` rerun is incremental
  on an existing build directory. This closes fresh-directory and incremental
  full device compilation, not signing,
  installation, execution, performance, thermal, audio, or touch-feel rows.
  Evidence: `docs/artifacts/2026-08-30/g16-full-device-build.md`.

## Active risks and blockers

- The newest audited Simulator menu-contract candidate has executable SHA-256
  `0459d6948e856547dcbe77f7b1839ff7882a8cf73cb0c3052c5c53ff99e98d90`.
  SunPad's Sunshine-specific 90%-clock and GMSE01 60 FPS rows retain their
  exact visible titles/icons but now explain that KartPad cannot apply those
  mechanisms and do not persist no-op preferences. This supersedes the prior
  `bdb805b9...` wrapper binary without changing its translated game core.

- The current touch-control candidate keeps the pinned twelve-file SunPad
  snapshot byte-identical while adapting two behaviors in KartPad's owning
  overlay: Classic R is a compact digital pill matching L, and an uninterrupted
  one-second A touch changes to a cyan held-acceleration state until touch-up.
  The focused Classic adapter passes. A Simulator-only end-to-end probe now
  drives the real SunPad touch-down/up targets and observes the mapped Classic
  state inside the live app: held `0x00000010`, released `0x00000000`. The full
  Simulator app audits at
  executable SHA-256
  `7c3c6a4ddda8a2d89d42e4a867dfc6c1e43aadd4635c28a2870e302e525956be`.
  Sequential iPhone and iPad visual/accessibility regressions both pass: R
  matches L, A enters `Acceleration held`, and release restores its normal
  state while retail rendering continues underneath. Each device and the
  Simulator shell were shut down before the next launch; zero runtimes remain.
  The exact updated UIKit host also compiles as an arm64 `IOS` 16.0 object with
  SHA-256
  `58df58a0577dd6c3276ec67c93bbf67955c6e1531a3912323cbb5881b72d4a55`;
  the reproducible check proves every Simulator-only test contract is absent.
  The unsigned physical-device shell and original icon catalog independently
  rebuild and pass their `IOS` package audit.

- About 14 GiB of host storage remains after private disc extraction, the full translated runtime build, and native trace evidence. Large generated products remain ignored; capacity must be checked before additional build graphs.
- Direct mobile WBFS import passes its complete Simulator integration boundary.
  A fresh no-data launch opened the supported `RMCP01` revision-0 WBFS,
  extracted and atomically activated the full 2.5 GiB/2,043-file tree,
  reproduced the accepted DOL/REL hashes, continued into retail rendering in
  the same process, accepted touch input, and reached the title again after a
  warm relaunch. The app links the narrow import graph rather than Dolphin's
  execution core; the package audit rejects JIT/cached-interpreter symbols.
  Physical extraction speed, interruption behavior under real device pressure,
  and thermals remain hardware acceptance. Evidence:
  `docs/artifacts/2026-08-30/g15-native-wbfs-import/`.
- No human-only prerequisite currently blocks G0 or the independent parts of G1.
- Physical-device, public-service, account, and hands-on acceptance rows remain future external prerequisites and are not claimed.
- WiiCompiled's bundled `MAP.txt` may be used as an ignored local reference, but independent provenance for republishing it is not established; do not copy it into public KartPad sources/artifacts.
- The exact 2008 Classic ABI is live and the game recognizes it. A/accelerate, analog steering, D-pad, and B/reverse are proven. Three-player gameplay switches to the retail 30 FPS cadence documented by the Dolphin oracle; a complete live-input three-player race remains open.
- Two content-private three-player automation attempts rendered all expected panes and exited normally but failed to complete because the synthetic driver left the course at both the accepted `0.35` and rejected `0.18` steering levels. The `0.18` experiment was reverted; these attempts are not runtime-defect or standings evidence.
- A normal three-player stationary-player experiment registered three independent channels and held the retail four-pane 30 Hz mode for about 310 live seconds, but CPU completion did not trigger FINISH/DNF/results while every local player remained unfinished. The shortcut is rejected: row 30 still needs at least one local finisher through sustained physical input or a separately proven normal input-driving method. The same run accumulated 29 dropped audio blocks / 11,136 bytes, so three-player audio remains an explicit fail signal. Evidence: `docs/artifacts/2026-08-30/g10-three-player-stationary-timeout.md`.
- A deterministic second-race crash after returning from a three-player race was traced to a reclaimed camera node retained by the global race-camera list. A broad slot-`0xff` guard was itself regressive because three-player retail mode uses a legitimate slot-`0xff` overview camera. The corrected generated-source guard additionally requires the observed `0x55440003` scene-heap poison; the exact formerly failing sequence now preserves all four panes and reaches live second-race gameplay in the same process. Full three-/four-player standings cycles remain open.
- The opt-in RKG player fixture matches native stream expansion and the exact 240-frame countdown cadence but later diverges through the live-player path. It remains a diagnostic harness, not evidence for staff-ghost synchronization or a completed track.
- Both private disc-derived staff sets pass a strict content-free preflight: 32 files, exactly one structurally consistent input for every retail course ID `0..31`, and matched per-stream frame counts. This establishes a complete oracle inventory only; native row 22 execution remains open.
- A guarded private all-cups fixture derived from the user's own backed-up save now exposes the remaining row-22 tracks. It validates magic/version/CRC and changes only GP-completion flags plus CRC. It is a test precondition, not row-23 progression evidence; representative Grand Prix and honest unlock progression remain open.
- Two-player split-screen PRD row 29 passes: P1 completed three live-keyboard laps, both panes reached the retail finish transition, and the full standings table retained distinct Mario/P1 and Luigi/P2 rows. The successful log contains zero fixture entries; evidence is under `docs/artifacts/2026-08-29/g10-two-player-race/`. Three/four-player full races remain open.
- Time Trial PRD row 26 passes: an exact `01:38.880` personal ghost was recorded, saved, loaded after relaunch, replayed completely, and then authentically replaced by a normal live-input `05:01.445` personal best. A second fresh process loaded the replacement; evidence is under `docs/artifacts/2026-08-29/g10-time-trial-record/`.
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
- Audio continuity instrumentation is bounded and cumulative. Its first uncontended diagnostic sample recorded 104,960 queue checks and 40,304,256 submitted bytes with zero post-start empty observations or drops. Replay pause/resume passes with zero empty observations and a bounded eight-block pause burst. Default-output migration also passes: two live route changes caused a bounded 101-block stale-data burst, then zero further drops through 98,304 checks; the original output was restored and gameplay remained live. A separate 2:00:18 representative run completed 22 exact replay segments with zero empty-before-push observations through 2,408,448 checks; 175 stale blocks (67,200 bytes, about 0.0073% of submitted bytes) were discarded without sustained starvation. Subjective listening remains open, and this two-hour run does not replace the G11 eight-hour soak. Evidence: `docs/artifacts/2026-08-30/g10-audio-two-hour.md`.
- The fresh-process Time Trial replacement check added a normal-load sample through 49,152 queue checks and 18,873,984 submitted bytes with zero post-start empty observations or drops. It strengthens ordinary menu/gameplay continuity but does not replace pause, default-device migration, or long-session acceptance.
- The portable development app intentionally stores writable `UserData` beside its executable and is not distributable. The exact branded arm64 package contains no writable/private state, links only Apple system libraries, declares macOS 14.0, and uses the original icon. The `325d5f3` gameplay candidate reaches configured live Grand Prix gameplay and keeps durable state in Application Support and rebuildable cache state in Caches; the save and bundle remain unchanged. The native shell provides Show Data, Show Cache, bounded Save Diagnostics, a standard display/audio Settings panel, and an entry into the existing F10 controller-mapping UI. Schema-3 diagnostics identify exact build/runtime, product/renderer/memory/scheduler strategies, selected safe settings, validated data, yes/no storage health, clean/unclean session state, and capped/redacted current/previous structured tails while excluding private content. An unconfigured launch validates a supported user-owned extracted RMCP01 folder before runtime initialization, writes and reloads `dvd_root`, and reaches the game in the same process; unsupported selections preserve the prior config, and both first-run and application-menu Quit routes exit without fatal teardown. Replacing an older signed app bundle with the current package preserves byte-identical external config/save state and boots retail rendering. The public Mac command-line workflow now accepts the pinned user WBFS, performs a fresh validated extraction, emits the complete private title graph, builds/audits the app, and reaches retail rendering/audio with clean input and shutdown; its function/shard trees are byte-identical to the prior graph. Automated fresh-clone reference provisioning, native image-generation progress/resume/cache management, and public updater/notarization infrastructure remain open. Evidence: `docs/artifacts/2026-08-30/g13-exact-macos-package.md`, `docs/artifacts/2026-08-30/g13-macos-native-menu.md`, `docs/artifacts/2026-08-30/g13-macos-settings/`, `docs/artifacts/2026-08-30/g13-macos-first-run/`, `docs/artifacts/2026-08-30/g13-macos-controller-menu.md`, `docs/artifacts/2026-08-30/g13-macos-diagnostics-v2.md`, `docs/artifacts/2026-08-30/g13-macos-update-in-place.md`, `docs/artifacts/2026-08-30/g13-macos-clean-rebuild.md`, `docs/artifacts/2026-08-30/g13-macos-session-diagnostics.md`, and `docs/artifacts/2026-08-30/g13-macos-wbfs-self-build.md`.
- Moonview Highway first use sampled at 1.3 FPS and recovered to roughly 46 FPS within 20 seconds, then remained around 46–54 FPS during focused checks. Exact guest completion passed, but G11/G36 must compare a controlled warm-cache rerun and resolve sustained frame pacing before performance acceptance.

## UI reference commitment

The local `ref/sunpad` checkout remains the direct implementation reference for the mobile touch interface and persistent three-dot menu. Its pinned twelve-file snapshot, now including controller slots and mapping, is byte-identical and runs above the full 29,065-function retail Metal app. A KartPad-owned layer adds `Multiplayer…` and `Motion Steering…` around the unchanged menu source, reports connected controllers and stable Player 1–4 assignment, opens controller setup guidance, and exposes default-off calibrated CoreMotion steering without changing the exact touch mixer. The runtime reads SunPad's persisted aspect, resolution, FPS, and controller mapping preferences; the latest current-core regression proves that all three non-restart display controls refresh visibly in-process. Touch Control Settings now clears the complete touch contribution on both open and close; an end-to-end probe observed Classic A change from held `0x00000010` to released `0x00000000` through the real modal path. The lower settings rows now pass deterministic UI-action coverage: Move enters edit mode, selecting A exposes its per-control slider, a `1.25` resize persists through Done, the native reset confirmation appears, and Reset removes position/size preferences and restores the default overlay on relaunch. The full app boots sequentially on iPhone 17 Pro and iPad Pro 13-inch (M5), survives reinstall/container migration with a relative game-data root, reaches title/menu and live Luigi Circuit on both, enters the iPhone retail two-player controller-registration screen, and backgrounds/resumes. Both device classes preserve exact save hashes across terminate/relaunch and return through their persisted licenses. Original 4:3 and bounded 16:9 now clear their complete presentation snapshots to opaque black; a combined supplied-before/rebuilt-after regression proves the fitted viewport no longer leaks striped/checker edge pixels. The exact Game Data submenu opens the system picker or scans KartPad's Files-visible folder; the final candidate directly extracts a supported WBFS or copies an extracted tree, validates, stages, swaps, restores the original copy under an injected swap failure, and automatically repairs a stranded rollback. A true no-data WBFS launch gates emulator startup, imports through native UI, and reaches gameplay without relaunching. Removal is scheduled while the guest remains live, can be undone, and deletes only private game data before the next emulator start. Dynamic fill remains experimental because it exposes the game's overscan/scratch area. Complete touch-driven races, physical finger-drag ergonomics, hands-on physical-controller races/feel, physical motion calibration/race acceptance, physical-device execution, and hands-on touch/audio acceptance remain open. Evidence: `docs/artifacts/2026-08-30/g14-simulator-shell/`, `docs/artifacts/2026-08-30/g14-full-runtime-link.md`, `docs/artifacts/2026-08-30/g14-full-game-app.md`, `docs/artifacts/2026-08-30/g14-full-game-simulator/`, `docs/artifacts/2026-08-30/g14-controller-multiplayer/`, `docs/artifacts/2026-08-30/g14-opaque-letterbox/`, `docs/artifacts/2026-08-30/g14-game-data-import/`, `docs/artifacts/2026-08-30/g14-ipad-current-race-profile.md`, `docs/artifacts/2026-08-30/g15-native-wbfs-import/`, `docs/artifacts/2026-08-30/g15-motion-steering/`, `docs/artifacts/2026-08-30/g15-touch-modal-input-clear/`, and `docs/artifacts/2026-08-30/g15-touch-layout-editor/`.

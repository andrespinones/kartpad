# KartPad engineering journal

This file is append-only. Evidence paths refer to sanitized, publishable artifacts unless explicitly marked private and ignored.

## 2026-08-28 — G0 workspace initialization

- Goal: establish the workspace and evidence system before modifying or translating private game data.
- State inspected: repository contains only the approved PRD/goal loop in `docs/`, a user-owned WBFS in `ref/`, and a complete local SunPad reference checkout in `ref/sunpad/`. The Git history contains the two documents at the repository root; their move into `docs/` was already present in the working tree and is preserved.
- Host: Apple Silicon arm64, 24 GiB memory, Xcode 26.6 (17F113), macOS SDK 26.5.
- Process state: no booted Simulator and no stale KartPad, WiiCompiled, Dolphin, or test-server process observed.
- Capacity: approximately 21 GiB free at session start. This is a near-term build-capacity risk and must be rechecked before dependency expansion or large generated graphs.
- Smallest step: add private/generated/build/reference exclusions and create the mandated evidence/status files.
- Immediate test: run repository safety inspection and verify the WBFS and local reference checkout are ignored before the first commit.
- Known-good source revision: `7875e82` (`origin/main`), documentation only.
- Next step: identify and hash the supplied disc without modifying it; pin WiiCompiled and reference revisions within available storage.

### G0/G1 result update

- Result: Pass for the initial workspace boundary and input-identification step.
- Disc container: WBFS, 2,778,726,400 bytes, modification time `2026-08-28T14:05:10-0500`.
- Embedded disc identity: `RMCP01`, Mario Kart Wii, PAL, maker `01`, revision 0, Wii magic `0x5d1c9ea3`.
- SHA-1: `73b83ac9b7e4a426de82fdc0a81b6131cc1c7975`.
- SHA-256: `fc035e60610842da6860d23d4a30c1f1c0f019d492469deb8a2ac25ef5822331`.
- Preservation: original WBFS mode changed from `-rw-r--r--` to read-only `-r--r--r--`; filename and contents were not altered.
- WiiCompiled: exact commit `1912292c804ff9b1b79938de89369ec4496f9fff`, tree `34f9deda094915e12f47316059911b28c6812964`, detached checkout, push disabled.
- SunPad reference: clean commit `e43f0ea6b797e5110787171957c9dc3c6213269c`, push disabled.
- Immediate test: hashes completed, header was inspected from the first WBFS disc sector, required paths resolve through `.gitignore`, and the repository safety script is the checkpoint gate.
- Next step: checkpoint G0, then inspect WiiCompiled and pin the remainder of the reference graph for G1.

## 2026-08-28 — G2 translator baseline attempt 1

- Goal: G2 baseline oracle, no-game-data translator suite.
- Target/profile: pinned WiiCompiled translator, host arm64 macOS, Release.
- Commit/build manifest: WiiCompiled `1912292c804ff9b1b79938de89369ec4496f9fff`; no build produced.
- Command: `dotnet test translator/tests/Translator.Tests/Translator.Tests.csproj -c Release` with a TRX evidence logger.
- Expected: restore/build and execute the no-game-data translator test suite.
- Actual: command exited 127 before restore because `dotnet` is not installed.
- First failing subsystem: host prerequisite.
- Primary error: `zsh: command not found: dotnet`.
- Reproduction rate: 1/1; not repeated unchanged.
- Evidence path: terminal result only; no TRX was produced.
- Variables changed since last known good: first translator test attempt.
- Classification: Blocked—local prerequisite, immediately actionable under standing authorization.
- Next step: install the required .NET 8 SDK, record its version, and rerun once.

### G2 translator baseline result

- Change: installed Homebrew `dotnet@8` SDK 8.0.130; invoked it by explicit keg path.
- Immediate test: pinned WiiCompiled `Translator.Tests` Release suite on native arm64.
- Result: Pass — 570 passed, 0 failed, 0 skipped, 570 total.
- Evidence: `docs/artifacts/2026-08-28/wii-compiled-translator-tests.trx`.
- Conclusion: the no-game-data translator suite is green at the pin. This does not establish runtime, game, ARM semantic, or gameplay correctness.
- Next step: finish G1 reference verification and begin the Dolphin behavioral oracle and host portability inventory.

## 2026-08-28 — G1 reference graph and branding track

- Goal: verify required source pins/licenses and complete the independent original-icon task.
- Source result: WheelWizard, rr-pulsar, Retro Rewind wfc-server, wfc-patcher-wii, and Dolphin pinned at immutable commits/trees recorded in `dependencies.lock.json`; every origin push URL is disabled.
- Recovery note: Homebrew Git 2.41 produced a broken partial Dolphin checkout with absent promised blobs. A second partial repair remained invalid, so the failure was escalated to a clean Apple Git 2.50.1 shallow checkout without filters. The clean Dolphin checkout passes connectivity and is the only accepted oracle path; the failed disposable clone is retained ignored as `ref/upstream/dolphin-partial-broken` pending safe cleanup.
- Licensing result: WiiCompiled/WheelWizard/rr-pulsar/SunPad GPLv3; wfc-server AGPLv3; wfc-patcher custom BSD-style attribution or GPLv2+ election; Dolphin aggregate GPLv3-compatible with per-file SPDX; vendored Aurora MIT.
- Icon result: original AI concept generated with OpenAI's built-in image tool, followed by a hand-authored editable SVG master and dark/tinted variants. The first ImageMagick SVG render failed visual QA because strokes collapsed; librsvg replaced that renderer. Corrected 1024 and 16 px outputs were visually inspected and are opaque.
- Icon master SHA-256: `33286f3e27b2eddc9d169d533f8d6f52a7013bd3d8787744941ab4204dbd5c6d`.
- Icon evidence/source: `branding/`, with exact prompt boundary and concept hash in `branding/PROVENANCE.md`.
- Next step: run full `verify-sources.sh`, update G1 status, and checkpoint to GitHub.

### G1 verification result

- Command: `KARTPAD_VERIFY_FULL_DISC=1 ./scripts/verify-sources.sh`.
- Result: Pass. All seven Git references matched their locked commit/tree, were clean, and had disabled push URLs. The WBFS remained read-only, retained its expected size/header/revision, and matched the full locked SHA-256.
- Classification: G1 Pass.
- Next lowest unmet goal: G2 baseline oracle. Capture a pinned Dolphin boot/title/menu, Time Trial, staff ghost, Grand Prix, audio, and save/relaunch evidence set where automation and available inputs permit.

## 2026-08-28 — G2 isolated Dolphin gameplay oracle

- Goal: establish a reproducible boot/save/menu/race/ghost behavioral oracle without modifying the supplied WBFS or the user's Dolphin profile.
- Target/profile: Dolphin 5.0-17995, arm64 JIT, Vulkan, HLE, private user directory; clean PAL `RMCP01` revision 0.
- Oracle executable SHA-256: `818bc7f1d344f4cf0a0ac78ee6c72dbf7800f3ad3ceebdc0c91f72aff7de4fe8`.
- Instance discipline: one Dolphin game instance and no KartPad instance. No additional Simulator was launched.
- Input attempt 1: isolated Quartz keyboard configuration. Expected synthesized A input to advance the wrist-strap screen; actual accessibility key events were not visible to Dolphin's polled keyboard backend. Reproduction 2/2. The unchanged approach was stopped.
- Escalation: inspected the pinned Dolphin input implementation and selected its built-in named-pipe controller backend. The private FIFO and mappings remain ignored under `private/oracle/`.
- Input result: Pass. Pipe A advanced wrist strap/title and drove the complete first-run license flow, main menu, Single Player, Time Trials, Luigi Circuit, and staff ghost selection deterministically.
- Save result: Pass. A new `Player` license was created in the isolated user directory. Evidence includes pre-create confirmation and created-license screens.
- Race/ghost result: Pass for the G2 baseline. The official Nin★sato Luigi Circuit staff ghost (`01:29.670`) was identified; a live challenge and deterministic staff replay rendered successfully. After first-shader warmup, the replay repeatedly reported `60 FPS / 60 VPS / 100%`.
- Control-semantics caveat: the exploratory live drive did not establish an unambiguous acceleration/brake mapping, so no completed human-controlled lap or steering-feel claim is made. The deterministic staff replay is the accepted complete-course behavioral reference; a smaller fixture remains required for KartPad input semantics.
- Audio caveat: subjective audio quality was not assessed and remains hands-on.
- Evidence: `docs/artifacts/2026-08-28/dolphin-oracle/README.md` and indexed screenshots in the same directory.
- Cleanup: Dolphin completed its save shutdown. The user's global `WiimoteNew.ini`, `GCPadNew.ini`, and `Dolphin.ini` matched their pre-session SHA-256 values exactly; no restore write was necessary.
- Classification: G2 Pass. The installed binary is labeled a hashed preliminary oracle distinct from the newer pinned Dolphin source checkout.
- Next lowest unmet goal: G3 host portability contract and no-game-data tests.

## 2026-08-28 — G3 host portability boundary

- Goal: compile a host-neutral utility boundary on arm64 macOS without Win32 libraries or x86-only flags while leaving the pinned Windows baseline untouched.
- Smallest implementation: explicit CMake capability switches and a `kartpad_host` library for monotonic time/deadline sleep, thread naming, application/cache/temp paths, directory creation, and durable atomic replacement.
- Separation: Darwin and Windows implementations are separate translation units selected by the target graph. Public headers contain standard C++ types only.
- Immediate test: `./scripts/test-host-portability.sh` with AppleClang 21.0.0, Ninja, arm64, deployment target 14.0, RelWithDebInfo.
- Result: Pass — host library and contract executable compiled/linked, CTest 1/1 passed, and the generated Darwin graph contained none of the forbidden Win32 libraries or `-march=x86-64`.
- Contract assertions: capability selection, monotonic advance, non-early deadline sleep, thread-name round trip, standard macOS path domains, first/replacement atomic writes, and no temporary sibling leakage.
- Build evidence: `docs/artifacts/2026-08-28/g3-host-portability-build-manifest.json`.
- Windows baseline: pinned WiiCompiled checkout remained clean at commit `1912292c804ff9b1b79938de89369ec4496f9fff`, tree `34f9deda094915e12f47316059911b28c6812964`; no upstream file was edited.
- Inventory: reproducible search script and source-complete first-party ownership table recorded in `docs/PORTABILITY.md`.
- Classification: G3 Pass. A Windows execution result is not claimed; its baseline source graph remains isolated and reproducible at the pin.
- Next lowest unmet goal: G4 Darwin guest-memory model, beginning with the checked oracle and scalar/endian/alias contract fixtures.

## 2026-08-28 — G4 checked guest memory and Darwin reservation probe

- Goal: select and prove a safe macOS guest-memory path before scheduler or full runtime bring-up.
- Selected path: checked/table memory, preserving the full 32-bit guest address domain sparsely and using shared backing IDs for guest aliases.
- Immediate command: `./scripts/test-guest-memory.sh`.
- Release result: Pass. Signed/unsigned scalar widths, every alignment, endian layout, cross-page access, boundary/domain faults, alias coherence, overlap rejection, MMIO dispatch, executable-write guard, fault diagnostics, concurrency, lifecycle, randomized stress, and guest microprogram passed.
- Sanitizer result: Pass under AddressSanitizer and UndefinedBehaviorSanitizer with no finding.
- Stress: four ordered worker threads plus 100,000 seeded random 64-bit writes/reads and full retained-state verification.
- Diagnostics: a failing access carries the translated function, guest PC, guest LR, and register dump supplied by the active CPU context provider.
- Microprogram: fetched bytecode from guest memory, performed a big-endian store, took a branch, invoked a host-call fixture, and halted with the expected result.
- Flat candidate probe: non-overwriting fixed reservation of 4 GiB plus guard at 16 TiB succeeded, as did protect/deallocate and a two-launch base-relative lifecycle. No destructive fixed overwrite flag was used.
- Decision: G4 Pass on the checked backend. Mach VM flat memory remains an optimization experiment until alias/protection/fault/differential evidence matches the checked oracle.
- Evidence: `docs/artifacts/2026-08-28/g4-guest-memory.md`.
- Next lowest unmet goal: G5 portable guest scheduler/context backend.

## 2026-08-28 — G5 explicit portable guest scheduler

- Goal: replace the Windows-fiber dependency with a deterministic arm64-safe guest execution contract.
- Strategy: explicit cooperative state machine. A translated step owns no persistent host stack; it returns yield, sleep, queue-wait, join-wait, or exit. Each guest thread stores a complete CPU context.
- Lock boundary: the scheduler selects/updates metadata under its mutex, releases it for guest/host/retrace callbacks, then applies the returned action. A nested callback inspection test passes.
- Immediate command: `./scripts/test-guest-scheduler.sh`.
- Lifecycle result: create suspended, resume, priority order, yield, sleep/alarm, simultaneous wake, queue, join, cancel, exit, 10,000 create/reap cycles, background suspension, idle/deadlock return, and shutdown while waiting/running all pass.
- Context result: GPRs, PC/LR/CR, FPSCR, every FP register bit pattern including NaN payloads, and 128 bytes of SIMD state persist across switches.
- Determinism result: two independent 1,000,000-operation runs distributed exactly 250,000 steps to each of four peers, emitted exactly 10,000 VI callbacks, and produced identical state hash `0x7287563387fb1677`.
- Sanitizer result: Pass under ASan/UBSan with no finding.
- Classification: G5 Pass for the backend contract. Wii OS HLE/translated-boundary integration is G6; physical mobile backgrounding remains a later device test.
- Evidence: `docs/artifacts/2026-08-28/g5-guest-scheduler.md`.
- Next lowest unmet goal: G6 native renderer/audio/input/storage/network subsystem initialization.

## 2026-08-28 — G6 native Apple subsystem smoke

- Goal: initialize renderer, audio, input, storage, and networking through native macOS APIs before translated-frame work.
- Immediate command: `./scripts/test-native-subsystems.sh` with `MTL_DEBUG_LAYER=1`.
- Renderer result: Pass. Metal API Validation enabled; Apple M2 device/queue cleared an 8×8 RGBA8 render target, completed normally, and all pixels matched the expected 0.25/0.5/0.75/1.0 color.
- Audio result: Pass for initialization. Apple's default output component instantiated, reported 48 kHz/eight channels, and disposed cleanly. No audible-quality claim is made.
- Input result: Pass for discovery initialization. GameController returned a valid zero-controller collection; physical mapping remains a later row.
- Storage result: Pass through durable atomic replacement and cleanup in the app-specific temporary domain.
- Network result: Pass for host smoke. `localhost` DNS and an actual IPv4 loopback bind/listen/connect/accept/send/receive payload passed.
- Classification: G6 Pass for native synthetic subsystem initialization. Dawn/Aurora surface integration, translated rendering, streaming audio, physical input, TLS, and external services remain gated later.
- Evidence: `docs/artifacts/2026-08-28/g6-native-subsystems.md`.
- Next lowest unmet goal: G7 first translated rendered frame through the real application surface/renderer bridge.

## 2026-08-28 — G6 gate correction and semantic differential

- Review correction: the native Apple subsystem smoke was useful preparation but had been mislabeled as G6. `GOAL-LOOP.md` defines G6 as exact PPC/AArch64 semantics. The error was caught before the next checkpoint; G6 was reopened and remains the lowest unmet goal.
- Smallest implementation: a standard-C++ semantics layer, a curated/seeded no-game-data harness built for arm64 and x86_64/Rosetta, and a real pinned-translator DOL microfixture executing integer add plus `fadds` through checked guest memory.
- Oracle: pinned Dolphin `FloatUtils.cpp` is compiled directly and its fres/frsqrte raw bits are compared byte-for-byte with the checked corpus.
- Result: arm64 and x86_64 each completed 250,080 checks with identical state hash `0xca5a9534a8da687b`; arm64 ASan/UBSan passed; translator suite remained 570/570; translated fixture matched on both architectures.
- Failure 1: upward float-to-word vector returned 2 instead of 3. First failing subsystem: guest rounding-mode selection. The optimized ambient-fenv approach was replaced with explicit guest-mode `trunc`/`ceil`/`floor`/nearest selection; changed run passed.
- Failure 2: initial `Force25Bit`, estimate, and wrapped-scale expected values disagreed. The implementations were not changed. Independent source inspection and compiled pinned-Dolphin output showed the hand-entered expectations were wrong; corrected corpora passed.
- Failure 3: sanitizer run exited because macOS ASan reports leak detection unsupported. The changed run disabled only unsupported leak detection; ASan/UBSan passed.
- Classification: In progress. The tested subset is green, but the complete translator-emitted helper surface is not yet portable/proven. Exact inventory and remaining work are in `docs/SEMANTICS.md`.
- Next step: port and test the remaining ISA/helper surface, with translated paired-single/GQR/FPSCR/ABI fixtures.

### Provisional G7 experiment (not gate acceptance)

- A pinned-translator synthetic command function drove a real AppKit/CAMetalLayer drawable with Metal validation and every-pixel comparison. The output is `docs/artifacts/2026-08-28/g7-translated-frame.png`.
- First build failure: strict CoreGraphics enum/integer bitwise mismatch. Explicit integer conversions fixed it; the changed build and UI run passed.
- Classification: preparatory only. No Dawn/Aurora, GX geometry, or game frame is claimed, and G7 remains gated behind G6.

### G6 paired/GQR/FPSCR expansion

- Added the complete portable paired-single operation family, all five GQR data encodings across paired and W=1 forms, representative wrapped scales, endian/NaN/subnormal rules, and broader randomized architecture differential coverage.
- Expanded the generated DOL itself: pinned translator output now performs real `psq_l`, `ps_add`, `psq_st`, and `fdivs` operations in addition to integer/`fadds`, then routes results through checked guest memory.
- First FPSCR run produced the correct infinity but left FPSCR zero. Root cause: ordinary optimized FP mode did not guarantee host exception observation around the translated expression. Semantic targets now use strict FP mode in addition to no-fast-math/no-contraction; the changed arm64 and x86_64 runs both produce FPSCR `0x84000000` (FX|ZX).
- Result: Pass for the expanded subset — 250,155 checks, identical state hash `0xb332d343c4e3dc81`, translated paired/GQR/flag fixture identical on arm64 and x86_64, sanitizers green, translator 570/570.
- Classification remains In progress pending the stateful helper inventory in `docs/SEMANTICS.md`.

### G6 real Mario Kart Wii translation surface

- Built pinned Wiimms ISO Tools in an ignored disposable copy. First macOS build failed because setup used GNU-only `awk gensub`, leaving the host type unset and adding `-static-libgcc`; the corrected portable `awk gsub` setup identified macOS. Native arm64 linking then rejected legacy unaligned common pointers, so the changed build targeted x86_64 and ran successfully under Rosetta.
- Extracted only `sys/main.dol` from the read-only supplied WBFS into ignored `private/` data. Its SHA-256 is `80d18895b39c63bd80f457398bfcbb91b7d16ac116a41a88967e954080155b05`, exactly WiiCompiled's pinned PAL DOL.
- Recursive translation from `0x800060A4` with unsupported instructions disabled emitted 10,836 functions. The 29,792-entry pinned map supplied boundaries; 802 functions were reached by the call graph and 10,034 additional valid entries were seeded from the map.
- First whole-surface compile exposed stack/resolved/state PSQ forms, state-free ABI guards, CR/XER helpers, time-base/MSR state, GX FIFO calls, cache-line zero, system calls, and fused negative multiply-subtract not represented by the microfixture. Each changed compile moved past the prior signature; no unchanged failed run was repeated.
- Final strict-FP AppleClang pass syntax-compiled all 10,836 emitted units. The full arm64/x86 semantic suite remained green at 250,155 checks and hash `0xb332d343c4e3dc81`; the stateful translated fixture matched with FPSCR `0xa7000003`; sanitizers, Dolphin oracle, and translator 570/570 passed.
- Classification remains In progress. Whole-title compilation proves portable surface ownership, not exact invalid-subcause/enabled-exception state or callback/scheduler execution.

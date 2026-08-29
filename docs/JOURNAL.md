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

### G6 translated FPSCR invalid-state lowering

- Replaced generic host `FE_INVALID` attribution for basic scalar add/subtract/multiply/divide/sqrt with explicit Broadway causes: VXSNAN, VXISI, VXIDI, VXZDZ, VXIMZ, VXSQRT, and ZX. FX/VX/FEX summaries and FPRF classification are updated from guest state.
- A value-only emitted expression could not represent enabled-exception write suppression. KartPad now applies a tracked patch to an ignored disposable WiiCompiled copy; scalar helpers receive the destination by reference and leave it unchanged when VE or ZE enables the raised cause. The pinned checkout remains clean and push-disabled.
- The first patched translator build failed because two former local emitters became unused under warnings-as-errors. Removing those obsolete local functions produced a clean build. The original upstream tests then reported 22 intentional shape mismatches; adjusting the disposable patch's expectations and adding `PPC_Fsqrts` coverage produced 571/571.
- The first translated invalid fixture reported zeros because its checked-memory harness initialized only the older 28-byte data section. Adding +infinity, -infinity, and 42.0 to the harness made the changed run prove canonical invalid NaN with VE disabled, then preservation of 42.0 with VE enabled.
- Result: arm64/x86_64 each pass 250,188 checks with identical hash `0x09ff7940379dd04a`; ASan/UBSan, Dolphin oracle, patched translator 571/571, and the translated suppression fixture pass. All 10,836 real-title units regenerate and syntax-compile with the patched translator.
- Classification: G6 remains In progress. Next smallest work is fused/conversion/estimate/paired exception state, followed by translated host callbacks and NI scheduler persistence.

### G6 translated float-to-word conversion state

- Routed `fctiw` and `fctiwz` through stateful translated calls instead of unconditional expression assignments. The pure model now emits the PowerPC `0xfff8...` result layout, preserves FPRF, records FI/FR/XX, raises VXCVI and VXSNAN, and suppresses invalid writes under VE.
- Replaced ambient-host nearest rounding with an explicit finite ties-to-even implementation, keeping all four guest rounding modes independent of host fenv state.
- Expanded the generated DOL to translate both conversion instructions and an enabled invalid conversion. Runtime evidence proves truncation of 2.75 to word 2, nearest-even to word 3, and preservation of the original 2.75 destination when converting infinity with VE enabled.
- Result: 250,197 arm64/x86_64 checks match at `0x817dafe156e3268c`; ASan/UBSan and patched translator 573/573 pass; all 10,836 real-title units regenerate and strict-FP syntax-compile.
- Classification: G6 remains In progress. Fused, estimate, paired-lane exception aggregation, callback execution, and NI scheduler persistence remain.

### G6 translated fused invalid state

- Replaced all eight scalar fused helper emissions (`fmadd`, `fmsub`, `fnmadd`, `fnmsub` and single variants) with destination-by-reference stateful calls. The model preserves PowerPC NaN operand priority (a, b, c), distinguishes invalid product VXIMZ from invalid add VXISI, preserves NaN sign behavior for negative forms, updates FPRF, and suppresses the destination under VE.
- First patched translator build failed because the last value-only scalar helper builder became unused under warnings-as-errors; removing it exposed one intentional operand-order assertion, which was updated to require the stateful destination-first shape. The changed suite passes 577/577.
- Expanded the translated DOL with invalid `fmadds` under VE. The runtime keeps the destination at 42.0 while setting VXIMZ; arm64/x86_64 and ASan/UBSan agree.
- Result: 250,202 checks, identical hash `0x8947f7ff3d2e35f4`, translated final FPSCR `0xe7911183`, and all 10,836 real-title units regenerate and strict-FP syntax-compile.
- Classification: G6 remains In progress. Estimate/paired exception aggregation, callbacks, and NI scheduler persistence remain.

### G6 translated scalar-estimate state

- Routed `fres` and `frsqrte` through stateful lowering while retaining the compiled-Dolphin bit-exact estimate algorithms. The model now raises ZX for reciprocal zero, VXSQRT for negative reciprocal-square-root, and VXSNAN for signaling NaNs, while updating summaries/FPRF and clearing FI/FR on exceptional results.
- Expanded the translated DOL with zero `fres` under ZE and negative `frsqrte` under VE. Both destinations remain 42.0 while ZE and VXSQRT become sticky; direct contracts also cover their disabled-enable results and signaling-NaN payload behavior.
- Regenerated the tracked translator patch as a zero-context diff and made its disposable-copy preparation explicitly apply zero-context patches; the immutable pinned checkout remains untouched.
- Result: 250,208 checks, identical arm64/x86_64 hash `0x6ca6a115ecbe463e`, translated final FPSCR `0xe7911393`, ASan/UBSan Pass, patched translator 579/579, and all 10,836 real-title units regenerate and strict-FP syntax-compile.
- Classification: G6 remains In progress. Paired-lane exception aggregation, callbacks, and NI scheduler persistence remain.

### G6 translated paired-estimate state

- Added raw-float signaling-NaN classification and a paired-estimate state result that aggregates ZX, VXSQRT, and VXSNAN across both lanes, clears FI/FR on exceptional inputs, applies NI rounding, and derives FPRF from PS0.
- Updated the existing `PPC_PsRes` and `PPC_PsRsqrte` runtime helpers without changing their translator ABI. Unlike scalar enabled exceptions, paired estimates retain the hardware behavior of always writing both lanes under VE/ZE.
- Expanded the translated DOL with `{0,+inf}` `ps_res` and `{1.5,-2}` `ps_rsqrte`; runtime evidence proves the results, sticky cross-lane causes, and final PS0 classification.
- Result: 250,214 checks, identical arm64/x86_64 hash `0x1f462e0cd4bbd7cb`, translated final FPSCR `0xe7904393`, ASan/UBSan Pass, patched translator 579/579, and all 10,836 real-title units strict-FP syntax-compile.
- Classification: G6 remains In progress. Paired arithmetic/fused exception aggregation, exact comparisons, callbacks, and NI scheduler persistence remain.

### G6 exact translated comparisons

- Added an exact comparison result model: CR/FPCC unordered for NaNs, VXSNAN for signaling NaNs, ordered VXVC for qNaN, and the Broadway rule that ordered sNaN omits VXVC when VE is enabled.
- Preserved scalar `fcmpo` versus `fcmpu` in the existing compare IR and made scalar/paired code generation update FPSCR before CR. Float compares are no longer removed or branch-fused because their FPSCR side effects are architecturally observable.
- Straight-line compare fixtures exposed legitimate fallthrough labels that Clang diagnosed as unused under `-Werror`; generated local labels are now explicitly `[[maybe_unused]]`, and every one of the 10,836 title units still strict-FP syntax-compiles.
- Result: 250,220 checks, identical arm64/x86_64 hash `0x5a58605df18e5d1e`, translated final FPSCR `0xe7981393`, ASan/UBSan Pass, and patched translator 579/579.
- Classification: G6 remains In progress. Paired arithmetic/fused exception aggregation, callbacks, and NI scheduler persistence remain.

### G6 paired arithmetic exception aggregation

- Routed every paired add/sub/mul/div, fused/negative-fused, splat multiply/add, and sum inline through shared state results. Both lane exceptions accumulate with original enables restored, results always write like Broadway paired instructions, NI rounding applies per lane, and FPRF follows the hardware-selected result lane.
- Added direct state checks for VE-enabled invalid add, ZE-enabled divide-by-zero, and fused VXIMZ with a finite second lane. Expanded the translated DOL with `ps_add` of `{+inf,-inf}` and its negation under VE; both canonical NaN lanes are written and VXISI becomes sticky.
- Result: 250,227 checks, identical arm64/x86_64 hash `0xccd5757c4c0643d4`, translated final FPSCR `0xe7991393`, ASan/UBSan Pass, patched translator 579/579, and all 10,836 title units strict-FP syntax-compile.
- Classification: G6 remains In progress. Translated callback execution and NI scheduler persistence are the next semantic-boundary work.

### G6 translated scheduler/callback boundary and gate pass

- Added a production scheduled-execution bridge that copies every persisted guest CPU field into `CpuContext`, establishes `CpuContextScope`, runs translated/host code with the scheduler lock released, clears the thread-local scope, and commits the complete context before yielding.
- Extended `GuestCpuContext` through CTR/XER/GQR/system/time-base state. A two-step scheduler fixture enables VE, performs a suppressed translated invalid add, yields, verifies NI/VXISI, enables ZE, performs suppressed reciprocal zero, and exits with NI/VE/ZE/VXISI/ZX plus the original destination intact. Nested host code observes the active context; code outside the callback observes none.
- Release and ASan/UBSan scheduler suites pass with the unchanged million-operation hash `0x7287563387fb1677`. The G7 translated-frame dispatcher now establishes the same scope and its app target builds cleanly.
- G6 classification: **Pass**. The 250,227-check arm64/x86_64 differential hash is `0xccd5757c4c0643d4`; Dolphin estimates, sanitizers, patched translator 579/579, translated semantic execution, scheduled persistence, and the complete 10,836-unit PAL title surface have zero unexplained mismatches. G7 becomes the lowest unmet goal.

### G7 pinned Aurora/Dawn Metal host frame

- Resolved Aurora's declared Dawn `v20260603.191052` Darwin arm64 archive to SHA-256 `084ffd2ef500d614e443e3d494738272134628867bad3270d67ee8b0fb5f0838` and added configure-time hash enforcement.
- Built the immutable WiiCompiled-vendored Aurora source with GX enabled and Dawn's Metal backend, then linked it into the KartPad graph through public Aurora targets.
- The finite host fixture selected `BACKEND_METAL`; Dawn reported the Apple M2 Metal adapter, BGRA8 surface, and Immediate presentation mode.
- Aurora's GPU readback captured the frame-2 `GXSetCopyClear` result at 1164x960. Both captured corners are exact BGRA `56 34 12 ff`; BMP SHA-256 is `8881f050f2df9a16ce38565f8a33830fdf649a5d00268322699a7cd06e218596`.
- Host-frame portion: **Pass**. G7 remains in progress pending translated GX geometry and the first game frame.

### G7 translated GX geometry

- Expanded the generated PowerPC fixture from a four-word direct-Metal clear command to a versioned 64-byte `KPGX` payload containing a clear color and three XYZ vertices. Exact pinned-translator regeneration is required by the test.
- The translated function executes within `CpuContextScope` and writes through checked guest memory. Resolved-range stores retain address-by-address checked semantics in the fixture backend instead of exposing raw backing pointers.
- The native bridge validates the command and issues real Dolphin GX projection, matrix, vertex-format, TEV, and triangle commands. Aurora decodes the FIFO, builds the GX pipeline, Dawn submits it to Metal, and Aurora captures the presentation texture.
- The logical 640x480 GX viewport maps to the 1164x960 Retina EFB. The captured corners are exact clear BGRA `30 20 10 ff`, while the center is exact triangle BGRA `00 00 00 ff`; BMP SHA-256 is `799af319cb7bdbbc3ce6371b00d3dad1a5c47a8a14c6108f2271b0210777477e`.
- Translated-GX portion: **Pass**. The first Mario Kart Wii frame is the remaining G7 condition.

### G7 real Mario Kart Wii frame and gate pass

- Extracted the user-owned PAL WBFS into ignored private data with `nodtool 2.0.0-alpha.9`. Hash validation rejected the container at H0 block 0, so the extraction was repeated without validation; the resulting `main.dol` SHA-256 still exactly matches the independently verified input DOL.
- Ported WiiCompiled's flat 4 GiB guest mapping and cooperative `OSThread` fibers to Apple arm64. The scheduler now uses `ucontext` host fibers and preserves the existing per-thread `CpuContext`, FPSCR/NI, wait, wake, resume, termination, and deferred-delete semantics.
- Linked all 10,264 shared translated functions, initialized Revolution OS, published 2,068 FST entries from 2,037 disc files, initialized GX/VI, and entered the real game frame loop. A live sample captured `EGG::AsyncDisplay::endRender → GXCopyDisp` on the main stack and VI-retrace sleep/resume on a guest fiber.
- Packaged the ignored spike as a signed portable macOS app for GUI playtesting. Computer Use captured the Nintendo wrist-strap safety screen at 60 FPS through Aurora, pinned Dawn, and Metal. Capture SHA-256 is `3228b6044cfc746e4bf86971f1445f412e5e8a6ff3029fa8b3b620d20be087b8`.
- Added a reproducible Apple runtime patch and preparation script. Private disc, NAND, translation, caches, and application products remain ignored.
- G7 classification: **Pass**. G8 is the lowest unmet goal: advance through intro/title/menu, verify audible audio, and prove keyboard/controller navigation.

## 2026-08-28 — G8 full title graph, audio, and controller navigation

- Goal: boot the native macOS build through intro/title/menu with audible audio and working navigation.
- Translation: generated the complete PAL DOL+`StaticR.rel` graph from the user-owned disc extraction. The graph contains 29,637 translated functions; 29,065 are shared base functions and the StaticR prolog `0x8055531C` is present.
- Build failure signature: the first full shard failed on undeclared `Ppc*StateInline` helpers. Cause: KartPad's FPSCR-aware translator patch emitted the exact stateful ABI proven at G6, while the production shell still exposed older value-only helpers. The production header now adapts generated calls to KartPad's tested header-only semantic model under C++20. The changed 72-shard build linked successfully.
- Runtime result: Pass. The app loaded 4,934,832 bytes of StaticR at `0x805102E0`, ran 43 DOL and 192 REL constructors, rendered the Wii/Mario Kart intros and title, and reached Select License at 60 FPS through Metal.
- Input failure 1: title ignored the existing GameCube keyboard mapping. Trace showed the Wii KPAD HLE returned no data and WPAD declared channel 0 disconnected. Implemented a big-endian core KPAD report and connected channel-0 WPAD contract.
- Input failure 2: short Computer Use key taps were occasionally invisible to `SDL_GetKeyboardState` between guest polls. An SDL event watch now latches key-down edges until the next KPAD sample. Changed run passed: Return advanced title, Right selected Options, Left+Return opened New License, and Q/Wii Remote 1 returned.
- Audio result: Pass for G8 audibility. SDL opened 32 kHz stereo at gain 1 and received non-silent PCM (peak 3988, queue 6,372 bytes). Independent AVFoundation capture of the active system-output device measured 427,776 samples over 4.46 seconds, mean `-36.2 dB`, peak `-17.6 dB`. The temporary WAV is not retained.
- Instance discipline: no Simulator and exactly one game instance. Every rebuild followed a Computer Use close and PID check before replacement/relaunch.
- Reproducibility: `scripts/generate-g8-full-title.sh`, the refreshed `patches/wiicompiled-apple-runtime.patch`, and `scripts/prepare-g7-game-runtime.sh` capture translation/runtime preparation without publishing game data.
- Evidence: `docs/artifacts/2026-08-28/g8-title-menu/`.
- G8 classification: **Pass**. G9 is the lowest unmet goal: create an isolated license, complete a race/results/menu cycle, save, quit/relaunch, and run the staff-ghost fixture.

## 2026-08-28 — G9 first macOS race, save, and staff ghost

- Created an isolated `Player` license in the portable app NAND and preserved ignored 17-file pre-license and post-license backups.
- Initial race playtesting proved sustained Wii Remote acceleration but exposed the lack of reliable steering. Controller work was reduced against Mario Kart's byte-matching decomp headers: its historical `KPADStatus` is `0x84`, `KPADUnifiedWpadStatus` is `0x38`, and the Classic format byte is at `0x36`. The newer public SDK layout used during the first experiment was incompatible.
- Implemented the exact Classic report in both KPAD paths. The live UI changed its back glyph to Classic `B`; Return/A accelerated, A/D changed native left-stick steering, and Q/B reversed. SDL event-held taps are bounded to 500 ms and keyboard stick magnitude is scaled to 0.35 for GUI control.
- Completed a 100cc Luigi Circuit VS session through standings, the `Next Race / Quit` result menu, and Main Menu. The GUI-driven kart timed out in 12th with 0 points; this is recorded as a playtest-quality limitation, not misrepresented as a winning player run.
- Save evidence: the 2,867,200-byte `rksys.dat` changed from post-license SHA-256 `5291cecd0ae1749a7996dfd8f3bc53978a9af08fe9aaf639a831214d6bb24f42` to post-race `1e7b6a9482d01436bf5fb650528191f8b725d1a74c178bad30ccae2d10cdc529`.
- Quit the only running instance, relaunched the signed portable app, and verified `Player` remained available while the save retained the post-race hash.
- Opened the original Luigi Circuit `Nin★sato` staff ghost (`01:29.670`) and ran its replay at 60 FPS. No Simulator was booted.
- Reproducibility: refreshed `patches/wiicompiled-apple-runtime.patch` dry-runs cleanly against the pinned runtime. Exact Classic input checkpoint `d59218f` is on GitHub.
- Evidence: `docs/artifacts/2026-08-28/g9-race-save/`.
- G9 classification: **Pass**. G10 is the lowest unmet goal: complete the mandatory macOS offline compatibility matrix and close the player-lap precision limitation.

## 2026-08-28 — G10 RKG structural oracle and player-fixture investigation

- Goal: establish a deterministic, locally inspectable staff-ghost input oracle before expanding the offline matrix.
- Corrected the RKG sequence-duration rule against the game's translated `KPad*ButtonsStream::readFrame`: a stored duration is `max(1, value)`, not `value + 1`. All 64 on-disc staff files now parse with equal face/direction/trick totals; the parser emits structural metadata only.
- Added a reproducible, opt-in guard to the translated PAL `KPadWiiController::calcInner` at `0x8051FC84`. With no configured/armed fixture it returns to the complete original function.
- Two identical startup crashes from an earlier duplicate native override were classified and removed. The guarded translated function then booted normally.
- A bounded probe of the game's own `KPadGhostController` proved that input begins on race stage 1 and stage 1 contains exactly 240 calls. The player fixture independently reported `stage=1 frame=0` and `stage=2 frame=240`.
- Native output verified the first direction expansion directly: `0x8e` for four calls before the next sequence. The corrected decoder matches it.
- Configuration errors were separately falsified: Luigi Circuit regular staff vehicle ID `0x10` is Sprinter, not Standard Kart M, and is locked on the fresh license. Later tests used selectable Shell Cup staff configurations and verified each character/vehicle label in the live UI.
- The regular N64 Mario Raceway file (`Baby Mario`, PAL `Nanobike`/Bit Bike, Manual) followed the racing line through a complete first lap and entered lap 2, then diverged later. The countdown cadence remained exact. Forcing the Wii slot's control-source field to `GHOST` raised the expected controller-interrupted dialog and was reverted.
- Classification: **Inconclusive diagnostic, not Pass.** The player-injection harness is not the native ghost product path and does not satisfy a G10 row. The native Luigi Circuit staff replay established in G9 remains healthy.
- Reproducibility: refreshed `patches/wiicompiled-apple-runtime.patch` dry-runs against the pinned runtime; `scripts/inspect-mkw-rkg.py --self-test` and the repository safety audit pass.
- Evidence: `docs/artifacts/2026-08-28/g10-offline/`.
- Next step: run independent native G10 rows—original tracks/cups, Grand Prix/VS/Battle/Time Trial, local multiplayer, controller slots, audio, and save behavior—while retaining the fixture only as a diagnostic tool.

## 2026-08-29 — G10 native N64 Mario Raceway ghost divergence

- Ran the final signed native arm64 product path with no configured RKG fixture and no player injection. Through the original Time Trials UI, selected Shell Cup → N64 Mario Raceway → regular staff ghost `Nin★Ichiro 02:14.799` → Watch Replay.
- Native result: **Fail.** The replay began on the expected line at 59.7–59.9 FPS, later moved off course, and was still running well beyond the recorded `02:14.799` duration. This is the game's own `KPadGhostController` path, so it falsifies the earlier working assumption that divergence was confined to the diagnostic live-player injector.
- Oracle comparison: launched the exact pinned Dolphin 5.0-17995 with an isolated user directory and the same read-only WBFS. The identical ghost held 60 FPS/VPS at 100%, stayed on the racing line at the recorded checkpoints, completed, and automatically restarted its replay loop.
- Classification: genuine P1 G10 native translated-runtime determinism defect. The comparison isolates the execution runtime from the WBFS, staff file, and expected finish behavior, but does not yet attribute the cause to PPC semantics, scheduler timing, HLE state, or physics integration. G6 is not reopened without that attribution.
- Reproduction count: native failure 1/1; pinned-Dolphin pass 1/1. The next run must add bounded state tracing rather than repeat the unchanged visual test.
- Instance discipline: exactly one game process ran at a time. KartPad was closed before Dolphin launched; Dolphin emulation was stopped before its app closed. The isolated controller's temporary `Always Connected` option was restored to off. No Simulator was booted.
- Evidence: `docs/artifacts/2026-08-28/g10-native-n64-mario/`.
- Next step: capture a deterministic native per-frame kart/physics state trace and locate the earliest divergent state transition against a known-good execution.

### Correction — full-frame comparison disproved the visual failure

- Added a read-only, opt-in native frame-end trace covering position, external/internal velocity, main rotation, internal speed, movement direction, race stage, and race timer. No controller or guest state was modified.
- The native run completed race stage 2 at timer transition `8319 → 8320`, entered finish stage 4, returned to stage 0, and began another replay. Its longest race segment is `240..8319`, exactly 8,080 frames; the initial wall-clock observation had crossed into the automatic second loop.
- Captured the same guest addresses using pinned Dolphin's built-in frame-end MemoryWatcher. Dolphin produced the identical `240..8319` segment.
- `scripts/compare-mkw-state-traces.py` compared 17 raw state words at every common frame: 8,080 frames, 137,360 word comparisons, **zero mismatches**.
- Corrected classification: **Pass.** The earlier P1 entry above is retained as an audit trail but is superseded. There is no observed native N64 Mario staff-replay divergence and no basis to reopen G6.
- During Dolphin controller recovery, a stopped Dolphin frontend remained open when a new emulation process started. The PID check caught and closed that frontend before play continued; only one game emulation was active. The isolated `Always Connected` option was restored to off, all Dolphin/KartPad processes were closed, and no Simulator was booted.
- Evidence: `docs/artifacts/2026-08-28/g10-native-n64-mario/state-trace-comparison.txt`.
- Next step: resume the independent G10 offline compatibility matrix. Visual elapsed-time inference is no longer an accepted ghost-timing oracle.

## 2026-08-29 — G10 representative Balloon Battle

- Ran the normal signed arm64 product path with no diagnostic environment and selected Single Player → Battle → Balloon Battle → Block Plaza.
- Configuration: 6-v-6 teams, Mario, Standard Kart M, Manual drift. Block Plaza loaded through its arena intro and the three-minute match ran to completion with all 12 racers.
- Observed active scoring, minimap state, AI movement, item effects, ink, balloon loss, acceleration, steering, and player position change. Final team score was red 9, blue 13.
- Result flow passed: the complete result table appeared, followed by `Next Battle / Quit`; Quit returned cleanly to Main Menu.
- Renderer labels around GUI interaction/capture ranged from 43.2 to 60.0 FPS. This is recorded, not rounded into a cadence claim; G11 requires its dedicated deterministic performance method.
- Classification: **Partial Pass for PRD row 27.** The required representative full Balloon Battle completes. Block Plaza is one of ten arenas proven to boot; the remaining nine arena boots are still required.
- Instance discipline: exactly one KartPad game process, no Dolphin, and no Simulator. The app was closed before documenting the row.
- Evidence: `docs/artifacts/2026-08-29/g10-balloon-battle/`.
- Next step: boot the remaining nine Balloon Battle arenas without repeating the unchanged full-match run.

## 2026-08-29 — G10 Balloon Battle all-arena completion

- Continued the same normal signed arm64 product path with no diagnostic environment and no Simulator.
- Booted the remaining nine retail Balloon Battle arenas through the normal Single Player UI: Delfino Pier, Funky Stadium, Chain Chomp Roulette, Thwomp Desert, SNES Battle Course 4, GBA Battle Course 3, N64 Skyscraper, GCN Cookie Land, and DS Twilight House.
- Each arena reached its intro or active-match presentation with environment, HUD, player kart, and opponents visible. Each boot-only check exited through Pause → Quit and returned cleanly to Main Menu before the next selection.
- Together with the completed Block Plaza match, this covers all ten retail arenas and the representative full-match requirement.
- Classification: **Pass for PRD row 27.** No second full match is required without a changed variable.
- Instance discipline: exactly one KartPad process throughout, no Dolphin, and no Simulator.
- Evidence: `docs/artifacts/2026-08-29/g10-balloon-battle/`.
- Next step: continue the lowest unmet G10 compatibility rows outside Balloon Battle.

## 2026-08-29 — G10 Coin Runners all-arena completion

- Ran the normal signed arm64 product path with no diagnostic environment and selected Single Player → Battle → Coin Runners.
- Configuration: 6-v-6 teams, Mario, Standard Kart M, Manual drift. Block Plaza ran through two complete three-minute matches with all 12 racers, changing team totals, individual coin totals, coins, items, AI, minimap activity, acceleration, and steering visible.
- The first match exercised the default next-match path. The second produced a clean full result table: red 40, blue 66, followed by the team outcome and clean return to Main Menu.
- Booted the other nine retail arenas through the normal UI: Delfino Pier, Funky Stadium, Chain Chomp Roulette, Thwomp Desert, SNES Battle Course 4, GBA Battle Course 3, N64 Skyscraper, GCN Cookie Land, and DS Twilight House.
- Each boot-only check reached countdown or active match with the Coin Runners HUD, coins, item boxes, player kart, and opponents visible, then exited through Pause → Quit.
- Classification: **Pass for PRD row 28.** Every arena boots and the representative full match completes.
- Instance discipline: exactly one KartPad process throughout, no Dolphin, and no booted Simulator.
- Evidence: `docs/artifacts/2026-08-29/g10-coin-runners/`.
- Next step: continue the remaining G10 track/cup/mode/local-multiplayer/controller/audio/save rows.

## 2026-08-29 — G10 explicit GameCube adapter limitation

- Audited the public Darwin product graph and adapter contract. macOS deliberately selects `src/apple/wup028_adapter_stub.cpp`; discovery/read/rumble report no active adapter and game-port assignments remain unclaimed.
- The product therefore does not advertise or silently attempt WUP-028 raw USB support. `docs/PORTABILITY.md` already identifies a separate macOS backend or explicit limitation as the portability requirement.
- Classification: **Pass for PRD row 32 by explicit limitation.** A physical adapter pass is not claimed. Ordinary SDL/GameController assignment and reconnect remain separate mandatory rows.
- Evidence: `docs/artifacts/2026-08-29/g10-gamecube-adapter.md`.
- Next step: continue the remaining G10 track/cup/mode/local-multiplayer/ordinary-controller/audio/save rows.

## 2026-08-29 — G10 four keyboard-backed controller slots

- Root cause: WPAD/KPAD hard-coded channel 0 as the only connected device; channels 1–3 always returned no controller or no samples, blocking local multiplayer.
- Implemented independent keyboard-backed Classic reports for all four channels, per-channel pending/previous state, connection-aware WPAD probe/info/LED/data-format behavior, and explicit P2–P4 connect/disconnect bindings.
- The retail four-player registration UI assigned yellow/P1, blue/P2, red/P3, and green/P4 controllers. P2 independently selected Luigi/Standard Kart M and accelerated/steered in live two-player Luigi Circuit.
- Sent a P3 A edge immediately before disconnect. The game raised the correct red/P3 interruption dialog. Reconnect restored four assignments and remained stable beyond the synthetic hold interval, proving stale held state was cleared.
- Increased keyboard stick magnitude from 0.35 to the full normalized range after the first split-screen driving pass showed insufficient recovery authority off road.
- The signed arm64 product rebuilds and launches; the refreshed public runtime patch dry-runs against the pinned source.
- Classification: **Pass for PRD row 31.** Full two-player and three/four-player race completion remain rows 29–30 and are not claimed here.
- Evidence: `docs/artifacts/2026-08-29/g10-controller-slots/`.
- Next step: complete the two-player and three/four-player split-screen race rows with the new channel implementation.

## 2026-08-29 — G10 items, AI, and collisions cross-evidence

- Audited the accepted native full-session evidence instead of repeating an unchanged fixture.
- Balloon Battle completed multiple 12-racer matches with active AI, item boxes/effects, Blooper ink, balloon loss, collisions, scoring, minimap activity, results, and clean exits.
- Coin Runners completed two 12-racer matches with coins, items, AI, collisions, changing team/individual totals, results, and clean exit. The Bowser/Automatic changed-variable match added another complete item/collision session.
- The earlier 100cc Luigi Circuit VS run independently completed a 12-racer item/AI race through standings and menu transition.
- Classification: **Pass for PRD row 25.** Heavy 12-racer item fixtures complete correctly without an observed P0/P1 defect.
- Evidence index: `docs/artifacts/2026-08-29/g10-items-ai-collisions.md`.
- Next step: continue the remaining G10 track/cup/mode/local-multiplayer/controller/audio/save rows.

## 2026-08-29 — G10 keyboard fallback race calibration

- A native two-player Luigi Circuit playtest exposed that `Return` must remain a short synthetic pulse for menu safety, which also made it a poor held accelerator during a race. Added `U` as a gameplay A/accelerator alias with the existing 500 ms synthetic hold and `M` as the matching gameplay B/reverse alias; `Return`/`Backspace` retain their short menu behavior.
- Repeated changed runs proved sustained forward acceleration, sustained reverse recovery, independent P2 input, item acquisition, AI traffic, stable 60 FPS presentation, and clean split-screen rendering. The first high-speed runs also showed that full-scale keyboard steering crossed a lane in only a few GUI-generated samples, so the fallback stick magnitude returned to the previously validated `0.35` calibration. Physical/touch analog sources are not changed by this keyboard-only scale.
- The affected runtime target rebuilt and the signed app passed strict code-sign verification after each calibration. These runs are diagnostic input evidence only: no complete two-player results screen was reached, so PRD row 29 remains open.
- Next step: complete the two-player results cycle with the calibrated fallback, then repeat the three/four-player full-race rows before advancing G10.

## 2026-08-29 — G10 representative vehicles, weights, and drift modes

- Completed a three-minute native Balloon Battle as Bowser on Standard Bike L with Automatic drift. The kart accelerated and steered, changed position, collided, received ink/item effects, participated in live scoring with 12 racers, reached the full result table, and returned cleanly to Main Menu.
- Combined that changed-variable run with existing accepted native evidence: Mario on Standard Kart M with Manual drift completed both Battle modes, and the Baby Mario Bit Bike/Nanobike Manual official staff replay completed bit-exactly against Dolphin on N64 Mario Raceway.
- The three configurations cover light/medium/heavy characters, kart and bike vehicle families, and Manual/Automatic drift through completed native sessions.
- Classification: **Pass for PRD row 24.** This is representative coverage; it does not claim every individual unlock as separately completed.
- Instance discipline: exactly one KartPad process, no Dolphin, and no booted Simulator.
- Evidence: `docs/artifacts/2026-08-29/g10-vehicle-character-drift/` plus the linked accepted G10 evidence directories.
- Next step: continue the remaining G10 track/cup/mode/local-multiplayer/controller/audio/save rows.

## 2026-08-29 — G10 forced-exit save safety

- Began from the stable Main Menu after the completed Battle matrix and made an ignored local recovery copy of the live 2,867,200-byte `rksys.dat`.
- The live save and recovery copy both hashed to `c5a5108cd3184d4b6e8ca55c4fdd768afd08638c99fcb98695757a5f3a58d1d6`.
- Resolved exactly one KartPad PID (23422), terminated that exact process with `SIGKILL`, and confirmed the live save was still byte-identical immediately afterward.
- Relaunched the signed product normally as exactly one new process (PID 26767). Select License displayed the existing `Player` license and progress grid without a damaged slot or recovery warning.
- The post-relaunch save remained byte-identical to the recovery copy with the same SHA-256.
- Classification: **Pass for PRD row 20 at a stable Main Menu boundary.** No unrelated save corruption was observed and the application recovered normally.
- No Dolphin and no booted Simulator were present. The ignored recovery copy remains under `private/g10-forced-exit/`.
- Evidence: `docs/artifacts/2026-08-29/g10-forced-exit-save/`.
- Next step: continue the remaining G10 track/cup/mode/local-multiplayer/controller/audio/save rows.

## 2026-08-29 — G10 two-player completion diagnostics

- Ran repeated native two-player Luigi Circuit fixtures with one KartPad process, no Dolphin, and no booted Simulator. P1 and P2 independently accelerated and steered; stable split-screen rendering, AI traffic, item activity, and 60 FPS presentation remained visible.
- A long parked-player run did not reach results even after the AI field circulated for more than ten minutes. Advancing P1 partway through the opening section did not satisfy the timeout condition, so no completion claim is made.
- Built Wiimm's ISO Tool locally as an ignored x86_64/Rosetta utility and enumerated the read-only WBFS. The disc contains both complete Nintendo staff-ghost sets. Disc-derived RKG files remain private and ignored.
- Tightened the opt-in RKG diagnostic with `KARTPAD_RKG_AUTOSTART=1`: it now arms only when `RaceManager` enters the countdown and leaves menu/intro controller handling untouched. The signed product reached the two-player countdown without the earlier interruption.
- The regular N64 Mario Raceway staff input was matched to Baby Mario, Nanobike, and Manual drift. Its Time Trial line still diverged immediately from the rear/outside VS starting slot, proving the different grid origin is material.
- Investigated the game's retail CPU controller path. Reclassifying local player 0 as CPU before and after the menu-to-race scenario copy each produced a reproducible scene-transition `EXC_BAD_ACCESS`; the entire CPU-player experiment was removed, the environment was cleared, and the stable full-title product was rebuilt and strictly code-sign verified.
- Classification: **Diagnostic only.** PRD row 29 remains open because no two-player standings/result cycle has completed.
- Evidence: `docs/artifacts/2026-08-29/g10-two-player-race/`.
- Next step: pursue a normal retail completion path that preserves local-player ownership, then repeat the three/four-player full-race row.

## 2026-08-29 — G10 normal two-player race completion

- Root cause of the apparently unresponsive manual runs: the GUI launch helper retained obsolete `KARTPAD_RKG_AUTOSTART` and `KARTPAD_RKG_INPUT` values after the parent environment was cleared. Renamed the opt-in diagnostic variables to `_V2`; the stale names are inert in the candidate.
- Tightened GUI keyboard steering independently of physical/touch analog sources: stick pulses are 120 ms at 0.22 normalized magnitude, while gameplay acceleration/reverse retain 500 ms holds and menu-safe keys retain 80 ms pulses.
- Rebuilt, copied, ad-hoc signed, and strictly verified the native arm64 app. The public runtime patch dry-ran cleanly against the pinned WiiCompiled source.
- Normal retail setup: two independently registered Classic channels, Mario and Luigi in Standard Kart M with Automatic drift, 100cc VS Solo Race on Luigi Circuit. P1 completed all three laps through live `U`/`M`/`A`/`D` input; P2 stayed independently connected in the lower pane.
- Both panes reached the retail `FINISH!` transition. The complete standings table followed with Mario 11th/1 point and Luigi 12th/0 points. The active process was the sole KartPad instance; no Dolphin and no Simulator were present.
- The process still exposed only the obsolete pre-rename diagnostic names inherited by the helper. No `_V2` variables were set and the complete console log contained zero `[input-fixture]` entries, proving the completion was not the RKG diagnostic path.
- Focused interaction/captures repeatedly displayed 59.5–60.1 FPS, including 60.0 at finish and standings. This passes the functional two-player cadence observation; G11 retains the separate p99/worst-case qualification.
- Classification: **Pass for PRD row 29.** Evidence and hashes are under `docs/artifacts/2026-08-29/g10-two-player-race/`.
- Next step: complete PRD row 30 with normal three-player and four-player split-screen races, then continue the remaining G10 matrix.

## 2026-08-29 — G10 three-player cadence and keyboard precision calibration

- Confirmed the original retail cadence from the Dolphin Mario Kart Wii oracle: three- and four-player split-screen are intentionally locked to 30 FPS. The native three-player Luigi Circuit gameplay overlay repeatedly reported 29.5–30.1 FPS while menus remained 59.8–60.1 FPS, preserving the mode transition instead of forcing a universal 60 FPS rate.
- Registered three independent Classic channels and repeatedly entered a normal 100cc VS Solo Race with Mario, Luigi, and Yoshi. All three panes rendered independently with AI, items, minimap state, and per-player HUDs active. No Simulator or Dolphin process was running.
- Hands-on steering exposed a GUI-keyboard-specific problem: the previous 0.22 stick magnitude and 120 ms synthetic hold crossed the narrow three-player pane's racing line in only a few generated samples. Reduced the synthetic stick hold to 50 ms and measured 0.12, 0.08, and 0.02 keyboard-only candidates. The 0.08 candidate entered the first curve cleanly; 0.02 could not generate enough steering rate before leaving the surface, so 0.08 is retained. Physical controller input, game physics, and future touch analog input are unchanged.
- Every candidate rebuilt, copied into the app, ad-hoc signed, passed strict signature verification, passed the repository safety audit, and retained a public patch that dry-runs against the pinned WiiCompiled source. Checkpoints `332a6d8`, `3fecc82`, and `ef01110` are on `origin/main`.
- Classification: **In progress for PRD row 30.** Three-player registration, independent panes, and verified original cadence pass, but no complete three-player standings cycle has been accepted yet; four-player full-race evidence is also still open.
- Next step: complete a normal three-player race with the precision candidate, repeat four-player at the same verified 30 FPS cadence, then archive finish/standings/log evidence.

## 2026-08-29 — G10 repeated-race camera lifecycle repair

- Reproduced a deterministic three-player lifecycle crash three times with the normal race → Pause/Quit → Main Menu → second race sequence. Every macOS report was `EXC_BAD_ACCESS` in translated guest function `func_805A2034`.
- Focused guest-state instrumentation found a reclaimed race-camera node still linked after scene teardown. Its player slot was `0xff`; the retail update treated that as `-1` and selected the reclaimed-memory sentinel immediately before the kart-object array.
- Added a strict, idempotent generation-time injector for the shared camera-list walker. It removes reclaimed camera nodes with the retail intrusive-list layout, maintains head/tail/count, clears the node links, and resumes the current traversal. Temporary diagnostic traces and the superseded narrow guard are absent from the candidate.
- Regenerated all 72 stable shards, rebuilt, signed, and strictly verified the arm64 app. A fresh single-process run completed the exact failing sequence and reached live three-pane gameplay in the second race without a crash or process relaunch.
- A simultaneous unrelated eight-worker LLVM translation invalidated the later overlay as cadence evidence and was left untouched. A clean-load 29.5–30.1 FPS observation already establishes the retail three-player mode; uncontended resampling and complete three-/four-player standings cycles remain open.
- Classification: **Pass for the repeated-race camera lifecycle defect; PRD row 30 remains in progress.** Evidence: `docs/artifacts/2026-08-29/g10-three-player-camera-lifecycle.md`.
- Next step: checkpoint the reproducible repair, re-sample after host contention clears, and complete the normal three- and four-player race rows.

## 2026-08-29 — G10 audio continuity telemetry

- Audited 83 native logs containing successful non-silent host playback. Fifty-eight older diagnostic runs contained the deliberately one-shot `output queue full` message, which could not distinguish one startup/load burst from sustained loss.
- Confirmed from the SDL 3 default-device contract that a stream opened on `SDL_AUDIO_DEVICE_DEFAULT_PLAYBACK` may migrate automatically when the system default changes; the migration still requires a hands-on KartPad test.
- Added content-free cumulative queue telemetry to the reproducible Apple runtime patch: checks, post-start empty observations, dropped blocks/bytes, submitted bytes, depth range/current depth, and queue limit. Queuing and timing behavior are unchanged.
- The first signed arm64 sample ran for approximately six minutes with 104,960 checks, 40,304,256 submitted bytes, zero post-start empty observations, zero dropped blocks, and a 0–14,796-byte observed range below the 15,360-byte limit.
- Reduced reporting from the fast diagnostic cadence to one report per 8,192 checks (about 30 seconds at the observed rate) plus orderly shutdown, keeping diagnostics bounded. This final cadence still needs its own runtime sample.
- Classification: **In progress for PRD row 33.** Uncontended queue continuity is healthy; final-cadence, gameplay/pause, device-change, and long-session evidence remain open. Evidence: `docs/artifacts/2026-08-29/g10-audio-queue-telemetry.md`.
- Next step: rebuild the bounded candidate, collect a fresh sample when host contention clears, then combine it with the three-player race and audio-transition playtest.

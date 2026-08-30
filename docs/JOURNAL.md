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
- Reduced reporting from the fast diagnostic cadence to one report per 8,192 checks (about 30 seconds at the observed rate) plus orderly shutdown, keeping diagnostics bounded. A fresh signed-app smoke run reported exactly at 8,192 and 16,384 checks with zero empty observations or drops. The simultaneous unrelated compilation makes this instrumentation evidence rather than a cadence claim.
- Added `scripts/summarize-audio-queue.py`, a strict content-free telemetry parser with JSON output, monotonic/range checks, `--require-clean`, and a synthetic self-test. It accepts the clean uncontended log and correctly rejects both load-contended runs once their cumulative drop count becomes nonzero.
- Classification: **In progress for PRD row 33.** Bounded telemetry and uncontended queue continuity are healthy; gameplay/pause, device-change, and long-session evidence remain open. Evidence: `docs/artifacts/2026-08-29/g10-audio-queue-telemetry.md`.
- Next step: combine the telemetry with the three-player race and audio-transition playtest after host contention clears.

## 2026-08-29 — G10 retail-course oracle preflight

- Parked the live three-player cadence run when eight unrelated `dolrecomp` workers saturated the host; observed 13–18 FPS and audio drops are explicitly rejected as product-performance evidence. The sole KartPad process was returned to Main Menu and closed cleanly. No Simulator was booted.
- Extended the content-free RKG inspector with `--require-course-matrix`. It now rejects missing or duplicate course IDs, unexpected IDs, mismatched face/direction/trick frame counts, empty times, and empty input payloads.
- The data-free self-test covers a valid 32-course matrix and three invalid variants. A one-file negative test exits 1, and the repository safety audit passes.
- Both private disc-derived staff sets pass the strict matrix: 32 files and exactly one input for every retail course ID `0..31`. No RKG payload or other private game content enters the publishable tree.
- Classification: **Preparation pass, not PRD row 22 acceptance.** The complete native per-track execution matrix remains open. Evidence: `docs/artifacts/2026-08-29/g10-retail-course-oracle.md`.
- Next step: use the validated oracle inventory to drive bounded native course-completion checks while returning to the three-/four-player row after unrelated host contention clears.

### Native completion assertion

- Added `scripts/summarize-mkw-state-trace.py` so row 22 runs can be accepted from guest state rather than screenshots or elapsed wall time. It validates the complete CSV schema, monotonic sample/retrace values, consecutive race-stage timing, a later finish-stage transition, and an optional exact RKG input-frame count.
- The data-free self-test rejects an unfinished race and two incorrect frame counts. The retained private N64 Mario Raceway native trace passes at the exact 8,320-frame staff input: race stage 2 covers `240..8319` for 8,080 samples and is followed by finish stage 4. The same trace correctly fails when asked for 8,319 input frames.
- Classification remains **preparation pass, not row 22 acceptance**. This creates the strict native assertion that each remaining track run must satisfy.

## 2026-08-29 — G10 Moo Moo Meadows exact native completion

- Started the retail Time Trials → Mushroom Cup → Moo Moo Meadows → `Nin★YuNya 01:37.856` → Watch Replay path in the sole native arm64 KartPad process. No Dolphin or Simulator was running.
- First attempt failure signature: the replay visibly reached its finish animation, but startup had logged `[state-trace] unable to open .../private/g10-track-matrix/moo-moo-native.csv` because the absolute parent directory did not exist. No trace was captured, so the visual run is rejected rather than rounded up to Pass.
- Created the exact ignored output directory and reran through the same retail path. The private trace SHA-256 is `b61dc910a085a09c0e62c252a9cd516223cde46d6fb175ce201b8154f719b572`.
- `scripts/summarize-mkw-state-trace.py --require-complete --expected-input-frames 6106` passes: race stage 2 covers exactly `240..6105` for 5,866 samples, followed by finish stage 4. A later partial segment is the retail automatic replay loop and is not mistaken for the accepted run.
- Eight unrelated `dolrecomp` workers remained active. Overlay and audio data from this run are rejected as performance/audio evidence; only exact guest-stage completion is accepted.
- Combined with the accepted Luigi Circuit live races and exact N64 Mario Raceway staff trace, PRD row 22 is now **3/32 Pass, 29 Open**. Evidence: `docs/artifacts/2026-08-29/g10-retail-tracks/README.md`.
- Next step: continue native exact completion on the remaining initially available cups, then obtain honest progression coverage for the locked cups without treating an unlock bypass as progression evidence.

## 2026-08-29 — G10 three-player camera lifecycle correction

- A later repeat-race failure invalidated the broad `playerId == 0xff` camera-reclamation premise. Retail three-player mode legitimately uses a non-player slot-`0xff` overview camera for its fourth pane; removing it left `RaceCameraMgr::sortedCameras` pointing into reclaimed scene-heap memory.
- Failure signature: `EXC_BAD_ACCESS` in `ScnMgrRace::vf_0xC`, reading through `0x55440003 + 8`, after a three-player race → quit → second-race sequence. A temporary scene-manager guard avoided the crash but exposed the second race as black except for HUD labels, so it was rejected and removed.
- Narrowed the generated camera-list guard to require both slot `0xff` and the observed leading scene-heap poison `0x55440003`. This preserves the legitimate overview camera and removes only the stale reclaimed node.
- Fixed clean regeneration on Apple by reapplying `_kData_*` Mach-O aliases after `generate-data-init` rewrites the blob assembly. Regenerated all 29,637 functions and 72 stable shards, rebuilt, copied, signed, and strictly verified candidate SHA-256 `3d15b8dade09679c0cdc78dd6a40304f28d3888e0fb2471da365e32bc9b6d16f`.
- Exact playtest passed in one PID: first three-player Luigi Circuit race rendered three player panes plus the overview pane, Pause/Quit returned to Main Menu, and the second race again reached live lap-one gameplay with all four panes intact. No Dolphin or booted Simulator was present.
- A separately retained crash report was later matched to this defect: its protected guest access was `0x55440027`, exactly the `0x55440003` reclaimed-scene sentinel plus 36 bytes, and its stack again entered `func_805A2034`. Its UUID identifies the earlier dynamic/Homebrew-linked development binary, not the corrected build or static package candidate. The report is recorded as corroborating pre-fix evidence rather than a current regression.
- The private 267-line PID 48089 log contains two retail `Scene Restart` records and no temporary `scnmgr-lifecycle` trace; its SHA-256 is `9085cef84e023f061e3d1e9ce325ddb8db2bd3a2a1a1a2724efdf4d2ac31ac47`. The public runtime patch dry-runs against the pinned WiiCompiled runtime; the repository safety audit, Python compile check, injector idempotence check, and `git diff --check` pass. Capture-time 14.8–19.8 FPS overlays and 18 audio drops are rejected as cadence/audio evidence.
- Post-run strict signature verification correctly failed because Dawn mutated `UserData/Cache/dawn_cache.db-shm` inside the sealed bundle. The playtested executable itself retained SHA-256 `3d15b8...`; re-sealing restored strict verification and produced signature-different executable SHA-256 `f6b40a...`. Writable runtime state inside the signed bundle is now an explicit G13 packaging risk.
- Classification: **Pass for the corrected repeated-race lifecycle defect; PRD row 30 remains in progress.** Complete three- and four-player standings cycles remain open.

## 2026-08-29 — G10 Mushroom Gorge exact native completion

- Started the retail Time Trials → Mushroom Cup → Mushroom Gorge → `Nin★Murak 02:16.110` → Watch Replay path in the sole native arm64 KartPad process. No Dolphin or Simulator was running.
- The official regular staff file reports course ID 2 and exactly 8,399 face/direction/trick frames. The ignored native trace SHA-256 is `e20883a2ca6cdfda1bb1f3da75535b852006a44ac87b833c46787ceea88277e4`; the playtested executable SHA-256 is `f6b40a3902ac5ba559d359c5b1cb5488176ebf14bc8eab3da1371c1fd146f9fc`.
- `scripts/summarize-mkw-state-trace.py --require-complete --expected-input-frames 8399` passes: race stage 2 covers exactly `240..8398` for 8,159 samples, followed by finish stage 4. A later partial segment is the retail automatic replay loop and is not mistaken for the accepted run.
- The focused UI observations held at 60.0 FPS, but only exact guest-stage completion is accepted from this run. The already recorded writable-cache bundle-seal issue recurred after execution and remains a G13 packaging risk.
- Combined with Luigi Circuit, Moo Moo Meadows, and N64 Mario Raceway, PRD row 22 is now **4/32 Pass, 28 Open**.
- Next step: continue the exact initially available retail track matrix with Toad's Factory, then progress into available Flower Cup tracks.

## 2026-08-29 — G10 Toad's Factory exact native completion

- Ran the retail Time Trials → Mushroom Cup → Toad's Factory → `Nin★Misa 02:22.480` → Watch Replay path in the sole native arm64 KartPad process. No Dolphin or Simulator was running.
- The regular staff file reports course ID 4 and exactly 8,781 frames. `scripts/summarize-mkw-state-trace.py --require-complete --expected-input-frames 8781` passes: stage 2 covers `240..8780` for 8,541 consecutive samples, followed by stage 4.
- The private trace SHA-256 is `259abe8ae52bf1a54b069ded79fbd41cf816fd82dde2fea45a546254d6a58495`; the exact executable SHA-256 is `3927307a33dd9cac30237906489b4423fd7a11ba4ccc3d81f54efbd15281b5d6`.
- Harness failure signature: the persistent GUI launch helper retained the preceding trace environment and wrote the Toad's Factory run over the ignored Mushroom Gorge filename. The exact contents passed before and after relocating them to `toads-factory-native.csv`. The prior Mushroom Gorge summary/hash remain recorded; future traces will launch with a fresh per-process environment and its convenience copy will be regenerated.
- PRD row 22 is now **5/32 Pass, 27 Open**. Next step: make trace-path selection process-local, falsify it with a fresh Mushroom Gorge regeneration, then continue Flower Cup.

### Process-local trace launcher regression

- Added `scripts/launch-g10-traced-runtime.sh` so each trace path is exported only in the runtime process that consumes it. It refuses a relative path, an existing output, a missing parent/runtime, and a second active KartPad process.
- Static syntax, usage, relative-path, existing-output, repository-safety, and diff checks pass. A real direct launch immediately created only the requested `mushroom-gorge-native.csv` and remained the sole game process.
- Repeated the official Mushroom Gorge Watch Replay path. The new private trace SHA-256 is `5aa1026555f10dc683c68fb80476ad077a641e4ab30669f50bebdbb43d3419b5`; the strict 8,399-frame assertion again passes with stage 2 exactly `240..8398` followed by stage 4.
- Classification: **Pass for process-local trace routing and restored Mushroom Gorge convenience evidence.** Capture-time FPS/audio were variable under host load and remain rejected from this harness regression.

## 2026-08-29 — G10 Mario Circuit exact native completion

- Used the process-local trace launcher for the retail Time Trials → Flower Cup → Mario Circuit → `Nin★==Kony 01:44.777` → Watch Replay path. Exactly one native KartPad process ran; no Dolphin or Simulator was present.
- The regular staff file reports course ID 0 and 6,521 frames. `scripts/summarize-mkw-state-trace.py --require-complete --expected-input-frames 6521` passes: stage 2 is exactly `240..6520` for 6,281 consecutive samples, followed by stage 4.
- The private trace SHA-256 is `621ffc9cb573aba276b1c51daa6a2a532970811331f38e999c14fe3f99ec6307`; the exact executable SHA-256 is `bc953f9e6642190a3bfe226558f69f1abfaed4416aeb1c9b7645caccc215ec82`.
- Capture-time FPS and audio drops under current host load are rejected. PRD row 22 is now **6/32 Pass, 26 Open**; Coconut Mall is the next available Flower Cup trace.

## 2026-08-29 — G10 Coconut Mall exact native completion

- Used the process-local trace launcher for Time Trials → Flower Cup → Coconut Mall → `Nin★♪SiM0 02:30.764` → Watch Replay. Exactly one native KartPad process ran; no Dolphin or Simulator was present.
- The regular staff file reports course ID 5 and 9,277 frames. The strict assertion passes with stage 2 exactly `240..9276` for 9,037 consecutive samples, followed by stage 4.
- The private trace SHA-256 is `64de24b8985da1e190aa8835fd47890253a265612c6c0795a880244af2664272`; the exact executable SHA-256 is `1c2f73f9105d6f41a5ed617f1d22334cd0220bb011ccb010348a8da90635e069`.
- Focused observations reached 60 FPS through indoor/outdoor transitions, escalators, traffic, shadows, and reflections, but capture-time variance and audio drops under current host load are rejected from performance/audio acceptance.
- PRD row 22 is now **7/32 Pass, 25 Open**. DK Summit is the next available Flower Cup trace.

## 2026-08-29 — G10 DK Summit exact native completion

- Used the process-local trace launcher for Time Trials → Flower Cup → PAL `DK's Snowboard Cross` → `Nin★mokke 02:34.693` → Watch Replay. Exactly one native KartPad process ran; no Dolphin or Simulator was present.
- The course ID 6 regular staff replay has 9,513 frames. The strict assertion passes with stage 2 exactly `240..9512` for 9,273 samples, followed by stage 4.
- The private trace SHA-256 is `7da9713d157958270635a4e27dd8e34eabe9b6095cdc0df46df018ce9f8dafee`; the exact executable SHA-256 is `bfa5378f45b3a4eba30804d37cdcfb957f065ab34948d2ada17929d1d25e9e28`.
- Focused observations displayed 60 FPS through half-pipe, snow, ski-lift, jump, and trick sections; audio drops under host load are rejected from performance/audio acceptance.
- PRD row 22 is now **8/32 Pass, 24 Open**. Wario's Gold Mine is the last open Flower Cup track.

## 2026-08-29 — G10 Wario's Gold Mine exact native completion

- Used the process-local trace launcher for Time Trials → Flower Cup → Wario's Gold Mine → `Nin★morimo 02:19.585` → Watch Replay. Exactly one native KartPad process ran; no Dolphin or Simulator was present.
- Course ID 7 has 8,607 regular-staff frames. The strict assertion passes with stage 2 exactly `240..8606` for 8,367 consecutive samples, followed by stage 4.
- The private trace SHA-256 is `25c25abdc17a5bcbcb09d016bb2b3b6e9a6f5df2e482649cba6d0c809a08f8ba`; the exact executable SHA-256 is `86d074650e352e266c50d3fc12489fd35854b3ac35d2968062e6ee316d8ddec6`.
- Focused observations displayed 60 FPS through ravines, mine interiors, carts, steam, branching rails, and dense wood geometry; audio drops are rejected from performance/audio acceptance.
- PRD row 22 is now **9/32 Pass, 23 Open**. The full Mushroom and Flower Cup four-track subsets pass native exact completion.

## 2026-08-29 — G10 GCN Peach Beach exact native completion

- Used the process-local trace launcher for Time Trials → Shell Cup → GCN Peach Beach → `Nin★HIRO 01:34.233` → Watch Replay. Exactly one native KartPad process ran; no Dolphin or Simulator was present.
- Course ID 16 has 5,889 regular-staff frames. The strict assertion passes with stage 2 exactly `240..5888` for 5,649 consecutive samples, followed by stage 4.
- The private trace SHA-256 is `0cf22954bcaa8b59edea83c181abbff5bea735263759df13fa4f637bb9e60b85`; the exact executable SHA-256 is `334e99a89cb1b061efb7f69bf7ab912e98f5661a361869152e76588912a70403`.
- Focused observations displayed 60 FPS through beach, surf, forest, obstacles, and translucent effects; four audio drops under host load are rejected from audio acceptance.
- PRD row 22 is now **10/32 Pass, 22 Open**. Shell Cup is 1/4; DS Yoshi Falls is next.

## 2026-08-29 — G10 DS Yoshi Falls exact native completion

- Used the process-local trace launcher for Time Trials → Shell Cup → DS Yoshi Falls → `Nin★DoTak 01:16.461` → Watch Replay. Exactly one native KartPad process ran; no Dolphin or Simulator was present.
- Course ID 20 has 4,824 regular-staff frames. The strict assertion passes with stage 2 exactly `240..4823` for 4,584 consecutive samples, followed by stage 4.
- The private trace SHA-256 is `9d52cf29f84851e183c9f4e4afe72531c8229f63ee0eb3431747ba0fea2fbe71`; the exact executable SHA-256 is `ee4260df39e341dd1baecf8d74115e8f28ca770152d980a6aa635c74e59731b5`.
- The private console log SHA-256 is `112ed94e5af89eea89f56db6bed7e31d3c951d09f3df0d085f89d146d78ead4c`. Bounded audio telemetry remains clean through 81,920 checks and 31,456,896 submitted bytes with zero empty observations/drops; this supports gameplay continuity but does not complete row 33's broader scope.
- PRD row 22 is now **11/32 Pass, 21 Open**. Shell Cup is 2/4; SNES Ghost Valley 2 is next.

## 2026-08-29 — G10 SNES Ghost Valley 2 exact native completion

- Used the process-local trace launcher for Time Trials → Shell Cup → SNES Ghost Valley 2 → `Nin★YOKO. 01:06.595` → Watch Replay. Exactly one native KartPad process ran; no Dolphin or Simulator was present.
- Course ID 25 has 4,232 regular-staff frames. The strict assertion passes with stage 2 exactly `240..4231` for 3,992 consecutive samples, followed by stage 4.
- The private trace SHA-256 is `9b308f3ed729cfb8cc805e04eb2000c1ed593b9e359f5ae2fd3ed223bcf10f68`; the exact executable SHA-256 is `d3ec1cfd25df859e19ad3332bfa7a539183c2d8f54371971c8a355a09cc2b046`.
- Focused observations displayed 60 FPS through dark/fogged geometry, animated ghosts, breakaway edges, transparent driver rendering, and boosts; seven audio drops under host load are rejected.
- PRD row 22 is now **12/32 Pass, 20 Open**. Shell Cup is 3/4; the already accepted N64 Mario Raceway completes the cup matrix.

## 2026-08-29 — G10 GBA Shy Guy Beach exact native completion

- The first launch accidentally selected the local Nintendo WFC privacy-notice flow. No agreement or network action occurred; Back was ineffective, so the sole process was closed and its partial trace was moved recoverably to Trash before a fresh offline run.
- Used the process-local trace launcher for Time Trials → Banana Cup → GBA Shy Guy Beach → `Nin★Kato 01:45.568` → Watch Replay. Exactly one native KartPad process ran; no Dolphin or Simulator was present.
- Course ID 31 has 6,568 regular-staff frames. The strict assertion passes with stage 2 exactly `240..6567` for 6,328 consecutive samples, followed by stage 4.
- The accepted private trace SHA-256 is `eecd70c0084708ffe4c06766c147a55a4f448721557d246e378d32f3b5770889`; executable SHA-256 is `8dc81191800692bf03a5eb6d3d0e04348e3a73e9f7d8efeb333e06cf144eb71c`.
- Private log SHA-256 `596da9664cf1288d30f3d4b950b05066d22ae6167c0ab4d64c02556a15b17e89` is audio-clean through 106,496 checks and 40,894,080 submitted bytes with zero empty observations/drops; broader row 33 scope remains open.
- PRD row 22 is now **13/32 Pass, 19 Open**. Banana Cup is 1/4.

## 2026-08-29 — G10 GCN Waluigi Stadium exact native completion

- Used the process-local trace launcher for Time Trials → Banana Cup → GCN Waluigi Stadium → `Nin★NARI★ 02:32.882` → Watch Replay. Exactly one native KartPad process ran; no Dolphin or Simulator was present.
- Course ID 18 has 9,404 regular-staff frames. The strict assertion passes with stage 2 exactly `240..9403` for 9,164 consecutive samples, followed by stage 4; later movement was the retail automatic replay loop.
- The private trace SHA-256 is `6b2a4644bbff65de2d12ea9a3cc18b7b6845ec3bca7b8546e026cfdbb6d9caeb`; the exact executable SHA-256 is `fa86a907ca2bebbc72eec1baf02cd83f3ceb816e584e33ed3dd23926ab945545`.
- Focused observations displayed 60 FPS through the crowd, dirt, ramp, lighting, boost, and water sections. Private log SHA-256 `0b4c18b56b690eda9a5d07e9a8d9ba5e65169290171468aad45429fe539dae8d` recorded nine audio-queue drops under host load, so this run is rejected for audio-row acceptance.
- PRD row 22 is now **14/32 Pass, 18 Open**. Banana Cup is 2/4.

## 2026-08-29 — G10 DS Delfino Square exact native completion

- Used the process-local trace launcher for Time Trials → Banana Cup → DS Delfino Square → `Nin★iwaco 02:41.807` → Watch Replay. Exactly one native KartPad process ran; no Dolphin or Simulator was present.
- Course ID 23 has 9,939 regular-staff frames. The strict assertion passes with stage 2 exactly `240..9938` for 9,699 consecutive samples, followed by stage 4; the later partial segment is the retail automatic replay loop.
- The private trace SHA-256 is `9438f871a2f1490c2b989b86f938a9c12aa9cb8f727b5ba7212006f0dde1010f`; the exact executable SHA-256 is `fa86a907ca2bebbc72eec1baf02cd83f3ceb816e584e33ed3dd23926ab945545`.
- Dense town geometry, shadows, bridges, water, and transparent ghost rendering remained intact. GUI sampling observed temporary 46–53 FPS readings before recovery to 60 FPS. Private log SHA-256 `3633b262262416c59f2f915ecd463d4d6ed78e97e8adfe0d464f8b7170f141fc` recorded 25 audio drops, rejected from audio-row acceptance.
- PRD row 22 is now **15/32 Pass, 17 Open**. Banana Cup is 3/4.

## 2026-08-29 — G10 N64 Sherbet Land exact native completion

- Used the process-local trace launcher for Time Trials → Banana Cup → N64 Sherbet Land → `Nin★Sakat 02:48.651` → Watch Replay. Exactly one native KartPad process ran; no Dolphin or Simulator was present.
- Course ID 27 has 10,349 regular-staff frames. The strict assertion passes with stage 2 exactly `240..10348` for 10,109 consecutive samples, followed by stage 4; the later partial segment is the retail automatic replay loop.
- The private trace SHA-256 is `877c38399ac6eaacecb0242a6183a2f6c267d711bc54f584e1ce7770d375ddf4`; the exact executable SHA-256 is `fa86a907ca2bebbc72eec1baf02cd83f3ceb816e584e33ed3dd23926ab945545`.
- Ice, snow, reflections, penguins, and ghost transparency remained intact. GUI samples temporarily read roughly 45–54 FPS under host load. Private log SHA-256 `e08a09425dcf787670131e761000c25b23c3bb1afa90f5a2e74ef1fd9812d0af` recorded 14 audio drops, rejected from audio-row acceptance.
- PRD row 22 is now **16/32 Pass, 16 Open**. Mushroom, Flower, Shell, and Banana Cups are each 4/4.

## 2026-08-29 — G10 guarded all-cups test fixture

- The remaining four cups were retail-locked on the existing license. Closed the sole process and moved the rejected menu-only SNES Mario Circuit 3 trace recoverably to Trash; it is not completion evidence.
- Backed up the user's ignored 2,867,200-byte RKSYS save byte-for-byte at SHA-256 `4c7b8d596bbef8160ddc24255539321d39c07996c1ade0fd2aa6f90c999a6cf6` before mutation.
- Added `scripts/create-all-cups-test-fixture.py` from the pinned decomp's RKSYS/RKPD layout. It refuses in-place/existing-output writes, validates size/magic/version/stored CRC, changes only the selected GP-completion word plus CRC, and passes positive/corruption/refusal self-tests.
- The ignored private fixture changes license 0 `0x00000000` → `0xffffc000` and has SHA-256 `f09f809cb13bedb6959cf05aeb550fe7c19db2ea74fcc3cf61665d5b0b7b90ec`. The retail license loaded normally and exposed all eight cups.
- Classification: **Pass as a private row-22 test precondition only.** Representative Grand Prix and honest unlock progression remain open and cannot be claimed from this fixture. Evidence: `docs/artifacts/2026-08-29/g10-all-cups-fixture.md`.

## 2026-08-29 — G10 SNES Mario Circuit 3 exact native completion

- Used the sole native KartPad process for Time Trials → Lightning Cup → SNES Mario Circuit 3 → `Nin★iwaco 01:38.880` → Watch Replay. No Dolphin or Simulator was present.
- Course ID 24 has 6,167 regular-staff frames. The strict assertion accepts stage 2 exactly `240..6166` for 5,927 consecutive samples, followed by stage 4. A separate 74-frame unfinished segment is ignored; the later partial segment is the retail automatic replay loop.
- The private trace SHA-256 is `1cdad62c99dd8e1bcede3c14f9ceb3033a9a319902e175eda3c7c2740195fa17`; exact executable SHA-256 is `fa86a907ca2bebbc72eec1baf02cd83f3ceb816e584e33ed3dd23926ab945545`.
- Focused observations displayed 60 FPS through flat-color geometry, barriers, transparency, and boost effects. Private log SHA-256 `bcbc782c220fad8fb0850d9540d37f2eaf7f46ffcf0ff045ef069c958f55aec7` recorded 17 audio drops, rejected from audio-row acceptance.
- PRD row 22 is now **17/32 Pass, 15 Open**. Lightning Cup is 1/4.

## 2026-08-29 — G10 Daisy Circuit exact native completion

- The private all-cups fixture remained byte-identical after relaunch/quit at SHA-256 `f09f809cb13bedb6959cf05aeb550fe7c19db2ea74fcc3cf61665d5b0b7b90ec`.
- Used the sole native KartPad process for Time Trials → Star Cup → Daisy Circuit → `Nin★Toki 01:56.822` → Watch Replay. No Dolphin or Simulator was present.
- Course ID 9 has 7,243 regular-staff frames. The strict assertion accepts stage 2 exactly `240..7242` for 7,003 consecutive samples, followed by stage 4; the later partial segment is the retail automatic replay loop.
- Private trace SHA-256 is `290104ee301b0f8c45da71960186ffdb052a8b3c25d3ac97e0154f57c1444532`; exact executable SHA-256 is `fa86a907ca2bebbc72eec1baf02cd83f3ceb816e584e33ed3dd23926ab945545`.
- Harbor, tunnel, lighthouse, animated scenery, glare, and ghost transparency remained intact. Private log SHA-256 `7e9daa7f5d8e3ee47999d7f5374d2bd45a5d19049123e7fd82f0bcdb8f6f6db3` recorded 147 audio drops and is rejected from audio-row acceptance.
- PRD row 22 is now **18/32 Pass, 14 Open**. Star Cup is 1/4.

## 2026-08-29 — G10 DS Desert Hills exact native completion

- Used the sole native KartPad process for Time Trials → Leaf Cup → DS Desert Hills → `Nin★CHIA 02:10.233` → Watch Replay. No Dolphin or Simulator was present.
- Course ID 21 has 8,047 regular-staff frames. The strict assertion accepts stage 2 exactly `240..8046` for 7,807 consecutive samples, followed by stage 4; the later partial segment is the retail automatic replay loop.
- Private trace SHA-256 is `bd9a6068adbc64633df6df1f2aac92bee2cf48b5f279918bdb1e71e3e14f436e`; exact executable SHA-256 is `fa86a907ca2bebbc72eec1baf02cd83f3ceb816e584e33ed3dd23926ab945545`.
- A bounded first-use shader compile sampled at 23 FPS, then presentation recovered to 60 FPS through sand, ruins, lighting, obstacles, and ghost transparency; retained for later performance work. Private log SHA-256 `4ba00de7368798886bf0eafdd2ab99afe844871822c9ed2632b6392653e16e88` recorded 39 audio drops and is rejected from audio-row acceptance.
- PRD row 22 is now **19/32 Pass, 13 Open**. Leaf Cup is 1/4.

## 2026-08-29 — G10 GCN Mario Circuit exact native completion

- Used the sole native KartPad process for Time Trials → Leaf Cup → GCN Mario Circuit → `Nin★♪Miz 01:59.771` → Watch Replay. No Dolphin or Simulator was present.
- Course ID 17 has 7,420 regular-staff frames. The strict assertion accepts stage 2 exactly `240..7419` for 7,180 consecutive samples, followed by stage 4.
- Private trace SHA-256 is `14a6c68d222b2a59e9714cb762cee36a6aa1eae206df4b6c18ad30bcfe67cca3`; exact executable SHA-256 is `fa86a907ca2bebbc72eec1baf02cd83f3ceb816e584e33ed3dd23926ab945545`.
- An initial 19.9 FPS presentation sample recovered to 60 FPS through animated trees, chain chomp, trackside geometry, boosts, and ghost transparency; retained for performance work. Private log SHA-256 `dc90b846ac856a1f31ce5830e60501e03023c3a5a84308e03652e29ca6f6881d` recorded four audio drops and is rejected from audio-row acceptance.
- PRD row 22 is now **20/32 Pass, 12 Open**. Leaf Cup is 2/4.

## 2026-08-29 — G10 Moonview Highway exact native completion

- Used the sole native KartPad process for Time Trials → Special Cup → Moonview Highway → `Nin★KOZ★ 02:16.802` → Watch Replay. No Dolphin or Simulator was present.
- Course ID 10 has 8,440 regular-staff frames. The strict assertion accepts stage 2 exactly `240..8439` for 8,200 consecutive samples, followed by stage 4; the later partial segment is the retail automatic replay loop.
- Private trace SHA-256 is `264a3fcfec4143cbfc243585f08b0244a3a12002324aabd05dcee2c5b2b796bc`; exact executable SHA-256 is `fa86a907ca2bebbc72eec1baf02cd83f3ceb816e584e33ed3dd23926ab945545`.
- First use sampled at 1.3 FPS, recovered to ~46 FPS within 20 seconds, and later sampled at 46–54 FPS through traffic, city/rural geometry, lighting, boosts, and ghost transparency. This is retained for G11/G36 warm-cache work. Private log SHA-256 `f74ae46452cee47ce12eeec215a055282c7a7a88524e82877fa458628fe0f305` recorded 33 audio drops and is rejected from audio-row acceptance.
- PRD row 22 is now **21/32 Pass, 11 Open**. Special Cup is 1/4.

## 2026-08-29 — G10 Grumble Volcano exact native completion

- Used the sole native KartPad process for Time Trials → Star Cup → Grumble Volcano → `Nin★Gorin 02:28.237` → Watch Replay. No Dolphin or Simulator was present.
- Course ID 3 has 9,126 regular-staff frames. The strict assertion accepts stage 2 exactly `240..9125` for 8,886 consecutive samples, followed by stage 4; the later partial segment is the retail automatic replay loop.
- Private trace SHA-256 is `308e333e3ea5290a89051039df21b99ede54048c1e3f48517dfd67da3c047180`; exact executable SHA-256 is `de6e157784b6256695c54d41d193da5e90363d480835db3826501fdeecbabe2b`.
- Bounded presentation checks ranged from 39.6 to 58 FPS through lava, collapsing terrain, tunnels, particles, and ghost transparency; retained for G11/G36 performance work. Private log SHA-256 `0d936c9e0bdd409db94dfdae7d1892ab521ca1f0e567bdea9f61d55523970c89` recorded 60 audio drops and is rejected from audio-row acceptance.
- Two setup attempts were rejected before acceptance: Challenge Ghost Data never reached finish stage 4, and an over-fast menu sequence entered Nintendo WFC. Both partial traces were moved recoverably to Trash and were not counted.
- PRD row 22 is now **22/32 Pass, 10 Open**. Star Cup is 2/4.

## 2026-08-29 — G10 Dry Dry Ruins exact native completion

- Used the sole native KartPad process for Time Trials → Special Cup → Dry Dry Ruins → `Nin★Kei 02:30.949` → Watch Replay. No Dolphin or Simulator was present.
- Course ID 14 has 9,288 regular-staff frames. The strict assertion accepts stage 2 exactly `240..9287` for 9,048 consecutive samples, followed by stage 4; the later partial segment is the retail automatic replay loop.
- Private trace SHA-256 is `477275d7e1cee0f61174421e81a46403f52fde057106e4f0ee97e2b325e42cd4`; exact executable SHA-256 is `80bcfee80ecd9615efef7ad2826407cf0562858c4c8dec5936a40e4e16f2532d`.
- Bounded presentation checks stayed at the 60 FPS overlay target through exterior sand, falling columns, bats, water, boost panels, interior geometry, and ghost transparency; deterministic cadence remains G11 work. Private log SHA-256 `9e8727372b9da8b2979c4b2242977244bcb910876461d7e135febfa80b9ac8e7` recorded three audio drops and is rejected from audio-row acceptance.
- PRD row 22 is now **23/32 Pass, 9 Open**. Special Cup is 2/4.

## 2026-08-29 — G10 DS Peach Gardens exact native completion

- Used the sole native KartPad process for Time Trials → Lightning Cup → DS Peach Gardens → `Nin★Ito.y 02:34.894` → Watch Replay. No Dolphin or Simulator was present.
- Course ID 22 has 9,525 regular-staff frames. The strict assertion accepts stage 2 exactly `240..9524` for 9,285 consecutive samples, followed by stage 4; the later partial segment is the retail automatic replay loop.
- Private trace SHA-256 is `ce59ada4bc1dfe100e8e02708b34821f5fc053e131503f8e45989f79b4239f3d`; exact executable SHA-256 is `f50f860f3a3546590dc91c2f36eff9db001108c767667188e2721ba24401e26f`.
- Presentation began at the 60 FPS target and later sampled at 51.7–55 FPS through hedges, Chain Chomps, flowers, statuary, garden/castle geometry, and ghost transparency; retained for G11/G36 work.
- Private log SHA-256 `3cdc89dbad0860ca86a5bb97303c75ab528c7a43321154ba0f1410ea5096d3f3` ended at 139,264 audio-queue checks with zero drops, zero post-start empty observations, and 53,476,992 submitted bytes. This is a clean telemetry candidate, not subjective audio acceptance.
- PRD row 22 is now **24/32 Pass, 8 Open**. Lightning Cup is 2/4.

## 2026-08-29 — G10 N64 DK's Jungle Parkway exact native completion

- Used the sole native KartPad process for Time Trials → Leaf Cup → N64 DK's Jungle Parkway → `Nin★Matt 02:58.264` → Watch Replay. No Dolphin or Simulator was present.
- Course ID 29 has 10,926 regular-staff frames. The strict assertion found two exact complete loops, each accepting stage 2 `240..10925` for 10,686 consecutive samples followed by stage 4; the final partial segment is the third automatic replay loop.
- Private trace SHA-256 is `b2cc03b7651ba45a090a03f838c299c15faaa5193ddbfea3ca037affe54a2ac5`; exact executable SHA-256 is `bb5e63cd56751f8a9e5daea4e8bdecce92275278a0e7ac10b5a52507cf03c79c`.
- Bounded presentation checks ranged from 38 to 58.5 FPS through the jungle, riverboat, bridge, water, vegetation, mud, particles, and ghost transparency; retained for G11/G36. Private log SHA-256 `5e08e0d93913085faf2782b654c98853ce06897aa6288cfbe694a8692e5fb95a` recorded 30 audio drops and is rejected from audio-row acceptance.
- PRD row 22 is now **25/32 Pass, 7 Open**. Leaf Cup is 3/4.

## 2026-08-29 — G10 GBA Bowser Castle 3 exact native completion

- Used the sole native KartPad process for Time Trials → Leaf Cup → GBA Bowser Castle 3 → `Nin★Fukuda 02:58.304` → Watch Replay. No Dolphin or Simulator was present.
- Course ID 30 has 10,928 regular-staff frames. The strict assertion accepts stage 2 exactly `240..10927` for 10,688 consecutive samples, followed by stage 4; the later partial segment is the automatic replay loop.
- Private trace SHA-256 is `e4b51fb794ae3cfddf4dae4161ddfa26fb630d7c084c0906f076c4334d430e8c`; exact executable SHA-256 is `7f4d9d9a138f4b780d8fc092ac25517615bbf3df687a3eaf8183910ca319bdfb`.
- Bounded presentation checks remained at the 60 FPS overlay target through lava, moving platforms, Thwomps, ramps, particles, storm effects, and ghost transparency; deterministic cadence remains G11 work. Private log SHA-256 `12f996acb5c88a1c9cbe195e1c3c5c047c8a8fbdae2aa08bb100ffe4877c4bf4` recorded 11 audio drops and is rejected from audio-row acceptance.
- PRD row 22 is now **26/32 Pass, 6 Open**. Leaf Cup is complete at 4/4.

## 2026-08-29 — G10 Maple Treeway exact native completion

- Used the sole native KartPad process for Time Trials → Star Cup → Maple Treeway → `Nin★pico 02:58.633` → Watch Replay. No Dolphin or Simulator was present.
- Course ID 11 has 10,948 regular-staff frames. The strict assertion accepts stage 2 exactly `240..10947` for 10,708 consecutive samples, followed by stage 4; the later partial segment is the automatic replay loop.
- Private trace SHA-256 is `b36a526eef9571fa16473b9f50c5f719e0ac1b91e40e248620658d76fbdca3b4`; exact executable SHA-256 is `cdfd788a365edadecac4c2134ecd600606bbab4e55a85217e63a12df11366296`.
- Bounded presentation checks remained at the 60 FPS overlay target through foliage, leaf particles, tree interiors, branches, the net bridge, Wigglers, moving hazards, and ghost transparency; deterministic cadence remains G11 work. Private log SHA-256 `f946d86b72862b051495a17ef5ac08c6288fb1bd474e0384261e99b8d6408801` recorded eight audio drops and is rejected from audio-row acceptance.
- PRD row 22 is now **27/32 Pass, 5 Open**. Star Cup is 3/4.

## 2026-08-29 — G10 GCN DK Mountain exact native completion

- Used the sole native KartPad process for Time Trials → Lightning Cup → GCN DK Mountain → `Nin★♫msk 02:57.744` → Watch Replay. No Dolphin or Simulator was present.
- Course ID 19 has 10,894 regular-staff frames. The strict assertion accepts stage 2 exactly `240..10893` for 10,654 consecutive samples followed by stage 4. Earlier non-finishing segments include a rejected menu-only Grand Prix prelude; the later partial segment is the automatic replay loop.
- Private trace SHA-256 is `6cfad5811fd108b5d24cfad977a58edbdc679107c9d8117a36b4dcf70eb76d88`; exact executable SHA-256 is `6989b5c35f54902641be367f9f426995c12c8c8d1eb1fa4722ef9d5a91f82ace`.
- Focused presentation checks sampled at 49–51 FPS through the cannon flight, mountain switchbacks, bridge, vegetation, dust, jumps, moving hazards, and ghost transparency; retained for G11/G36. Private log SHA-256 `1e1ba66b908f6e1830d8ad368c83d0b3ab9e310ad86a47bc3635422c8dbb1e84` recorded 85 audio drops and is rejected from audio-row acceptance.
- PRD row 22 is now **28/32 Pass, 4 Open**. Lightning Cup is 3/4.

## 2026-08-29 — G10 Koopa Cape exact native completion

- Used the sole native KartPad process for Time Trials → Star Cup → Koopa Cape → `Nin★Rose 03:03.022` → Watch Replay. No Dolphin or Simulator was present.
- Course ID 15 has 11,211 regular-staff frames. The strict assertion accepts stage 2 exactly `240..11210` for 10,971 consecutive samples followed by stage 4. Earlier non-finishing preview segments are ignored; the later partial segment is the automatic replay loop.
- Private trace SHA-256 is `9a1d221da310ddc39001c9cf122b9f5d70da1354570f5bcf7a960a62234658f0`; exact executable SHA-256 is `94b1da8d3d97cb857f75ef358cdd2817b27ba52eeed28f827d0bd21349fa17aa`.
- Bounded presentation checks remained at the 60 FPS overlay target through water, waterfalls, ramps, moving shells, rotating electrical hazards, transparent pipe geometry, particles, and ghost transparency; deterministic cadence remains G11 work. Private log SHA-256 `dc32da54eb0e57cc39e257bb407362603bf76cdce8dc1e275f840ff700eab087` recorded 56 audio drops and is rejected from audio-row acceptance.
- PRD row 22 is now **29/32 Pass, 3 Open**. Star Cup is complete at 4/4.

## 2026-08-29 — G10 Bowser's Castle exact native completion

- Used the sole native KartPad process for Time Trials → Special Cup → Bowser's Castle → `Nin★YABUKI 03:04.836` → Watch Replay. No Dolphin or Simulator was present.
- Course ID 12 has 11,320 regular-staff frames. The strict assertion accepts stage 2 exactly `240..11319` for 11,080 consecutive samples followed by stage 4; the later partial segment is the automatic replay loop.
- Private trace SHA-256 is `1113377b06e3dcd119ae1bb3129aeb220168f6e9a408d28976603b12a4bff817`; exact executable SHA-256 is `c7e28cfa27f69d0efd9d243c0ab2fd04187971cc8856a87f30a2c4b3234a9cbc`.
- Bounded presentation checks sampled from 51 to 60 FPS through lava, Thwomps, moving geometry, half-pipes, fire effects, interior/exterior geometry, and ghost transparency. Private log SHA-256 `66247e3e9637b5da5de85b9ef1858d9044cf965c0bc2b20a650c120bf6794eed` recorded three audio drops and is rejected from audio-row acceptance.
- PRD row 22 is now **30/32 Pass, 2 Open**. Special Cup is 3/4.

## 2026-08-29 — G10 Rainbow Road exact native completion

- Used the sole native KartPad process for Time Trials → Special Cup → Rainbow Road → `Nin★Konno 03:05.895` → Watch Replay. No Dolphin or Simulator was present.
- Course ID 13 has 11,383 regular-staff frames. The strict assertion accepts stage 2 exactly `240..11382` for 11,143 consecutive samples followed by stage 4; the later partial segment is the automatic replay loop.
- Private trace SHA-256 is `a1fd02aaf2950c22424570509719b5a7f54cc4de9cfa88cf52fb37e628f25a22`; exact executable SHA-256 is `8fc836be5c0c620625070d4c0a0fef37502fa7550c156c34640cfd3defbc4ce8`.
- Bounded presentation checks sampled from 49 to 56 FPS through the star field, transparent road, animated rails, half-pipes, boost ramps, banked turns, camera transitions, and ghost transparency. Private log SHA-256 `4c404aa3820e8a19f6361e38b256ccf79e964cbc8de29e5f48d76c0c12c2e591` recorded 30 audio drops and is rejected from audio-row acceptance.
- PRD row 22 is now **31/32 Pass, 1 Open**. Special Cup is complete at 4/4.

## 2026-08-29 — G10 N64 Bowser's Castle and retail-track matrix completion

- Used the sole native KartPad process for Time Trials → Lightning Cup → N64 Bowser's Castle → `Nin★GASK2 03:19.323` → Watch Replay. No Dolphin or Simulator was present.
- Course ID 28 has 12,188 regular-staff frames. The strict assertion accepts stage 2 exactly `240..12187` for 11,948 consecutive samples followed by stage 4; the later partial segment is the automatic replay loop.
- Private trace SHA-256 is `a79ca17ab964bbc029139b2b155d6997019dbd7550ed041117a9eb38ead5df21`; exact executable SHA-256 is `421fad338fca6d4e197bc533cc5a73a36461c36b70436e99b0e7b54d6a889404`.
- Bounded presentation checks sampled from 52 to 58 FPS through lava, stone corridors, moving platforms, fire hazards, exterior towers, bridges, jumps, camera transitions, and ghost transparency. Private log SHA-256 `da41f9a68c71bad36cef491e39c466db5df7a86771f6e2b8e2c7b7e54dad734c` recorded 41 audio drops and is rejected from audio-row acceptance.
- PRD row 22 is now **32/32 Pass, 0 Open**. Lightning Cup and the exact native retail-track matrix are complete.

## 2026-08-29 — G10 full-range keyboard steering correction

- A fresh three-player Luigi Circuit completion attempt exposed that the keyboard Classic-stick bridge used `0.08f` despite its full-normalized-range contract. P1 could accelerate but could not reliably recover from barriers.
- Changed the reproducible Apple-runtime patch and the immediate private generated source to `1.0f`; the arm64 target rebuilt, the patch dry-ran against the pin, the app passed strict signature verification, and live three-player driving showed decisive turn and reverse-turn response.
- Public patch SHA-256 is `9cda1217ab0f9d16549e19f288bd8c61d9ee38f6729eeb43f0a48700198b8fe5`; closed re-sealed executable SHA-256 is `dee991ea9596cf24b05c3329215722a52238d7c3faf5d4e236fcd157f07eee0f`. Evidence: `docs/artifacts/2026-08-29/g10-keyboard-steering-range.md`.
- Three private traces remain rejected: the old 8%-range attempt, an over-steered retry with the obsolete cadence, and a calibrated GUI-tap attempt that entered runoff and struck scenery. None reached standings, so row 30 remains open without inflation.

## 2026-08-29 — G10 obsolete-service graceful fallback

- Exercised Nintendo WFC (1P) and Mario Kart Channel in the sole native process. WFC exposed the original data-sharing warning; the privacy-safe Do Not Allow path explicitly disabled WFC and returned to Main Menu. Channel local rankings opened normally.
- No public-service connection, data consent, Dolphin, or Simulator was used. The private log contains DWC initialization with no error/panic signature; the app closed normally.
- The live RKSYS remained byte-identical to the all-cups fixture at SHA-256 `f09f809cb13bedb6959cf05aeb550fe7c19db2ea74fcc3cf61665d5b0b7b90ec`. Private trace SHA-256 is `02eb3c43f1d10302301472ae38dadf976c568297aac639a4da28f6123c4fc186`; private log SHA-256 is `71269bd71150c5016ac5d5a252dba92acf9cf59d15340fcb52aeed2f5d5a2e6f`.
- Evidence: `docs/artifacts/2026-08-29/g10-obsolete-services/`. Its 1,327 audio drops are rejected from audio/performance acceptance.

## 2026-08-29 — G10 accessibility steering cadence refinement

- The first honest 50cc Mushroom Cup attempts exposed a second GUI-input limitation after full physical keyboard range was restored: 50 ms synthetic axis pulses left neutral gaps between accessibility-generated taps, while extending full-strength pulses to 250 ms made each correction too coarse.
- Split physical and synthetic axis levels. Real keyboard holds retain the full normalized endpoint; synthesized GUI taps use 0.35 for 250 ms. Controllers and future touch input remain unchanged.
- Rebuilt and re-sealed the arm64 app. A clean Luigi Circuit smoke run took the opening bend with bounded single-tap corrections; all incomplete cup traces remain rejected, and Grand Prix progression is still open.
- Public patch SHA-256 is `c7aa6bdcdba3dd49bcfb325bbb0074d2a92ee9a6a4c208dbbc1edbb1aabc78be`; closed executable SHA-256 is `454a9eebbeb0d680c77a52480970b512842a3a46c89ef37483f82d3187a2a0fe`.

## 2026-08-29 — G10 Time Trial personal-record lifecycle

- Created and saved a `Player 01:38.880` SNES Mario Circuit 3 personal ghost through the retail result flow. A fresh process loaded the record and its `Watch Replay` path consumed the full stored stream through finish before the normal automatic replay loop.
- Personal Time Trial ghosts are authentically replaced by beating the stored best. Added a strict private-fixture tool that changes only the selected leaderboard timer plus core CRC and leaves the ghost payload untouched; its positive and refusal self-tests pass.
- Rejected an expert-stream divergence, two existing-PB grid-origin mismatches, and a live run that exceeded the retail recorder budget. None is acceptance evidence.
- A later normal live-input run completed all real checkpoints and laps in `05:01.445`, displayed `Saved ghost data for Player!`, and replaced the personal best. Its strict private trace accepts race time `240..18308`, 18,069 consecutive racing samples, and finish stage 4.
- A second fresh process loaded the `Player 05:01.445` card. The final save SHA-256 is `ad79c24bc5eb0ba6bc8cd2836a55680621892b578a04ea49d8884a71a42c563a`; the bounded relaunch audio sample ended with zero empty observations and zero dropped blocks.
- Classification: **PRD row 26 Pass.** Evidence and complete diagnostic boundary: `docs/artifacts/2026-08-29/g10-time-trial-record/`.

## 2026-08-29 — G10 replay pause/resume audio continuity

- Ran the durable `Player 05:01.445` SNES Mario Circuit 3 replay in the sole signed native process, opened the retail pause menu for 15 seconds, selected `Continue Replay`, and observed the ghost resume normally.
- Before pause, the bounded queue reached 40,960 checks with zero empty observations or drops. While paused it reached its latency cap and deliberately discarded eight stale blocks (3,072 bytes); no underrun occurred. After resume, the count remained exactly eight through 81,920 checks and 31,453,824 submitted bytes, proving no continuing starvation or drop cascade.
- The live save remained byte-identical at SHA-256 `ad79c24bc5eb0ba6bc8cd2836a55680621892b578a04ea49d8884a71a42c563a`.
- Classification: **Pass for PRD row 33's pause/resume subcase; row 33 remains in progress.** Output-device migration, subjective listening, and the required long session remain open. Evidence: `docs/artifacts/2026-08-29/g10-audio-pause-resume/`.

## 2026-08-29 — G10 live output-device migration

- Ran the durable `Player 05:01.445` SNES Mario Circuit 3 replay in the sole signed native process. With no Simulator or reference emulator active, changed the macOS default output from the user's original `Jump Desktop Audio` to `MacBook Air Speakers`, observed active replay, then restored and verified the original output.
- Pre-switch telemetry reached 57,344 checks with zero empty observations and zero drops. The two route transitions deliberately discarded 101 stale blocks (38,784 bytes) in bounded bursts; no empty observation occurred. The counter then remained exactly 101 through 98,304 checks and 37,709,568 submitted bytes while the replay remained visibly live.
- The app closed normally, the final queue was bounded at 6,468/15,360 bytes, and the RKSYS save remained byte-identical at SHA-256 `ad79c24bc5eb0ba6bc8cd2836a55680621892b578a04ea49d8884a71a42c563a`.
- Classification: **Pass for PRD row 33's output-device-change subcase.** This proves continuity and recovery without sustained underrun or latency growth; it does not claim subjective absence of a transient. Subjective listening and the required long representative session remain open. Evidence: `docs/artifacts/2026-08-29/g10-audio-device-migration/`.

## 2026-08-29 — G13 distributable static macOS package checkpoint

- Audited the working runtime's linkage and found a real compatibility defect: it declared macOS 14.0 while loading Homebrew dependencies built for macOS 26. Replaced host-discovered Abseil, SDL3, libpng, and FreeType with pinned static source builds under the declared deployment target.
- The first relink was rejected at undefined `func_8055531C`. The build cache showed the obsolete 10,836-function G6 manifest; the function exists in the authoritative 29,637-function G8 full-title graph. Reconfigured with only that corrected manifest and linked successfully without a stub or fallback. The preparation script now defaults to the full graph.
- Added first-party source-path redaction, a fail-closed macOS packager, and a package auditor. The packager includes the DSP ROM, initial pipeline cache, first-run Wii bootstrap, and original ICNS while refusing private/writable state and non-system dependencies.
- The regenerated candidate identifies committed source `17cee52d92b70b73e8216a8469dfba668cf4022d`, is arm64 with a macOS 14.0 floor, has only Apple system dynamic dependencies, contains no builder-home path or disc image, and passes strict ad-hoc codesign and bundle audits.
- Candidate hashes: unsigned packaged runtime `544e47f42718db5894127cef7712374d2fd871a6cac55645a87a0b6ec6af2303`; signed executable `05f868bc6826ee009356abc236e9ce507a123e687d86ced0fb33665ab1a11d36`; bundle-content audit `8a8ff8b38aa699070f3e6ad20a251a4adafb0a3d5cdb7df71aed90bacecbd602`.
- Classification: **Pass for G13 build/link/package audit only.** Exact-package launch, Application Support relocation, and gameplay remain open. The candidate was not launched because the one-game-instance rule protects the active long replay. Evidence: `docs/artifacts/2026-08-29/g13-macos-package/`.

## 2026-08-29 — G13 static-source archive pin completion

- Audited every FetchContent input used by the new static macOS graph. Aurora already enforced hashes for Dawn, libpng, FreeType, xxHash, fmt, ImGui, SQLite, zstd, and Tracy; only Abseil 20240722.0 and SDL 3.4.4 lacked archive digests.
- Declared those two inputs before Aurora so CMake's first-declaration rule enforces exact SHA-256 values. Generated URL metadata now contains the expected hashes, both downloaded archives match, patch dry-run passes, and reconfiguration succeeds.
- Ninja reported no work and the runtime remained byte-identical at SHA-256 `4c12eadfd5edf0dd106b76692bef82d8162026684969c7b498a0d3a830f4a0a5`, confirming a reproducibility-only change.

## 2026-08-29 — G15 exact SunPad overlay baseline, Classic adapter, and native shell

- Imported the exact SunPad touch overlay, settings, diagnostics, input state, and mixer from pinned commit `e43f0ea6b797e5110787171957c9dc3c6213269c`, together with the complete GPLv3 text and explicit upstream provenance. A repository verifier proves the nine source files and license remain byte-identical to the local pinned reference.
- Used Nintendo's *Mario Kart Wii Instruction Booklet* Classic Controller diagram rather than inferred mappings. Added a separate adapter from SunPad's normalized GameCube-shaped input to KartPad's existing Classic ABI: A accelerate, B/R drift-brake, L item, X/ZR rear view, Plus pause, and D-pad trick/wheelie.
- Added an arm64 Objective-C++ contract test covering every button independently, their simultaneous union, both sticks, and connection state. The focused build/test and exact-snapshot verifier pass.
- Added a real UIKit lifecycle and `CAMetalLayer` iOS target that compiles the byte-identical overlay directly, packages the original light/dark/tinted icon assets and privacy manifest, and builds as a system-library-only arm64 iOS Simulator app with a 16.0 minimum. The fail-closed shell auditor passes.
- The launch runner audits before install, refuses a second booted Simulator, and refuses to overlap the live macOS game. Its concurrent-game guard exited 75 as designed; no Simulator was booted during the protected macOS soak.
- Classification: **mobile shell/source integration in progress**. Direct-copy, input-boundary, native build, package, and concurrency-guard evidence pass; the game core is not linked and no Simulator gameplay, visual comparison, or touch-feel acceptance is claimed. Evidence: `docs/artifacts/2026-08-29/g15-sunpad-overlay.md`.

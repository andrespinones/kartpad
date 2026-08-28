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

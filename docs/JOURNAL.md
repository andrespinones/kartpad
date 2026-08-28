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

# G10 three-player camera lifecycle repair

Date: 2026-08-29

## Scope

This artifact records a deterministic native-runtime defect found while working toward PRD row 30. It is repair evidence for repeated local-multiplayer lifecycle transitions; it is not a claim that the complete three- or four-player race row passes.

## Before

The following normal retail sequence reproduced the same crash three times:

1. Register three independent Classic-controller channels.
2. Start a three-player 100cc VS race on Luigi Circuit.
3. Pause, quit the race, and return to Main Menu.
4. Start a second three-player race.

Each failure was an `EXC_BAD_ACCESS` in translated guest function `func_805A2034`. Focused instrumentation at the shared race-camera list walker showed a reclaimed camera object still linked after scene teardown. Its player slot was `0xff`; the retail camera update sign-extended that value to `-1` and selected the word immediately before the active kart-object array. The resulting accessor value was the deterministic reclaimed-memory sentinel `0x55440003`.

An independently retained macOS report (incident `971E643B-5DC8-49AE-BB03-50AAC083B40C`) later corroborated the same failure. It records `EXC_BAD_ACCESS (SIGBUS)` in `func_805A2034` at guest-mapped address `0x100055440027`: guest address `0x55440027`, exactly the reclaimed scene-heap sentinel `0x55440003` plus the translated 36-byte field access. The report belongs to an earlier dynamic development binary (UUID `37EA5AFE-E0BF-3496-ADE3-F1340876C3AA`, version `0.0.1`, bundle `dev.kartpad.runtime-spike`) that loaded Homebrew SDL; it is not the corrected development binary or the static package candidate. The report therefore strengthens the diagnosis but is not a new failure of the corrected build.

Local macOS reports were created at 07:01:07, 07:34:32, and 07:52:05. They remain outside the repository because full diagnostic reports can contain host-specific data.

## Rejected broad repair

`scripts/inject-g10-camera-lifecycle-guard.py` reproducibly patches the generated shared camera-list walker before stable build shards are emitted. At the existing translated thunk boundary it:

- recognizes a reclaimed camera marker;
- unlinks that node using the retail intrusive-list layout and previous/next semantics;
- updates the list head, tail, and count;
- clears the removed node's links; and
- resumes from the current list head during the same walker pass.

The first version treated every `player slot == 0xff` camera as reclaimed. That premise was false: retail three-player races deliberately create a non-player overview camera with slot `0xff` for the fourth pane. A later repeat-race run crashed in `ScnMgrRace::vf_0xC` while reading through `0x55440003 + 8`. A bounded diagnostic guard prevented that crash but logged a live scene manager whose camera pointer itself was `0x55440003`; the second race then showed HUD labels over a black scene. This proved the broad camera removal had left `RaceCameraMgr::sortedCameras` referring to an overview camera that the guard had incorrectly unlinked and allowed the scene heap to reclaim. The diagnostic guard and its generated-source invocation were removed.

## Corrected repair

The retained guard now requires both independent facts before unlinking a list node:

- `RaceCamera::playerId == 0xff`; and
- the camera object's leading word is the observed scene-heap poison `0x55440003`.

The conjunction preserves legitimate retail non-player cameras while still removing the stale reclaimed node that caused the original `func_805A2034` failure. The injector requires one exact signature and insertion point, refuses partial input, and verifies idempotently when run twice against the generated function. `scripts/generate-g8-full-title.sh` invokes it as part of the full-title generation path, so the repair is not an ignored build-tree edit.

The same generation script now reapplies the leading-underscore Mach-O aliases after `generate-data-init`, which otherwise rewrites `data_sections_init_blobs.S` and makes a clean incremental Apple link fail on undefined `_kData_*` symbols.

## After

The arm64 runtime was regenerated into all 72 stable shards, rebuilt, copied into `KartPadRuntime.app`, ad-hoc signed, and passed strict signature verification.

Playtested executable SHA-256: `3d15b8dade09679c0cdc78dd6a40304f28d3888e0fb2471da365e32bc9b6d16f`.

With the corrected guard in place, a fresh single-process run completed the exact three-player Luigi Circuit race → Pause/Quit → Main Menu → three-player Luigi Circuit sequence. The first race rendered the three player panes plus the fourth retail overview pane. The second race again rendered all four panes during its intro and live lap-one gameplay, with distinct Mario, Luigi, and Yoshi HUD state and a functioning overview camera. PID 48089 remained the sole KartPad process across the transition and was closed only after acceptance. No Dolphin or Simulator was running. Its 267-line private console log hashes to `9085cef84e023f061e3d1e9ce325ddb8db2bd3a2a1a1a2724efdf4d2ac31ac47`, contains two retail `Scene Restart` records, and contains no temporary `scnmgr-lifecycle` diagnostic.

The captured overlays from this focused lifecycle run ranged from 14.8–19.8 FPS and are explicitly rejected as cadence evidence. Its bounded audio summary also recorded 18 dropped blocks, so the run is not audio acceptance. The already accepted clean-load observation remains the retail 29.5–30.1 FPS three-player cadence; complete three-/four-player standings cycles remain open.

The pre-run app passed strict ad-hoc signature verification. The post-run check then correctly failed because Dawn had mutated `UserData/Cache/dawn_cache.db-shm` inside the sealed app bundle; the executable itself still had the playtested hash above. Re-sealing restored strict bundle verification and produced signature-different executable SHA-256 `f6b40a3902ac5ba559d359c5b1cb5488176ebf14bc8eab3da1371c1fd146f9fc`. This writable-in-bundle packaging issue is recorded for G13 and is not hidden as a successful post-run seal.

## Classification

**Pass for the repeated-race camera lifecycle defect.** PRD row 30 remains in progress until normal three- and four-player races each reach their full standings/result cycle.

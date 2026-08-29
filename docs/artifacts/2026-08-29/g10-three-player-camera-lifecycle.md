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

Local macOS reports were created at 07:01:07, 07:34:32, and 07:52:05. They remain outside the repository because full diagnostic reports can contain host-specific data.

## Repair

`scripts/inject-g10-camera-lifecycle-guard.py` reproducibly patches the generated shared camera-list walker before stable build shards are emitted. At the existing translated thunk boundary it:

- recognizes the reclaimed camera marker (`player slot == 0xff`);
- unlinks that node using the retail intrusive-list layout and previous/next semantics;
- updates the list head, tail, and count;
- clears the removed node's links; and
- resumes from the current list head during the same walker pass.

The injector requires one exact function signature and one exact insertion point, refuses partial or unexpected input, and is idempotent. `scripts/generate-g8-full-title.sh` invokes it as part of the full-title generation path, so the repair is not an ignored build-tree edit.

## After

The arm64 runtime was regenerated into all 72 stable shards, rebuilt, copied into `KartPadRuntime.app`, ad-hoc signed, and passed strict signature verification.

With the generic list guard in place, a fresh single-process run completed the exact race → quit → Main Menu → race reproduction and reached live three-pane Luigi Circuit gameplay in the second race without a crash or process relaunch. A prior narrow diagnostic guard also survived an additional restart cycle, supporting the lifecycle diagnosis; that diagnostic implementation and its temporary traces were removed before this candidate.

The post-repair process remained live for more than 15 minutes. Its later frame-rate overlay is not accepted as cadence evidence because a separate eight-worker LLVM translation job was simultaneously consuming the host. That unrelated process was left untouched. The already accepted clean-load observation remains the retail 29.5–30.1 FPS three-player cadence; a new uncontended sample and complete three-/four-player standings cycles remain open.

## Classification

**Pass for the repeated-race camera lifecycle defect.** PRD row 30 remains in progress until normal three- and four-player races each reach their full standings/result cycle.

# G11 FPSCR helper-effect model

Date: 2026-08-30

## Problem

KartPad's reproducible WiiCompiled patch lowers stateful floating-point
instructions to runtime helpers that read and update `CpuContext.fpscr`.
The inherited helper-effect catalog still labeled several of those helpers as
pure, while other newly introduced double-precision and No-NI helper names fell
through to a full-context boundary. Both outcomes were wrong: one hid real
architectural state and the other blocked otherwise safe compiler analysis.

## Change

- `GuestHelperEffect` now carries hidden FPSCR read/write bits.
- Scalar, No-NI, paired arithmetic, estimates, conversions, comparisons,
  `mffs`, `mcrfs`, and `mtfs*` helpers have explicit effects.
- ABI contracts and backward guest-state liveness consume those effects.
- Unknown helpers remain complete-context boundaries.
- The patch preparation path uses `git apply --recount` so the compact tracked
  patch is reproducible after the added source sections.

This is a correctness foundation, not an FPSCR-elision transform. Stateful
arithmetic remains read/modify/write because sticky exception state and enabled
exception bits can affect later observations and destination writes.

## Verification

- Clean patch application and Release translator build from immutable upstream.
- Translator tests: 582 passed, 0 failed, 0 skipped.
- arm64 and x86_64 semantics: 250,227 checks each, identical state hash
  `0xccd5757c4c0643d4`.
- Translated fixture: identical checked-memory result and final FPSCR
  `0xe7991393` on both architectures.
- arm64 ASan/UBSan translated and direct semantic fixtures pass.
- Dolphin estimate oracle remains byte-identical.

## Result

Accepted as a prerequisite. No performance claim is made until a full-title
generation and production profile quantify the effect of replacing false
full-context fences with precise FPSCR dependencies.

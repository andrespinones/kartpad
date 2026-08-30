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

## Full-title production counterbalance

The exact `2282e2c` graph regenerated all 29,637 functions, updated 1,093
emitted files, derived 296 state-free interfaces and 70 compact call-site
variants, and built an audited telemetry package:

- bundle-content SHA-256:
  `5639c6d88250e9490e6ade128ce83e36a8c92ae1cac9b04ccb331affbcb8cfea`
- executable SHA-256:
  `a9f05ebc8cfba4be0e790337439f82a52c27154014903e07bd86d25035cf39ef`

Back-to-back 30-second Time Profiler samples used the same title attract-race
sequence and the same persisted application state. The candidate recorded
10.432 sampled CPU-seconds and 7.527 main-thread seconds. Exact source
`2cfb7e1` recorded 10.813 sampled CPU-seconds and 7.402 main-thread seconds.
The candidate's total was 3.5% lower, but its main-thread time was 1.7% higher;
that is noise, not a supported speedup. `feclearexcept` remained 0.443 versus
0.465 seconds and `fetestexcept` 0.066 versus 0.081 seconds.

Both packages held 60 FPS with approximately 16.7 ms p50, bounded p99/worst
samples, zero queued pipelines during measurement, zero audio drops, normal
scene transitions, and clean exits. No Simulator was booted. Raw traces and
private logs remain ignored.

Final classification: the effect model is retained for correctness, but its
production performance effect is **neutral**. FPSCR bookkeeping remains a
ranked CPU cost; this change does not solve it.

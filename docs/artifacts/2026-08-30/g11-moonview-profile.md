# G11 Moonview Highway profile checkpoint

Date: 2026-08-30  
Revision under test: `90a24ec`  
Package: `build/KartPad-g11-present-2cfb7e1.app`  
Bundle SHA-256: `dc6ecdca64df7a031fde00ab63472f0130674e8705bd27196483d6a0005615de`

## Fixture

The exact packaged macOS build was launched through
`scripts/run-macos-package.sh` with no booted Simulator and no other KartPad or
Dolphin process. The deterministic fixture was one-player 100cc VS on Moonview
Highway, Mario in the Standard Kart with Automatic drift, stationary after the
course became interactive. Pipeline caches were already warm.

The overlay held 60 FPS while stationary. Instruments then captured the same
live process and scene for 30 seconds with Time Profiler and 20 seconds with
Metal System Trace. The app exited through its normal Command-Q path afterward;
the bounded session record says `endedCleanly=yes`.

Raw Instruments traces and exports remain ignored under `private/`. They are not
committed because they include host paths and environment data.

## CPU result

Time Profiler sampled 16.219 CPU-seconds during its 30-second recording:

| Thread | Sampled CPU time | Share |
| --- | ---: | ---: |
| Main thread | 14.507 s | 89.4% |
| Frame submission thread | 1.131 s | 7.0% |
| All remaining threads | 0.581 s | 3.6% |

The dominant leaf costs were `feclearexcept` at 6.098 seconds (37.6%) and
`fetestexcept` at 1.424 seconds (8.8%). `PpcFmulsStateInline` was responsible
for 4.509 seconds inclusive (27.8%). This ranks host floating-point environment
bookkeeping inside the scalar PowerPC semantics as the first CPU optimization
candidate. It does **not** justify weakening FPSCR correctness.

## GPU result

The Metal trace contained 70,318 KartPad GPU intervals spanning 20.561 seconds.
The union of those intervals occupied 2.499 seconds, or 12.15% of the span.
There were no drawable-wait intervals and no graphics-compiler activity during
the warm capture. Metal allocation was stable at 545.39–545.42 MiB.

| Channel | Intervals | p50 | p95 | p99 | Maximum |
| --- | ---: | ---: | ---: | ---: | ---: |
| Compute | 6,168 | 48.5 us | 55.1 us | 469.4 us | 0.668 ms |
| Fragment | 32,067 | 16.0 us | 263.6 us | 479.0 us | 1.082 ms |
| Vertex | 32,083 | 8.8 us | 27.4 us | 291.3 us | 0.508 ms |

CPU-to-GPU latency was 1.182 ms at p50, 2.760 ms at p95, 12.526 ms at p99,
and 13.266 ms at maximum. The built-in display reported 60 surface swaps in
each complete one-second bucket. The evidence therefore does not rank steady
GPU execution as the bottleneck in this fixture.

## Next bounded experiment

On arm64, replace only the host `feclearexcept`/`fetestexcept` plumbing used by
the existing PowerPC semantic helpers with direct FPSR clear/read operations.
Translate the FPSR overflow, underflow, and inexact bits back into the same
standard exception-mask contract. Accept the experiment only if the narrow
semantic contracts, translated fixture, cross-architecture hashes, and broader
G6 suites remain exact, then compare the same packaged Moonview fixture.

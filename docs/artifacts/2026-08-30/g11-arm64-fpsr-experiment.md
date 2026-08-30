# G11 arm64 FPSR experiment

Date: 2026-08-30  
Starting revision: `b3964fb`  
Outcome: **rejected and reverted**

## Hypothesis

The first Moonview Time Profiler capture attributed 46.4% of sampled CPU time
to `feclearexcept` and `fetestexcept`. The bounded hypothesis was that reading
and clearing AArch64 FPSR directly could retain the exact PowerPC FPSCR contract
while avoiding libc call overhead.

The experimental helper preserved non-exception FPSR state, translated OFC,
UFC, and IXC back to the existing host exception mask, and left the x86_64 path
unchanged. It was never committed as production code.

## Correctness gates

The experiment passed every gate used for the G6 semantic boundary:

- arm64 and x86_64 each completed 250,227 checks with reference state hash
  `0xccd5757c4c0643d4`;
- the translated semantic fixture remained bit-identical, including FPSCR
  `0xe7991393`;
- the sanitized arm64 contracts and translated fixture passed;
- all 579 translator tests passed.

## Microbenchmark

A release-mode loop of ten million stateful scalar PowerPC multiplies produced
the same result/FPSCR checksum. Across five runs, the median fell from 41.1233
ns per operation to 30.4203 ns, a 26.0% microbenchmark improvement.

That result was not accepted on its own.

## Production counterbalance

Both packages ran the same one-player 100cc VS fixture on Moonview Highway with
Mario, Standard Kart, Automatic drift, stationary after the course became
interactive. Pipeline queues were empty, presentation was 60 FPS, and each
package received a separate 30-second Time Profiler capture. The optimized run
was immediately followed by the original package to reduce machine-state bias.

| Measurement | Direct FPSR experiment | Original libc control |
| --- | ---: | ---: |
| Sampled CPU time | 17.575 s | 17.392 s |
| Main-thread sampled time | 14.918 s | 14.719 s |
| Main-thread share | 84.88% | 84.63% |
| `PpcFmulsStateInline` inclusive | 4.232 s | 4.320 s |
| Visible steady presentation | 60 FPS | 60 FPS |

The direct path moved samples out of the named libc leaves and into the inlined
PowerPC wrappers, but it did not reduce total or main-thread CPU time. The
serialized FPSR access itself is the cost. The tiny frame-time difference seen
in individual 60-frame windows was not large or stable enough to override the
paired CPU result. The implementation and benchmark target were therefore
reverted.

The telemetry-enabled experiment package audited at bundle-content SHA-256
`8272998b127d2ddcadddc6600e4e9c23505384ea0fbe1fbb8df8aaafdf910c46`.
Both production runs exited through Command-Q with `endedCleanly=yes`. Raw
Instruments traces remain ignored under `private/` because they contain host
paths and environment data.

## Better-ranked next direction

The full translated graph contains 43,649 stateful scalar FP helper call sites:

| Helper family | Static call sites |
| --- | ---: |
| `fmuls` | 19,406 |
| `fsubs` | 11,372 |
| `fadds` | 9,412 |
| `fdivs` | 2,075 |
| Remaining scalar families | 1,384 |

By contrast, the graph contains only 12 explicit FPSCR observer/mutator call
sites: five `mffs`, five `mtfsf`, and two `mtfsb1`, spread across three of 106
generated shard files.

This does **not** permit globally dropping exception state: an FP instruction
can feed a later observer across calls. It does rank a translator data-flow
optimization above further host-FPSR micro-tuning. The safe shape is to emit
the existing value-only helper only when interprocedural analysis proves the
instruction's FPSCR result dead before every observer, exception-enable effect,
and guest-state boundary; otherwise retain the exact stateful helper. That path
can remove serialized host exception accesses rather than merely spelling them
differently.


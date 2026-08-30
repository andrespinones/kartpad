# G11 macOS pipeline-worker sweep

Date: 2026-08-30  
Classification: diagnostic comparison; G11 remains open

## Question

Would reducing Aurora's priority Metal pipeline-compilation workers from six
to one remove the first-use frame and audio disruption seen on the accepted
Apple Silicon title fixture?

Each leg used an audited exact package, one game process, no booted Simulator,
an empty KartPad application cache, bounded presentation/audio telemetry, and a
normal Command-Q shutdown. Generated caches were retained under ignored
`private/`; the original two-file application cache was restored after every
leg with relative tree SHA-256
`34fafbdcd96c978d025b1604cf2fe74e14f1561d9d8aa1ea647d929226c7c031`.

## Results

| Leg | Priority workers | Minimum effective FPS | Maximum p99 | Worst | Audio drops | First pipeline state |
|---|---:|---:|---:|---:|---:|---|
| Original controlled cold baseline | 6 | 51.958 | 83.783 ms | 85.094 ms | 20 | 534 queued / 665 created |
| Initial experimental sweep | 1 | 59.999 | 16.922 ms | 26.557 ms | 0 | 0 queued / 1,199 created |
| Exact post-commit confirmation | 1 | 55.460 | 55.101 ms | 71.437 ms | 17 | 1,138 queued / 61 created |
| Counterbalance A | 6 | 52.000 | 59.646 ms | 91.367 ms | 0 | 0 queued / 1,199 created |
| Counterbalance B | 1 | 59.868 | 16.990 ms | 25.169 ms | 0 | 206 queued / 993 created |
| Counterbalance A repeat | 6 | 59.974 | 17.596 ms | 18.016 ms | 0 | 0 queued / 1,199 created |

The exact package hashes were:

- six-worker source `2cfb7e161db8e3f4d69f658d163dcb8e3d242e6c`, bundle
  `dc6ecdca64df7a031fde00ab63472f0130674e8705bd27196483d6a0005615de`;
- one-worker source `64359cb974b3683bf31f5c65db26dfa2351533aa`, bundle
  `84f213f8096138ec59883a254723f11835beb918522bb9d672a56cf38426f861`.

The three counterbalance console-log SHA-256 values were
`b91595ae3cbb2bd799f8a73e0d4aeaac301cc35b2c8e4e8f097252c274715ed4`,
`208b94737d34b745a664cce399bcf3075ebe8acc4289feb7268f2221ac6e9263`,
and `ae26a397e7d65881ae66b64274efa45170e6640e8fa4149953c505f9072d5bc1`.
Logs remain private because they may contain local runtime context.

## Decision

The first one-worker result did not reproduce in its exact post-commit run,
and six workers became equally smooth after the machine-level Metal/Dawn state
was exercised. Application-cache emptiness alone therefore does not define a
true GPU cold start. Worker count is not established as the root cause, while
one worker demonstrably drains a visible queue more slowly.

The macOS one-worker default is reverted. The bounded telemetry remains. The
next optimization experiment must control or explicitly record both KartPad's
SQLite caches and machine/driver-level Metal state, then profile a deterministic
race fixture rather than infer causality from title-path ordering.


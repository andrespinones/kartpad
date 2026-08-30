# G11 interrupted macOS soak

Date: 2026-08-30  
Classification: interrupted diagnostic; **not** the required eight-hour pass

## Identity and controls

- Runtime source fingerprint: `2282e2c04e80e754a3292854547e0a91dc7572b7`
- Monitor/tooling source: `bbb01a690c0ac124c34829e963238ce6c6cd3770`
- Executable SHA-256:
  `a9f05ebc8cfba4be0e790337439f82a52c27154014903e07bd86d25035cf39ef`
- Audited bundle-content SHA-256:
  `5639c6d88250e9490e6ade128ce83e36a8c92ae1cac9b04ccb331affbcb8cfea`
- Hardware: Mac14,2 on macOS 26.5 (`25F71`), AC power
- Requested duration: 28,800 seconds
- Sampled duration: 15,010 seconds (4:10:10), 251 one-minute samples
- Maximum sample gap: 61 seconds

Exactly one KartPad game process was tracked and `simctl` reported zero booted
iOS devices during checked intervals. However, the Simulator application shell
was left visibly open beside the macOS game. That violated the user's
one-visible-runtime expectation even though no Simulator device was booted.
The operator stopped the visible runtimes; the monitor recorded the game as
exited early at 15,072 seconds. The run has no end vmmap, `leaks` result,
normal-quit record, or eight-hour duration and is rejected from PRD row 38.

## Memory and thread result

The partial trace is useful diagnostic evidence, not soak acceptance:

| Metric | Result |
|---|---:|
| Initial / final sampled RSS | 436,912 / 424,576 KiB |
| Minimum / maximum RSS | 257,120 / 1,125,792 KiB |
| Post-15-minute first / last RSS | 907,600 / 424,576 KiB |
| Post-warmup least-squares slope | -137,681.6 KiB/hour |
| Thread minimum / maximum | 23 / 28 |

Repeated attract-mode scene changes produced large allocation and release
cycles. The endpoint, fitted slope, and repeated low-water returns contradict
monotonic growth over this partial duration. They do not replace the missing
eight-hour end-state leak scan.

## Frame and audio result

The workload exercised both retail 60 Hz and native 30 Hz scenes. Long clean
stretches held their target cadence with no queued pipelines. Representative
transitions also exposed bounded misses, including 137 and 154 ms worst-frame
windows, a brief 54.7--57.8 FPS 60 Hz scene, and a native-30 transition that
briefly reached 21.3 FPS before recovering.

Audio queue telemetry is a strict failure:

| Metric | Result |
|---|---:|
| Queue checks | 5,038,080 |
| Submitted bytes | 1,934,438,016 |
| Empty-before-push observations | 0 |
| Dropped blocks / bytes | 480 / 184,320 |
| Observed queue range / limit | 0--15,352 / 15,360 bytes |

Drops occurred in bursts around scene exits and transitions. One burst
coincided with 62 queued pipeline compiles and a 137 ms frame; others occurred
without queued compiles, proving shader compilation is not the only cause. The
runtime's fixed 120 ms maximum queue is below observed transition pressure.
Steady-state audio remained clean between bursts, but any audible drop rejects
strict continuity acceptance.

## Save and privacy

The portable save remained byte-identical at SHA-256
`ad79c24bc5eb0ba6bc8cd2836a55680621892b578a04ea49d8884a71a42c563a`,
2,867,200 bytes, with unchanged modification time. The private console log has
SHA-256 `cb4c7a4d0942d6567bed6582f751af2d1b6d5451332cac168a83b5bafc06608a`.
Raw logs, samples, vmmap output, game data, and save data remain ignored and
outside Git.

## Next experiment

Before restarting the soak, counterbalance the unchanged 120 ms control with a
narrowly larger maximum queue. Measure actual high-water and drain behavior so
extra overflow headroom is not confused with a fixed latency increase. Keep a
candidate only if transition drops reach zero without underruns, unbounded
queue growth, progressive latency, or frame/save regression. Close the
Simulator application itself and verify zero visible competing runtimes before
launching either macOS or a single Simulator device.
